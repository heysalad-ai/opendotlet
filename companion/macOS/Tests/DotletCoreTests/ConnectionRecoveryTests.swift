import XCTest

@testable import DotletCore

final class ConnectionRecoveryTests: XCTestCase {
  func testTransientLossRetriesWithCappedBackoffAndSuccessResetsIt() {
    var recovery = ConnectionRecovery()
    let now = Date(timeIntervalSince1970: 100)
    recovery.start(at: now)
    XCTAssertTrue(recovery.shouldRetry(at: now))
    recovery.attemptStarted()
    XCTAssertFalse(recovery.shouldRetry(at: now.addingTimeInterval(100)))
    for delay in [1.0, 2, 4, 8, 15, 30, 30] {
      recovery.failed(at: now)
      XCTAssertFalse(recovery.shouldRetry(at: now.addingTimeInterval(delay - 0.01)))
      XCTAssertTrue(recovery.shouldRetry(at: now.addingTimeInterval(delay)))
      recovery.attemptStarted()
    }
    recovery.succeeded()
    XCTAssertTrue(recovery.wanted)
    XCTAssertFalse(recovery.shouldRetry(at: now.addingTimeInterval(100)))
    recovery.failed(at: now)
    XCTAssertTrue(recovery.shouldRetry(at: now.addingTimeInterval(1)))
  }

  func testExplicitDisconnectCancelsPendingAndLateFailureCannotRestartIt() {
    var recovery = ConnectionRecovery()
    let now = Date()
    recovery.start(at: now)
    recovery.failed(at: now)
    recovery.stop()
    recovery.failed(at: now)
    XCTAssertFalse(recovery.wanted)
    XCTAssertFalse(recovery.shouldRetry(at: now.addingTimeInterval(1000)))
    recovery.start(at: now)
    XCTAssertTrue(recovery.shouldRetry(at: now))
  }
}
