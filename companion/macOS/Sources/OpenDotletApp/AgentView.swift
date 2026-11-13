import AppKit
import DotletCore
import SwiftUI

struct AgentTeamView: View {
  @ObservedObject var team: AgentTeamStore
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Picker("Agent", selection: Binding(get: { team.selectedID }, set: { team.select($0) })) {
          ForEach(team.profiles) { Text($0.name).tag($0.id) }
        }.pickerStyle(.menu)
        Spacer()
        Button("Duplicate agent") { team.duplicate() }.buttonStyle(StickerButtonStyle())
          .disabled(team.selected == nil)
      }
      Text(
        "Separate roles, memory and tasks. One shared desktop."
      )
      .font(.system(size: 12)).foregroundStyle(DeckStyle.muted).fixedSize(
        horizontal: false, vertical: true)
      if let error = team.errorMessage { InlineNotice(text: error) }
      if let profile = team.selected, let service = team.selectedService {
        AgentWorkspace(team: team, service: service, profile: profile).id(profile.id)
      }
    }.padding(26)
  }
}

private struct AgentWorkspace: View {
  @ObservedObject var team: AgentTeamStore
  @ObservedObject var service: AgentService
  var profile: AgentProfile
  @State private var draft = ""
  @State private var name = ""
  @State private var role = ""
  @State private var root = ""
  @State private var configuration = ""
  @State private var showingConfiguration = false
  private var canUseComputer: Bool {
    guard let permissions = service.snapshot?.permissions, !permissions.isEmpty else {
      return false
    }
    return permissions.values.allSatisfy { $0 }
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        Label(
          service.connected
            ? "Agent connected" : (service.starting ? "Starting agent…" : "Agent offline"),
          systemImage: service.connected ? "checkmark.circle" : "circle"
        )
        .font(.system(size: 12, weight: .medium))
        Spacer()
        Button("Agent settings") { showingConfiguration.toggle() }
        if service.starting {
          Button("Cancel connection") { service.shutdown() }
        } else {
          Button(service.connected ? "Disconnect agent" : "Connect agent") {
            if service.connected {
              service.shutdown()
            } else {
              Task {
                do { try await service.connect() } catch {
                  service.errorMessage = error.localizedDescription
                }
              }
            }
          }
        }
        if service.running {
          Button("Stop task") { Task { await service.stop() } }
        }
      }
      if let error = service.errorMessage { InlineNotice(text: error) }
      Toggle(
        "Send new button transcripts to this agent",
        isOn: Binding(
          get: { team.voiceAgentID == profile.id },
          set: { team.voiceAgentID = $0 ? profile.id : nil })
      )
      .toggleStyle(.switch).font(.system(size: 12))
      if service.connected {
        HStack(spacing: 12) {
          Toggle(
            "Use computer",
            isOn: Binding(
              get: { service.snapshot?.computerEnabled ?? false },
              set: { value in Task { await service.computerAccess(value) } })
          )
          .toggleStyle(.switch).disabled(service.running || !canUseComputer)
          if service.snapshot?.computerEnabled != true {
            Button(
              service.snapshot?.codex.authenticated == true ? "Codex connected" : "Connect Codex"
            ) {
              Task { await service.connectCodex() }
            }.disabled(service.running || service.snapshot?.codex.authenticated == true)
            Toggle("Allow file changes", isOn: $service.writable).disabled(service.running)
          }
        }.font(.system(size: 11))
        DisclosureGroup("Connection details") {
          if !canUseComputer {
            Text(
              "Computer use needs OpenDotlet’s macOS Accessibility and Screen Recording permissions. Codex tasks can run independently."
            )
            .font(.system(size: 11)).foregroundStyle(DeckStyle.muted).fixedSize(
              horizontal: false, vertical: true)
            Button("Open Privacy & Security") {
              NSWorkspace.shared.open(
                URL(
                  string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension")!
              )
            }.font(.system(size: 11))
          }
          Text(
            service.snapshot?.computerEnabled == true
              ? (service.apiConfigured
                ? "Using your existing Ambi API configuration. The computer worker can see and operate the desktop for the task you send."
                : "No OpenAI key was found in the selected Ambi configuration.")
              : "Codex uses its existing sign-in. File access starts read-only in this agent’s own working folder."
          )
          .font(.system(size: 10)).foregroundStyle(DeckStyle.muted).fixedSize(
            horizontal: false, vertical: true)
        }.font(.system(size: 11))
      }
      ScrollViewReader { proxy in
        ScrollView {
          VStack(alignment: .leading, spacing: 18) {
            if let state = service.snapshot {
              if let job = state.job {
                VStack(alignment: .leading, spacing: 6) {
                  Text(job.status.capitalized).font(.system(size: 12, weight: .semibold))
                  Text(job.task).font(.system(size: 12)).textSelection(.enabled)
                  if let result = job.result {
                    Text(result).font(.system(size: 12)).textSelection(.enabled)
                  }
                }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
                  .background(DeckStyle.raised, in: RoundedRectangle(cornerRadius: 12))
              }
              ForEach(state.codex.pending) { approval in
                Surface {
                  VStack(alignment: .leading, spacing: 10) {
                    Text("Permission requested").font(.system(size: 13, weight: .semibold))
                    Text(approval.reason).font(.system(size: 12)).textSelection(.enabled)
                    if let cwd = approval.cwd, !cwd.isEmpty {
                      Text("Folder: " + cwd).font(.system(size: 11)).textSelection(.enabled)
                    }
                    if let root = approval.grantRoot, !root.isEmpty {
                      Text("Requested scope: " + root).font(.system(size: 11)).textSelection(
                        .enabled)
                    }
                    if let network = approval.network, let host = network["host"], !host.isEmpty {
                      Text("Network: " + host + " · " + (network["protocol"] ?? "")).font(
                        .system(size: 11)
                      ).textSelection(.enabled)
                    }
                    if let command = approval.command, !command.isEmpty {
                      Text(command).font(.system(size: 11, design: .monospaced)).textSelection(
                        .enabled)
                    }
                    ForEach(Array((approval.changes ?? []).enumerated()), id: \.offset) {
                      _, change in
                      Text(change.path + "\n" + change.diff).font(
                        .system(size: 11, design: .monospaced)
                      ).textSelection(.enabled)
                    }
                    HStack {
                      Button("Allow once") {
                        Task { await service.approve(approval.id, decision: "accept") }
                      }
                      .disabled(approval.canAccept == false)
                      Button("Decline") {
                        Task { await service.approve(approval.id, decision: "decline") }
                      }
                    }
                  }
                }
              }
              if !state.activity.isEmpty {
                DisclosureGroup("Task activity") {
                  VStack(alignment: .leading, spacing: 10) {
                    ForEach(state.activity.suffix(30)) { item in
                      VStack(alignment: .leading, spacing: 3) {
                        Text(item.title + " · " + item.status).font(
                          .system(size: 11, weight: .medium))
                        if let detail = item.detail {
                          Text(detail).font(.system(size: 11)).foregroundStyle(DeckStyle.muted)
                            .textSelection(.enabled)
                        }
                      }
                    }
                  }.padding(.top, 8)
                }.font(.system(size: 12))
              }
              ForEach(state.transcript) { item in
                VStack(alignment: .leading, spacing: 7) {
                  Text(item.role == "assistant" ? profile.name : "You").font(
                    .system(size: 11, weight: .semibold)
                  )
                  .foregroundStyle(DeckStyle.muted)
                  Text(item.text).font(.system(size: 13)).textSelection(.enabled).lineSpacing(4)
                }.frame(maxWidth: .infinity, alignment: .leading)
              }
              if state.transcript.isEmpty {
                Text("Give \(profile.name) a task. Its replies and progress will appear here.")
                  .font(.system(size: 13)).foregroundStyle(DeckStyle.muted)
              }
            } else {
              Text(
                "Connect to reuse your local Ambi engine. Starting an agent leaves microphone, camera and computer access off."
              )
              .font(.system(size: 13)).foregroundStyle(DeckStyle.muted)
            }
            Color.clear.frame(height: 1).id("agent-bottom")
          }.padding(.vertical, 12)
        }
        .onChange(of: service.snapshot?.transcript.last?.text) { _, _ in
          proxy.scrollTo("agent-bottom", anchor: .bottom)
        }
      }
      VStack(alignment: .leading, spacing: 12) {
        TextField("", text: $draft, axis: .vertical).textFieldStyle(.plain).lineLimit(1...4)
          .inputHint("Give this agent a task…", empty: draft.isEmpty, inset: 0, size: 14)
          .accessibilityLabel("Agent task")
        HStack {
          Text(
            "Sends this task to the selected agent. Recordings stay local until you send a transcript."
          )
          .font(.system(size: 10)).foregroundStyle(DeckStyle.muted)
          Spacer()
          Button("Send task") {
            let text = draft
            Task { if await service.send(text), draft == text { draft = "" } }
          }.buttonStyle(AccentButtonStyle()).disabled(
            service.running || service.starting
              || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }.padding(16).background(DeckStyle.panel, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DeckStyle.ink, lineWidth: 2))
    }
    .onAppear {
      name = profile.name
      role = profile.role
      root = profile.backendRoot
      configuration = profile.configurationFile
    }
    .sheet(isPresented: $showingConfiguration) {
      settings.padding(24).frame(width: 560)
    }
  }
  private var settings: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Agent settings").font(DeckStyle.display(22))
      TextField("Agent name", text: $name).textFieldStyle(.roundedBorder)
      TextField("Role", text: $role, axis: .vertical).textFieldStyle(.roundedBorder).lineLimit(
        1...3)
      TextField("Ambi folder", text: $root).textFieldStyle(.roundedBorder)
      TextField("Existing private configuration file", text: $configuration).textFieldStyle(
        .roundedBorder)
      Text(
        "This is a file path, not an API key. The backend reads the existing configuration privately."
      )
      .font(.system(size: 10)).foregroundStyle(DeckStyle.muted)
      Button("Save agent") {
        var updated = profile
        updated.name = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
        updated.role = String(role.prefix(1000))
        updated.backendRoot = root
        updated.configurationFile = configuration
        team.update(updated)
        showingConfiguration = false
      }.disabled(service.running || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      Button("Cancel") { showingConfiguration = false }
    }.font(.system(size: 12))
  }
}
