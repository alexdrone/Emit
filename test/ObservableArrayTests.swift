import XCTest
@testable import Emit

class ObservableArrayTests: XCTestCase {

  func testArrayChange() {
    var arrayChangeCount = 0
    let o = ObservableArray<Foo>()
    let old = [Foo(bar: "a"), Foo(bar: "b"), Foo(bar: "c")]
    let new = [Foo(bar: "a"), Foo(bar: "d")]
    o.assign { $0 = old }
    let obs = o.observeArrayChange {
      arrayChangeCount += 1
      assert($0.old == old)
      assert($0.new == new)
      assert($0.object === o)
    }
    o.assign { $0 = new }
    o.assign { $0 = new }
    assert(arrayChangeCount == 1)
    let _ = obs
  }

  func testElementChange() {
    var objectChange = 0
    let o = ObservableArray<Foo>()
    let old = [Foo(bar: "a"), Foo(bar: "b"), Foo(bar: "c")]
    o.assign { $0 = old }
    let obs = o.observeElementChange { (event, object, index) in
      objectChange += 1
      assert(index == 1)
      assert(object.bar == "new")
    }
    old[1].bar = "new"
    assert(objectChange == 1)
    let _ = obs
  }

  func testElementKeyPath() {
    var objectChange = 0
    let o = ObservableArray<Foo>()
    let old = [Foo(bar: "a"), Foo(bar: "b"), Foo(bar: "c")]
    o.assign { $0 = old }
    let obs = o.observeElementKeyPath(keyPath: \.bar) { (event, object, index) in
      objectChange += 1
      assert(index == 1)
      assert(object.bar == "new")
      assert(event.newValue == "new")
    }
    old[1].bar = "new"
    assert(objectChange == 1)
    let _ = obs
  }
}
