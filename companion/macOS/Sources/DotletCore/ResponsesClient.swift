import Foundation

public struct ResponsesClient {
  private let session: URLSession
  public init(session: URLSession? = nil) {
    self.session = session ?? URLSession(configuration: .ephemeral)
  }
  public static func request(key: String, model: String, messages: [ChatMessage]) throws
    -> URLRequest
  {
    guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw DotletError.invalid("Add your OpenAI API key in AI settings first.")
    }
    let model = model.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !model.isEmpty, model.count <= 100 else {
      throw DotletError.invalid("Enter a valid model name in AI settings.")
    }
    let history = Array(messages.suffix(40))
    guard !history.isEmpty, history.reduce(0, { $0 + $1.text.count }) <= 64000,
      history.allSatisfy({ $0.text.count <= 16000 })
    else {
      throw DotletError.invalid(
        "This chat is too long to send. Start a new chat or shorten the message.")
    }
    var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
    request.httpMethod = "POST"
    request.timeoutInterval = 90
    request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: [
      "model": model, "store": false, "max_output_tokens": 2048,
      "instructions":
        "You are OpenDotlet, a helpful little desktop companion. Be warm, clear and concise. You can answer questions, but you have no tools or direct access to hardware. Never claim to have changed a screen, accessed files, or performed an action. Raw microphone audio stays on the Mac; you receive only the text explicitly sent by the user.",
      "input": history.map {
        ["role": $0.kind == .assistant ? "assistant" : "user", "content": $0.text]
      },
    ])
    return request
  }
  public static func text(from data: Data, status: Int) throws -> String {
    guard (200..<300).contains(status) else {
      switch status {
      case 401: throw DotletError.invalid("OpenAI rejected the API key. Check it in AI settings.")
      case 403:
        throw DotletError.invalid(
          "This key cannot access the selected model. Check project permissions and model access.")
      case 429:
        throw DotletError.invalid(
          "OpenAI usage or rate limit reached. Check API billing or wait before retrying.")
      case 400, 404:
        throw DotletError.invalid(
          "OpenAI could not use this model or request. Check the model name in AI settings.")
      default:
        throw DotletError.invalid(
          "OpenAI could not complete the request (HTTP \(status)). Your message is saved; try again later."
        )
      }
    }
    guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      object["status"] as? String == "completed",
      let output = object["output"] as? [[String: Any]]
    else {
      throw DotletError.invalid(
        "OpenAI returned an incomplete response. Your message is saved; retry when ready.")
    }
    var text: [String] = []
    for item in output
    where item["type"] as? String == "message" && item["role"] as? String == "assistant" {
      for content in item["content"] as? [[String: Any]] ?? [] {
        if content["type"] as? String == "output_text", let value = content["text"] as? String {
          text.append(value)
        }
        if content["type"] as? String == "refusal", let value = content["refusal"] as? String {
          text.append(value)
        }
      }
    }
    let result = text.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !result.isEmpty else {
      throw DotletError.invalid("OpenAI returned no text. Your message is saved; retry when ready.")
    }
    return result
  }
  public func reply(key: String, model: String, messages: [ChatMessage]) async throws -> String {
    let request = try Self.request(key: key, model: model, messages: messages)
    let (data, response) = try await session.data(for: request)
    guard let response = response as? HTTPURLResponse else {
      throw DotletError.invalid("No valid response from OpenAI.")
    }
    return try Self.text(from: data, status: response.statusCode)
  }
}
