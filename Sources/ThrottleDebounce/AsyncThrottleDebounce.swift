import Foundation

/// An actor-isolated throttler for asynchronous workflows in Swift Concurrency.
public actor AsyncThrottler {
    private let interval: TimeInterval
    private var lastRun: Date = .distantPast

    public init(interval: TimeInterval) {
        self.interval = interval
    }

    /// Executes the given async block only if the interval duration has elapsed since the last execution.
    @discardableResult
    public func execute<T: Sendable>(_ operation: @Sendable () async throws -> T) async throws -> T? {
        let now = Date()
        guard now.timeIntervalSince(lastRun) >= interval else {
            return nil
        }
        lastRun = now
        return try await operation()
    }
}

/// An actor-isolated debouncer for asynchronous tasks in Swift Concurrency.
public actor AsyncDebouncer {
    private let delay: TimeInterval
    private var currentTask: Task<Void, Never>?

    public init(delay: TimeInterval) {
        self.delay = delay
    }

    /// Schedules an async action, cancelling any prior pending invocation.
    public func submit(_ action: @escaping @Sendable () async -> Void) {
        currentTask?.cancel()
        currentTask = Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                if !Task.isCancelled {
                    await action()
                }
            } catch {
                // Task cancelled
            }
        }
    }
}
