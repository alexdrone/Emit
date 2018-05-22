import Foundation

@_fixed_layout
public struct EventAttributes: OptionSet {
  /// The raw represenation for this option.
  public let rawValue: Int
  /// The event notification represents the initial value for the property.
  public static let initial = EventAttributes(rawValue: 1 << 0)
  /// This property is being refreshed and is pending update.
  /// Useful to model an interstitial state for this change.
  public static let pending = EventAttributes(rawValue: 1 << 0)
  /// Associated to an *ObjectChange* event can be used to notify the deallocation of the
  /// observed object.
  /// - note: This is meaningful only if the event dispatch strategy is *immediate*.
  public static let dealloc = EventAttributes(rawValue: 2 << 0)

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
}

public protocol AnyEvent {
  /// The event unique identifier.
  var id: EventIdentifier { get }
  /// The observable object triggering this event.
  var object: AnyObservable? { get }
  /// Additional attributes for the event.
  var attributes: EventAttributes { get }
  /// Additional user info dictionary passed down to the observer.
  var userInfo: UserInfo? { get set }
}

@_fixed_layout
public struct Event: AnyEvent {
  final public class Id { }

  /// The event unique identifier (usually a const string).
  public var id: EventIdentifier
  public weak var object: AnyObservable?
  public var attributes: EventAttributes
  public var userInfo: UserInfo?
  /// Additional information emitted by the observable object that helps identifing the nature
  /// of this property change.
  public let debugDescription: String?

  /// Creates a new *ObjectChange* event.
  /// - parameter id: A unique identifier for this event.
  /// - parameter object: The object that has changed (Optional).
  /// - parameter attributes: Event qualifiers.
  /// - parameter debugDescription: Optional debug description.
  public init(
    id: String,
    object: AnyObservable? = nil,
    attributes: EventAttributes = [],
    userInfo: UserInfo? = nil,
    debugDescription: String? = nil) {

    self.id = id
    self.object = object
    self.attributes = attributes
    self.userInfo = userInfo
    self.debugDescription = debugDescription
  }
}

public extension Event.Id {
  public static let objectChange: EventIdentifier = "_object"
  public static let all: EventIdentifier = "_all"
}

@_fixed_layout
public struct ObjectChangeEvent: AnyEvent {
  public static let id: EventIdentifier = Event.Id.objectChange
  /// The keypath identifier.
  public let id: String = ObjectChangeEvent.id
  public weak var object: AnyObservable?
  /// Additional information emitted by the observable object that helps identifing the nature
  /// of this property change.
  public let debugDescription: String?
  public let attributes: EventAttributes
  public var userInfo: UserInfo?

  /// Creates a new *ObjectChange* event.
  /// - parameter object: The object that has changed.
  /// - parameter attributes: Event qualifiers.
  /// - parameter debugDescription: Optional debug description.
  init(object: AnyObservable, attributes: EventAttributes = [], debugDescription: String? = nil) {
    self.object = object
    self.attributes = attributes
    self.debugDescription = debugDescription
  }
}

@_fixed_layout
public struct PropertyChangeEvent<O: AnyObservable, V>: AnyEvent {
  /// The keypath identifier.
  public let id: EventIdentifier
  public weak var object: AnyObservable?
  public let attributes: EventAttributes
  public var userInfo: UserInfo?
  /// Additional information emitted by the observable object that helps identifing the nature
  /// of this property change.
  public let debugDescription: String?
  /// The old value for this property.
  public let oldValue: V?
  /// The new value for this property.
  public let newValue: V

  /// Creates a new property change event from the object and keypath passed as argument.
  /// - parameter keyPath: The keypath triggering this change.
  /// - parameter object: The object that is changing.
  /// - parameter old: The old value for this property.
  /// - parameter new: The new value for this property.
  /// - parameter attributes: Event qualifiers.
  /// - parameter debugDescription: Optional debug description.
  init(
    keyPath: KeyPath<O, V>,
    object: O,
    old: V? = nil,
    new: V,
    attributes: EventAttributes = [],
    debugDescription: String? = nil) {

    self.id = keyPath.id
    self.object = object
    self.oldValue = old
    self.newValue = new
    self.attributes = attributes
    self.debugDescription = debugDescription
  }
}

@_fixed_layout
public struct ValueChangeEvent<V>: AnyEvent {
  /// The event unique identifier (usually a const string).
  public var id: EventIdentifier
  public weak var object: AnyObservable?
  public var attributes: EventAttributes
  public var userInfo: UserInfo?
  /// Additional information emitted by the observable object that helps identifing the nature
  /// of this property change.
  public let debugDescription: String?
  /// The value associated to this event.
  public let value: V

  /// Creates a new *ObjectChange* event.
  /// - parameter id: A unique identifier for this event.
  /// - parameter object: The object that has changed (Optional).
  /// - parameter attributes: Event qualifiers.
  /// - parameter debugDescription: Optional debug description.
  public init(
    id: String,
    object: AnyObservable? = nil,
    value: V,
    attributes: EventAttributes = [],
    userInfo: UserInfo? = nil,
    debugDescription: String? = nil) {
  
    self.id = id
    self.object = object
    self.value = value
    self.attributes = attributes
    self.userInfo = userInfo
    self.debugDescription = debugDescription
  }
}

@_fixed_layout
public struct ArrayChangeEvent<O: AnyObservable>: AnyEvent {
  /// The event unique identifier (usually a const string).
  public var id: EventIdentifier
  public weak var object: AnyObservable?
  public var attributes: EventAttributes
  public var userInfo: UserInfo?
  /// Additional information emitted by the observable object that helps identifing the nature
  /// of this property change.
  public let debugDescription: String?

  /// Creates a new *ObjectChange* event.
  /// - parameter id: A unique identifier for this event.
  /// - parameter object: The object that has changed (Optional).
  /// - parameter attributes: Event qualifiers.
  /// - parameter debugDescription: Optional debug description.
  public init(
    id: String,
    object: AnyObservable? = nil,
    attributes: EventAttributes = [],
    userInfo: UserInfo? = nil,
    debugDescription: String? = nil) {

    self.id = id
    self.object = object
    self.attributes = attributes
    self.userInfo = userInfo
    self.debugDescription = debugDescription
  }
}

extension AnyKeyPath {
  /// Unique identifier for a keypath.
  public var id: EventIdentifier {
    return String(format: "_k[%x]", hashValue)
  }
}

public typealias EventIdentifier =  String
public typealias UserInfo = [String: Any]
public typealias PCEvent = PropertyChangeEvent
public typealias OCEvent = ObjectChangeEvent
