import XCTest

@testable import DotletCore

final class LiveFaceTests: XCTestCase {
  func testUnknownStateSelectsPeelFromStart() {
    XCTAssertEqual(
      LiveFace.commands(to: 2, from: nil), "FACES OPENDOTLET\nPAUSE\nNEXT\nNEXT\nSTATUS\n")
    XCTAssertEqual(
      LiveFace.commands(to: 0, from: ScreenSelection(library: .openai, index: 5)),
      "FACES OPENDOTLET\nPAUSE\nSTATUS\n")
  }
  func testShortestRelativeSteps() {
    let listening = ScreenSelection(library: .opendotlet, index: 1)
    XCTAssertEqual(LiveFace.commands(to: 3, from: listening), "PAUSE\nNEXT\nNEXT\nSTATUS\n")
    XCTAssertEqual(LiveFace.commands(to: 0, from: listening), "PAUSE\nPREV\nSTATUS\n")
    // From the paper character (14) to idle (0) wraps forward one step.
    XCTAssertEqual(
      LiveFace.commands(to: 0, from: ScreenSelection(library: .opendotlet, index: 14)),
      "PAUSE\nNEXT\nSTATUS\n")
  }
  func testRejectsOutOfRangeFrames() {
    XCTAssertNil(LiveFace.commands(to: 15, from: nil))
    XCTAssertNil(LiveFace.commands(to: -1, from: nil))
  }
  func testMoodsMatchFirmwareFrameOrder() {
    for mood in ScreenMood.allCases {
      XCTAssertEqual(
        FaceLibrary.opendotlet.frames[mood.rawValue], String(describing: mood))
    }
    XCTAssertEqual(ScreenMood.idleIndex(character: "coral"), 0)
    XCTAssertEqual(ScreenMood.idleIndex(character: "mint"), 9)
    XCTAssertEqual(FaceLibrary.opendotlet.frames[ScreenMood.idleIndex(character: "paper")], "paper")
    XCTAssertEqual(ScreenMood.idleIndex(character: "unknown"), 0)
  }
  func testChatTitlesEndAtAWord() {
    XCTAssertEqual(Conversation.title(for: "Short note"), "Short note")
    XCTAssertEqual(
      Conversation.title(for: "OpenDotlet setup: try the Peel faces on the round screen."),
      "OpenDotlet setup: try the Peel faces on the…")
    XCTAssertEqual(Conversation.title(for: "First line\nSecond line"), "First line")
  }
}
