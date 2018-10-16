import Foundation
import XCTest
@testable import Emit

// MARK: Foo

final class Foo: Observable {
  /// The event emitter.
  lazy var eventEmitter = makeEventEmitter()
  /// A observable property.
  var bar: String = "bar" {
    didSet { emitPropertyChangeEvent(keyPath: \.bar) }
  }
  /// A non-observable property.
  var baz = "baz"
  /// Init.
  init(bar: String = "bar") {
    self.bar = bar
  }
  init() { }

  /// Test method that trigger an event.
  func doSomething() {
    let event = Event(id: Id.didSomething)
    emitEvent(event)
  }
  /// Test method that trigger a value change event.
  func changeSomeValueNotAProperty() {
    let event = ValueChangeEvent(id: Id.didChangeSomeValue, value: 42)
    emitEvent(event)
  }
}

extension Foo: Equatable {
  public static func == (lhs: Foo, rhs: Foo) -> Bool {
    return lhs.bar == rhs.bar && lhs.baz == rhs.baz
  }
}

extension Foo {
  struct Id {
    static let didSomething = "ObservableFoo.didSomething"
    static let didChangeSomeValue = "ObservableFoo.didChangeSomeValueg"
  }
}

final class ObservableNSFoo: NSObject, Observable {
  lazy var eventEmitter = makeEventEmitter()
  @objc dynamic var dynamicBar: String = "test"

  override init() {
    super.init()
    bindKVOToPropertyChangeEvent(keyPath: \.dynamicBar)
  }
}
