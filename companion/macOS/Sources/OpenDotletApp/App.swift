import AppKit
import DotletCore
// App shell adapted from NiceDeck (MIT), OpenStreamDeck contributors.
import SwiftUI

@main
struct OpenDotletApp: App {
  @StateObject private var store = DotletStore()
  @StateObject private var chats = ChatStore()
  @StateObject private var screen = ScreenStore()
  @StateObject private var ai = AISettings()
  @StateObject private var team = AgentTeamStore()
  @StateObject private var keyboard = KeyboardStore()
  @AppStorage("appearance") private var appearance = "light"
  init() { PeelFonts.register() }
  var body: some Scene {
    WindowGroup(id: "main") {
      DotletView(store: store, chats: chats, screen: screen, ai: ai, team: team, keyboard: keyboard)
        .frame(minWidth: 860, minHeight: 600)
        .preferredColorScheme(appearance == "dark" ? .dark : .light)
        .tint(DeckStyle.tint)
        .onAppear {
          if let icon = Bundle.main.resourceURL?.appendingPathComponent("AppIcon.icns"),
            let image = NSImage(contentsOf: icon)
          {
            NSApp.applicationIconImage = image
          }
          NSApp.activate(ignoringOtherApps: true)
          keyboard.start()
          chats.importRecordings(store.recordings, historical: true)
          team.prepareRecordings(store.recordings)
        }
        .onDisappear {
          if store.sessionEnabled || store.recording { store.setEnabled(false) }
          chats.cancelReply()
          team.voiceAgentID = nil
        }
        .onChange(of: store.recordings.map(\.id)) { _, _ in
          chats.importRecordings(store.recordings)
          chats.markAgentRecordings(team.receiveRecordings(store.recordings))
        }
        .onChange(of: store.recording) { _, recording in
          if recording {
            chats.beginCapture()
            team.beginCapture()
          }
        }
        .onChange(of: store.sessionEnabled) { _, enabled in if !enabled { team.voiceAgentID = nil }
        }
    }
    .windowStyle(.hiddenTitleBar).defaultSize(width: 1100, height: 760)
    .commands {
      CommandGroup(replacing: .newItem) {
        Button("New Chat") { chats.newChat() }.keyboardShortcut("n")
        Button("Connect Dotlet") { store.connect() }.keyboardShortcut("k")
          .disabled(store.maintainingConnection)
        Button("Enable Button") { store.setEnabled(true) }.keyboardShortcut("r")
          .disabled(!store.ready || store.busy || store.sessionEnabled)
        Button("Pause Button") { store.setEnabled(false) }.keyboardShortcut(".").disabled(
          !store.connected)
      }
      CommandMenu("Layout") {
        Button("Compact Window") {
          NSApp.keyWindow?.setContentSize(NSSize(width: 860, height: 600))
        }
        Button("Standard Window") {
          NSApp.keyWindow?.setContentSize(NSSize(width: 1100, height: 760))
        }
      }
    }
    MenuBarExtra("Open.Dotlet", systemImage: keyboard.busy ? "circle.dotted.circle.fill" : "circle.grid.3x3.fill") {
      DotletMenu(keyboard: keyboard)
    }
  }
}

enum WorkspacePage: String { case chats, keyboard, agents, screen, devices, ai }

struct DotletView: View {
  @ObservedObject var store: DotletStore
  @ObservedObject var chats: ChatStore
  @ObservedObject var screen: ScreenStore
  @ObservedObject var ai: AISettings
  @ObservedObject var team: AgentTeamStore
  @ObservedObject var keyboard: KeyboardStore
  @State private var page: WorkspacePage = .keyboard
  @AppStorage("dotletCharacter") private var character = "coral"
  @AppStorage("dotletName") private var name = "My Dotlet"
  @AppStorage("appearance") private var appearance = "light"
  @AppStorage("faceLibrary") private var faceLibrary = "opendotlet"
  @State private var celebrating = false
  @State private var celebrationID = UUID()
  /// The Peel frame the round screen should show for the current button/AI state.
  private var liveFace: Int {
    if store.recording { return ScreenMood.listening.rawValue }
    if store.busy && !store.transcribing { return ScreenMood.working.rawValue }  // receiving audio
    if store.transcribing || chats.requestingID != nil { return ScreenMood.thinking.rawValue }
    if team.selectedService?.running == true { return ScreenMood.working.rawValue }
    if store.errorMessage != nil || chats.aiError != nil { return ScreenMood.error.rawValue }
    if celebrating { return ScreenMood.done.rawValue }
    if !store.connected { return ScreenMood.offline.rawValue }
    return ScreenMood.idleIndex(character: character)
  }
  private func syncScreen() {
    guard faceLibrary == FaceLibrary.opendotlet.rawValue else { return }
    screen.show(index: liveFace)
  }
  private func celebrate() {
    let id = UUID()
    celebrationID = id
    celebrating = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
      if celebrationID == id { celebrating = false }
    }
  }
  var body: some View {
    HStack(spacing: 0) {
      sidebar.frame(width: 232)
      Rectangle().fill(DeckStyle.line).frame(width: 1)
      VStack(spacing: 0) {
        header
        Rectangle().fill(DeckStyle.line).frame(height: 1)
        Group {
          switch page {
          case .chats:
            ChatView(
              store: store, chats: chats, ai: ai, character: character, name: name,
              agentName: team.selected?.name ?? "agent", agentID: team.selectedID,
              sendToAgent: { text in
                team.send(text)
                page = .agents
              })
          case .keyboard: KeyboardView(keyboard: keyboard)
          case .agents: AgentTeamView(team: team)
          case .screen: ScreenSetupView(screen: screen, character: $character, name: $name)
          case .devices: DeviceSetupView(store: store, screen: screen)
          case .ai: AISetupView(settings: ai)
          }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
        footer
      }
    }.foregroundStyle(DeckStyle.ink).background(DeckStyle.background)
      .onReceive(NotificationCenter.default.publisher(for: .openDotletKeyboard)) { _ in page = .keyboard }
      .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in keyboard.shutdown() }
      .onChange(of: keyboard.snapshot?.job?.id) { _, _ in
        if keyboard.snapshot?.job?.source == "physical keypad" && keyboard.busy {
          page = .keyboard
        }
      }
      .onChange(of: liveFace) { _, _ in syncScreen() }
      .onChange(of: screen.ready) { _, ready in if ready { syncScreen() } }
      .onChange(of: screen.liveFaces) { _, on in if on { syncScreen() } }
      .onChange(of: store.recordings.count) { old, new in if new > old { celebrate() } }
      .onChange(of: chats.repliesReceived) { _, _ in celebrate() }
      .onChange(of: team.selectedService?.snapshot?.job?.status) { _, status in
        if status == "completed" { celebrate() }
      }
  }
  private var sidebar: some View {
    Group {
      if Bundle.main.object(forInfoDictionaryKey: "OpenDotletPortable") as? Bool == true {
        VStack(alignment: .leading, spacing: 24) {
          HStack(spacing: 10) {
            BrandImage(name: "symbol").frame(width: 34, height: 34)
            Text("Open.Dotlet").font(DeckStyle.display(23))
          }.padding(.top, 24)
          Text("Your saved tasks.\nOne press away.").font(.system(size: 14)).foregroundStyle(DeckStyle.muted)
          nav("Agent team", symbol: "circle.grid.3x3", destination: .keyboard)
          Text("Public alpha · 0.6.0").font(.system(size: 11)).foregroundStyle(DeckStyle.muted)
          Spacer()
          Text("No keypad? Run a saved task from the app to try it.")
            .font(.system(size: 12)).foregroundStyle(DeckStyle.muted)
          Link("Setup and source", destination: URL(string: "https://opendotlet.com/#build")!)
            .font(.system(size: 12))
          Button("Switch appearance") { appearance = appearance == "dark" ? "light" : "dark" }
            .buttonStyle(.plain).font(.system(size: 12))
          Text("Saved on this Mac").font(.system(size: 11)).foregroundStyle(DeckStyle.muted)
        }.padding(20).background(DeckStyle.sidebar)
      } else { developmentSidebar }
    }
  }
  private var developmentSidebar: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 9) {
        BrandImage(name: "symbol").frame(width: 28, height: 28).accessibilityHidden(true)
        Text("OpenDotlet").font(DeckStyle.display(20))
      }.padding(.top, 42).padding(.horizontal, 20).padding(.bottom, 26)
      Button {
        page = .chats
      } label: {
        HStack(spacing: 10) {
          BrandImage(name: "characters/dotlet-\(character)").frame(width: 36, height: 36)
          VStack(alignment: .leading, spacing: 3) {
            Text(name.isEmpty ? "My Dotlet" : name).font(.system(size: 13, weight: .semibold))
              .lineLimit(1)
            Text(store.connected ? "Voice button connected" : "Voice button offline").font(.system(size: 11))
              .foregroundStyle(DeckStyle.muted)
          }
          Spacer(minLength: 0)
        }.padding(10).background(
          page == .chats ? DeckStyle.raised : .clear, in: RoundedRectangle(cornerRadius: 12))
      }.buttonStyle(.plain).padding(.horizontal, 10).accessibilityLabel("Open chats")
      nav("Agent team", symbol: "circle.grid.3x3", destination: .keyboard)
      nav("Advanced agents", symbol: "person.2", destination: .agents)
      nav("Screen setup", symbol: "display", destination: .screen)
      nav("Devices", symbol: "cable.connector", destination: .devices)
      nav("AI settings", symbol: "sparkles", destination: .ai)
      HStack {
        Text("Chats").font(.system(size: 12, weight: .semibold)).foregroundStyle(DeckStyle.muted)
        Spacer()
        Button {
          chats.newChat()
          page = .chats
        } label: {
          Image(systemName: "plus")
        }
        .buttonStyle(.plain).help("New chat (⌘N)").accessibilityLabel("New chat")
      }.padding(.horizontal, 20).padding(.top, 27).padding(.bottom, 12)
      ScrollView {
        LazyVStack(spacing: 4) {
          ForEach(chats.ordered) { chat in
            Button {
              chats.select(chat.id)
              page = .chats
            } label: {
              HStack(alignment: .top, spacing: 8) {
                Image(systemName: "bubble.left").font(.system(size: 12)).padding(.top, 2)
                VStack(alignment: .leading, spacing: 4) {
                  Text(chat.title).font(.system(size: 12, weight: .medium)).lineLimit(2)
                    .multilineTextAlignment(.leading)
                  Text(chat.updated.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10)).foregroundStyle(DeckStyle.muted)
                }
                Spacer(minLength: 0)
              }.padding(10).background(
                page == .chats && chats.archive.selectedID == chat.id ? DeckStyle.raised : .clear,
                in: RoundedRectangle(cornerRadius: 10))
            }.buttonStyle(.plain).accessibilityLabel("Chat: \(chat.title)")
          }
        }.padding(.horizontal, 10)
      }
      Divider().overlay(DeckStyle.line).padding(.horizontal, 16)
      HStack {
        Image(systemName: "externaldrive").font(.system(size: 12))
        Text("Saved on this Mac").font(.system(size: 11))
        Spacer()
        Button {
          appearance = appearance == "dark" ? "light" : "dark"
        } label: {
          Image(systemName: appearance == "dark" ? "sun.max" : "moon")
        }.buttonStyle(.plain).help("Switch appearance").accessibilityLabel("Switch appearance")
      }.foregroundStyle(DeckStyle.muted).padding(20)
    }.background(DeckStyle.sidebar)
  }
  private func nav(_ title: String, symbol: String, destination: WorkspacePage) -> some View {
    Button {
      page = destination
    } label: {
      Label(title, systemImage: symbol).font(.system(size: 13, weight: .medium))
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .background(
          page == destination ? DeckStyle.raised : .clear, in: RoundedRectangle(cornerRadius: 10))
    }.buttonStyle(.plain).padding(.horizontal, 10).padding(.top, 5)
  }
  private var header: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(
          page == .keyboard ? "Agent team" : page == .chats
            ? (chats.selected?.title ?? "New chat")
            : (page == .agents
              ? "Advanced agents"
              : (page == .screen ? "Screen setup" : (page == .ai ? "AI settings" : "Your devices")))
        )
        .font(DeckStyle.display(19, black: false)).lineLimit(1).truncationMode(.tail)
        Text(
          page == .keyboard ? "Little dotlets. Useful tasks. One press." : page == .chats
            ? "Thoughts, at the press of a key."
            : (page == .agents
              ? "Tasks, memory and computer use."
              : (page == .screen
                ? "A face for your little companion."
                : (page == .ai
                  ? "Your key. Your conversations." : "Connect the button and round display.")))
        )
        .font(.system(size: 12)).foregroundStyle(DeckStyle.muted)
      }
      Spacer(minLength: 4)
      if team.selectedService?.running == true {
        Button("Stop agent task") { Task { await team.selectedService?.stop() } }
          .buttonStyle(StickerButtonStyle())
      }
      if page != .keyboard { Button(
        store.maintainingConnection ? "Disconnect button" : "Connect button"
      ) {
        if store.maintainingConnection { store.disconnect() } else { store.connect() }
      }.buttonStyle(StickerButtonStyle()) }
    }.padding(.horizontal, 26).padding(.top, 28).padding(.bottom, 18)
  }
  private var footer: some View {
    HStack(spacing: 12) {
      Label(
        page == .keyboard ? keyboard.status : store.recording
          ? "Microphone recording" : (store.connected ? "Microphone off" : "Button disconnected"),
        systemImage: page == .keyboard ? "keyboard" : (store.recording ? "mic.fill" : "mic.slash"))
      Spacer(minLength: 4)
      Text(screen.ready ? "Screen connected" : "Local workspace")
    }.font(.system(size: 10)).foregroundStyle(DeckStyle.muted).padding(.horizontal, 26).padding(
      .vertical, 11
    )
    .background(DeckStyle.sidebar.opacity(0.45))
  }
}
