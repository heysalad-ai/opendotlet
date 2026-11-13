import XCTest

@testable import DotletCore

final class ProtocolTests: XCTestCase {
  func status(_ bytes: Data, id: UInt16 = 7) throws -> DeviceStatus {
    var b = [UInt8](repeating: 0, count: 20)
    b[0] = 1
    b[1] = 3
    b[2] = UInt8(id)
    b[19] = 5
    func put(_ offset: Int, _ n: UInt32) {
      for i in 0..<4 { b[offset + i] = UInt8(truncatingIfNeeded: n >> (8 * i)) }
    }
    put(4, UInt32(bytes.count / 2))
    put(8, 1_000_000)
    put(12, Wire.checksum(bytes))
    return try DeviceStatus(Data(b))
  }
  func packet(_ bytes: [UInt8], offset: UInt32 = 0, id: UInt16 = 7) -> Data {
    Data(
      [0xa1, UInt8(truncatingIfNeeded: id), UInt8(truncatingIfNeeded: id >> 8)]
        + (0..<4).map { UInt8(truncatingIfNeeded: offset >> ($0 * 8)) } + bytes)
  }
  func testCompleteClip() throws {
    let bytes = Data([1, 3, 2, 3])
    var a = try ClipAssembler(status: status(bytes))
    try a.append(packet([1, 3]))
    try a.append(packet([2, 3], offset: 2))
    XCTAssertEqual(try a.finish(), bytes)
    XCTAssertEqual(a.progress, 1)
  }
  func testRejectsCorruptAndTruncated() throws {
    let bytes = Data([1, 3, 2, 3])
    var a = try ClipAssembler(status: status(bytes))
    try a.append(packet([1, 3]))
    XCTAssertThrowsError(try a.finish())
    try a.append(packet([3, 3], offset: 2))
    XCTAssertThrowsError(try a.finish())
  }
  func testRejectsWrongClipAndOffset() throws {
    var a = try ClipAssembler(status: status(Data([1, 3, 2, 3])))
    XCTAssertThrowsError(try a.append(packet([1, 3], id: 8)))
    XCTAssertThrowsError(try a.append(packet([1, 3], offset: 2)))
  }
  func testRejectsMalformedStatus() {
    XCTAssertThrowsError(try DeviceStatus(Data([1, 3])))
  }
  func testRejectsOutOfRangeADC() throws {
    let bytes = Data([0, 32])
    var a = try ClipAssembler(status: status(bytes))
    try a.append(packet([0, 32]))
    XCTAssertThrowsError(try a.finish())
  }
}
