import Combine
import Darwin
import XCTest

@testable import DotletCore

final class ScreenTests: XCTestCase {
  func testCommandMappingAndBounds() throws {
    XCTAssertEqual(
      try ScreenSelection(library: .opendotlet, index: 13).commands(),
      "FACES OPENDOTLET\nPAUSE\n" + String(repeating: "NEXT\n", count: 13) + "STATUS\n")
    XCTAssertEqual(
      try ScreenSelection(library: .openai, index: 0).commands(), "FACES OPENAI\nPAUSE\nSTATUS\n")
    XCTAssertThrowsError(try ScreenSelection(library: .openai, index: 28).commands())
    XCTAssertThrowsError(try ScreenSelection(library: .opendotlet, index: -1).commands())
    XCTAssertEqual(FaceLibrary.openai.frames[8], "Cyan smile")
  }
  func testAcknowledgementsRejectOlderOrMalformedFirmware() {
    let good = ScreenStatus.parse(
      "I (200) gallery: STATUS index=13 count=15 auto=0 library=opendotlet free_heap=10000")
    XCTAssertEqual(good?.selection, ScreenSelection(library: .opendotlet, index: 13))
    XCTAssertEqual(good?.autoplay, false)
    for line in [
      "STATUS index=0 count=28 auto=0", "STATUS index=28 count=28 auto=0 library=openai",
      "STATUS index=0 count=15 auto=0 library=openai",
      "STATUS index=0 count=15 auto=3 library=opendotlet", "ALIVE index=0 library=opendotlet",
    ] {
      XCTAssertNil(ScreenStatus.parse(line))
    }
  }
  @MainActor func testPseudoTerminalHandshakeAndApplyRequireMatchingAcknowledgement() throws {
    var master: Int32 = -1
    var slave: Int32 = -1
    var name = [CChar](repeating: 0, count: 256)
    XCTAssertEqual(openpty(&master, &slave, &name, nil, nil), 0)
    guard master >= 0 else { return }
    defer {
      Darwin.close(master)
      Darwin.close(slave)
    }
    _ = fcntl(master, F_SETFL, O_NONBLOCK)
    let domain = "OpenDotlet.ScreenTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: domain)!
    defer { defaults.removePersistentDomain(forName: domain) }
    let screen = ScreenStore(defaults: defaults)
    screen.connect(path: String(cString: name))
    defer { screen.disconnect() }
    XCTAssertTrue(screen.connected, screen.errorMessage ?? "")
    func write(_ text: String) { text.withCString { p in _ = Darwin.write(master, p, strlen(p)) } }
    write("STATUS index=0 count=15 auto=0 library=opendotlet\n")
    let ready = expectation(description: "ready")
    var bag = Set<AnyCancellable>()
    screen.$ready.filter { $0 }.first().sink { _ in ready.fulfill() }.store(in: &bag)
    wait(for: [ready], timeout: 2)
    screen.apply(ScreenSelection(library: .openai, index: 2))
    XCTAssertTrue(screen.applying)
    let ignored = expectation(description: "wrong acknowledgement does not complete apply")
    screen.$confirmed.dropFirst().first().sink { _ in
      XCTAssertTrue(screen.applying)
      ignored.fulfill()
    }.store(in: &bag)
    write("STATUS index=0 count=15 auto=0 library=opendotlet\n")
    wait(for: [ignored], timeout: 2)
    XCTAssertTrue(screen.applying)
    let applied = expectation(description: "matching status")
    screen.$applying.dropFirst().filter { !$0 }.first().sink { _ in applied.fulfill() }.store(
      in: &bag)
    write("STATUS index=2 count=28 auto=0 library=openai\n")
    wait(for: [applied], timeout: 2)
    XCTAssertEqual(screen.confirmed?.selection, ScreenSelection(library: .openai, index: 2))
    XCTAssertNil(screen.errorMessage)
    var output = [UInt8](repeating: 0, count: 4096)
    let count = Darwin.read(master, &output, output.count)
    XCTAssertGreaterThan(count, 0)
    let sent = String(decoding: output.prefix(max(0, count)), as: UTF8.self)
    XCTAssertTrue(sent.contains("FACES OPENAI\nPAUSE\nNEXT\nNEXT\nSTATUS\n"), sent)
  }

  @MainActor func testScreenReconnectsToSamePortAfterCableLossAndDisconnectStopsRetry() throws {
    let domain = "OpenDotlet.ScreenTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: domain)!
    defer { defaults.removePersistentDomain(forName: domain) }
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    let path = folder.appendingPathComponent("screen").path
    var master: Int32 = -1
    var slave: Int32 = -1
    var name = [CChar](repeating: 0, count: 256)
    XCTAssertEqual(openpty(&master, &slave, &name, nil, nil), 0)
    defer {
      if master >= 0 { Darwin.close(master) }
      if slave >= 0 { Darwin.close(slave) }
    }
    try FileManager.default.createSymbolicLink(
      atPath: path, withDestinationPath: String(cString: name))
    let screen = ScreenStore(defaults: defaults)
    defer { screen.disconnect() }
    screen.connect(path: path)
    var bag = Set<AnyCancellable>()
    func acknowledge() {
      let line = "STATUS index=0 count=15 auto=0 library=opendotlet\n"
      line.withCString { p in _ = Darwin.write(master, p, strlen(p)) }
    }
    let firstReady = expectation(description: "original screen ready")
    screen.$ready.filter { $0 }.first().sink { _ in firstReady.fulfill() }.store(in: &bag)
    acknowledge()
    wait(for: [firstReady], timeout: 2)
    let lost = expectation(description: "cable removed")
    screen.$connected.dropFirst().filter { !$0 }.first().sink { _ in lost.fulfill() }.store(
      in: &bag)
    Darwin.close(master)
    Darwin.close(slave)
    master = -1
    slave = -1
    wait(for: [lost], timeout: 2)
    XCTAssertFalse(screen.ready)
    XCTAssertTrue(screen.maintainingConnection)
    XCTAssertEqual(screen.port, path)
    // Replace the removed device at the same path, as USB re-enumeration does.
    XCTAssertEqual(openpty(&master, &slave, &name, nil, nil), 0)
    try FileManager.default.removeItem(atPath: path)
    try FileManager.default.createSymbolicLink(
      atPath: path, withDestinationPath: String(cString: name))
    let restored = expectation(description: "same port reopened automatically")
    screen.$connected.filter { $0 }.first().sink { _ in restored.fulfill() }.store(in: &bag)
    wait(for: [restored], timeout: 4)
    let secondReady = expectation(description: "restored firmware acknowledged")
    screen.$ready.filter { $0 }.first().sink { _ in secondReady.fulfill() }.store(in: &bag)
    acknowledge()
    wait(for: [secondReady], timeout: 2)
    XCTAssertEqual(screen.port, path)
    XCTAssertNil(screen.errorMessage)
    screen.disconnect()
    XCTAssertFalse(defaults.bool(forKey: "screenKeepConnected"))
    let settled = expectation(description: "explicit disconnect remains stopped")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { settled.fulfill() }
    wait(for: [settled], timeout: 2)
    XCTAssertFalse(screen.connected)
    XCTAssertFalse(screen.maintainingConnection)
  }

  @MainActor func testSavedScreenRestoresAfterRelaunchWithoutSelectingAnotherPort() throws {
    let domain = "OpenDotlet.ScreenTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: domain)!
    defer { defaults.removePersistentDomain(forName: domain) }
    let missing = "/dev/cu.opendotlet-test-missing-\(UUID().uuidString)"
    defaults.set(missing, forKey: "screenPort")
    defaults.set(true, forKey: "screenKeepConnected")
    let screen = ScreenStore(defaults: defaults)
    defer { screen.disconnect() }
    XCTAssertTrue(screen.maintainingConnection)
    screen.refreshPorts()
    XCTAssertEqual(screen.port, missing)
    let attempt = expectation(description: "remembered port retried")
    var bag = Set<AnyCancellable>()
    screen.$errorMessage.compactMap { $0 }.first().sink { message in
      XCTAssertTrue(message.contains("Retrying automatically"))
      attempt.fulfill()
    }.store(in: &bag)
    wait(for: [attempt], timeout: 2)
    XCTAssertFalse(screen.connected)
    XCTAssertEqual(screen.port, missing)
  }
}
