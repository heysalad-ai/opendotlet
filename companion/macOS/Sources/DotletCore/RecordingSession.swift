/// One explicit Enable authorizes repeated physical holds for this app session.
/// This intent is never persisted across app launches.
public struct RecordingSession {
  public private(set) var requested = false
  public private(set) var arming = false

  public init() {}
  public mutating func enable() { requested = true }
  public mutating func pause() {
    requested = false
    arming = false
  }
  public mutating func armRequested() { arming = true }
  public mutating func resetPendingCommand() { arming = false }
  public func shouldArm(ready: Bool, busy: Bool, armed: Bool) -> Bool {
    requested && !arming && ready && !busy && !armed
  }
}
