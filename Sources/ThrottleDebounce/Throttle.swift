import Foundation

/// Creates a throttled action closure that limits invocation rate to at most once per specified time interval.
///
/// - Parameters:
///   - interval: The minimum time duration between executions.
///   - queue: The dispatch queue on which the action should execute. Defaults to `.main`.
///   - action: The closure to execute when permitted.
/// - Returns: A closure wrapping the throttled execution.
public func throttle(
    interval: TimeInterval,
    queue: DispatchQueue = .main,
    action: @escaping @Sendable () -> Void
) -> @Sendable () -> Void {
    let lock = NSLock()
    var lastExecutionTime: DispatchTime = .distantPast

    return {
        lock.lock()
        let now = DispatchTime.now()
        let intervalNano = UInt64(interval * 1_000_000_000)
        let elapsed = now.uptimeNanoseconds - lastExecutionTime.uptimeNanoseconds

        if elapsed >= intervalNano {
            lastExecutionTime = now
            lock.unlock()
            queue.async {
                action()
            }
        } else {
            lock.unlock()
        }
    }
}

/// Overload accepting milliseconds for convenience.
public func throttle(
    milliseconds: Int,
    queue: DispatchQueue = .main,
    action: @escaping @Sendable () -> Void
) -> @Sendable () -> Void {
    throttle(interval: TimeInterval(milliseconds) / 1000.0, queue: queue, action: action)
}
