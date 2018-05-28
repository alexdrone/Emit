import Foundation

public struct AnyObserver: Equatable {
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
  public static func ==(lhs: AnyObserver, rhs: AnyObserver) -> Bool {
    return lhs.observer === rhs.observer
  }
}

public protocol EventEmitterProtocol: class, Synchronizable, Dispatchable {
  /// All of the events emitted are also going ot be propagate to this emitter (if applicable).
  var chainedEventEmitter: EventEmitterProtocol? { get set }
  /// Emit an event.
  func emitEvent(_ event: AnyEvent, observer: AnyObserver?, strategy: DispatchStrategy?)
}

final public class EventEmitter<O: AnyObservable>: EventEmitterProtocol {
  /// Reference for the observable object emitting changes.
  public weak var observableObject: O?
  /// Dispatch the event notifications with the desired *EventDispatchStrategy*.
  /// - note: This can be overridden with a custom *Dispatcher* implementation.
  public var dispatcher: Dispatcher = DefaultDispatcher.default
  /// The event dispatch strategy.
  public var dispatchStrategy: DispatchStrategy = .immediate
  /// The synchronization strategy used for observers registration/deregistration.
  public var synchronizationStrategy: SynchronizationStrategy = NonSyncronizedMainThread.default
  /// All of the events emitted are also going ot be propagate to this emitter (if applicable).
  public weak var chainedEventEmitter: EventEmitterProtocol?
  /// The current registered observers.
  private var observers: [AnyObserver] = []
  /// Used to track the bindings betwzween KVO and *PropertyChangeEvent*.
  private var kvoTokens: [String: NSKeyValueObservation] = [:]

  /// Constructs a new emitter with the observable object passed as argument.
  public init(object: O) {
    self.observableObject = object
  }

  // MARK: Registration

  /// Registers a new observer for the observable object.
  func register(observer: Observer, for events: [EventIdentifier]) {
    let container = AnyObserver(observer: observer, events: events)
    synchronize { [weak self] in
      guard let `self` = self else { return }
      self.observers = self.observers.filter { $0 != container && $0.observer != nil }
      self.observers.append(container)
    }
    // Initial change event.
    emitObjectChangeEvent(observer: container, attributes: [.initial])
  }

  /// Force unregister an observer.
  /// - note: This is not necessary in most use-cases since the observation is stopped whenever
  /// the observer object is being deallocated.
  func unregister(observer: Observer) {
    synchronize { [weak self] in
      guard let `self` = self else { return }
      self.observers = self.observers.filter { $0.observer !== observer && $0.observer != nil }
    }
  }

  // MARK: ObservationTokens

  /// Creates an ad-hoc observer for the event passed as argument.
  /// The observation lifecycle is linked to the *ObservationToken* lifecycle.
  /// - parameter id: The identifier of the event being observed.
  /// - parameter onChange: The closure executed whenever the desired event is emitted.
  func observe<E: AnyEvent>(
    id: EventIdentifier,
    onChange: @escaping (E) -> Void) -> Token<O, E> {

    let observer = ObservationToken<O, E>(id: id, onChange: onChange)
    observer.object = observableObject
    register(observer: observer, for: [id])
    return observer
  }

  /// Creates an ad-hoc observer for the event passed as argument.
  /// The observation lifecycle is linked to the *ObservationToken* lifecycle.
  /// - parameter keyPath: The observed keypath.
  /// - parameter onChange: The closure executed whenever the desired event is emitted.
  func observe<V>(
    keyPath: KeyPath<O, V>,
    onChange: @escaping (PCEvent<O, V>) -> Void) -> PropertyToken<O, V> {

    let observer = PropertyChangeObservationToken(keyPath: keyPath, onChange: onChange)
    observer.object = observableObject
    register(observer: observer, for: [keyPath.id])
    return observer
  }

  /// Listen for *ArrayChangeEvent* events.
  /// - note: This function is a no-op and returns *nil* if the observed object associated to
  /// this emitter is not of kind *ArrayChangeEvent<T>*.
  /// - parameter onChange: The closure executed whenever the desired event is emitted.
  func observeArray<T: Equatable>(
    onChange: @escaping (ArrayChangeEvent<T>) -> Void) -> Token<O, ArrayChangeEvent<T>>? {

    guard let _ = observableObject as? ObservableArray<T> else { return nil }
    return observe(id: Event.Id.arrayChange, onChange: onChange)
  }

  // MARK: Emit

  /// Emit a *ObjectChange* event.
  /// - parameter attributes: Additional event qualifiers.
  func emitObjectChangeEvent(attributes: EventAttributes = []) {
    emitObjectChangeEvent(observer: nil, attributes: attributes)
  }

  func emitObjectChangeEvent(observer: AnyObserver?, attributes: EventAttributes = []) {
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
  func emitPropertyChangeEvent<V>(
    keyPath: KeyPath<O, V>,
    old: V?,
    attributes: EventAttributes,
    debugDescription: String,
    userInfo: UserInfo?) {

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
  public func emitEvent(
    _ event: AnyEvent,
    observer: AnyObserver?,
    strategy: DispatchStrategy? = nil) {

    chainedEventEmitter?.emitEvent(event, observer: observer, strategy: strategy)
    let currentStrategy = strategy ?? dispatchStrategy
    dispatcher.dispatch(strategy: currentStrategy) { [weak self] in
      guard let strongSelf = self else { return }

      let targets = observer != nil ? [observer!] : strongSelf.observers
      // Notifies the observers.
      for target in targets
        where target.events.contains(event.id) || event.id == Event.Id.all {
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
  func bindKVOToPropertyChangeEvent<N: NSObject & AnyObservable,V>(
    object: N,
    keyPath: KeyPath<N, V>) {

    synchronize { [weak self] in
      guard let `self` = self else { return }
      let token: NSKeyValueObservation? = object.observe(keyPath, options: [.new, .old, .initial]) {
        [weak self] (obj: N, change: NSKeyValueObservedChange<V>) in
        let event = PropertyChangeEvent<N, V>(
          keyPath: keyPath,
          object: object,
          old: change.oldValue,
          new: change.newValue ?? obj[keyPath: keyPath],
          attributes: [],
          debugDescription: "\(keyPath._kvcKeyPathString ?? "")")
        // Notifies the observers.
        self?.emitEvent(event)
        self?.emitObjectChangeEvent()
      }
      guard let observationToken = token else { return }
      self.kvoTokens[keyPath.id] = observationToken
    }
  }

  /// Unregister the binding between KVO changes and *PropertyChangeEvent*.
  func unbindKVOToPropertyChangeEvent<N: NSObject & AnyObservable,V>(
    object: N,
    keyPath: KeyPath<N, V>) {

    synchronize { [weak self] in
      guard let `self` = self else { return }
      self.kvoTokens[keyPath.id] = nil
    }
  }
}
