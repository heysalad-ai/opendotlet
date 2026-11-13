import XCTest

@testable import DotletCore

final class ResponsesTests: XCTestCase {
  func testRequestIsStatelessTextOnlyAndUsesExpectedEndpoint() throws {
    let messages = [ChatMessage(text: "Hello"), ChatMessage(text: "Hi", kind: .assistant)]
    let request = try ResponsesClient.request(
      key: "test-key", model: "gpt-5.4-mini", messages: messages)
    XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/responses")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
    let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
    XCTAssertEqual(body["store"] as? Bool, false)
    XCTAssertEqual(body["model"] as? String, "gpt-5.4-mini")
    XCTAssertNil(body["tools"])
    let input = body["input"] as! [[String: String]]
    XCTAssertEqual(input.map { $0["role"] }, ["user", "assistant"])
    XCTAssertEqual(input[0]["content"], "Hello")
  }
  func testExtractsTextAfterReasoningAndMultipleOutputMessages() throws {
    let body =
      #"{"status":"completed","output":[{"type":"reasoning","summary":[]},{"type":"message","role":"assistant","content":[{"type":"output_text","text":"Hello"},{"type":"output_text","text":"Peter"}]}]}"#
    XCTAssertEqual(try ResponsesClient.text(from: Data(body.utf8), status: 200), "Hello\nPeter")
  }
  func testAuthenticationRateLimitIncompleteAndEmptyResponsesAreErrors() {
    for status in [400, 401, 403, 404, 429, 500] {
      XCTAssertThrowsError(try ResponsesClient.text(from: Data(), status: status))
    }
    for body in [
      #"{"status":"incomplete","output":[]}"#, #"{"status":"completed","output":[]}"#, "bad json",
    ] {
      XCTAssertThrowsError(try ResponsesClient.text(from: Data(body.utf8), status: 200))
    }
    XCTAssertThrowsError(
      try ResponsesClient.request(
        key: "", model: "gpt-5.4-mini", messages: [ChatMessage(text: "Hi")]))
    XCTAssertThrowsError(
      try ResponsesClient.request(key: "test", model: "", messages: [ChatMessage(text: "Hi")]))
    XCTAssertThrowsError(
      try ResponsesClient.request(
        key: "test", model: "gpt-5.4-mini",
        messages: [ChatMessage(text: String(repeating: "a", count: 16001))]))
  }
  func testRealURLSessionPathWithProtocolFixture() async throws {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [ResponseFixtureProtocol.self]
    let client = ResponsesClient(session: URLSession(configuration: config))
    let text = try await client.reply(
      key: "fixture-not-a-real-key", model: "gpt-5.4-mini",
      messages: [ChatMessage(text: "Fixture request")])
    XCTAssertEqual(text, "Fixture reply")
  }
}

private final class ResponseFixtureProtocol: URLProtocol {
  override class func canInit(with request: URLRequest) -> Bool {
    request.url?.host == "api.openai.com"
  }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    let response = HTTPURLResponse(
      url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1",
      headerFields: ["Content-Type": "application/json"])!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(
      self,
      didLoad: Data(
        #"{"status":"completed","output":[{"type":"message","role":"assistant","content":[{"type":"output_text","text":"Fixture reply"}]}]}"#
          .utf8))
    client?.urlProtocolDidFinishLoading(self)
  }
  override func stopLoading() {}
}
