// App-store pattern adapted from NiceDeck's DeckStore (MIT, OpenStreamDeck contributors).
import AppKit
import Combine
import CoreBluetooth
import DotletCore
import Foundation

struct Recording: Identifiable, Codable {
  var id: String
  var date: Date
  var text: String
  var seconds: Double
  var folder: String
}

final class DotletStore: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate
{
  @Published var connected = false
  @Published var ready = false
  @Published var enabled = false
  @Published var busy = false
  @Published var scanning = false
  @Published var status = "Connect your Dotlet"
  @Published var detail = "Pair the button, enable it, then hold the key to capture a thought."
  @Published var errorMessage: String?
  @Published var recordings: [Recording] = []
  @Published var selectedID: String?
  @Published var progress = 0.0
  @Published var recording = false
  @Published var transcribing = false
  @Published private(set) var maintainingConnection = false
  @Published private var recordingSession = RecordingSession()
  var sessionEnabled: Bool { recordingSession.requested }
  private var recovery = ConnectionRecovery()
  private var preferSavedPeripheral = true
  private var lastStatusAt = Date()
  private var lastStatusPollAt = Date()
  private var central: CBCentralManager!
  private var peripheral: CBPeripheral?
  private var control: CBCharacteristic?
  private var statusChar: CBCharacteristic?
  private var audioChar: CBCharacteristic?
  private var assembler: ClipAssembler?
  private var heartbeat: Timer?
  private var activeRecordingSession: NSObjectProtocol?
  private var deadline = Date.distantFuture
  private var scanDeadline = Date.distantFuture
  private var transferStarted = Date.distantPast
  private var operationID = UUID()
  private var process: Process?
  private var terminationObserver: NSObjectProtocol?
  private var wakeObserver: NSObjectProtocol?
  private var workspace: URL {
    URL(
      fileURLWithPath: Bundle.main.object(forInfoDictionaryKey: "OpenDotletWorkspace") as? String
        ?? FileManager.default.currentDirectoryPath)
  }
  private var support: URL {
    FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
      .appendingPathComponent("OpenDotlet", isDirectory: true)
  }
  var selected: Recording? { recordings.first { $0.id == selectedID } }
  override init() {
    super.init()
    load()
    // Bluetooth permission is requested only when the user chooses Connect.
    heartbeat = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
    if let heartbeat { RunLoop.main.add(heartbeat, forMode: .common) }
    terminationObserver = NotificationCenter.default.addObserver(
      forName: NSApplication.willTerminateNotification, object: nil, queue: .main
    ) { [weak self] _ in
      self?.recordingSession.pause()
      self?.closeConnection()
      self?.process?.terminate()
    }
    wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
    ) { [weak self] _ in
      guard let self, self.recovery.wanted else { return }
      if self.peripheral == nil && !self.scanning { self.recovery.start() }
    }
    if UserDefaults.standard.bool(forKey: "buttonKeepConnected") {
      DispatchQueue.main.async { [weak self] in self?.connect() }
    }
  }
  func log(_ message: String) {
    let line = "\(ISO8601DateFormatter().string(from:Date())) \(message)\n"
    let dir = support.appendingPathComponent("Diagnostics", isDirectory: true)
    try? FileManager.default.createDirectory(
      at: dir, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
    let file = dir.appendingPathComponent("wireless.log")
    if !FileManager.default.fileExists(atPath: file.path) {
      FileManager.default.createFile(atPath: file.path, contents: nil)
    }
    if let h = try? FileHandle(forWritingTo: file) {
      _ = try? h.seekToEnd()
      try? h.write(contentsOf: Data(line.utf8))
      try? h.close()
    }
  }
  func connect() {
    log(
      "CONNECT requested active=\(peripheral != nil) scanning=\(scanning) manager=\(central?.state.rawValue ?? -1)"
    )
    maintainingConnection = true
    UserDefaults.standard.set(true, forKey: "buttonKeepConnected")
    recovery.start()
    errorMessage = nil
    guard peripheral == nil && !scanning else { return }
    if central == nil {
      status = "Preparing Bluetooth…"
      central = CBCentralManager(delegate: self, queue: .main)
    } else if central.state == .poweredOn {
      scan()
    }
  }
  private func scan() {
    guard recovery.wanted, central.state == .poweredOn, peripheral == nil, !scanning else { return }
    recovery.attemptStarted()
    if preferSavedPeripheral,
      let saved = UserDefaults.standard.string(forKey: "buttonPeripheralID").flatMap(UUID.init),
      let known = central.retrievePeripherals(withIdentifiers: [saved]).first
    {
      preferSavedPeripheral = false
      attach(known)
      return
    }
    preferSavedPeripheral = true
    // macOS may reconnect the board through its earlier keyboard bond before
    // this app can scan. Attach to that same known device, then verify service.
    let existing = central.retrieveConnectedPeripherals(withServices: [
      CBUUID(string: Wire.service), CBUUID(string: "1800"), CBUUID(string: "1812"),
    ])
    log(
      "EXISTING count=\(existing.count) names=\(existing.map { $0.name ?? "unknown" }.joined(separator:","))"
    )
    if let p = existing.first(where: {
      if let saved = UserDefaults.standard.string(forKey: "buttonPeripheralID") {
        return $0.identifier.uuidString == saved
      }
      return $0.name?.hasPrefix("OpenDotlet") == true || $0.name == "MG24 Dot Voice Key"
    }) {
      attach(p)
      return
    }
    scanning = true
    status = "Looking for your Dotlet…"
    detail = "Keep the button powered and nearby."
    scanDeadline = Date().addingTimeInterval(20)
    central.scanForPeripherals(withServices: [CBUUID(string: Wire.service)], options: nil)
    log("SCAN service=\(Wire.service)")
  }
  private func attach(_ p: CBPeripheral) {
    guard p.state != .disconnecting else {
      retryConnection("Waiting for the previous Bluetooth connection to close.")
      return
    }
    peripheral = p
    p.delegate = self
    scanDeadline = Date().addingTimeInterval(30)
    status = "Connecting to Dotlet…"
    central.connect(p, options: nil)
    log("ATTACH peripheral=\(p.identifier)")
  }
  func disconnect() {
    recordingSession.pause()
    recovery.stop()
    maintainingConnection = false
    UserDefaults.standard.set(false, forKey: "buttonKeepConnected")
    closeConnection()
  }
  private func closeConnection() {
    recordingSession.resetPendingCommand()
    endRecordingActivity()
    write(2)
    enabled = false
    recording = false
    let transcribing = process?.isRunning == true
    busy = transcribing
    ready = false
    scanning = false
    if central?.state == .poweredOn { central.stopScan() }
    let previous = peripheral
    peripheral = nil
    if let previous, central?.state == .poweredOn { central.cancelPeripheralConnection(previous) }
    connected = false
    control = nil
    statusChar = nil
    audioChar = nil
    assembler = nil
    if !transcribing {
      operationID = UUID()
      process = nil
      status = "Button disconnected"
      detail = "Connect when you want to record again."
    }
    log("DISCONNECT requested")
  }
  private func retryConnection(_ reason: String) {
    closeConnection()
    guard recovery.wanted else { return }
    recovery.failed()
    errorMessage = nil
    if !transcribing { status = "Reconnecting to Dotlet…" }
    detail = "\(reason) Reconnecting automatically; the microphone stays off."
    log("RECONNECT scheduled reason=\(reason)")
  }
  func setEnabled(_ value: Bool) {
    errorMessage = nil
    if value {
      guard ready, !busy else { return }
      recordingSession.enable()
      armNextClip()
    } else {
      recordingSession.pause()
      write(2)
      enabled = false
      status = recording ? "Stopping recording…" : "Button paused"
      detail =
        recording
        ? "Waiting for the button to confirm it has stopped."
        : "Enable once to keep the button ready for repeated recordings."
    }
  }
  private func armNextClip() {
    guard recordingSession.shouldArm(ready: ready, busy: busy, armed: enabled) else { return }
    recordingSession.armRequested()
    status = "Enabling button…"
    write(1)
    deadline = Date().addingTimeInterval(5)
  }
  private func write(_ byte: UInt8) {
    guard let p = peripheral, let c = control, p.state == .connected else { return }
    p.writeValue(Data([byte]), for: c, type: .withResponse)
  }
  private func tick() {
    if recovery.shouldRetry(), central?.state == .poweredOn, peripheral == nil, !scanning {
      scan()
    }
    if scanning && Date() > scanDeadline {
      retryConnection("Keep the button powered and nearby.")
      return
    }
    if peripheral != nil && !ready && Date() > scanDeadline {
      retryConnection("Accept pairing if macOS asks.")
      return
    }
    if enabled || recording { write(3) }
    // Supervision normally detects radio loss; an idle read also catches a
    // connected peripheral whose application has stopped responding.
    if ready, !busy, !enabled {
      if Date().timeIntervalSince(lastStatusAt) > 30 {
        retryConnection("The button stopped responding.")
        return
      }
      if Date().timeIntervalSince(lastStatusPollAt) >= 10, let p = peripheral, let c = statusChar {
        lastStatusPollAt = Date()
        p.readValue(for: c)
      }
    }
    if busy && assembler != nil && Date().timeIntervalSince(transferStarted) > 80 {
      write(2)
      assembler = nil
      busy = false
      recording = false
      fail("The audio transfer timed out. Please enable the button and record again.")
    }
    if recordingSession.arming && Date() > deadline {
      fail("The button did not confirm recording readiness. Please reconnect.")
    }
    if errorMessage == nil { armNextClip() }
  }
  private func fail(_ message: String) {
    recordingSession.pause()
    write(2)
    errorMessage = message
    status = "Needs attention"
    detail = "Your previous recordings are saved on this Mac."
    log("ERROR \(message)")
  }
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    log("BLUETOOTH state=\(central.state.rawValue) wanted=\(recovery.wanted)")
    switch central.state {
    case .poweredOn:
      if recovery.wanted {
        closeConnection()
        recovery.start()
        scan()
      }
    case .unauthorized:
      closeConnection()
      fail(
        "Bluetooth access is off for OpenDotlet. Allow it in System Settings → Privacy & Security → Bluetooth, then reconnect."
      )
    case .poweredOff:
      closeConnection()
      recovery.failed()
      status = "Waiting for Bluetooth…"
      detail = "Turn Bluetooth on; your Dotlet will reconnect automatically."
    case .unsupported:
      closeConnection()
      fail("This Mac does not support the required Bluetooth connection.")
    default:
      closeConnection()
      recovery.failed()
      status = "Preparing Bluetooth…"
    }
  }
  func centralManager(
    _ central: CBCentralManager, didDiscover p: CBPeripheral, advertisementData: [String: Any],
    rssi: NSNumber
  ) {
    guard recovery.wanted, peripheral == nil, scanning else { return }
    if let saved = UserDefaults.standard.string(forKey: "buttonPeripheralID"),
      saved != p.identifier.uuidString
    {
      return
    }
    central.stopScan()
    scanning = false
    attach(p)
    log("FOUND peripheral=\(p.identifier) name=\(p.name ?? "unknown")")
  }
  func centralManager(_ central: CBCentralManager, didConnect p: CBPeripheral) {
    guard recovery.wanted, peripheral === p else {
      central.cancelPeripheralConnection(p)
      return
    }
    connected = true
    lastStatusAt = Date()
    lastStatusPollAt = Date()
    status = "Securing connection…"
    detail = "Accept the macOS Bluetooth pairing request if it appears."
    p.discoverServices([CBUUID(string: Wire.service)])
    log("CONNECTED peripheral=\(p.identifier)")
  }
  func centralManager(_ central: CBCentralManager, didFailToConnect p: CBPeripheral, error: Error?)
  {
    guard peripheral === p else { return }
    retryConnection(error?.localizedDescription ?? "The button is not available yet.")
  }
  func centralManager(
    _ central: CBCentralManager, didDisconnectPeripheral p: CBPeripheral, error: Error?
  ) {
    if peripheral?.identifier == p.identifier {
      retryConnection(error?.localizedDescription ?? "Bluetooth connection interrupted.")
    }
  }
  func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
    guard peripheral === p else { return }
    if let error {
      fail(error.localizedDescription)
      return
    }
    guard let services = p.services, !services.isEmpty else {
      fail(
        "This paired device is using an older Bluetooth service. Remove its old MG24 keyboard pairing in System Settings, then reconnect the Dotlet."
      )
      return
    }
    for service in services {
      p.discoverCharacteristics(
        [CBUUID(string: Wire.control), CBUUID(string: Wire.status), CBUUID(string: Wire.audio)],
        for: service)
    }
  }
  func peripheral(
    _ p: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?
  ) {
    guard peripheral === p else { return }
    if let error {
      fail(error.localizedDescription)
      return
    }
    for c in service.characteristics ?? [] {
      switch c.uuid.uuidString {
      case Wire.control: control = c
      case Wire.status:
        statusChar = c
        p.setNotifyValue(true, for: c)
      case Wire.audio:
        audioChar = c
        p.setNotifyValue(true, for: c)
      default: break
      }
    }
    if let c = statusChar { p.readValue(for: c) }
  }
  func peripheral(
    _ p: CBPeripheral, didUpdateNotificationStateFor c: CBCharacteristic, error: Error?
  ) {
    guard peripheral === p else { return }
    if let error {
      fail("Could not enable Bluetooth audio: \(error.localizedDescription)")
      return
    }
    if statusChar?.isNotifying == true && audioChar?.isNotifying == true, let c = statusChar {
      p.readValue(for: c)
    }
  }
  func peripheral(_ p: CBPeripheral, didWriteValueFor c: CBCharacteristic, error: Error?) {
    guard peripheral === p else { return }
    if let error {
      enabled = false
      fail("The button rejected a command: \(error.localizedDescription)")
    }
  }
  func peripheral(_ p: CBPeripheral, didUpdateValueFor c: CBCharacteristic, error: Error?) {
    guard peripheral === p else { return }
    if let error {
      fail(error.localizedDescription)
      return
    }
    guard let value = c.value else { return }
    do {
      if c.uuid.uuidString == Wire.status {
        try receive(DeviceStatus(value))
      } else if c.uuid.uuidString == Wire.audio {
        guard assembler != nil else {
          throw DotletError.invalid("Audio arrived without its clip details. Please record again.")
        }
        if assembler!.data.isEmpty {
          log("AUDIO PACKET bytes=\(value.count) clip=\(assembler!.status.id)")
        }
        try assembler!.append(value)
        progress = assembler!.progress
      }
    } catch {
      write(2)
      assembler = nil
      busy = false
      recording = false
      enabled = false
      fail(error.localizedDescription)
    }
  }
  private func receive(_ device: DeviceStatus) throws {
    lastStatusAt = Date()
    log(
      "STATUS state=\(device.state) clip=\(device.id) samples=\(device.samples) elapsed=\(device.elapsed) flags=\(device.flags)"
    )
    ready =
      device.encrypted && device.subscribed
      && control != nil && statusChar?.isNotifying == true && audioChar?.isNotifying == true
    guard ready else { return }
    recovery.succeeded()
    if let peripheral {
      UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: "buttonPeripheralID")
    }
    if device.state == 1 || device.state == 2 {
      if activeRecordingSession == nil {
        activeRecordingSession = ProcessInfo.processInfo.beginActivity(
          options: .userInitiatedAllowingIdleSystemSleep,
          reason: "Keep the explicitly enabled Dotlet recording session responsive")
      }
    } else {
      endRecordingActivity()
    }
    switch device.state {
    case 0:
      recordingSession.resetPendingCommand()
      enabled = false
      recording = false
      assembler = nil
      busy = process?.isRunning == true
      if !busy {
        status = "Dotlet connected"
        detail = "Enable once, then hold to speak whenever you like. Pause stops the session."
      }
    case 1:
      recordingSession.resetPendingCommand()
      enabled = true
      busy = false
      recording = false
      status = "Ready when you are"
      detail = "Hold to record. Release to transcribe. It stays ready until you pause."
    case 2:
      recordingSession.resetPendingCommand()
      errorMessage = nil
      enabled = false
      busy = true
      recording = true
      progress = 0
      status = "Listening…"
      detail = "Speak near your Dotlet. Release the key when you finish."
    case 3:
      enabled = false
      recording = false
      busy = true
      status = "Receiving your recording…"
      detail = "The microphone is off. Keep the Dotlet nearby."
      if assembler?.status.id != device.id {
        assembler = try ClipAssembler(status: device)
        transferStarted = Date()
        progress = 0
      }
    case 4:
      guard let assembler, assembler.status.id == device.id else { return }
      let data = try assembler.finish()
      self.assembler = nil
      recording = false
      log("CLIP VERIFIED bytes=\(data.count) checksum=\(device.checksum) transport=BLE")
      transcribe(data, status: device)
    default: throw DotletError.invalid("The button reported a recording error. Please reconnect.")
    }
  }
  private func transcribe(_ data: Data, status device: DeviceStatus) {
    status = "Transcribing on your Mac…"
    detail = "Your audio stays local."
    busy = true
    transcribing = true
    let token = UUID()
    operationID = token
    let id = UUID().uuidString
    let folder = support.appendingPathComponent("Recordings/\(id)", isDirectory: true)
    do {
      try FileManager.default.createDirectory(
        at: folder, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
      try data.write(to: folder.appendingPathComponent("microphone.adc"), options: .atomic)
      try JSONSerialization.data(withJSONObject: device.metadata, options: .prettyPrinted).write(
        to: folder.appendingPathComponent("capture.json"))
    } catch {
      busy = false
      transcribing = false
      fail("Could not save the recording: \(error.localizedDescription)")
      return
    }
    if device.elapsed < 500_000 {
      transcriptionFailed("That tap was too short. Hold the key while speaking, then release it.")
      return
    }
    let worker = Process()
    worker.executableURL = workspace.appendingPathComponent(".venv/bin/python")
    worker.arguments = [
      workspace.appendingPathComponent("tools/transcribe_clip.py").path, "--adc",
      folder.appendingPathComponent("microphone.adc").path, "--metadata",
      folder.appendingPathComponent("capture.json").path, "--models",
      workspace.appendingPathComponent("models").path,
    ]
    worker.environment = ProcessInfo.processInfo.environment.merging([
      "PATH": "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin", "HF_HUB_OFFLINE": "1",
      "HF_HUB_DISABLE_TELEMETRY": "1",
    ]) { _, new in new }
    let output = Pipe()
    worker.standardOutput = output
    let errorURL = folder.appendingPathComponent("transcription.log")
    FileManager.default.createFile(atPath: errorURL.path, contents: nil)
    worker.standardError = try? FileHandle(forWritingTo: errorURL)
    process = worker
    worker.terminationHandler = { [weak self] task in
      let result = output.fileHandleForReading.readDataToEndOfFile()
      DispatchQueue.main.async {
        guard let self, self.operationID == token else { return }
        self.process = nil
        self.busy = false
        self.transcribing = false
        guard task.terminationStatus == 0 else {
          self.transcriptionFailed(
            "Local transcription failed. The audio was saved; show the recordings folder to inspect it."
          )
          return
        }
        do {
          let object = try JSONSerialization.jsonObject(with: result) as? [String: Any]
          let text = object?["text"] as? String ?? ""
          let item = Recording(
            id: id, date: Date(), text: text.isEmpty ? "No speech detected" : text,
            seconds: Double(device.elapsed) / 1_000_000, folder: folder.path)
          self.recordings.insert(item, at: 0)
          self.selectedID = id
          self.save()
          self.status = text.isEmpty ? "No speech detected" : "Thought captured"
          self.detail =
            self.sessionEnabled
            ? "The button will be ready for your next hold."
            : "Button paused. Enable it when you want to record."
          self.log(
            "TRANSCRIPTION COMPLETE clip=\(device.id) words=\(text.split(separator:" ").count)")
        } catch { self.transcriptionFailed("Could not read the local transcription result.") }
      }
    }
    do { try worker.run() } catch {
      process = nil
      busy = false
      transcribing = false
      transcriptionFailed(
        "Local transcription tools could not start. Rebuild OpenDotlet from its workspace.")
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 90) { [weak self, weak worker] in
      guard let self, self.operationID == token, let worker, worker.isRunning else { return }
      self.operationID = UUID()
      worker.terminate()
      self.process = nil
      self.busy = false
      self.transcribing = false
      self.transcriptionFailed("Transcription timed out. The audio is saved on this Mac.")
    }
  }
  private func transcriptionFailed(_ message: String) {
    busy = false
    transcribing = false
    errorMessage = message
    status = "Recording needs another try"
    detail = "The audio is saved on this Mac."
    log("TRANSCRIPTION ERROR \(message)")
    // A rejected tap or local worker failure does not revoke the user's
    // continuous hold-to-record session. The next physical hold retries.
    armNextClip()
  }
  private func endRecordingActivity() {
    if let activeRecordingSession { ProcessInfo.processInfo.endActivity(activeRecordingSession) }
    activeRecordingSession = nil
  }
  private func load() {
    if let bytes = try? Data(contentsOf: support.appendingPathComponent("recordings.json")),
      let items = try? JSONDecoder().decode([Recording].self, from: bytes)
    {
      recordings = items
      selectedID = items.first?.id
    }
  }
  private func save() {
    do {
      try FileManager.default.createDirectory(
        at: support, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
      try JSONEncoder().encode(recordings).write(
        to: support.appendingPathComponent("recordings.json"), options: .atomic)
    } catch { fail("Could not save the transcript list.") }
  }
  func reveal() {
    if let selected {
      NSWorkspace.shared.selectFile(
        URL(fileURLWithPath: selected.folder).appendingPathComponent("microphone.wav").path,
        inFileViewerRootedAtPath: selected.folder)
    }
  }
  func revealAll() {
    try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
    NSWorkspace.shared.open(support)
  }
  func copyTranscript() {
    guard let selected else { return }
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(selected.text, forType: .string)
  }
}
