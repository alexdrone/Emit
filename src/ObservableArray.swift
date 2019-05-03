import Foundation

public protocol ObservableArrayProtocol: Observable, Synchronizable { }

final public class ObservableArray<T: Equatable>: ObservableArrayProtocol {
  /// The associated event emitter.
  public lazy var eventEmitter: EventEmitter<ObservableArray<T>> = {
    return EventEmitter(object: self)
  }()
  /// The concrete array store.
  public private(set) var array: [T] = [] {
    didSet {
      let new = array
      onArrayChange(old: oldValue, new: new)
    }
  }
  /// The synchronization strategy used for observers registration/deregistration and for
  /// array changes.
  public var synchronizationStrategy: SynchronizationStrategy = NonSynchronizedMainThread.default {
    didSet { eventEmitter.synchronizationStrategy = synchronizationStrategy }
  }
  /// The dispatch function.
  /// Override this closure if you wish to process the array changes on a thread different
  /// from the main thread.
  /// - note: Events are going to be dispatched on the thread the block passed as argument is
  /// dispatched to.
  public var dispatch = { (block: () -> Void) in block() }

  // MARK: - Assign

  /// Perform the desired change to the array.
  public func assign(changes: @escaping (inout [T]) -> Void) {
    synchronize { [weak self] in
      // Equality check.
      guard let `self` = self else { return }
      var copy = self.array
      changes(&copy)
      self.array = copy
    }
  }

  // MARK: - ObservationTokens

  /// Listen for `ArrayChangeEvent` events.
  /// - parameter onChange: The closure executed whenever the desired event is emitted.
  public func observeArrayChange(onChange: @escaping (ArrayChangeEvent<T>) -> Void) -> Observer {
    return eventEmitter.observeArray(onChange: onChange)!
  }

  /// Listen for `ObjectChangeEvent` events triggered by any of the elements in the array.
  /// - parameter onChange: The closure executed whenever the desired event is emitted.
  public func observeElementChange(
    onChange: @escaping (ObjectChangeEvent, T, Int) -> Void
  ) -> Observer {
    return observeObjectChange { [weak self] event in
      guard event.object !== self, let `self` = self, let el = event.object as? T else { return }
      self.dispatch { [weak self] in
        // Find the index for the object that triggered the event (if applicable).
        guard let `self` = self, let index = self.array.firstIndex(of: el) else { return }
        let object = self.array[index]
        onChange(event, object, index)
      }
    }
  }

  /// Creates an ad-hoc observer for the property change associated to the given keypath.
  /// The observation lifecycle is linked to the `ObservationToken` lifecycle.
  /// - parameter keyPath: The observed keypath.
  /// - parameter onChange: The closure executed whenever the desired event is emitted.
  public func observeElementKeyPath<V>(
    keyPath: KeyPath<T, V>,
    onChange: @escaping (_KpEvent<T, V>, T, Int) -> Void
  ) -> Observer? {
    let observer = observeEvent(id: keyPath.id) { [weak self] (event: _KpEvent<T, V>) in
      guard event.object !== self, let `self` = self, let el = event.object as? T else { return }
      self.dispatch { [weak self] in
        // Find the index for the object that triggered the event (if applicable).
        guard let `self` = self, let index = self.array.firstIndex(of: el) else { return }
        let object = self.array[index]
        onChange(event, object, index)
      }
    }
    return observer
  }

  // MARK: - Private

  /// Emit the `ArrayChangeEvent`.
  private func onArrayChange(old: [T], new: [T]) {
    dispatch { [weak self] in
      // Equality check.
      guard let `self` = self, old != new else { return }
      // Dependant event emitter.
      old.compactMap {
        $0 as? AnyObservable
      }.forEach {
        $0.anyEventEmitter.chainedEventEmitter = nil
      }
      new.compactMap {
        $0 as? AnyObservable
      }.forEach { [weak self] in
        $0.anyEventEmitter.chainedEventEmitter = self?.eventEmitter
      }
      let event = ArrayChangeEvent(object: self, old: old, new: new)
      self.emitObjectChangeEvent()
      self.emitEvent(event)
    }
  }
}

public extension Observer where Self: ObservableArrayProtocol {
  /// Prevents the `observeKeyPath` function to be invoked on ObservableArrays.
  @available(*, unavailable) func observeKeyPath<V>(
    keyPath: KeyPath<Self, V>,
    onChange: @escaping (_KpEvent<Self, V>) -> Void) -> PropertyToken<Self, V> {
    fatalError()
  }

  /// Prevents the `emitPropertyChangeEvent` function to be invoked on ObservableArrays.
  @available(*, unavailable) func emitPropertyChangeEvent<V>(
    keyPath: KeyPath<Self, V>,
    old: V? = nil,
    attributes: EventAttributes = [],
    debugDescription: String = "",
    userInfo: UserInfo? = nil) {
    fatalError()
  }
}
