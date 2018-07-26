import Foundation

// MARK: - Dispatch Strategy

public protocol Dispatcher {
  /// Provide an implementation for the desired dispatch strategy.
  func dispatch(strategy: DispatchStrategy, _ block: @escaping () -> Void)
}

public enum DispatchStrategy {
  /// The event is dispatched in the same thread that called *emitEvent* right away.
  case immediate
  /// The event is always dispatched on the main thread.
  case mainThread
  /// The event is always dispatched on the main thread, on the next run loop.
  case nextRunLoop
  /// The event is always dispatched off the main thead.
  case backgroundThread
  /// The event is dispatched on a (shared) internal serial queue.
  case serialQueue
}

open class DefaultDispatcher: Dispatcher {
  public static let `default` = DefaultDispatcher()
  /// Internal serial dispatch queue.
  public let serialOperationQueue: OperationQueue = {
    let operationQueue = OperationQueue()
    operationQueue.maxConcurrentOperationCount = 1
    return operationQueue
  }()
  /// Default dispatcher implementation.
  @inline(__always)
  open func dispatch(strategy: DispatchStrategy, _ block: @escaping () -> Void) {
    switch strategy {
    case .immediate:
      block()
    case .mainThread:
      if Thread.isMainThread {
        block()
      } else {
        DispatchQueue.main.async(execute: block)
      }
    case .nextRunLoop:
      DispatchQueue.main.async(execute: block)
    case .backgroundThread:
      DispatchQueue.global().async(execute: block)
    case .serialQueue:
      serialOperationQueue.addOperation(block)
    }
  }
  
  public init() { }
}

public protocol Dispatchable {
  /// - note: This can be overridden with a custom *Dispatcher* implementation.
  var dispatcher: Dispatcher { get set }
  /// The default event dispatch strategy.
  var dispatchStrategy: DispatchStrategy  { get set }
}

public extension Dispatchable {
  /// Short-hand for *dispatcher.dispatch(strategy:_:)*
  @inline(__always)
  public func dispatch(_ block: @escaping () -> Void) {
    dispatcher.dispatch(strategy: dispatchStrategy, block)
  }
}

// MARK: - Observer Registration Strategy

public protocol SynchronizationStrategy  {
  /// Synchronize the block of code passed as argument.
  func synchronize( _ block: @escaping () -> Void)
}

public class NonSyncronizedMainThread: SynchronizationStrategy {
  public static let `default` = NonSyncronizedMainThread()
  /// Simply checks that the block is performed on the main thread without any additional
  /// synchronization logic.
  @inline(__always)
  public func synchronize(_ block: @escaping () -> Void) {
    assert(Thread.isMainThread)
    block()
  }
}

public protocol Synchronizable {
  /// The synchronization strategy for the object implementing this protocol.
  var synchronizationStrategy: SynchronizationStrategy { get set }
}

public extension Synchronizable {
  /// Short-hand for *synchronizationStrategy.synchronize(_:)*.
  @inline(__always)
  public func synchronize(_ block: @escaping () -> Void) {
    synchronizationStrategy.synchronize(block)
  }
}
