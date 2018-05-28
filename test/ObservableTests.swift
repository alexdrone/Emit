import XCTest
@testable import Emit

class ObservableTests: XCTestCase {

  func testInitialObjectChangeEvent() {
    var changeCount = 0
    let foo = Foo()
    // An *ObjectChange* event is trigger on registration with attributes '.initial'.
    let token = foo.observeObjectChange { event in
      changeCount += 1
      XCTAssert(event.object === foo)
      XCTAssert(event.attributes.rawValue == EventAttributes.initial.rawValue)
      XCTAssert(event.id == ObjectChangeEvent.id)
    }
    XCTAssert(changeCount == 1)
    // Just to silence the variable never used token.
    token.dispose()
  }

  func testObjectChangeEvent() {
    var changeCount = 0
    let foo = Foo()
    // An *ObjectChange* event is trigger on registration with attributes '.initial'.
    // For every *PropertyChangeEvent* emitted, a *ObjectChange* is emitted too.
    let token = foo.observeObjectChange { event in
      changeCount += 1
      XCTAssert(event.object === foo)
      XCTAssert(event.id == ObjectChangeEvent.id)
    }
    foo.bar = "baz"
    XCTAssert(changeCount == 2)
    // Just to silence the variable never used token.
    token.dispose()
  }

  func testPropertytChangeEvent() {
    var propertyChangeCount = 0
    var objectChangeCount = 0
    let foo = Foo()
    // A change to *foo.bar* will trigger a *PropertyChangeEvent*.
    let token = foo.observeKeyPath(keyPath: \.bar) { event in
      propertyChangeCount += 1
      XCTAssert(event.object === foo)
      XCTAssert(event.newValue == "baz")
    }
    // An *ObjectChange* event is trigger on registration with attributes '.initial'.
    // For every *PropertyChangeEvent* emitted, a *ObjectChange* is emitted too.
    let objChangeToken = foo.observeObjectChange { event in
      objectChangeCount += 1
      XCTAssert(event.object === foo)
      XCTAssert(event.id == ObjectChangeEvent.id)
    }
    foo.bar = "baz"
    XCTAssert(propertyChangeCount == 1)
    XCTAssert(objectChangeCount == 2)
    // Just to silence the variable never used token.
    token.dispose()
    objChangeToken.dispose()
  }

  func testSimpleEvent() {
    var objectChangeCount = 0
    var eventChangeCount = 0
    let foo = Foo()
    // *doSomething* in foo triggers *didSomething*.
    let id = Foo.EventIdentifier.didSomething
    let token = foo.observeEvent(id: id){ (event: Event)  in
      eventChangeCount += 1
      XCTAssert(event.id == id)
    }
    // An *ObjectChange* event is trigger on registration with attributes '.initial'.
    // No *ObjectChange notification is triggered when a custom event is emitted.
    let objChangeToken = foo.observeObjectChange { event in
      objectChangeCount += 1
      XCTAssert(event.object === foo)
      XCTAssert(event.id == ObjectChangeEvent.id)
      XCTAssert(event.attributes.rawValue == EventAttributes.initial.rawValue)
    }
    foo.doSomething()
    XCTAssert(eventChangeCount == 1)
    XCTAssert(objectChangeCount == 1)
    // Just to silence the variable never used token.
    token.dispose()
    objChangeToken.dispose()
  }

  func testValueChangeEvent() {
    var objectChangeCount = 0
    var eventChangeCount = 0
    let foo = Foo()
    // *changeSomeValueNotAProperty* in foo triggers *didChangeSomeValue*.
    let id = Foo.EventIdentifier.didChangeSomeValue
    let token = foo.observeEvent(id: id){ (event: ValueChangeEvent<Int>)  in
      eventChangeCount += 1
      XCTAssert(event.id == id)
      XCTAssert(event.value == 42)
    }
    // An *ObjectChange* event is trigger on registration with attributes '.initial'.
    // No *ObjectChange notification is triggered when a custom event is emitted.
    let objChangeToken = foo.observeObjectChange { event in
      objectChangeCount += 1
      XCTAssert(event.object === foo)
      XCTAssert(event.id == ObjectChangeEvent.id)
      XCTAssert(event.attributes.rawValue == EventAttributes.initial.rawValue)
    }
    foo.changeSomeValueNotAProperty()
    XCTAssert(eventChangeCount == 1)
    XCTAssert(objectChangeCount == 1)
    // Just to silence the variable never used token.
    token.dispose()
    objChangeToken.dispose()
  }

  func testKVOBinding() {
    var objectChangeCount = 0
    var propertyChangeCount = 0
    let foo = ObservableNSFoo()
    // A change to *foo.bar* will trigger a *PropertyChangeEvent*.
    let token = foo.observeKeyPath(keyPath: \.dynamicBar) { event in
      propertyChangeCount += 1
      XCTAssert(event.object === foo)
      XCTAssert(event.newValue == "baz")
    }
    // An *ObjectChange* event is trigger on registration with attributes '.initial'.
    // For every *PropertyChangeEvent* emitted, a *ObjectChange* is emitted too.
    let objChangeToken = foo.observeObjectChange { event in
      objectChangeCount += 1
      XCTAssert(event.object === foo)
      XCTAssert(event.id == ObjectChangeEvent.id)
    }
    foo.dynamicBar = "baz"
    XCTAssert(propertyChangeCount == 1)
    XCTAssert(objectChangeCount == 2)
    // Just to silence the variable never used token.
    token.dispose()
    objChangeToken.dispose()
  }
}
