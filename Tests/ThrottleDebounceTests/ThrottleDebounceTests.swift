import XCTest
@testable import ThrottleDebounce

final class SafeBox<T>: @unchecked Sendable {
    private var value: T
    private let lock = NSLock()

    init(_ value: T) {
        self.value = value
    }

    func mutate(_ block: (inout T) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        block(&value)
    }

    func get() -> T {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

final class ThrottleDebounceTests: XCTestCase {
    func testThrottleLimitsInvocations() {
        let expectation = self.expectation(description: "Throttled action fires")
        let executionCount = SafeBox(0)

        let throttled = throttle(milliseconds: 200, queue: .main) {
            executionCount.mutate { $0 += 1 }
        }

        // Fire 5 times immediately
        for _ in 0..<5 {
            throttled()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            XCTAssertEqual(executionCount.get(), 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testDebouncePostponesExecution() {
        let expectation = self.expectation(description: "Debounced action executes once")
        let executionCount = SafeBox(0)

        let debounced = debounce(milliseconds: 150, queue: .main) {
            executionCount.mutate { $0 += 1 }
        }

        // Rapidly call multiple times
        debounced()
        debounced()
        debounced()

        XCTAssertEqual(executionCount.get(), 0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            XCTAssertEqual(executionCount.get(), 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testAsyncThrottler() async throws {
        let throttler = AsyncThrottler(interval: 0.1)
        let counter = SafeBox(0)

        let r1 = try await throttler.execute {
            var current = 0
            counter.mutate {
                $0 += 1
                current = $0
            }
            return current
        }
        XCTAssertEqual(r1, 1)

        // Immediate next call should be throttled out (nil)
        let r2 = try await throttler.execute {
            var current = 0
            counter.mutate {
                $0 += 1
                current = $0
            }
            return current
        }
        XCTAssertNil(r2)

        // Wait past interval
        try await Task.sleep(nanoseconds: 120_000_000)
        let r3 = try await throttler.execute {
            var current = 0
            counter.mutate {
                $0 += 1
                current = $0
            }
            return current
        }
        XCTAssertEqual(r3, 2)
    }
}
