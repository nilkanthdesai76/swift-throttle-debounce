import Foundation

/// Creates a debounced action closure that postpones execution until after a specified quiet period has elapsed.
///
/// - Parameters:
///   - interval: The quiet period duration required before execution fires.
///   - queue: The dispatch queue on which the action should execute. Defaults to `.main`.
///   - action: The closure to execute once the quiet period elapses.
/// - Returns: A closure wrapping the debounced execution.
public func debounce(
    interval: TimeInterval,
    queue: DispatchQueue = .main,
    action: @escaping @Sendable () -> Void
) -> @Sendable () -> Void {
    let lock = NSLock()
    var workItem: DispatchWorkItem?

    return {
        lock.lock()
        workItem?.cancel()

        let newWorkItem = DispatchWorkItem {
            action()
        }
        workItem = newWorkItem
        lock.unlock()

        queue.asyncAfter(deadline: .now() + interval, execute: newWorkItem)
    }
}

/// Overload accepting milliseconds for convenience.
public func debounce(
    milliseconds: Int,
    queue: DispatchQueue = .main,
    action: @escaping @Sendable () -> Void
) -> @Sendable () -> Void {
    debounce(interval: TimeInterval(milliseconds) / 1000.0, queue: queue, action: action)
}
