import Foundation

final class ThrottlerState: @unchecked Sendable {
    private let lock = NSLock()
    private var lastExecutionTime: DispatchTime?

    func shouldExecute(interval: TimeInterval) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let now = DispatchTime.now()
        guard let last = lastExecutionTime else {
            lastExecutionTime = now
            return true
        }

        let intervalNano = UInt64(interval * 1_000_000_000)
        let elapsed = now.uptimeNanoseconds - last.uptimeNanoseconds

        if elapsed >= intervalNano {
            lastExecutionTime = now
            return true
        }
        return false
    }
}

/// Creates a throttled action closure that limits invocation rate to at most once per specified time interval.
public func throttle(
    interval: TimeInterval,
    queue: DispatchQueue = .main,
    action: @escaping @Sendable () -> Void
) -> @Sendable () -> Void {
    let state = ThrottlerState()
    return {
        if state.shouldExecute(interval: interval) {
            queue.async {
                action()
            }
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
