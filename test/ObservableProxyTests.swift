import XCTest
@testable import Emit

struct Info: Equatable {
  var name: String = "foo"
  var number: Int = 3
}

class ObservableProxyTests: XCTestCase {

  func testObserveProxyObjectChange() {
    var changeCount = 0
    let proxy = ObservableProxy(buffer: Info())
    let token = proxy.observeObjectChange { event in
      changeCount += 1
      XCTAssert(event.object === proxy)
      XCTAssert(event.id == Event.Id.objectChange)
    }
    XCTAssert(changeCount == 1)

    proxy.set(\Info.name, "baz")
    XCTAssert(changeCount != 1)
    // Just to silence the variable never used token.
    token.dispose()
  }

  func testObserveProxyKeyPathChange() {
    var changeCount = 0
    let proxy = ObservableProxy(buffer: Info())
    let token = proxy.observeKeyPath(keyPath: \Info.name) { event in
      changeCount += 1
      XCTAssert(event.id == (\Info.name).id)
      XCTAssert(event.newValue == "baz")
      XCTAssert(event.oldValue == "foo")
    }
    proxy.set(\Info.name, "baz")
    XCTAssert(changeCount == 1)

    // Just to silence the variable never used token.
    token.dispose()
  }
}
