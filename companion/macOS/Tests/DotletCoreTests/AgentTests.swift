import XCTest

@testable import DotletCore

final class AgentTests: XCTestCase {
  func testDuplicateCopiesConfigurationButCreatesIndependentIdentity() throws {
    let profile = AgentProfile(
      name: "Research", role: "Research carefully", backendRoot: "/local/ambi",
      configurationFile: "/private/config")
    let copy = profile.duplicate()
    XCTAssertNotEqual(profile.id, copy.id)
    XCTAssertEqual(copy.role, profile.role)
    XCTAssertEqual(copy.configurationFile, profile.configurationFile)
    XCTAssertEqual(copy.name, "Research copy")
    XCTAssertEqual(
      try JSONDecoder().decode(AgentProfile.self, from: JSONEncoder().encode(copy)), copy)
  }
  func testRejectsRemoteOrCredentialBearingBackendAddresses() {
    for address in [
      "https://127.0.0.1:9001", "http://example.com:9001", "http://localhost:9001",
      "http://user:password@127.0.0.1:9001", "http://127.0.0.1:9001/path",
      "http://127.0.0.1:9001?token=private",
    ] {
      XCTAssertThrowsError(try AgentClient(base: URL(string: address)!, agentID: "fixture"))
    }
  }
  func testAgentAttributionPersistsWithoutSendingAgentTasksToDirectOpenAIChat() throws {
    var archive = ChatArchive()
    archive.addNote("Agent-only task")
    let message = try XCTUnwrap(archive.selected?.messages.last)
    archive.markSentToAgent(message.id, in: archive.selectedID, agentID: "agent-one")
    XCTAssertTrue(archive.apiMessages(in: archive.selectedID).isEmpty)
    archive.beginCapture()
    archive.addRecording(id: "recording", text: "Physical button task", date: Date())
    archive.markRecordingSentToAgent("recording", agentID: "agent-two")
    let restored = try JSONDecoder().decode(ChatArchive.self, from: JSONEncoder().encode(archive))
    XCTAssertEqual(restored.selected?.messages.first?.sentToAgent, "agent-one")
    XCTAssertEqual(restored.selected?.messages.last?.sentToAgent, "agent-two")
    XCTAssertTrue(restored.apiMessages(in: restored.selectedID).isEmpty)
  }
  func testAuthenticatedOwnedAgentPathAndTaskState() async throws {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [AgentFixtureProtocol.self]
    let client = try AgentClient(
      base: URL(string: "http://127.0.0.1:9001")!, agentID: "fixture",
      session: URLSession(configuration: config))
    let first = try await client.bootstrap()
    XCTAssertEqual(first.dotlet.agentID, "fixture")
    XCTAssertTrue(client.apiConfigured)
    XCTAssertFalse(first.computerEnabled)
    let state = try await client.state()
    XCTAssertEqual(state.transcript.last?.text, "fixture reply")
    try await client.post("stop-task", body: ["client_id": "owned-client"])
    do {
      try await client.post("start")
      XCTFail("Voice startup must not be exposed by the agent adapter")
    } catch {}
  }
  func testForeignAgentIdentityCannotAuthorizeTaskSubmission() async throws {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [AgentFixtureProtocol.self]
    let client = try AgentClient(
      base: URL(string: "http://127.0.0.1:9001")!, agentID: "another-agent",
      session: URLSession(configuration: config))
    do {
      _ = try await client.bootstrap()
      XCTFail("Wrong agent was accepted")
    } catch {}
    do {
      try await client.post("codex-message", body: ["text": "must not send"])
      XCTFail("A foreign service authorized a task")
    } catch {}
  }
}

private final class AgentFixtureProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "127.0.0.1" }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    let state =
      #"{"dotlet":{"protocol":1,"agent_id":"fixture"},"status":"idle","phase":"ready","workspace":"/private/fixture","permissions":{},"computer_enabled":false,"transcript":[{"id":"1","role":"assistant","text":"fixture reply"}],"activity":[],"codex":{"authenticated":true,"status":"ready","pending":[]}}"#
    let bootstrap = request.url?.path == "/api/bootstrap"
    let authenticated = request.value(forHTTPHeaderField: "X-Ambi-Token") == "fixture-process-token"
    XCTAssertEqual(request.value(forHTTPHeaderField: "Origin"), "http://127.0.0.1:9001")
    let status = bootstrap || authenticated ? 200 : 403
    let body =
      bootstrap
      ? "{\"token\":\"fixture-process-token\",\"api_configured\":true,\"state\":\(state)}"
      : (request.url?.path == "/api/state" ? state : "{\"ok\":true}")
    let response = HTTPURLResponse(
      url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: Data(body.utf8))
    client?.urlProtocolDidFinishLoading(self)
  }
  override func stopLoading() {}
}
