import Foundation

public protocol Observer: class {
  /// An event just got triggered from the observed object.
  func onChange(event: AnyEvent)
}

public class ObservationToken<O: Observable, E: AnyEvent>: Observer {
  /// Closure called whenever an event change is being triggered.
  public let onChangeBlock: (E) -> Void
  /// The event identifier associated to this observer.
  public let id: EventIdentifier
  /// The observed object.
  public weak var object: O?

  /// Constructs a new `ObservationToken`.
  /// - parameter id: The identifier for the event that is being observed.
  /// The default value is `Event.Id.objectChange`
  init(id: EventIdentifier = Event.Id.objectChange, onChange: @escaping (E) -> Void) {
    self.id = id
    self.onChangeBlock = onChange
  }

  /// An event just got triggered from the observed object.
  public func onChange(event: AnyEvent) {
    guard event.id == id  else { return }
    guard let event = event as? E else {
      print("warning: Type mismatch for event with identifier \(id) — expected \(E.self).")
      return
    }
    onChangeBlock(event)
  }

  /// Force unregister the observer.
  /// - note: This is not necessary in most use-cases since the observation is stopped whenever
  /// the observer object is being deallocated.
  public func dispose() {
    object?.unregister(observer: self)
  }
}

public class PropertyChangeObservationToken<O: Observable, V>: Token<O, _KpEvent<O, V>> {
  /// Constructs a new `ObservationToken`.
  /// - parameter id: The keyPath being observed.
  init(keyPath: KeyPath<O, V>, onChange: @escaping (PropertyChangeEvent<O, V>) -> Void) {
    super.init(id: keyPath.id, onChange: onChange)
  }
}

public typealias Token = ObservationToken
public typealias PropertyToken = PropertyChangeObservationToken
