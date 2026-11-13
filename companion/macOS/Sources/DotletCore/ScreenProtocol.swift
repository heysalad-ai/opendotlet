import Foundation

public enum FaceLibrary: String, CaseIterable, Codable, Identifiable {
  case opendotlet, openai
  public var id: String { rawValue }
  public var title: String { self == .opendotlet ? "OpenDotlet Peel" : "OpenAI stickers" }
  public var frames: [String] {
    self == .opendotlet
      ? [
        "idle", "listening", "thinking", "working", "approval", "done", "offline", "error",
        "coral", "mint", "sky", "lilac", "sun", "ink", "paper",
      ]
      : [
        "Green dot", "Green plus", "Pink happy", "Blue calm", "Orange calm", "Purple wink",
        "Blue squeeze", "Cyan stars", "Cyan smile", "Pink surprise", "OpenAI white", "OpenAI black",
        "Community 1", "Community 2", "Community 3", "Community 4", "Community 5", "Community 6",
        "Community 7", "Community 8", "Community 9", "Community 10", "Community 11", "Community 12",
        "Exchange sheet", "Community sheet", "Build blue", "Build green",
      ]
  }
}

public struct ScreenSelection: Equatable, Codable {
  public var library: FaceLibrary
  public var index: Int
  public init(library: FaceLibrary, index: Int) {
    self.library = library
    self.index = index
  }
  public var isValid: Bool { library.frames.indices.contains(index) }
  public func commands() throws -> String {
    guard isValid else { throw DotletError.invalid("Choose a valid face before applying it.") }
    return "FACES \(library.rawValue.uppercased())\nPAUSE\n"
      + String(repeating: "NEXT\n", count: index) + "STATUS\n"
  }
}

public struct ScreenStatus: Equatable {
  public let selection: ScreenSelection
  public let autoplay: Bool
  public static func parse(_ line: String) -> ScreenStatus? {
    guard line.contains("STATUS "), let start = line.range(of: "STATUS ") else { return nil }
    var values: [String: String] = [:]
    for part in line[start.upperBound...].split(separator: " ") {
      let item = part.split(separator: "=", maxSplits: 1)
      if item.count == 2 { values[String(item[0])] = String(item[1]) }
    }
    guard let name = values["library"], let library = FaceLibrary(rawValue: name),
      let index = values["index"].flatMap(Int.init),
      let count = values["count"].flatMap(Int.init), count == library.frames.count,
      let auto = values["auto"], auto == "0" || auto == "1"
    else { return nil }
    let selection = ScreenSelection(library: library, index: index)
    guard selection.isValid else { return nil }
    return ScreenStatus(selection: selection, autoplay: auto == "1")
  }
}

/// Live expressions in the Peel library, in firmware frame order (indices 0–7).
/// Character faces follow at 8–14 (coral, mint, sky, lilac, sun, ink, paper).
public enum ScreenMood: Int, CaseIterable {
  case idle = 0, listening, thinking, working, approval, done, offline, error
  public static let characters = ["coral", "mint", "sky", "lilac", "sun", "ink", "paper"]
  /// Idle shows the owner's chosen character; coral uses the idle state face.
  public static func idleIndex(character: String) -> Int {
    guard let position = characters.firstIndex(of: character), position > 0 else { return 0 }
    return 8 + position
  }
}

/// Builds serial commands that move the screen to a Peel frame using only the
/// commands the face-library firmware already understands (no reflash needed).
public enum LiveFace {
  public static func commands(to target: Int, from current: ScreenSelection?) -> String? {
    let count = FaceLibrary.opendotlet.frames.count
    guard (0..<count).contains(target) else { return nil }
    guard let current, current.library == .opendotlet, current.isValid else {
      // FACES resets to frame 0 paused; firmware saves the library only when it changes.
      return "FACES OPENDOTLET\nPAUSE\n" + String(repeating: "NEXT\n", count: target) + "STATUS\n"
    }
    let forward = (target - current.index + count) % count
    let backward = (current.index - target + count) % count
    let steps =
      forward <= backward
      ? String(repeating: "NEXT\n", count: forward) : String(repeating: "PREV\n", count: backward)
    return "PAUSE\n" + steps + "STATUS\n"
  }
}
