import Foundation

public struct AgentProfile: Codable, Identifiable, Equatable {
  public var id = UUID().uuidString
  public var name: String
  public var role: String
  public var backendRoot: String
  public var configurationFile: String
  public init(name: String, role: String, backendRoot: String, configurationFile: String) {
    self.name = name
    self.role = role
    self.backendRoot = backendRoot
    self.configurationFile = configurationFile
  }
  public func duplicate() -> AgentProfile {
    AgentProfile(
      name: name + " copy", role: role, backendRoot: backendRoot,
      configurationFile: configurationFile)
  }
}

public struct AgentMessage: Decodable, Identifiable {
  public var id: String
  public var role: String
  public var text: String
}
public struct AgentActivity: Decodable, Identifiable {
  public var id: String
  public var title: String
  public var status: String
  public var detail: String?
}
public struct AgentJob: Decodable {
  public var id: String
  public var task: String
  public var status: String
  public var result: String?
  public var engine: String?
}
public struct AgentApproval: Decodable, Identifiable {
  public var id: String
  public var reason: String
  public var command: String?
  public var changes: [Change]?
  public var canAccept: Bool?
  public var cwd: String?
  public var grantRoot: String?
  public var network: [String: String]?
  public struct Change: Decodable {
    public var path: String
    public var diff: String
  }
  enum CodingKeys: String, CodingKey {
    case id, reason, command, changes, cwd, network
    case canAccept = "can_accept"
    case grantRoot = "grant_root"
  }
}
public struct AgentCodexState: Decodable {
  public var authenticated: Bool
  public var status: String
  public var pending: [AgentApproval]
}
public struct AgentIdentity: Decodable {
  public var version: Int
  public var agentID: String
  enum CodingKeys: String, CodingKey {
    case version = "protocol"
    case agentID = "agent_id"
  }
}
public struct AgentSnapshot: Decodable {
  public var dotlet: AgentIdentity
  public var status: String
  public var phase: String
  public var workspace: String
  public var permissions: [String: Bool]
  public var computerEnabled: Bool
  public var transcript: [AgentMessage]
  public var activity: [AgentActivity]
  public var job: AgentJob?
  public var codex: AgentCodexState
  enum CodingKeys: String, CodingKey {
    case dotlet, status, phase, workspace, permissions, transcript, activity, job, codex
    case computerEnabled = "computer_enabled"
  }
}

private final class NoAgentRedirects: NSObject, URLSessionTaskDelegate {
  func urlSession(
    _ session: URLSession, task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
    completionHandler: @escaping (URLRequest?) -> Void
  ) { completionHandler(nil) }
}

/// The token authenticates one owned loopback process. It is never persisted.
public final class AgentClient {
  public let base: URL
  private let agentID: String
  private let session: URLSession
  private var token: String?
  public private(set) var apiConfigured = false

  public init(base: URL, agentID: String, session: URLSession? = nil) throws {
    guard base.scheme == "http", base.host == "127.0.0.1", base.port != nil,
      base.user == nil, base.password == nil, base.query == nil, base.fragment == nil,
      base.path.isEmpty || base.path == "/"
    else { throw DotletError.invalid("The agent service must use its owned local connection.") }
    self.base = base
    self.agentID = agentID
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = 5
    self.session =
      session
      ?? URLSession(configuration: configuration, delegate: NoAgentRedirects(), delegateQueue: nil)
  }

  public func bootstrap() async throws -> AgentSnapshot {
    struct Bootstrap: Decodable {
      var token: String
      var apiConfigured: Bool
      var state: AgentSnapshot
      enum CodingKeys: String, CodingKey {
        case token, state
        case apiConfigured = "api_configured"
      }
    }
    let data = try await request("bootstrap")
    let result = try JSONDecoder().decode(Bootstrap.self, from: data)
    try validate(result.state)
    guard !result.token.isEmpty else {
      throw DotletError.invalid("The agent returned an invalid connection token.")
    }
    token = result.token
    apiConfigured = result.apiConfigured
    return result.state
  }

  public func state() async throws -> AgentSnapshot {
    let result = try JSONDecoder().decode(AgentSnapshot.self, from: await request("state"))
    try validate(result)
    return result
  }

  public func post(_ action: String, body: [String: Any] = [:]) async throws {
    guard
      [
        "codex-message", "codex-connect", "codex-approval", "stop-task", "computer-access",
        "workspace",
      ].contains(action)
    else { throw DotletError.invalid("Unsupported agent action.") }
    _ = try await request(action, body: body)
  }

  private func validate(_ state: AgentSnapshot) throws {
    guard state.dotlet.version == 1, state.dotlet.agentID == agentID else {
      token = nil
      throw DotletError.invalid("This service belongs to a different agent. No task was sent.")
    }
  }

  private func request(_ action: String, body: [String: Any]? = nil) async throws -> Data {
    guard action == "bootstrap" || token != nil else {
      throw DotletError.invalid("Connect the agent before sending a task.")
    }
    var request = URLRequest(url: base.appendingPathComponent("api/\(action)"))
    request.cachePolicy = .reloadIgnoringLocalCacheData
    request.setValue(
      base.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/")),
      forHTTPHeaderField: "Origin")
    if let token { request.setValue(token, forHTTPHeaderField: "X-Ambi-Token") }
    if let body {
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try JSONSerialization.data(withJSONObject: body)
    }
    let (data, response) = try await session.data(for: request)
    guard let response = response as? HTTPURLResponse else {
      throw DotletError.invalid("The local agent returned no response.")
    }
    guard response.url?.scheme == base.scheme, response.url?.host == base.host,
      response.url?.port == base.port
    else {
      throw DotletError.invalid("The local agent attempted to redirect its connection.")
    }
    if response.statusCode == 403 { token = nil }
    guard (200..<300).contains(response.statusCode) else {
      let message =
        (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
      throw DotletError.invalid(
        message.map { String($0.prefix(300)) }
          ?? "The local agent request failed (\(response.statusCode)).")
    }
    return data
  }
}
