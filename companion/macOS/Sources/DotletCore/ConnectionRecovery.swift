import Foundation

/// Connection intent survives transport errors; only an explicit stop cancels it.
/// Recording permission is deliberately outside this policy.
public struct ConnectionRecovery {
  public private(set) var wanted = false
  private var failures = 0
  private var retryAt: Date?

  public init() {}

  public mutating func start(at now: Date = Date()) {
    wanted = true
    failures = 0
    retryAt = now
  }

  public mutating func stop() {
    wanted = false
    retryAt = nil
    failures = 0
  }

  public mutating func attemptStarted() { retryAt = nil }

  public mutating func succeeded() {
    failures = 0
    retryAt = nil
  }

  public mutating func failed(at now: Date = Date()) {
    guard wanted else { return }
    let delays: [TimeInterval] = [1, 2, 4, 8, 15, 30]
    retryAt = now.addingTimeInterval(delays[min(failures, delays.count - 1)])
    failures = min(failures + 1, delays.count - 1)
  }

  public func shouldRetry(at now: Date = Date()) -> Bool {
    wanted && retryAt.map { now >= $0 } == true
  }
}
