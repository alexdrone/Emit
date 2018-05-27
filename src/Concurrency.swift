import Foundation

// MARK - Event Dispatch Strategy

public protocol Dispatcher {
  /// This can provide custom threading behaviour for the given dispatch strategy
  /// e.g. Run on a custom dispatch group or queue.
  func dispatch(strategy: EventDispatchStrategy, _ block: @escaping () -> Void)
}

public enum EventDispatchStrategy {
  /// The event is dispatched in the same thread that called *emitEvent* right away.
  case immediate
  /// The event is always dispatched on the main thread.
  /// If the *emitEvent* invokation was alread in the main thread the effect of this strategy is
  /// the same of *immediate*.
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
  open func dispatch(strategy: EventDispatchStrategy, _ block: @escaping () -> Void) {
    switch strategy {
    // The block is executed immeditely on the same call stack.
    case .immediate:
      block()
    // The event is always dispatched on the main thread.
    case .mainThread:
      if Thread.isMainThread {
        block()
      } else {
        DispatchQueue.main.async(execute: block)
      }
    // The event is always dispatched on the main thread, on the next run loop.
    case .nextRunLoop:
      DispatchQueue.main.async(execute: block)
    // Dispatch the event on the background thread.
    case .backgroundThread:
      DispatchQueue.global().async(execute: block)
    // The event is dispatched on a (shared) internal serial queue.
    case .serialQueue:
      serialOperationQueue.addOperation(block)
    }
  }
  
  public init() { }
}

// MARK - Observer Registration Strategy

public protocol SynchronizationStrategy  {
  /// Entry point for customizing the synchronization strategy.
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
