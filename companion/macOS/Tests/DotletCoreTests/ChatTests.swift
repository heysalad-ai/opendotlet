import XCTest

@testable import DotletCore

final class ChatTests: XCTestCase {
  func testPersistentRoundTripAndRecordingDeduplication() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let file = root.appendingPathComponent("chats.json")
    var archive = ChatArchive()
    archive.addNote("  Remember the screen test  ")
    archive.addRecording(id: "clip1", text: "Spoken thought", date: Date())
    archive.addRecording(id: "clip1", text: "Duplicate", date: Date())
    try archive.save(to: file)
    let saved = try ChatArchive.read(from: file)
    XCTAssertEqual(saved, archive)
    XCTAssertEqual(saved.selected?.messages.count, 2)
    XCTAssertEqual(saved.selected?.messages.first?.text, "Remember the screen test")
    XCTAssertEqual(
      (try FileManager.default.attributesOfItem(atPath: file.path)[.posixPermissions] as? NSNumber)?
        .intValue, 0o600)
  }
  func testVoiceAndRepliesStayWithOriginatingChatAfterSwitch() {
    var archive = ChatArchive()
    let first = archive.selectedID
    archive.beginCapture()
    let second = archive.newConversation()
    archive.addRecording(id: "clip2", text: "For first room", date: Date())
    XCTAssertEqual(
      archive.conversations.first { $0.id == first }?.messages.last?.recordingID, "clip2")
    XCTAssertTrue(archive.selected!.messages.isEmpty)
    archive.addReply("Late answer", to: first)
    XCTAssertEqual(archive.selectedID, second)
    XCTAssertTrue(archive.selected!.messages.isEmpty)
    XCTAssertEqual(archive.conversations.first { $0.id == first }?.messages.last?.kind, .assistant)
  }
  func testOnlyExplicitlySelectedMessagesGoToAI() {
    var archive = ChatArchive()
    archive.addNote("Private note")
    archive.addRecording(id: "local", text: "Local recording", date: Date())
    XCTAssertTrue(archive.apiMessages(in: archive.selectedID).isEmpty)
    let message = archive.selected!.messages.last!
    archive.markSent(message.id, in: archive.selectedID)
    archive.addReply("Actual reply fixture", to: archive.selectedID)
    XCTAssertEqual(
      archive.apiMessages(in: archive.selectedID).map(\.text),
      ["Local recording", "Actual reply fixture"])
  }
  func testEmptyNotesAndCorruptHistory() throws {
    var archive = ChatArchive()
    archive.addNote(" \n ")
    XCTAssertTrue(archive.selected!.messages.isEmpty)
    let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: file) }
    try Data("broken".utf8).write(to: file)
    XCTAssertThrowsError(try ChatArchive.read(from: file))
    XCTAssertEqual(try String(contentsOf: file), "broken")
  }
}
