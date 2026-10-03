import XCTest
@testable import ThrottleDebounce

final class ThrottleDebounceTests: XCTestCase {
    func testThrottleLimitsInvocations() {
        let expectation = self.expectation(description: "Throttled action fires")
        var executionCount = 0

        let throttled = throttle(milliseconds: 200, queue: .main) {
            executionCount += 1
        }

        // Fire 5 times immediately
        for _ in 0..<5 {
            throttled()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            XCTAssertEqual(executionCount, 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testDebouncePostponesExecution() {
        let expectation = self.expectation(description: "Debounced action executes once")
        var executionCount = 0

        let debounced = debounce(milliseconds: 150, queue: .main) {
            executionCount += 1
        }

        // Rapidly call multiple times
        debounced()
        debounced()
        debounced()

        XCTAssertEqual(executionCount, 0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            XCTAssertEqual(executionCount, 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testAsyncThrottler() async throws {
        let throttler = AsyncThrottler(interval: 0.1)
        var count = 0

        let r1 = try await throttler.execute {
            count += 1
            return count
        }
        XCTAssertEqual(r1, 1)

        // Immediate next call should be throttled out (nil)
        let r2 = try await throttler.execute {
            count += 1
            return count
        }
        XCTAssertNil(r2)

        // Wait past interval
        try await Task.sleep(nanoseconds: 120_000_000)
        let r3 = try await throttler.execute {
            count += 1
            return count
        }
        XCTAssertEqual(r3, 2)
    }
}
