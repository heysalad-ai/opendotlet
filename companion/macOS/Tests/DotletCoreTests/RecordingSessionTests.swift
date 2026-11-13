import XCTest

@testable import DotletCore

final class RecordingSessionTests: XCTestCase {
  func testRepeatedHoldsNeedOnlyOneEnableAndNeverRearmDuringProcessing() {
    var session = RecordingSession()
    XCTAssertFalse(session.shouldArm(ready: true, busy: false, armed: false))
    session.enable()
    for _ in 0..<3 {
      XCTAssertTrue(session.shouldArm(ready: true, busy: false, armed: false))
      session.armRequested()
      XCTAssertFalse(session.shouldArm(ready: true, busy: false, armed: false))
      session.resetPendingCommand()
      XCTAssertFalse(session.shouldArm(ready: true, busy: false, armed: true))
      XCTAssertFalse(session.shouldArm(ready: true, busy: true, armed: false))
      XCTAssertFalse(session.shouldArm(ready: false, busy: false, armed: false))
      // Finishing transfer/transcription permits the next physical hold.
    }
  }

  func testPauseCancelsPendingRearmAndRestartDoesNotResumeMicrophoneSession() {
    var session = RecordingSession()
    session.enable()
    session.armRequested()
    session.pause()
    session.resetPendingCommand()
    XCTAssertFalse(session.shouldArm(ready: true, busy: false, armed: false))
    XCTAssertFalse(RecordingSession().requested)
    // A transport interruption can resume the existing explicit session,
    // but cannot create permission when the user has paused it.
    session.enable()
    session.armRequested()
    session.resetPendingCommand()
    XCTAssertTrue(session.shouldArm(ready: true, busy: false, armed: false))
  }
}
