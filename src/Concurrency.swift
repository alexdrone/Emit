import Foundation

public protocol SynchronizationStrategy {
  /// Synchronize the block of code passed as argument.
  func synchronize( _ block: @escaping () -> Void)
}

/// An object that contains a `SynchronizationStrategy` member becomes `Synchronizable``.
public protocol Synchronizable {
  /// The synchronization strategy for the object implementing this protocol.
  var synchronizationStrategy: SynchronizationStrategy { get set }
}

public extension Synchronizable {
  /// Short-hand for `self.synchronizationStrategy.synchronize(_:)`.
  /// Runs the code passed as parameter with the desired synchronization strategy.
  @inline(__always)
  public func synchronize(_ block: @escaping () -> Void) {
    synchronizationStrategy.synchronize(block)
  }
}

// MARK: - Strategies

/// The block is executed in a non-synchronized fashion but with assertions that make sure that
/// the caller is running on the main thread.
/// This often the default synchronzation mechanism.
final public class NonSynchronizedMainThread: SynchronizationStrategy {
  public static let `default` = NonSynchronizedMainThread()
  /// Simply checks that the block is performed on the main thread without any additional
  /// synchronization logic.
  @inline(__always)
  public func synchronize(_ block: @escaping () -> Void) {
    assert(Thread.isMainThread)
    block()
  }
}

/// Synchronization based on `os_unfair_lock`.
final public class SpinLockSynchronized: SynchronizationStrategy {
  public static let `default` = SpinLockSynchronized()
  /// Internal lock.
  private var lock = os_unfair_lock_s()
  /// Simply checks that the block is performed on the main thread without any additional
  /// synchronization logic.
  public func synchronize(_ block: @escaping () -> Void) {
    os_unfair_lock_lock(&lock)
    block()
    os_unfair_lock_unlock(&lock)
  }
}
