import Foundation

public enum DotletError: LocalizedError {
  case invalid(String)
  public var errorDescription: String? {
    if case .invalid(let message) = self { return message }
    return nil
  }
}
public enum Wire {
  public static let service = "5F31A700-6D6C-4B7D-9F7C-0A2D6E010001"
  public static let control = "5F31A701-6D6C-4B7D-9F7C-0A2D6E010001"
  public static let status = "5F31A702-6D6C-4B7D-9F7C-0A2D6E010001"
  public static let audio = "5F31A703-6D6C-4B7D-9F7C-0A2D6E010001"
  public static func u16(_ b: [UInt8], _ offset: Int) -> UInt16 {
    UInt16(b[offset]) | UInt16(b[offset + 1]) << 8
  }
  public static func u32(_ b: [UInt8], _ offset: Int) -> UInt32 {
    (0..<4).reduce(0) { $0 | UInt32(b[offset + $1]) << ($1 * 8) }
  }
  public static func checksum(_ data: Data) -> UInt32 {
    data.reduce(UInt32(2_166_136_261)) { ($0 ^ UInt32($1)) &* 16_777_619 }
  }
}
public struct DeviceStatus: Equatable {
  public let state: UInt8, id: UInt16, samples: UInt32, elapsed: UInt32
  public let checksum: UInt32, maxLateness: UInt16, reason: UInt8, flags: UInt8
  public var encrypted: Bool { flags & 1 != 0 }
  public var microphonePowered: Bool { flags & 2 != 0 }
  public var subscribed: Bool { flags & 4 != 0 }
  public init(_ data: Data) throws {
    let b = [UInt8](data)
    guard b.count == 20, b[0] == 1, b[1] <= 5 else {
      throw DotletError.invalid("Unsupported device status. Reconnect the button.")
    }
    state = b[1]
    id = Wire.u16(b, 2)
    samples = Wire.u32(b, 4)
    elapsed = Wire.u32(b, 8)
    checksum = Wire.u32(b, 12)
    maxLateness = Wire.u16(b, 16)
    reason = b[18]
    flags = b[19]
    guard samples <= 80000, elapsed <= 10_500_000 else {
      throw DotletError.invalid("The clip exceeds the device recording limit.")
    }
  }
  public var metadata: [String: Any] {
    [
      "samples": samples, "elapsed_us": elapsed, "checksum": checksum,
      "max_lateness_us": maxLateness, "reason": reason, "clip_id": id, "transport": "BLE",
    ]
  }
}
public struct ClipAssembler {
  public let status: DeviceStatus
  public private(set) var data = Data()
  public var progress: Double { Double(data.count) / Double(max(status.samples * 2, 1)) }
  public init(status: DeviceStatus) throws {
    guard status.state == 3, status.samples > 0, status.elapsed > 0, status.encrypted,
      !status.microphonePowered, status.reason <= 1
    else { throw DotletError.invalid("The device did not finish a valid recording.") }
    self.status = status
  }
  public mutating func append(_ packet: Data) throws {
    let b = [UInt8](packet)
    guard b.count > 7, b[0] == 0xa1, Wire.u16(b, 1) == status.id else {
      throw DotletError.invalid("Received audio for a different clip. Please record again.")
    }
    let offset = Int(Wire.u32(b, 3))
    let payload = Data(b.dropFirst(7))
    guard offset == data.count, data.count + payload.count <= Int(status.samples) * 2 else {
      throw DotletError.invalid(
        "Audio packets arrived out of order or incomplete. Please record again.")
    }
    data.append(payload)
  }
  public func finish() throws -> Data {
    guard data.count == Int(status.samples) * 2, Wire.checksum(data) == status.checksum else {
      throw DotletError.invalid("Audio integrity check failed. Please record again.")
    }
    let b = [UInt8](data)
    for i in stride(from: 0, to: b.count, by: 2) {
      guard Wire.u16(b, i) <= 4095 else {
        throw DotletError.invalid("Invalid microphone sample received.")
      }
    }
    return data
  }
}
