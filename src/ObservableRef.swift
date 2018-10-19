//import Foundation
//
//public final class ObservableRef<T: Equatable>: Observable, Equatable {
//  public let eventEmitter: EventEmitter<T> {
//    return EventEmitter
//  }
//  /// The actual store object (e.g. a protobuf)
//  private var buffer: T? {
//    didSet {
//      emitObjectChangeEvent()
//    }
//  }
//  /// Set the backing store for this observable reference.
//  public func emplace(buffer: T?) {
//    self.buffer = buffer
//  }
//
//  public func set<V>(_ keyPath: ReferenceWritableKeyPath<T, V>, _ value: V) {
//    buffer?[keyPath: keyPath] = value
//    emitPropertyChangeEvent(keyPath: keyPath)
//  }
//
//  public func get<V>(_ keyPath: KeyPath<T, V>) -> V {
//    return buffer?[keyPath: keyPath]
//  }
//
//  /// Returns a Boolean value indicating whether two values are equal.
//  public static func == (lhs: ObservableRef, rhs: ObservableRef) -> Bool {
//    return lhs.buffer == rhs.buffer
//  }
//}
//
