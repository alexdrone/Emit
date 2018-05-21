import Foundation

struct AnyObserver: Equatable {
  /// The concrete observer.
  private(set) weak var observer: Observer?
  /// The registered eents.
  let events: Set<EventIdentifier>
  /// Creates a new weak container for the observer.
  init(observer: Observer, events: [EventIdentifier]) {
    self.observer = observer
    self.events = Set(events)
  }
  /// Returns 'true' if the targets are identical, 'false' otherwise.
  static func ==(lhs: AnyObserver, rhs: AnyObserver) -> Bool {
    return lhs.observer === rhs.observer
  }
}

public enum EventDispatchStrategy {
  /// The event is dispatched in the same thread that called *emitEvent* right away.
  case immediate
  /// The event is always dispatched on the main thread.
  /// If the *emitEvent* invokation was alread in the main thread the effect of this strategy is
  /// the same of *immediate*.
  case mainThread
  /// The event is always dispatched on the main thread, on the next run loop.
  case nextRunLoop
  /// The event is always dispatched off the main thead.
  case backgroundThread
}

final public class EventEmitter<O: AnyObservable>  {
  /// Reference for the observable object emitting changes.
  public weak var observableObject: O?
  /// The current registered observers.
  private var observers: [AnyObserver] = []
  /// Used to track the bindings between KVO and *PropertyChangeEvent*.
  private var kvoTokens: [String: NSKeyValueObservation] = [:]
  /// The event dispatch strategy.
  private var defaultDispatchStrategy: EventDispatchStrategy = .immediate

  /// Constructs a new emitter with the observable object passed as argument.
  public init(object: O) {
    self.observableObject = object
  }

  // MARK: Registration

  /// Registers a new observer for the observable object.
  public func register(observer: Observer, for events: [EventIdentifier] = [ObjectChangeEvent.id]) {
    assert(Thread.isMainThread)
    let container = AnyObserver(observer: observer, events: events)
    observers = observers.filter { $0 != container && $0.observer != nil }
    observers.append(container)
    // Initial change event.
    emitObjectChangeEvent(observer: container, attributes: [.initial])
  }

  /// Force unregister an observer.
  /// - note: This is not necessary in most use-cases since the observation is stopped whenever
  /// the observer object is being deallocated.
  public func unregister(observer: Observer) {
    assert(Thread.isMainThread)
    observers = observers.filter { $0.observer !== observer && $0.observer != nil }
  }

  // MARK: ObservationTokens

  /// Creates an ad-hoc observer for the event passed as argument.
  /// The observation lifecycle is linked to the *ObservationToken* lifecycle.
  /// - parameter id: The identifier of the event being observed.
  /// - parameter onChange: The closure executed whenever the desired event is emitted.
  public func observe<E: AnyEvent>(
    id: EventIdentifier,
    onChange: @escaping (E) -> Void) -> Token<O, E> {
    assert(Thread.isMainThread)
    let observer = ObservationToken<O, E>(id: id, onChange: onChange)
    observer.object = observableObject
    register(observer: observer, for: [id])
    return observer
  }

  /// Creates an ad-hoc observer for the event passed as argument.
  /// The observation lifecycle is linked to the *ObservationToken* lifecycle.
  /// - parameter keyPath: The observed keypath.
  /// - parameter onChange: The closure executed whenever the desired event is emitted.
  public func observe<V>(
    keyPath: KeyPath<O, V>,
    onChange: @escaping (PCEvent<O, V>) -> Void) -> PropertyToken<O, V> {
    assert(Thread.isMainThread)
    let observer = PropertyChangeObservationToken(keyPath: keyPath, onChange: onChange)
    observer.object = observableObject
    register(observer: observer, for: [keyPath.id])
    return observer
  }

  // MARK: Emit

  /// Emit a *ObjectChange* event.
  /// - parameter attributes: Additional event qualifiers.
  public func emitObjectChangeEvent(attributes: EventAttributes = []) {
    emitObjectChangeEvent(observer: nil, attributes: attributes)
  }

  private func emitObjectChangeEvent(observer: AnyObserver?, attributes: EventAttributes = []) {
    guard let object = observableObject else { return }
    let event = ObjectChangeEvent(object: object, attributes: attributes)
    // Notifies the observers.
    emitEvent(event, observer: observer)
  }

  /// Emit a property change event.
  /// - parameter keyPath: The keypath for the changing property.
  /// - parameter old: Optional old value.
  /// - parameter attributes: Additional event qualifiers.
  /// - parameter debugDescription: Optional custom debug string for this event.
  /// - parameter userInfo: Optional user info dictionary.
  public func emitPropertyChangeEvent<V>(
    keyPath: KeyPath<O, V>,
    old: V? = nil,
    attributes: EventAttributes = [],
    debugDescription: String = "",
    userInfo: UserInfo? = nil) {
    // Sanity check.
    guard let object = observableObject else { return }
    let new = object[keyPath: keyPath]

    var event = PropertyChangeEvent(
      keyPath: keyPath,
      object: object,
      old: old,
      new: new,
      attributes: attributes,
      debugDescription: debugDescription)
    event.userInfo = userInfo
    // Notifies the observers.
    emitEvent(event)
    emitObjectChangeEvent()
  }

  /// Emit any arbitrary event.
  /// - parameter event: The event that is going to be pushed down to all of the observers.
  public func emitEvent(_ event: AnyEvent) {
    emitEvent(event, observer: nil)
  }

  /// Emit an event.
  /// - parameter event: The broadcasted event.
  /// - parameter observer: The target observer (all if none is specified).
  /// - parameter strategy: The event disptach strategy.
  private func emitEvent(
    _ event: AnyEvent,
    observer: AnyObserver?,
    strategy: EventDispatchStrategy? = nil) {

    let currentStrategy = strategy ?? defaultDispatchStrategy
    dispatch(strategy: currentStrategy) { [weak self] in
      guard let strongSelf = self else { return }

      let targets = observer != nil ? [observer!] : strongSelf.observers
      // Notifies the observers.
      for target in targets
        where target.events.contains(event.id) || event.id == ObjectChangeEvent.id {
          guard let observer = target.observer else { continue }
          observer.onChange(event: event)
      }
    }
  }

  // MARK: KVO Binding

  /// Whenever a KVO change for *object* is triggered, a *PropertyChangeEvent*
  /// (and an associated *ObjectChangeEvent*) is emitted to all of the registered observers.
  /// This is a convenient way to unify the object event propagation.
  /// - parameter object: The object being KVO observed.
  /// - parameter keyPath: The target keyPath.
  public func bindKVOToPropertyChangeEvent<N: NSObject & AnyObservable,V>(
    object: N,
    keyPath: KeyPath<N, V>) {
    assert(Thread.isMainThread)
    let token: NSKeyValueObservation? = object.observe(keyPath, options: [.new, .old, .initial]) {
      [weak self] (obj: N, change: NSKeyValueObservedChange<V>) in
      let event = PropertyChangeEvent<N, V>(
        keyPath: keyPath,
        object: object,
        old: change.oldValue,
        new: change.newValue ?? obj[keyPath: keyPath],
        attributes: [],
        debugDescription: "KVO")
      // Notifies the observers.
      self?.emitEvent(event)
      self?.emitObjectChangeEvent()
    }
    guard let observationToken = token else { return }
    kvoTokens[keyPath.id] = observationToken
  }

  /// Unregister the binding between KVO changes and *PropertyChangeEvent*.
  public func unbindKVOToPropertyChangeEvent<N: NSObject & AnyObservable,V>(
    object: N,
    keyPath: KeyPath<N, V>) {
    assert(Thread.isMainThread)
    kvoTokens[keyPath.id] = nil
  }

  // MARK: Dispatch

  public func dispatch(strategy: EventDispatchStrategy, _ block: @escaping () -> Void) {
    switch strategy {
    case .immediate:
      block()
    case .mainThread:
      if Thread.isMainThread {
        block()
      } else {
        DispatchQueue.main.async(execute: block)
      }
    case .nextRunLoop:
      DispatchQueue.main.async(execute: block)
    case .backgroundThread:
      DispatchQueue.global().async(execute: block)
    }
  }
}
