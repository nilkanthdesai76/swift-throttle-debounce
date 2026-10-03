import Foundation

final class DebouncerState: @unchecked Sendable {
    private let lock = NSLock()
    private var workItem: DispatchWorkItem?

    func schedule(interval: TimeInterval, queue: DispatchQueue, action: @escaping @Sendable () -> Void) {
        lock.lock()
        workItem?.cancel()

        let item = DispatchWorkItem {
            action()
        }
        workItem = item
        lock.unlock()

        queue.asyncAfter(deadline: .now() + interval, execute: item)
    }
}

/// Creates a debounced action closure that postpones execution until after a specified quiet period has elapsed.
public func debounce(
    interval: TimeInterval,
    queue: DispatchQueue = .main,
    action: @escaping @Sendable () -> Void
) -> @Sendable () -> Void {
    let state = DebouncerState()
    return {
        state.schedule(interval: interval, queue: queue, action: action)
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
