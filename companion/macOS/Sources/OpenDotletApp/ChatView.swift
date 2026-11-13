import AppKit
import DotletCore
import SwiftUI

struct ChatView: View {
  @ObservedObject var store: DotletStore
  @ObservedObject var chats: ChatStore
  @ObservedObject var ai: AISettings
  var character: String
  var name: String
  var agentName: String
  var agentID: String
  var sendToAgent: (String) -> Void
  var body: some View {
    VStack(spacing: 0) {
      ScrollViewReader { proxy in
        ScrollView {
          VStack(alignment: .leading, spacing: 28) {
            HStack(spacing: 12) {
              BrandImage(name: "characters/dotlet-\(character)").frame(width: 48, height: 48)
              VStack(alignment: .leading, spacing: 5) {
                Text(name.isEmpty ? "My Dotlet" : name).font(DeckStyle.display(18, black: false))
                Text(
                  "Tasks with \(agentName) · local Ambi engine"
                )
                .font(.system(size: 12)).foregroundStyle(DeckStyle.muted)
              }
              Spacer()
            }.padding(.bottom, 6)
            if chats.selected?.messages.isEmpty != false {
              VStack(alignment: .leading, spacing: 12) {
                Text("What’s on your mind?").font(DeckStyle.display(30))
                Text(
                  "Type a message, or hold your Dotlet key to capture a thought. Send it when you’re ready for a reply."
                )
                .font(.system(size: 14)).foregroundStyle(DeckStyle.muted).lineSpacing(5)
              }.padding(.vertical, 40)
            }
            ForEach(chats.selected?.messages ?? []) { item in
              message(item).id(item.id)
            }
            if chats.requestingID == chats.archive.selectedID {
              HStack(spacing: 12) {
                BrandImage(name: "symbol").frame(width: 26, height: 26)
                ProgressView().controlSize(.small)
                Text("Thinking…").font(.system(size: 13)).foregroundStyle(DeckStyle.muted)
                Button("Stop") { chats.cancelReply() }.buttonStyle(.borderless)
              }.id("reply-progress")
            }
            Color.clear.frame(height: 1).id("bottom")
          }.padding(28).frame(maxWidth: 830, alignment: .leading).frame(
            maxWidth: .infinity, alignment: .leading)
        }
        .onChange(of: chats.selected?.messages.count) { _, _ in
          proxy.scrollTo("bottom", anchor: .bottom)
        }
        .onChange(of: chats.archive.selectedID) { _, _ in proxy.scrollTo("bottom", anchor: .bottom)
        }
      }
      VStack(alignment: .leading, spacing: 12) {
        if let error = chats.errorMessage { InlineNotice(text: error) }
        if let error = chats.selectedAIError {
          InlineNotice(text: error)
          Button("Retry reply") { chats.retry(settings: ai) }.disabled(chats.requestingID != nil)
        }
        if let error = store.errorMessage { InlineNotice(text: error) }
        captureControls
        VStack(alignment: .leading, spacing: 12) {
          TextField("", text: $chats.draft, axis: .vertical)
            .textFieldStyle(.plain).font(.system(size: 14)).lineLimit(1...5)
            .inputHint("Message your Dotlet…", empty: chats.draft.isEmpty, inset: 0, size: 14)
            .accessibilityLabel("Message your Dotlet")
          HStack {
            Text("Send a task to your agent. Audio stays on this Mac.")
              .font(.system(size: 10)).foregroundStyle(DeckStyle.muted).fixedSize(
                horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button("Save note") { chats.send() }.buttonStyle(.borderless)
              .disabled(chats.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if ai.hasKey {
              Button("OpenAI reply") { chats.sendToAI(settings: ai) }.buttonStyle(.borderless)
                .disabled(
                  chats.requestingID != nil
                    || chats.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Button {
              chats.sendDraftToAgent(id: agentID, send: sendToAgent)
            } label: {
              Label("Send", systemImage: "arrow.up")
            }
            .buttonStyle(AccentButtonStyle()).disabled(
              chats.requestingID != nil
                || chats.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
            .keyboardShortcut(.return, modifiers: .command)
          }
        }.padding(16).background(DeckStyle.panel, in: RoundedRectangle(cornerRadius: 18))
          .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(DeckStyle.ink, lineWidth: 2))
          .background(RoundedRectangle(cornerRadius: 18).fill(DeckStyle.shadow).offset(x: 3, y: 3))
      }.padding(.horizontal, 26).padding(.top, 12).padding(.bottom, 20)
    }
  }
  private func message(_ item: ChatMessage) -> some View {
    HStack(alignment: .top, spacing: 12) {
      if item.kind == .assistant {
        BrandImage(name: "symbol").frame(width: 28, height: 28)
      } else {
        Image(systemName: item.kind == .voice ? "mic" : "person.crop.circle")
          .font(.system(size: 18)).foregroundStyle(DeckStyle.muted).frame(width: 28, height: 28)
      }
      VStack(alignment: .leading, spacing: 9) {
        HStack(spacing: 9) {
          Text(item.kind == .assistant ? (name.isEmpty ? "Dotlet" : name) : "You").font(
            .system(size: 13, weight: .semibold))
          Text(item.date.formatted(date: .omitted, time: .shortened)).font(.system(size: 10))
            .foregroundStyle(DeckStyle.muted)
          if item.kind != .assistant {
            Text(
              item.sentToAI == true
                ? "AI message"
                : (item.sentToAgent != nil
                  ? "Agent task"
                  : (item.kind == .voice ? "Voice transcript · local" : "Local note"))
            ).font(.system(size: 10)).foregroundStyle(DeckStyle.muted)
          }
        }
        Text(item.text).font(.system(size: 14)).lineSpacing(5).textSelection(.enabled)
          .fixedSize(horizontal: false, vertical: true).frame(
            maxWidth: .infinity, alignment: .leading)
        HStack(spacing: 14) {
          Button("Copy") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(item.text, forType: .string)
          }
          if item.sentToAI == true && item.kind != .assistant
            && item.id == chats.selected?.messages.last?.id && chats.selectedAIError == nil
          {
            Button("Get reply") { chats.requestCurrentReply(settings: ai) }.disabled(
              chats.requestingID != nil)
          }
          if let id = item.recordingID {
            Button("Show audio") {
              store.selectedID = id
              store.reveal()
            }
            if item.sentToAI != true {
              Button("Send transcript to OpenAI") { chats.sendVoice(item, settings: ai) }.disabled(
                chats.requestingID != nil)
            }
          }
          if item.kind != .assistant {
            Button("Send to \(agentName)") {
              chats.sendMessageToAgent(item, id: agentID, send: sendToAgent)
            }
          }
        }.font(.system(size: 10)).buttonStyle(.borderless).foregroundStyle(DeckStyle.muted)
      }
    }
  }
  private var captureControls: some View {
    HStack(spacing: 12) {
      Image(systemName: store.recording ? "mic.fill" : "keyboard")
        .foregroundStyle(store.recording ? Color.green : DeckStyle.muted)
      VStack(alignment: .leading, spacing: 3) {
        Text(store.status).font(.system(size: 12, weight: .medium))
        Text(
          store.recording
            ? "Release the key when finished."
            : "Green: recording. Blue: transferring. Up to 10 seconds."
        )
        .font(.system(size: 10)).foregroundStyle(DeckStyle.muted)
      }
      Spacer(minLength: 0)
      if store.busy && !store.recording { ProgressView().controlSize(.small) }
      Button(
        store.recording
          ? "Cancel recording" : (store.sessionEnabled ? "Pause button" : "Enable button")
      ) {
        store.setEnabled(store.recording ? false : !store.sessionEnabled)
      }.buttonStyle(StickerButtonStyle()).disabled(!store.ready || (store.busy && !store.recording))
    }
  }
}
