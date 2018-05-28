import Foundation
import XCTest
@testable import Emit

final class Foo: Observable, Equatable {
  struct EventIdentifier {
    static let didSomething = "ObservableFoo.didSomething"
    static let didChangeSomeValue = "ObservableFoo.didChangeSomeValueg"
  }
  public static func == (lhs: Foo, rhs: Foo) -> Bool {
    return lhs.bar == rhs.bar && lhs.baz == rhs.baz
  }
  lazy var eventEmitter: EventEmitter<Foo> = {
    return EventEmitter(object: self)
  }()

  // Test props.

  var bar: String = "bar" {
    didSet { emitPropertyChangeEvent(keyPath: \.bar) }
  }
  var baz = "baz"

  // Init.

  init(bar: String = "bar") {
    self.bar = bar
  }
  init() { }

  // Test methods.

  func doSomething() {
    let event = Event(id: EventIdentifier.didSomething)
    emitEvent(event)
  }

  func changeSomeValueNotAProperty() {
    let event = ValueChangeEvent(id: EventIdentifier.didChangeSomeValue, value: 42)
    emitEvent(event)
  }
}

final class ObservableNSFoo: NSObject, Observable {
  @objc dynamic var dynamicBar: String = "test"

  lazy var eventEmitter: EventEmitter<ObservableNSFoo> = {
    return EventEmitter(object: self)
  }()

  override init() {
    super.init()
    bindKVOToPropertyChangeEvent(keyPath: \.dynamicBar)
  }
}
