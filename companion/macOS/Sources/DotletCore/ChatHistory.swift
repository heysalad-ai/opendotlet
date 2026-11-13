import Foundation

public struct ChatMessage: Identifiable, Codable, Equatable {
  public enum Kind: String, Codable { case note, voice, assistant }
  public var id: String
  public var text: String
  public var date: Date
  public var kind: Kind
  public var recordingID: String?
  public var sentToAI: Bool? = false
  public var sentToAgent: String?
  public init(text: String, date: Date = Date(), kind: Kind = .note, recordingID: String? = nil) {
    self.id = UUID().uuidString
    self.text = text
    self.date = date
    self.kind = kind
    self.recordingID = recordingID
  }
}

public struct Conversation: Identifiable, Codable, Equatable {
  public var id = UUID().uuidString
  public var title = "New chat"
  public var created = Date()
  public var messages: [ChatMessage] = []
  public init() {}
  public var updated: Date { messages.last?.date ?? created }
  /// First line of the first message, cut at a word boundary with an ellipsis.
  public static func title(for text: String, limit: Int = 48) -> String {
    let line = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? text
    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count > limit else { return trimmed.isEmpty ? "New chat" : trimmed }
    let cut = String(trimmed.prefix(limit))
    let word = cut.lastIndex(of: " ").map { String(cut[..<$0]) } ?? cut
    return word.trimmingCharacters(in: CharacterSet(charactersIn: " ,.;:-")) + "…"
  }
}

public struct ChatArchive: Codable, Equatable {
  public var conversations: [Conversation] = [Conversation()]
  public var selectedID: String
  public var captureTargetID: String?
  public init() { selectedID = conversations[0].id }
  public var selected: Conversation? { conversations.first { $0.id == selectedID } }
  @discardableResult public mutating func newConversation() -> String {
    let item = Conversation()
    conversations.insert(item, at: 0)
    selectedID = item.id
    return item.id
  }
  public mutating func beginCapture() { captureTargetID = selectedID }
  public mutating func addNote(_ text: String) {
    append(ChatMessage(text: text.trimmingCharacters(in: .whitespacesAndNewlines)), to: selectedID)
  }
  public mutating func addRecording(id: String, text: String, date: Date, historical: Bool = false)
  {
    guard !conversations.contains(where: { $0.messages.contains { $0.recordingID == id } }) else {
      return
    }
    let target = historical ? selectedID : (captureTargetID ?? selectedID)
    append(ChatMessage(text: text, date: date, kind: .voice, recordingID: id), to: target)
    if !historical { captureTargetID = nil }
  }
  public mutating func markSent(_ messageID: String, in conversationID: String) {
    guard let room = conversations.firstIndex(where: { $0.id == conversationID }),
      let item = conversations[room].messages.firstIndex(where: { $0.id == messageID })
    else { return }
    conversations[room].messages[item].sentToAI = true
  }
  public mutating func addReply(_ text: String, to conversationID: String) {
    append(ChatMessage(text: text, kind: .assistant), to: conversationID)
  }
  public mutating func markSentToAgent(
    _ messageID: String, in conversationID: String, agentID: String
  ) {
    guard let room = conversations.firstIndex(where: { $0.id == conversationID }),
      let item = conversations[room].messages.firstIndex(where: { $0.id == messageID })
    else { return }
    conversations[room].messages[item].sentToAgent = agentID
  }
  public mutating func markRecordingSentToAgent(_ recordingID: String, agentID: String) {
    for room in conversations.indices {
      if let item = conversations[room].messages.firstIndex(where: { $0.recordingID == recordingID }
      ) {
        conversations[room].messages[item].sentToAgent = agentID
      }
    }
  }
  public func apiMessages(in conversationID: String) -> [ChatMessage] {
    (conversations.first { $0.id == conversationID }?.messages ?? []).filter {
      $0.kind == .assistant || $0.sentToAI == true
    }
  }
  private mutating func append(_ message: ChatMessage, to id: String) {
    guard !message.text.isEmpty, let index = conversations.firstIndex(where: { $0.id == id }) else {
      return
    }
    if conversations[index].messages.isEmpty {
      conversations[index].title = Conversation.title(for: message.text)
    }
    conversations[index].messages.append(message)
  }
  public static func read(from url: URL) throws -> ChatArchive {
    if !FileManager.default.fileExists(atPath: url.path) { return ChatArchive() }
    let archive = try JSONDecoder().decode(ChatArchive.self, from: Data(contentsOf: url))
    guard !archive.conversations.isEmpty,
      archive.conversations.contains(where: { $0.id == archive.selectedID })
    else {
      throw CocoaError(.fileReadCorruptFile)
    }
    return archive
  }
  public func save(to url: URL) throws {
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true,
      attributes: [.posixPermissions: 0o700])
    try JSONEncoder().encode(self).write(to: url, options: .atomic)
    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
  }
}
