import Foundation

public final class ObservableProxy<T: ObservableProtocol & Equatable>: AnyObservable, Equatable {
  /// The event emitter associated with this observable proxy.
  public private(set) lazy var eventEmitter = makeEventEmitter()

  private func makeEventEmitter() -> EventEmitter<T> {
    return EventEmitter<T>(object: buffer)
  }

  /// The actual store object (e.g. a protobuf)
  private var buffer: T {
    didSet {
      eventEmitter = makeEventEmitter()
      eventEmitter.emitObjectChangeEvent(attributes: [])
    }
  }

  public init(buffer: T) {
    self.buffer = buffer
  }

  /// Set the backing store for this observable reference.
  public func emplace(buffer: T) {
    self.buffer = buffer
  }

  public func set<V>(_ keyPath: ReferenceWritableKeyPath<T, V>, _ value: V) {
    let old = buffer[keyPath: keyPath]
    buffer[keyPath: keyPath] = value
    eventEmitter.emitPropertyChangeEvent(
      keyPath: keyPath,
      old: old,
      attributes: [],
      debugDescription: "\(keyPath.id) from Proxy:\(buffer)",
      userInfo: nil)
  }

  public func get<V>(_ keyPath: KeyPath<T, V>) -> V {
    return buffer[keyPath: keyPath]
  }

  /// Returns a Boolean value indicating whether two values are equal.
  public static func == (lhs: ObservableProxy<T>, rhs: ObservableProxy<T>) -> Bool {
    return lhs.buffer == rhs.buffer
  }

  // MARK: Registration

  /// Registers a new observer for the observable object.
  public func register(observer: Observer, for events: [EventIdentifier] = [Event.Id.all]) {
    eventEmitter.register(observer: observer, for: events)
  }

  /// Force unregister an observer.
  /// - note: This is not necessary in most use-cases since the observation is stopped whenever
  /// the observer object is being deallocated.
  public func unregister(observer: Observer) {
    eventEmitter.unregister(observer: observer)
  }

  // MARK: ObservationTokens

  /// Ad-hoc observer that reacts to `ObjectChangeEvent` events.
  /// - parameter onChange: The closure executed whenever the `ObjectChangeEvent` event is emitted.
  public func observeObjectChange(
    onChange: @escaping (ObjectChangeEvent) -> Void
  ) -> Token<T, _ObjEvent> {
    return observeEvent(id: Event.Id.objectChange, onChange: onChange)
  }

  /// Creates an ad-hoc observer for the event passed as argument.
  /// The observation lifecycle is linked to the `ObservationToken` lifecycle.
  /// - parameter id: The identifier of the event being observed.
  /// - parameter onChange: The closure executed whenever the desired event is emitted.
  public func observeEvent<E: AnyEvent>(
    id: EventIdentifier,
    onChange: @escaping (E) -> Void
  ) -> Token<T, E> {
    return eventEmitter.observe(id: id, onChange: onChange)
  }

  /// Creates an ad-hoc observer for the property change associated to the given keypath.
  /// The observation lifecycle is linked to the `ObservationToken` lifecycle.
  /// - parameter keyPath: The observed keypath.
  /// - parameter onChange: The closure executed whenever the desired event is emitted.
  public func observeKeyPath<V>(
    keyPath: KeyPath<T, V>,
    onChange: @escaping (_KpEvent<T, V>) -> Void) -> PropertyToken<T, V> {
    return eventEmitter.observe(keyPath: keyPath, onChange: onChange)
  }

  // MARK: Internal

  /// Internal only - type-erased event emitter.
  public var anyEventEmitter: EventEmitterProtocol {
    return eventEmitter
  }
}

