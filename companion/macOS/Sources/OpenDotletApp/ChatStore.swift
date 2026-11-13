import AppKit
import Combine
import DotletCore
import Foundation

@MainActor
final class ChatStore: ObservableObject {
  @Published var archive = ChatArchive()
  @Published var errorMessage: String?
  @Published var draft = ""
  @Published var requestingID: String?
  @Published var aiError: String?
  /// Increments when a reply arrives; drives the screen's "done" face.
  @Published var repliesReceived = 0
  private var requestTask: Task<Void, Never>?
  private var requestToken = UUID()
  private var failedConversationID: String?

  private var readFailed = false
  private let file: URL
  init(directory: URL? = nil) {
    let support =
      directory
      ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("OpenDotlet")
    file = support.appendingPathComponent("chats.json")
    do { archive = try ChatArchive.read(from: file) } catch {
      readFailed = true
      errorMessage =
        "Chat history could not be read. It has not been overwritten. Show the recordings folder to inspect chats.json."
    }
  }
  var selectedAIError: String? { failedConversationID == archive.selectedID ? aiError : nil }
  var selected: Conversation? { archive.selected }
  var ordered: [Conversation] { archive.conversations.sorted { $0.updated > $1.updated } }
  func select(_ id: String) {
    archive.selectedID = id
    draft = ""
    save()
  }
  func newChat() {
    guard !readFailed else { return }
    archive.newConversation()
    draft = ""
    save()
  }
  func send() {
    guard !readFailed, !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return
    }
    archive.addNote(draft)
    draft = ""
    save()
  }
  func beginCapture() {
    archive.beginCapture()
    save()
  }
  func importRecordings(_ items: [Recording], historical: Bool = false) {
    guard !readFailed else { return }
    let existing = Set(archive.conversations.flatMap(\.messages).compactMap(\.recordingID))
    let added = items.filter { !existing.contains($0.id) }.sorted { $0.date < $1.date }
    guard !added.isEmpty else { return }
    for item in added {
      archive.addRecording(id: item.id, text: item.text, date: item.date, historical: historical)
    }
    save()
  }
  func sendToAI(settings: AISettings) {
    guard !readFailed, requestingID == nil,
      !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else { return }
    let original = draft
    archive.addNote(draft)
    guard let id = archive.selected?.messages.last?.id else { return }
    archive.markSent(id, in: archive.selectedID)
    if save() {
      draft = ""
      requestReply(in: archive.selectedID, settings: settings)
    } else {
      draft = original
    }
  }
  func sendVoice(_ message: ChatMessage, settings: AISettings) {
    guard !readFailed, requestingID == nil else { return }
    archive.markSent(message.id, in: archive.selectedID)
    if save() { requestReply(in: archive.selectedID, settings: settings) }
  }
  func sendDraftToAgent(id: String, send: (String) -> Void) {
    guard !readFailed, !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return
    }
    let text = draft
    archive.addNote(text)
    if let messageID = archive.selected?.messages.last?.id {
      archive.markSentToAgent(messageID, in: archive.selectedID, agentID: id)
    }
    if save() {
      draft = ""
      send(text)
    }
  }
  func sendMessageToAgent(_ message: ChatMessage, id: String, send: (String) -> Void) {
    guard !readFailed else { return }
    archive.markSentToAgent(message.id, in: archive.selectedID, agentID: id)
    if save() { send(message.text) }
  }
  func markAgentRecordings(_ deliveries: [(recordingID: String, agentID: String)]) {
    for delivery in deliveries {
      archive.markRecordingSentToAgent(delivery.recordingID, agentID: delivery.agentID)
    }
    if !deliveries.isEmpty { save() }
  }
  func requestCurrentReply(settings: AISettings) {
    guard !archive.apiMessages(in: archive.selectedID).isEmpty else { return }
    requestReply(in: archive.selectedID, settings: settings)
  }
  func retry(settings: AISettings) {
    guard let id = failedConversationID else { return }
    requestReply(in: id, settings: settings)
  }
  func cancelReply() {
    requestToken = UUID()
    requestTask?.cancel()
    requestTask = nil
    requestingID = nil
  }
  private func requestReply(in conversationID: String, settings: AISettings) {
    guard requestingID == nil else { return }
    let key: String
    do {
      guard let saved = try settings.readKey(), !saved.isEmpty else {
        aiError = "Add your OpenAI API key in AI settings, then retry."
        failedConversationID = conversationID
        return
      }
      key = saved
    } catch {
      aiError = error.localizedDescription
      failedConversationID = conversationID
      return
    }
    let model = settings.model
    let messages = archive.apiMessages(in: conversationID)
    let token = UUID()
    requestToken = token
    requestingID = conversationID
    failedConversationID = conversationID
    aiError = nil
    requestTask = Task { [weak self] in
      do {
        let response = try await ResponsesClient().reply(key: key, model: model, messages: messages)
        guard let self, self.requestToken == token, !Task.isCancelled else { return }
        self.archive.addReply(response, to: conversationID)
        self.repliesReceived += 1
        self.requestingID = nil
        self.requestTask = nil
        self.failedConversationID = nil
        self.save()
      } catch {
        guard let self, self.requestToken == token else { return }
        self.requestingID = nil
        self.requestTask = nil
        if error is URLError {
          self.aiError =
            "Could not reach OpenAI. Your message is saved; check your connection and retry."
        } else {
          self.aiError = error.localizedDescription
        }
      }
    }
  }
  @discardableResult private func save() -> Bool {
    guard !readFailed else { return false }
    do {
      try archive.save(to: file)
      errorMessage = nil
      return true
    } catch {
      errorMessage = "Could not save chat history on this Mac: \(error.localizedDescription)"
      return false
    }
  }
}
