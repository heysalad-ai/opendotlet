import AppKit
import Combine
import DotletCore
import Foundation

@MainActor
final class AgentService: ObservableObject {
  let profile: AgentProfile
  @Published var snapshot: AgentSnapshot?
  @Published var connected = false
  @Published var starting = false
  @Published var errorMessage: String?
  @Published var apiConfigured = false
  @Published var writable = false
  private var process: Process?
  private var client: AgentClient?
  private var poller: Task<Void, Never>?
  private let clientID = UUID().uuidString
  private var connecting: Task<Void, Error>?
  private let directory: URL
  var running: Bool {
    snapshot?.job?.status == "running" || snapshot?.codex.status == "approval-required"
  }

  init(profile: AgentProfile, directory: URL) {
    self.profile = profile
    self.directory = directory
  }
  func connect() async throws {
    if connected { return }
    if let connecting { return try await connecting.value }
    let task = Task { [weak self] in
      guard let self else { return }
      self.starting = true
      defer {
        self.starting = false
        self.connecting = nil
      }
      try await self.openService()
    }
    connecting = task
    try await task.value
  }
  private func openService() async throws {
    let root = URL(fileURLWithPath: profile.backendRoot)
    let python = root.appendingPathComponent(".venv/bin/python")
    guard FileManager.default.isExecutableFile(atPath: python.path),
      FileManager.default.fileExists(atPath: root.appendingPathComponent("app_runtime.py").path),
      FileManager.default.fileExists(atPath: profile.configurationFile)
    else {
      throw DotletError.invalid(
        "Check this agent’s Ambi folder and existing private configuration file.")
    }
    try FileManager.default.createDirectory(
      at: directory, withIntermediateDirectories: true,
      attributes: [.posixPermissions: 0o700])
    let manifest = directory.appendingPathComponent("service-\(clientID).json")
    if process?.isRunning != true {
      try? FileManager.default.removeItem(at: manifest)
      let project =
        Bundle.main.object(forInfoDictionaryKey: "OpenDotletWorkspace") as? String
        ?? FileManager.default.currentDirectoryPath
      let worker = Process()
      worker.executableURL = python
      worker.currentDirectoryURL = root
      var environment = ProcessInfo.processInfo.environment
      environment["PATH"] =
        FileManager.default.homeDirectoryForCurrentUser.path
        + "/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
      worker.environment = environment
      worker.arguments = [
        project + "/tools/agent_service.py", "--ambi-root", root.path,
        "--config", profile.configurationFile, "--data",
        directory.appendingPathComponent("data").path,
        "--manifest", manifest.path, "--agent-id", profile.id, "--role", profile.role,
        "--desktop-lease",
        directory.deletingLastPathComponent().appendingPathComponent("desktop.lock").path,
      ]
      let log = directory.appendingPathComponent("service.log")
      FileManager.default.createFile(
        atPath: log.path, contents: nil, attributes: [.posixPermissions: 0o600])
      let output = try FileHandle(forWritingTo: log)
      worker.standardOutput = output
      worker.standardError = output
      worker.terminationHandler = { [weak self] task in
        Task { @MainActor in
          guard let self, self.process === task else { return }
          self.connected = false
          self.client = nil
          self.poller?.cancel()
          self.poller = nil
        }
        try? output.close()
      }
      process = worker
      try worker.run()
    }
    struct Manifest: Decodable {
      var port: Int
      var pid: Int32
      var agentID: String
      enum CodingKeys: String, CodingKey {
        case port, pid
        case agentID = "agent_id"
      }
    }
    var info: Manifest?
    for _ in 0..<100 {
      try Task.checkCancellation()
      guard process?.isRunning == true else {
        throw DotletError.invalid(
          "The Ambi service could not start. Check its local configuration and dependencies.")
      }
      if let data = try? Data(contentsOf: manifest),
        let value = try? JSONDecoder().decode(Manifest.self, from: data),
        value.pid == process?.processIdentifier, value.agentID == profile.id
      {
        info = value
        break
      }
      try await Task.sleep(nanoseconds: 100_000_000)
    }
    guard let info, (1...65535).contains(info.port) else {
      throw DotletError.invalid("The local agent did not become ready.")
    }
    let client = try AgentClient(
      base: URL(string: "http://127.0.0.1:\(info.port)")!, agentID: profile.id)
    var state: AgentSnapshot?
    for _ in 0..<30 {
      do {
        state = try await client.bootstrap()
        break
      } catch { try await Task.sleep(nanoseconds: 100_000_000) }
    }
    guard let state else {
      throw DotletError.invalid("The local agent did not confirm its identity.")
    }
    self.client = client
    snapshot = state
    apiConfigured = client.apiConfigured
    connected = true
    errorMessage = nil
    poller?.cancel()
    poller = Task { [weak self] in
      while !Task.isCancelled {
        do {
          try await Task.sleep(nanoseconds: 500_000_000)
          let next = try await client.state()
          guard !Task.isCancelled else { return }
          self?.snapshot = next
        } catch {
          guard !Task.isCancelled else { return }
          self?.connected = false
          self?.errorMessage =
            "The agent connection was interrupted. Connect again to restore its state; tasks are not replayed."
          return
        }
      }
    }
  }
  @discardableResult func send(_ text: String) async -> Bool {
    do {
      try await connect()
      guard let client, !running else {
        throw DotletError.invalid("Stop or finish this agent’s current task first.")
      }
      try await client.post(
        "codex-message", body: ["text": text, "writable": writable, "client_id": clientID])
      snapshot = try await client.state()
      errorMessage = nil
      return true
    } catch {
      errorMessage = error.localizedDescription
      return false
    }
  }
  func stop() async {
    do {
      try await client?.post("stop-task", body: ["client_id": clientID])
      snapshot = try await client?.state()
    } catch { errorMessage = error.localizedDescription }
  }
  func computerAccess(_ enabled: Bool) async {
    do {
      try await connect()
      try await client?.post("computer-access", body: ["enabled": enabled])
      snapshot = try await client?.state()
    } catch { errorMessage = error.localizedDescription }
  }
  func connectCodex() async {
    do {
      try await connect()
      try await client?.post("codex-connect")
      snapshot = try await client?.state()
    } catch { errorMessage = error.localizedDescription }
  }
  func approve(_ id: String, decision: String) async {
    do { try await client?.post("codex-approval", body: ["id": id, "decision": decision]) } catch {
      errorMessage = error.localizedDescription
    }
  }
  func shutdown() {
    connecting?.cancel()
    connecting = nil
    poller?.cancel()
    poller = nil
    connected = false
    client = nil
    if process?.isRunning == true { process?.terminate() }
    process = nil
  }
}

@MainActor
final class AgentTeamStore: ObservableObject {
  struct Archive: Codable {
    var profiles: [AgentProfile]
    var selectedID: String
  }
  @Published var profiles: [AgentProfile] = []
  @Published var selectedID = ""
  @Published var errorMessage: String?
  @Published var voiceAgentID: String?
  private var captureAgentID: String?
  private var seenRecordings = Set<String>()
  private var services: [String: AgentService] = [:]
  private var subscriptions: [String: AnyCancellable] = [:]
  private let directory: URL
  private var readFailed = false
  private var terminationObserver: NSObjectProtocol?
  var selected: AgentProfile? { profiles.first { $0.id == selectedID } }
  var selectedService: AgentService? { selected.map { service(for: $0) } }
  init() {
    directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("OpenDotlet/Agents")
    let file = directory.appendingPathComponent("team.json")
    if FileManager.default.fileExists(atPath: file.path) {
      do {
        let archive = try JSONDecoder().decode(Archive.self, from: Data(contentsOf: file))
        guard !archive.profiles.isEmpty,
          Set(archive.profiles.map(\.id)).count == archive.profiles.count,
          archive.profiles.allSatisfy({ UUID(uuidString: $0.id) != nil }),
          archive.profiles.contains(where: { $0.id == archive.selectedID })
        else { throw CocoaError(.fileReadCorruptFile) }
        profiles = archive.profiles
        selectedID = archive.selectedID
      } catch {
        readFailed = true
        errorMessage = "The agent team could not be read. Its saved file has not been overwritten."
      }
    } else {
      let home = FileManager.default.homeDirectoryForCurrentUser.path
      let profile = AgentProfile(
        name: "My Dotlet",
        role: "Helpful general assistant. Keep reports concise and verify task results.",
        backendRoot: home + "/Documents/ChatGPT/Ambient_Computer/ambi-integration-2026-11-03",
        configurationFile: home + "/Documents/ChatGPT/Ambient_Computer/ambi-openai-hackathon/.env")
      profiles = [profile]
      selectedID = profile.id
      save()
    }
    terminationObserver = NotificationCenter.default.addObserver(
      forName: NSApplication.willTerminateNotification,
      object: nil, queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated {
        if let self { for service in self.services.values { service.shutdown() } }
      }
    }
  }
  func service(for profile: AgentProfile) -> AgentService {
    if let existing = services[profile.id] { return existing }
    let service = AgentService(
      profile: profile, directory: directory.appendingPathComponent(profile.id))
    services[profile.id] = service
    subscriptions[profile.id] = service.objectWillChange.sink { [weak self] in
      self?.objectWillChange.send()
    }
    return service
  }
  func select(_ id: String) {
    if selectedID != id { voiceAgentID = nil }
    selectedID = id
    save()
  }
  func duplicate() {
    guard let selected else { return }
    let copy = selected.duplicate()
    voiceAgentID = nil
    profiles.append(copy)
    selectedID = copy.id
    save()
  }
  func update(_ profile: AgentProfile) {
    guard let index = profiles.firstIndex(where: { $0.id == profile.id }),
      services[profile.id]?.running != true
    else { return }
    services.removeValue(forKey: profile.id)?.shutdown()
    if voiceAgentID == profile.id { voiceAgentID = nil }
    subscriptions.removeValue(forKey: profile.id)
    profiles[index] = profile
    save()
  }
  func send(_ text: String) {
    guard let selectedService else { return }
    Task { await selectedService.send(text) }
  }
  func prepareRecordings(_ recordings: [Recording]) { seenRecordings = Set(recordings.map(\.id)) }
  func beginCapture() { captureAgentID = voiceAgentID }
  func receiveRecordings(_ recordings: [Recording]) -> [(recordingID: String, agentID: String)] {
    let added = recordings.filter { !seenRecordings.contains($0.id) }
    seenRecordings.formUnion(recordings.map(\.id))
    guard let id = captureAgentID, voiceAgentID == id,
      let profile = profiles.first(where: { $0.id == id })
    else { return [] }
    captureAgentID = nil
    let service = service(for: profile)
    var deliveries: [(recordingID: String, agentID: String)] = []
    for item in added {
      guard !item.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        item.text != "No speech detected"
      else { continue }
      if service.running {
        errorMessage =
          "\(profile.name) is still working. Your new transcript is saved in Chats; send it when the task finishes."
      } else {
        deliveries.append((item.id, id))
        Task { await service.send(item.text) }
      }
    }
    return deliveries
  }
  private func save() {
    guard !readFailed else { return }
    do {
      try FileManager.default.createDirectory(
        at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
      let file = directory.appendingPathComponent("team.json")
      try JSONEncoder().encode(Archive(profiles: profiles, selectedID: selectedID)).write(
        to: file, options: .atomic)
      try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
    } catch { errorMessage = "Could not save your agent team." }
  }
}
