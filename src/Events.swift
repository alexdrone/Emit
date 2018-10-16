import Foundation

// MARK: - Identifiers

public extension Event.Id {
  /// This is the `EventIdentifier` propagated to a observer that is listening for
  /// `observeObjectChange` for a given object.
  public static let objectChange: EventIdentifier = "__object"
  /// This is the `EventIdentifier` propagated to a observer that is listening for
  /// `observeArrayChange` for a given object.
  public static let arrayChange: EventIdentifier = "__array"
  /// This is the `EventIdentifier` that can be passed to `register(observer:for events:)` whenever
  /// The observer is interesting in listening to every event emitted by the observed object.
  public static let all: EventIdentifier = "__all"
}

// MARK: - Attributes

/// Additional attributes that can be passed down to the observer whenever an event is emitted.
@_fixed_layout public struct EventAttributes: OptionSet {
  /// The raw represenation for this option.
  public let rawValue: Int
  /// You can use this additional, one-time notification to establish the initial value of a
  /// property in the observer.
  public static let initial = EventAttributes(rawValue: 1 << 0)
  /// This property is being refreshed and is pending update.
  public static let pending = EventAttributes(rawValue: 1 << 1)

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
}

// MARK: - Protocols

/// Type-erased event.
public protocol AnyEvent {
  /// The event unique identifier.
  var id: EventIdentifier { get }
  /// The observable object that triggered this event (if applicable).
  var object: AnyObservable? { get }
  /// Event qualifiers.
  var attributes: EventAttributes { get }
  /// Additional user info dictionary passed down to the observer.
  var userInfo: UserInfo? { get set }
}

public protocol DebuggableEvent: AnyEvent {
  /// Information emitted by the observable object that helps identifing the origin of this event
  /// notification.
  var debugDescription: String? { get }
}

// MARK: - Events

/// A user-defined event.
/// This can be used to notify custom events to observers.
@_fixed_layout public struct Event: DebuggableEvent {
  public let id: EventIdentifier
  public weak var object: AnyObservable?
  public let attributes: EventAttributes
  public let debugDescription: String?
  public var userInfo: UserInfo?

  /// Creates a new `ObjectChange` event.
  public init(id: String,
    object: AnyObservable? = nil,
    attributes: EventAttributes = [],
    userInfo: UserInfo? = nil,
    debugDescription: String? = nil
  ) {
    self.id = id
    self.object = object
    self.attributes = attributes
    self.userInfo = userInfo
    self.debugDescription = debugDescription
  }

  final public class Id { }
}

/// Event propagated to a observer that is listening for `observeObjectChange`.
@_fixed_layout public struct ObjectChangeEvent: DebuggableEvent {
  public let id: String = Event.Id.objectChange
  public weak var object: AnyObservable?
  public let debugDescription: String?
  public let attributes: EventAttributes
  public var userInfo: UserInfo?

  /// Creates a new `ObjectChange` event.
  init(object: AnyObservable, attributes: EventAttributes = [], debugDescription: String? = nil) {
    self.object = object
    self.attributes = attributes
    self.debugDescription = debugDescription
  }
}

/// Event propagated to a observer that is listening for `observeKeyPath`.
@_fixed_layout public struct PropertyChangeEvent<O: AnyObservable, V>: DebuggableEvent {
  public let id: EventIdentifier
  public weak var object: AnyObservable?
  public let attributes: EventAttributes
  public let debugDescription: String?
  public var userInfo: UserInfo?
  /// The old value for this property.
  public let oldValue: V?
  /// The new value for this property.
  public let newValue: V

  /// Creates a new property change event from the object and keypath passed as argument.
  init(
    keyPath: KeyPath<O, V>,
    object: O,
    old: V? = nil,
    new: V,
    attributes: EventAttributes = [],
    debugDescription: String? = nil
  ) {
    self.id = keyPath.id
    self.object = object
    self.oldValue = old
    self.newValue = new
    self.attributes = attributes
    self.debugDescription = debugDescription
  }
}

/// Used to propagate a synthesized value and not a property change.
@_fixed_layout public struct ValueChangeEvent<V>: DebuggableEvent {
  public let id: EventIdentifier
  public weak var object: AnyObservable?
  public let attributes: EventAttributes
  public let debugDescription: String?
  public var userInfo: UserInfo?
  /// The value associated to this event.
  public let value: V

  /// Creates a new `ValueChangeEvent` event.
  public init(
    id: String,
    object: AnyObservable? = nil,
    value: V,
    attributes: EventAttributes = [],
    userInfo: UserInfo? = nil,
    debugDescription: String? = nil
  ) {
    self.id = id
    self.object = object
    self.value = value
    self.attributes = attributes
    self.userInfo = userInfo
    self.debugDescription = debugDescription
  }
}

/// Event propagated to a observer that is listening for `observeArrayChange`.
@_fixed_layout public struct ArrayChangeEvent<T: Equatable>: AnyEvent {
  public let id: EventIdentifier
  public var object: AnyObservable? { return observableArray }
  public let attributes: EventAttributes = []
  public var userInfo: UserInfo?
  /// The observable array that triggered the change.
  public weak var observableArray: ObservableArray<T>?
  /// The old collection.
  public let old: [T]
  /// The new collection.
  public let new: [T]

  /// Creates a new `ArrayChangeEvent` event.
  public init(object: ObservableArray<T>? = nil, old: [T], new: [T]) {
    self.id = Event.Id.arrayChange
    self.observableArray = object
    self.old = old
    self.new = new
  }
}

// MARK: - Extensions

extension AnyKeyPath {
  /// Unique identifier for a keypath.
  public var id: EventIdentifier {
    if let path = _kvcKeyPathString { return path }
    print("warning: retrieving the `id` of a non-KVC property.")
    return String(format: "_k[%x]", hashValue)
  }
}

public typealias EventIdentifier = String
public typealias UserInfo = [String: Any]
/// Internal shortcut for `PropertyChangeEvent`.
public typealias _KpEvent = PropertyChangeEvent
/// Internal shortcut for `ObjectChangeEvent`.
public typealias _ObjEvent = ObjectChangeEvent
