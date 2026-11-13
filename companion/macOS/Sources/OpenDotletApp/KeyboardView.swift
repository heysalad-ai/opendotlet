import AppKit
import SwiftUI

/// The physical keypad is the team: each dotlet owns a saved task and its results.
struct KeyboardView: View {
  @ObservedObject var keyboard: KeyboardStore
  @AppStorage("keypadViewRotated") private var rotated = true
  @State private var selected = 30
  @State private var editing: SavedDot?
  @State private var selectedRunID: String?
  private var dot: SavedDot? {
    keyboard.dots.first { ($0.row - 1) * 6 + $0.col == selected }
  }
  private var runs: [DotRun] {
    guard let dot else { return [] }
    return (keyboard.snapshot?.history ?? []).filter { $0.dot_id == dot.id }
  }
  private var result: DotRun? {
    if let selectedRunID, let saved = runs.first(where: { $0.id == selectedRunID }) { return saved }
    return runs.first
  }
  var body: some View {
    GeometryReader { geometry in
      HStack(alignment: .top, spacing: 24) {
        ScrollView {
          teamBoard
        }.frame(width: min(330, max(240, (geometry.size.width - 64) * 0.42)))
        Rectangle().fill(DeckStyle.line).frame(width: 1)
        ScrollViewReader { proxy in
          ScrollView {
            VStack(alignment: .leading, spacing: 22) {
              taskDetails
              Divider().overlay(DeckStyle.line)
              resultDetails
                .id("result")
            }.frame(maxWidth: 740, alignment: .leading).frame(maxWidth: .infinity, alignment: .topLeading)
              .padding(.bottom, 24)
          }
          .onChange(of: selected) { _, _ in selectedRunID = nil; proxy.scrollTo("task", anchor: .top) }
          .onChange(of: selectedRunID) { _, new in
            if new != nil { proxy.scrollTo("result", anchor: .top) }
          }
        }
      }.padding(24)
    }
    .onChange(of: keyboard.snapshot?.job?.id) { _, _ in
      selectedRunID = nil
      if let job = keyboard.snapshot?.job, let row = job.row, let col = job.col {
        selected = (row - 1) * 6 + col
      }
    }
    .sheet(item: $editing) { dot in
      DotEditor(dot: dot) { keyboard.save($0); editing = nil }
    }
  }
  private var teamBoard: some View {
    VStack(alignment: .leading, spacing: 18) {
      VStack(alignment: .leading, spacing: 6) {
        Text("Your dotlets").font(DeckStyle.display(25))
        Text("Give each little face a job.").font(.system(size: 13)).foregroundStyle(DeckStyle.muted)
      }
      HStack {
        Text("\(keyboard.dots.count) assigned · \(30 - keyboard.dots.count) available")
          .font(.system(size: 12)).foregroundStyle(DeckStyle.muted)
        Spacer()
        Button { rotated.toggle() } label: { Image(systemName: "rotate.right") }
          .buttonStyle(.plain).help("Rotate the keypad view 180 degrees").accessibilityLabel("Rotate view")
      }
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 6), spacing: 5) {
        ForEach(rotated ? Array((1...30).reversed()) : Array(1...30), id: \.self) { key in
          let assigned = keyboard.dots.first { ($0.row - 1) * 6 + $0.col == key }
          let illustration = KeyIllustration.forKey(key)
          Button { selected = key } label: {
            VStack(spacing: 4) {
              if let illustration { IllustratedKeycap(key: illustration).frame(height: 33) }
              else { Image(systemName: "circle").frame(height: 33) }
              Circle().fill(assigned == nil ? Color.white.opacity(0.12) : DeckStyle.accent)
                .frame(width: 5, height: 5)
            }.frame(maxWidth: .infinity).padding(.vertical, 4).padding(.horizontal, 2)
              .background(selected == key ? Color.white.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 10))
              .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected == key ? DeckStyle.accent : .clear, lineWidth: 2))
          }.buttonStyle(.plain)
            .help("\(illustration?.name ?? "Key") · \(assigned?.name ?? "Available")")
            .accessibilityLabel("\(illustration?.name ?? "Key"), key \(key), matrix row \((key - 1) / 6 + 1), column \((key - 1) % 6 + 1), \(assigned?.name ?? "available")")
        }
      }.padding(10).background(Color(hex: "111519"), in: RoundedRectangle(cornerRadius: 16))
      Text("Matches your physical keypad. Select a face to give it a saved Codex task.")
        .font(.system(size: 12)).foregroundStyle(DeckStyle.muted).fixedSize(horizontal: false, vertical: true)
      Divider().overlay(DeckStyle.line)
      Toggle("Physical keys enabled", isOn: Binding(
        get: { keyboard.snapshot?.enabled ?? false }, set: keyboard.setEnabled))
        .toggleStyle(.switch).font(.system(size: 12)).disabled(keyboard.snapshot == nil)
      Label(keyboard.status, systemImage: keyboard.busy ? "sparkles" : "cable.connector")
        .font(.system(size: 12)).foregroundStyle(DeckStyle.muted)
        .fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
      if let notice = keyboard.notice {
        Text(notice).font(.system(size: 12)).foregroundStyle(DeckStyle.muted).textSelection(.enabled)
      }
      if keyboard.error != nil {
        Button("Reconnect task service") { Task { await keyboard.connect() } }.buttonStyle(StickerButtonStyle())
      }
      if keyboard.snapshot?.runtime?.codex_available == false {
        Text("Install Codex CLI and run codex login in Terminal, then retry.")
          .font(.system(size: 12)).foregroundStyle(DeckStyle.muted)
      }
      Link("Codex setup guide", destination: URL(string: "https://learn.chatgpt.com/docs/codex/cli")!)
        .font(.system(size: 12))
      DisclosureGroup("Device options") {
        VStack(alignment: .leading, spacing: 12) {
          if keyboard.snapshot?.runtime?.portable == true {
            Picker("USB port", selection: $keyboard.selectedPort) {
              Text("Choose a port").tag("")
              ForEach(keyboard.usbPorts) { port in Text("\(port.port) · \(port.name)").tag(port.port) }
            }
            HStack {
              Button("Refresh ports", action: keyboard.refreshPorts)
              Button("Connect USB") { keyboard.connectUSB() }.disabled(keyboard.selectedPort.isEmpty)
            }
            Button("Disconnect USB") { keyboard.connectUSB(disconnect: true) }
            Text(keyboard.usbMessage).font(.system(size: 11)).foregroundStyle(DeckStyle.muted)
          }
          if let dot {
            Button("Assign this task to a physical key…") { keyboard.learn(dot.id) }
              .disabled(keyboard.busy)
          }
          if keyboard.snapshot?.runtime?.portable != true {
            Button("Pair Windows client", action: keyboard.pairWindows)
          }
          Text(keyboard.snapshot?.last_event ?? "No key events yet.")
            .font(.system(size: 11)).foregroundStyle(DeckStyle.muted).textSelection(.enabled)
        }.padding(.top, 10)
      }.font(.system(size: 12))
        .onAppear { if keyboard.snapshot?.runtime?.portable == true { keyboard.refreshPorts() } }
    }.padding(.bottom, 24)
  }
  private var taskDetails: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .top, spacing: 12) {
        if let illustration = KeyIllustration.forKey(selected) {
          IllustratedKeycap(key: illustration).frame(width: 42, height: 42)
        }
        VStack(alignment: .leading, spacing: 5) {
          Text(dot?.name ?? "A dotlet waiting for a task").font(.system(size: 22, weight: .semibold))
          Text("Row \((selected - 1) / 6 + 1) · Column \((selected - 1) % 6 + 1)")
            .font(.system(size: 11)).foregroundStyle(DeckStyle.muted)
        }
        Spacer(minLength: 0)
      }
      if let dot {
        Text(dot.prompt).font(.system(size: 13)).lineSpacing(4).textSelection(.enabled)
        Label(URL(fileURLWithPath: dot.workspace).lastPathComponent, systemImage: "folder")
          .font(.system(size: 12)).foregroundStyle(DeckStyle.muted).help(dot.workspace)
        HStack(spacing: 12) {
          Button(keyboard.busy ? "Working in Codex…" : "Run task") { keyboard.run(dot.id) }
            .buttonStyle(AccentButtonStyle()).disabled(keyboard.busy || keyboard.snapshot == nil)
          Button("Edit task") { editing = dot }.buttonStyle(StickerButtonStyle()).disabled(keyboard.busy)
        }
        Text("Press this face on your keypad to run it. Codex has read-only access to the project.")
          .font(.system(size: 11)).foregroundStyle(DeckStyle.muted).fixedSize(horizontal: false, vertical: true)
      } else {
        Text("Choose what this dotlet should do and the project it should work in. Its physical key will run that saved task.")
          .font(.system(size: 14)).lineSpacing(4).foregroundStyle(DeckStyle.muted)
        Button("Assign a task") {
          editing = SavedDot(id: "key-\(selected)", row: (selected - 1) / 6 + 1,
            col: (selected - 1) % 6 + 1, name: "", prompt: "", workspace: keyboard.workspace)
        }.buttonStyle(AccentButtonStyle()).disabled(keyboard.snapshot == nil || keyboard.busy)
      }
    }.id("task")
  }
  @ViewBuilder private var resultDetails: some View {
    if let job = result {
      VStack(alignment: .leading, spacing: 16) {
        HStack {
          Label(job.status == "running" ? "Working in Codex" : job.status.capitalized,
                systemImage: job.status == "completed" ? "checkmark.circle" : (job.status == "running" ? "sparkles" : "info.circle"))
            .font(.system(size: 14, weight: .semibold))
          Spacer()
          if job.status == "running" {
            ProgressView().controlSize(.small)
            Button("Cancel run", action: keyboard.cancel).buttonStyle(StickerButtonStyle())
          } else if !job.result.isEmpty {
            Button {
              NSPasteboard.general.clearContents()
              NSPasteboard.general.setString(job.result, forType: .string)
            } label: { Label("Copy", systemImage: "doc.on.doc") }
              .buttonStyle(.plain).font(.system(size: 12)).accessibilityLabel("Copy result")
          }
        }
        HStack {
          Text("Started from \(job.source)").font(.system(size: 11)).foregroundStyle(DeckStyle.muted)
          Spacer()
          if let started = job.started {
            Text(Date(timeIntervalSince1970: started), style: .time).font(.system(size: 11)).foregroundStyle(DeckStyle.muted)
          }
        }
        if runs.count > 1 {
          Picker("Task history", selection: Binding(get: { selectedRunID ?? runs.first?.id ?? "" }, set: { selectedRunID = $0 })) {
            ForEach(Array(runs.enumerated()), id: \.element.id) { index, run in
              Text("\(index == 0 ? "Latest run" : "Earlier run") · \(run.status.capitalized)\(run.started.map { " · " + Date(timeIntervalSince1970: $0).formatted(date: .omitted, time: .shortened) } ?? "")")
                .tag(run.id)
            }
          }.pickerStyle(.menu).font(.system(size: 12))
        }
        if !job.error.isEmpty { InlineNotice(text: job.error) }
        if job.result.isEmpty {
          Text(job.status == "running" ? "Your dotlet is reading the project. Its response will appear here automatically." : "This run has no response. You can run the task again when ready.")
            .font(.system(size: 14)).foregroundStyle(DeckStyle.muted).lineSpacing(5)
        } else {
          DotletResultText(text: job.result)
        }
      }
    } else {
      VStack(alignment: .leading, spacing: 8) {
        Text(dot == nil ? "Make it yours" : "Your result will appear here").font(.system(size: 17, weight: .semibold))
        Text(dot == nil ? "A dotlet can review a project, explain code, or help plan your next step. You choose its task." : "Run the task here or press its physical key. You’ll see progress and the completed response in this space.")
          .font(.system(size: 13)).foregroundStyle(DeckStyle.muted).lineSpacing(4)
      }
    }
  }
}

/// Preserve paragraphs and lists while rendering inline emphasis and links as native text.
private struct DotletResultText: View {
  let text: String
  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      ForEach(Array(text.components(separatedBy: "\n\n").enumerated()), id: \.offset) { _, paragraph in
        let heading = paragraph.hasPrefix("#") && paragraph.firstIndex(of: " ") != nil
        let content = heading ? String(paragraph.drop(while: { $0 == "#" || $0 == " " })) : paragraph
        Text((try? AttributedString(markdown: content, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(content))
          .font(.system(size: heading ? 17 : 14, weight: heading ? .semibold : .regular))
          .lineSpacing(5).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}

private struct DotEditor: View {
  @Environment(\.dismiss) private var dismiss
  @State var dot: SavedDot
  var save: (SavedDot) -> Void
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(dot.name.isEmpty ? "Give your dotlet a task" : "Edit dotlet task").font(.title2.bold())
      TextField("Task name", text: $dot.name).accessibilityLabel("Task name")
      Text("Saved prompt").font(.headline)
      TextEditor(text: $dot.prompt).frame(height: 130).border(.secondary.opacity(0.3)).accessibilityLabel("Saved prompt")
      TextField("Project folder", text: $dot.workspace).accessibilityLabel("Project folder")
      Button("Choose project folder…") {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true; panel.canChooseFiles = false
        if panel.runModal() == .OK, let url = panel.url { dot.workspace = url.path }
      }
      Text("A fresh key press runs this prompt in Codex with read-only project access.").font(.caption).foregroundStyle(.secondary)
      HStack {
        Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
        Spacer()
        Button("Save task") { save(dot) }.keyboardShortcut(.defaultAction)
          .disabled(dot.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || dot.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || dot.prompt.count > 4000 || !FileManager.default.fileExists(atPath: dot.workspace))
      }
    }.padding(24).frame(width: 530)
  }
}

struct DotletMenu: View {
  @ObservedObject var keyboard: KeyboardStore
  @Environment(\.openWindow) private var openWindow
  var body: some View {
    Text("Open.Dotlet").font(.headline)
    Text(keyboard.status)
    Divider()
    ForEach(keyboard.dots) { dot in
      Button("Run \(dot.name)") { keyboard.run(dot.id) }.disabled(keyboard.busy)
    }
    if keyboard.busy { Button("Cancel run", action: keyboard.cancel) }
    Toggle("Physical keys enabled", isOn: Binding(get: { keyboard.snapshot?.enabled ?? false }, set: keyboard.setEnabled))
      .disabled(keyboard.snapshot == nil)
    Divider()
    Button("Open agent team") {
      NotificationCenter.default.post(name: .openDotletKeyboard, object: nil)
      openWindow(id: "main")
      NSApp.activate(ignoringOtherApps: true)
    }
    Button("Quit OpenDotlet") { NSApp.terminate(nil) }
  }
}
extension Notification.Name { static let openDotletKeyboard = Notification.Name("openDotletKeyboard") }
