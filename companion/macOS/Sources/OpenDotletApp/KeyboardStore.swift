import AppKit
import Foundation

struct SavedDot: Codable, Identifiable {
  var id: String
  var row: Int
  var col: Int
  var name: String
  var prompt: String
  var workspace: String
}
struct DotRun: Codable, Identifiable {
  var id: String
  var name: String
  var status: String
  var source: String
  var result: String
  var error: String
  var dot_id: String?
  var row: Int?
  var col: Int?
  var started: Double?
}
struct KeyboardSnapshot: Codable {
  struct Runtime: Codable { var codex_available: Bool; var portable: Bool }
  var dots: [SavedDot]
  var job: DotRun?
  var device: String
  var last_event: String
  var enabled: Bool
  var learning: String?
  var history: [DotRun]
  var runtime: Runtime?
}

@MainActor
final class KeyboardStore: ObservableObject {
  @Published var snapshot: KeyboardSnapshot?
  @Published var error: String?
  @Published var connecting = false
  @Published var notice: String?
  @Published var actionError: String?
  private var terminationObserver: NSObjectProtocol?
  private var process: Process?
  private var polling: Task<Void, Never>?
  private var started = false
  private let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent(Bundle.main.object(forInfoDictionaryKey: "OpenDotletSupportSubdirectory") as? String ?? "OpenDotlet/Keyboard")
  private let session: URLSession = {
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 3
    config.httpShouldSetCookies = false
    config.urlCache = nil
    return URLSession(configuration: config)
  }()
  var busy: Bool { snapshot?.job?.status == "running" }
  var dots: [SavedDot] { snapshot?.dots ?? [] }
  var status: String { actionError ?? error ?? (busy ? "Codex is running…" : snapshot?.device ?? "Connecting…") }
  var workspace: String {
    Bundle.main.object(forInfoDictionaryKey: "OpenDotletWorkspace") as? String
      ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/OpenDotlet").path
  }
  func start() {
    guard !started else { return }
    started = true
    terminationObserver = NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
      MainActor.assumeIsolated { self?.shutdown() }
    }
    polling = Task { [weak self] in
      guard let self else { return }
      await self.connect()
      while !Task.isCancelled {
        await self.refresh()
        try? await Task.sleep(for: .seconds(0.6))
      }
    }
  }
  func connect() async {
    connecting = true
    defer { connecting = false }
    do {
      _ = try await call("state")
      error = nil
      actionError = nil
      return
    } catch {}
    let base = URL(fileURLWithPath: workspace)
    let python = base.appendingPathComponent(".venv/bin/python")
    let executable = FileManager.default.isExecutableFile(atPath: python.path)
      ? python : URL(fileURLWithPath: "/usr/bin/python3")
    let p = Process()
    if let runtime = Bundle.main.resourceURL?.appendingPathComponent("Runtime/opendotlet-host"),
       FileManager.default.isExecutableFile(atPath: runtime.path) {
      p.executableURL = runtime
      p.arguments = ["serve", "--data", root.path]
    } else {
      p.executableURL = executable
      p.arguments = [base.appendingPathComponent("tools/dotlet.py").path, "serve", "--workspace", workspace]
    }
    p.standardOutput = FileHandle.nullDevice
    p.standardError = FileHandle.nullDevice
    do {
      try p.run()
      process = p
      for _ in 0..<30 {
        try? await Task.sleep(for: .milliseconds(100))
        if let data = try? await call("state") {
          snapshot = try JSONDecoder().decode(KeyboardSnapshot.self, from: data)
          error = nil
          return
        }
      }
      error = "Could not start the saved-dot host. Retry or check the CLI."
    } catch { self.error = error.localizedDescription }
  }
  func call(_ route: String, body: [String: Any]? = nil) async throws -> Data {
    struct Manifest: Decodable { let version: Int; let port: Int; let token: String }
    let data = try Data(contentsOf: root.appendingPathComponent("service.json"))
    let manifest = try JSONDecoder().decode(Manifest.self, from: data)
    guard manifest.version == 1, (1...65535).contains(manifest.port), !manifest.token.isEmpty,
      let url = URL(string: "http://127.0.0.1:\(manifest.port)/\(route)") else {
      throw NSError(domain: "OpenDotlet", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid keyboard host."])
    }
    var request = URLRequest(url: url)
    request.setValue("Bearer \(manifest.token)", forHTTPHeaderField: "Authorization")
    if let body {
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try JSONSerialization.data(withJSONObject: body)
    }
    let (result, response) = try await session.data(for: request)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      let message = (try? JSONSerialization.jsonObject(with: result) as? [String: String])?["error"]
      throw NSError(domain: "OpenDotlet", code: 2, userInfo: [NSLocalizedDescriptionKey: message ?? "Keyboard host unavailable."])
    }
    return result
  }
  func refresh() async {
    do {
      let updated = try JSONDecoder().decode(KeyboardSnapshot.self, from: await call("state"))
      if snapshot?.learning != nil && updated.learning == nil { notice = nil }
      snapshot = updated
      error = nil
    } catch { self.error = error.localizedDescription }
  }
  struct USBPort: Decodable, Identifiable { var port: String; var name: String; var id: String { port } }
  struct USBState: Decodable { var ports: [USBPort]; var selected: String; var message: String }
  @Published var usbPorts: [USBPort] = []
  @Published var selectedPort = ""
  @Published var usbMessage = "Choose the USB keypad port, then connect."
  func refreshPorts() {
    Task {
      do {
        let info = try JSONDecoder().decode(USBState.self, from: await call("ports"))
        usbPorts = info.ports
        if !info.selected.isEmpty { selectedPort = info.selected }
        usbMessage = info.message
      } catch { usbMessage = "USB selection requires the downloadable companion runtime." }
    }
  }
  func connectUSB(disconnect: Bool = false) {
    Task {
      do {
        let info = try JSONDecoder().decode(USBState.self, from: await call("serial", body: ["port": disconnect ? "" : selectedPort]))
        usbMessage = info.message
        actionError = nil
      } catch { actionError = error.localizedDescription }
    }
  }
  func run(_ id: String) {
    guard !busy else { return }
    Task {
      do { _ = try await call("run", body: ["id": id]); actionError = nil; await refresh() }
      catch { self.actionError = error.localizedDescription }
    }
  }
  func learn(_ id: String) {
    Task {
      do {
        _ = try await call("learn", body: ["id": id])
        actionError = nil
        notice = "Press the physical key you want to use. That press will save the binding and run this prompt."
        await refresh()
      } catch { self.actionError = error.localizedDescription }
    }
  }
  func pairWindows() {
    Task {
      do { _ = try await call("pair-window", body: [:]); actionError = nil; notice = "Ready to pair the configured Windows client for five minutes." }
      catch { self.actionError = error.localizedDescription }
    }
  }
  func cancel() {
    Task {
      do { _ = try await call("cancel", body: [:]); await refresh() }
      catch { self.actionError = error.localizedDescription }
    }
  }
  func setEnabled(_ enabled: Bool) {
    Task {
      do { _ = try await call("enabled", body: ["enabled": enabled]); await refresh() }
      catch { self.actionError = error.localizedDescription }
    }
  }
  func save(_ dot: SavedDot) {
    Task {
      do {
        var updated = dots.filter { $0.id != dot.id }
        updated.append(dot)
        let data = try JSONEncoder().encode(updated)
        let list = try JSONSerialization.jsonObject(with: data)
        _ = try await call("dots", body: ["version": 1, "dots": list])
        await refresh()
      } catch { self.actionError = error.localizedDescription }
    }
  }
  func shutdown() {
    polling?.cancel()
    polling = nil
    if process?.isRunning == true { process?.terminate() }
  }
}
