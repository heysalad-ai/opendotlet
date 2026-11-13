import Combine
import Darwin
import Foundation

public final class ScreenStore: ObservableObject {
  @Published public var ports: [String] = []
  @Published public var port = ""
  @Published public var connected = false
  @Published public var ready = false
  @Published public var applying = false
  @Published public var status = "No screen connected"
  @Published public var errorMessage: String?
  @Published public var confirmed: ScreenStatus?
  @Published public private(set) var maintainingConnection = false
  /// When on, the screen follows the button and replies (listening, thinking, done…).
  @Published public var liveFaces: Bool =
    UserDefaults.standard.object(forKey: "liveFaces") as? Bool ?? true
  {
    didSet { UserDefaults.standard.set(liveFaces, forKey: "liveFaces") }
  }
  private var descriptor: Int32 = -1
  private var reader: DispatchSourceRead?
  private let queue = DispatchQueue(label: "com.heysalad.opendotlet.screen")
  private var buffer = Data()
  private var generation = UUID()
  private var pending: ScreenSelection?
  private var applyToken = UUID()
  // Our belief about the Peel frame on screen while STATUS replies are in flight.
  private var liveIndex: Int?
  private var awaitingStatus = 0
  private var recovery = ConnectionRecovery()
  private let defaults: UserDefaults
  private var rememberedPort = ""
  private var monitor: Timer?
  private var lastStatusAt = Date()
  private var lastPollAt = Date()

  public init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    rememberedPort = defaults.string(forKey: "screenPort") ?? ""
    port = rememberedPort
    refreshPorts()
    if defaults.bool(forKey: "screenKeepConnected"), !rememberedPort.isEmpty {
      maintainingConnection = true
      recovery.start()
    }
    monitor = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.checkConnection() }
    if let monitor { RunLoop.main.add(monitor, forMode: .common) }
  }
  deinit {
    monitor?.invalidate()
    reader?.cancel()
  }
  public func refreshPorts() {
    ports = ((try? FileManager.default.contentsOfDirectory(atPath: "/dev")) ?? [])
      .filter { $0.hasPrefix("cu.usb") || $0.hasPrefix("cu.SLAB") || $0.hasPrefix("cu.wch") }
      .map { "/dev/\($0)" }.sorted()
    if port.isEmpty { port = ports.first ?? "" }
    if !port.isEmpty, !ports.contains(port) { ports.append(port) }
  }
  public func connect() {
    guard !connected, !port.isEmpty else { return }
    connect(path: port)
  }
  // Explicit path also permits an isolated pseudo-terminal integration test.
  public func connect(path: String) {
    port = path
    rememberedPort = path
    maintainingConnection = true
    defaults.set(path, forKey: "screenPort")
    defaults.set(true, forKey: "screenKeepConnected")
    recovery.start()
    openConnection(path: path)
  }
  private func openConnection(path: String) {
    closeConnection()
    recovery.attemptStarted()
    let fd = Darwin.open(path, O_RDWR | O_NOCTTY | O_NONBLOCK)
    guard fd >= 0 else {
      retryConnection("Could not open the screen port: \(String(cString: strerror(errno)))")
      return
    }
    guard flock(fd, LOCK_EX | LOCK_NB) == 0 else {
      Darwin.close(fd)
      retryConnection("This serial port is already in use. Close its other monitor.")
      return
    }
    var options = termios()
    guard tcgetattr(fd, &options) == 0 else {
      Darwin.close(fd)
      retryConnection("This port is not a serial device.")
      return
    }
    cfmakeraw(&options)
    cfsetspeed(&options, speed_t(B115200))
    options.c_cflag |= tcflag_t(CLOCAL | CREAD)
    guard tcsetattr(fd, TCSANOW, &options) == 0 else {
      Darwin.close(fd)
      retryConnection("Could not configure the serial port.")
      return
    }
    descriptor = fd
    connected = true
    ready = false
    errorMessage = nil
    buffer = Data()
    let token = UUID()
    generation = token
    status = "Checking screen firmware…"
    liveIndex = nil
    awaitingStatus = 1
    lastStatusAt = Date()
    lastPollAt = Date()
    let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
    source.setEventHandler { [weak self] in
      var bytes = [UInt8](repeating: 0, count: 4096)
      let size = Darwin.read(fd, &bytes, bytes.count)
      if size > 0 {
        let chunk = Data(bytes.prefix(size))
        DispatchQueue.main.async {
          guard self?.generation == token else { return }
          self?.receive(chunk)
        }
      } else if size == 0 || (size < 0 && errno != EAGAIN && errno != EINTR) {
        DispatchQueue.main.async {
          guard let self, self.generation == token else { return }
          self.retryConnection("The screen disconnected. Check its USB cable.")
        }
      }
    }
    source.setCancelHandler { Darwin.close(fd) }
    reader = source
    source.resume()
    send("STATUS\n")
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
      guard let self, self.generation == token, !self.ready else { return }
      self.status = "Screen firmware not recognised"
      self.errorMessage =
        "No compatible face-library status received. Use the selectable-face-libraries firmware, and close any other serial monitor."
    }
  }
  public func disconnect() {
    recovery.stop()
    maintainingConnection = false
    defaults.set(false, forKey: "screenKeepConnected")
    closeConnection()
    errorMessage = nil
  }
  private func closeConnection() {
    generation = UUID()
    reader?.cancel()
    reader = nil
    descriptor = -1
    connected = false
    ready = false
    applying = false
    pending = nil
    confirmed = nil
    liveIndex = nil
    awaitingStatus = 0
    status = "No screen connected"
  }
  private func retryConnection(_ reason: String) {
    closeConnection()
    guard recovery.wanted else { return }
    recovery.failed()
    status = "Reconnecting to screen…"
    errorMessage = "\(reason) Retrying automatically on the same port."
  }
  private func checkConnection() {
    if !connected, recovery.shouldRetry() {
      // Never fall back to the first USB port: it may be the microphone board.
      openConnection(path: rememberedPort)
    } else if connected {
      if Date().timeIntervalSince(lastStatusAt) > 15 {
        retryConnection("The screen stopped responding.")
      } else if !applying, Date().timeIntervalSince(lastPollAt) >= 5 {
        lastPollAt = Date()
        awaitingStatus += 1
        send("STATUS\n")
      }
    }
  }
  /// Moves the screen to a Peel frame for live state. Unlike `apply`, this does not
  /// wait for confirmation; each command ends with STATUS so the app resynchronises.
  public func show(index: Int) {
    guard liveFaces, ready, !applying else { return }
    let current =
      liveIndex.map { ScreenSelection(library: .opendotlet, index: $0) } ?? confirmed?.selection
    if current == ScreenSelection(library: .opendotlet, index: index), confirmed?.autoplay == false
    {
      return
    }
    guard let commands = LiveFace.commands(to: index, from: current) else { return }
    liveIndex = index
    awaitingStatus += 1
    send(commands)
  }
  public func apply(_ selection: ScreenSelection) {
    guard ready, !applying else { return }
    do {
      let commands = try selection.commands()
      let requestID = UUID()
      applyToken = requestID
      errorMessage = nil
      pending = selection
      applying = true
      status = "Applying face…"
      awaitingStatus += 1
      send(commands)
      let token = generation
      DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
        guard let self, self.generation == token, self.applyToken == requestID, self.applying else {
          return
        }
        self.pending = nil
        self.applying = false
        self.status = "Face not confirmed"
        self.errorMessage =
          "The screen did not confirm this face. Check the display and try Apply again."
      }
    } catch { errorMessage = error.localizedDescription }
  }
  private func send(_ string: String) {
    let fd = descriptor
    let token = generation
    let data = Data(string.utf8)
    queue.async { [weak self] in
      let result: Bool = data.withUnsafeBytes { bytes in
        guard let base = bytes.baseAddress else { return true }
        var written = 0
        while written < bytes.count {
          let count = Darwin.write(fd, base.advanced(by: written), bytes.count - written)
          if count > 0 {
            written += count
          } else if count < 0 && errno == EINTR {
            continue
          } else {
            return false
          }
        }
        return true
      }
      if !result {
        DispatchQueue.main.async {
          guard let self, self.generation == token else { return }
          self.retryConnection("Could not send the face command.")
        }
      }
    }
  }
  private func receive(_ chunk: Data) {
    buffer.append(chunk)
    if buffer.count > 65536 {
      buffer = Data()
      errorMessage = "Screen sent an oversized response. Reconnect it."
      return
    }
    while let newline = buffer.firstIndex(of: 10) {
      let line = String(decoding: buffer.prefix(upTo: newline), as: UTF8.self)
      buffer.removeSubrange(...newline)
      guard let device = ScreenStatus.parse(line) else { continue }
      lastStatusAt = Date()
      recovery.succeeded()
      confirmed = device
      if awaitingStatus > 0 { awaitingStatus -= 1 }
      if awaitingStatus == 0 {
        liveIndex = device.selection.library == .opendotlet ? device.selection.index : nil
      }
      ready = true
      if let pending {
        if device.selection == pending && !device.autoplay {
          self.pending = nil
          applying = false
          status = "Face confirmed by screen"
          errorMessage = nil
        }
      } else {
        status = "Screen ready · \(device.selection.library.title)"
        errorMessage = nil
      }
    }
  }
}
