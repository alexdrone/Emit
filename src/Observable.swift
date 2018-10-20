import Foundation

/// An observable object.
public protocol ObservableProtocol: class { }

/// An object able to emit events.
public protocol Observable: AnyObservable {
  /// The event emitter associated to this instance.
  var eventEmitter: EventEmitter<Self> { get }
}

extension Observable {
  /// Build the `EventEmitter` instance for this observable object.
  public func makeEventEmitter() -> EventEmitter<Self> {
    return EventEmitter(object: self);
  }

  // MARK: ObservationTokens

  /// Ad-hoc observer that reacts to `ObjectChangeEvent` events.
  /// - parameter onChange: The closure executed whenever the `ObjectChangeEvent` event is emitted.
  public func observeObjectChange(
    onChange: @escaping (ObjectChangeEvent) -> Void) -> Token<Self, _ObjEvent> {
    return observeEvent(id: Event.Id.objectChange, onChange: onChange)
  }

  /// Creates an ad-hoc observer for the event passed as argument.
  /// The observation lifecycle is linked to the `ObservationToken` lifecycle.
  /// - parameter id: The identifier of the event being observed.
  /// - parameter onChange: The closure executed whenever the desired event is emitted.
  public func observeEvent<E: AnyEvent>(
    id: EventIdentifier,
    onChange: @escaping (E) -> Void
  ) -> Token<Self, E> {
    return eventEmitter.observe(id: id, onChange: onChange)
  }

  /// Creates an ad-hoc observer for the property change associated to the given keypath.
  /// The observation lifecycle is linked to the `ObservationToken` lifecycle.
  /// - parameter keyPath: The observed keypath.
  /// - parameter onChange: The closure executed whenever the desired event is emitted.
  public func observeKeyPath<V>(
    keyPath: KeyPath<Self, V>,
    onChange: @escaping (_KpEvent<Self, V>) -> Void
  ) -> PropertyToken<Self, V> {
    return eventEmitter.observe(keyPath: keyPath, onChange: onChange)
  }

  // MARK: Event propagation

  /// Emit a `ObjectChange` event.
  /// - parameter attributes: Additional event qualifiers.
  public func emitObjectChangeEvent(attributes: EventAttributes = []) {
    eventEmitter.emitObjectChangeEvent(attributes: attributes)
  }

  /// Emit a property change event.
  /// - parameter keyPath: The keypath for the changing property.
  /// - parameter old: Optional old value.
  /// - parameter attributes: Additional event qualifiers.
  /// - parameter debugDescription: Optional custom debug string for this event.
  /// - parameter userInfo: Optional user info dictionary.
  public func emitPropertyChangeEvent<V>(
    keyPath: KeyPath<Self, V>,
    old: V? = nil,
    attributes: EventAttributes = [],
    debugDescription: String = "",
    userInfo: UserInfo? = nil
  ) -> Void {
    eventEmitter.emitPropertyChangeEvent(
      keyPath: keyPath,
      old: old,
      attributes: attributes,
      debugDescription: debugDescription,
      userInfo: userInfo)
  }

  /// Emit any arbitrary event.
  /// - parameter event: The event that is going to be pushed down to all of the observers.
  public func emitEvent(_ event: AnyEvent) {
    eventEmitter.emitEvent(event)
  }

  // MARK: Internal

  /// Internal only - type-erased event emitter.
  public var anyEventEmitter: EventEmitterProtocol {
    return eventEmitter
  }
}

// MARK: - KVO Binding

extension Observable where Self: NSObject {

  /// Whenever a KVO change is triggered, a `PropertyChangeEvent`
  /// (and an associated `ObjectChangeEvent`) is emitted to all of the registered observers.
  /// This is a convenient way to unify the object event propagation.
  /// - parameter keyPath: The target keyPath.
  public func bindKVOToPropertyChangeEvent<V>(keyPath: KeyPath<Self, V>) {
    eventEmitter.bindKVOToPropertyChangeEvent(object: self, keyPath: keyPath)
  }

  /// Unregister the binding between KVO changes and `PropertyChangeEvent`.
  public func unbindKVOToPropertyChangeEvent<V>(keyPath: KeyPath<Self, V>) {
    eventEmitter.unbindKVOToPropertyChangeEvent(object: self, keyPath: keyPath)
  }
}

// MARK: - Internal Protocols

public protocol AnyObservable: ObservableProtocol {
  /// Type-erased event emitter.
  var anyEventEmitter: EventEmitterProtocol { get }
}

public extension AnyObservable {

  // MARK: Registration

  /// Registers a new observer for the observable object.
  public func register(observer: Observer, for events: [EventIdentifier] = [Event.Id.all]) {
    anyEventEmitter.register(observer: observer, for: events)
  }

  /// Force unregister an observer.
  /// - note: This is not necessary in most use-cases since the observation is stopped whenever
  /// the observer object is being deallocated.
  public func unregister(observer: Observer) {
    anyEventEmitter.unregister(observer: observer)
  }
}
