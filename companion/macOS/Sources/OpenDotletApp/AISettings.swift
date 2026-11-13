import Combine
import Foundation
import Security

@MainActor
final class AISettings: ObservableObject {
  @Published var hasKey = false
  @Published var errorMessage: String?
  @Published var keyDraft = ""
  @Published var model: String =
    UserDefaults.standard.string(forKey: "openAIModel") ?? "gpt-5.4-mini"
  {
    didSet { UserDefaults.standard.set(model, forKey: "openAIModel") }
  }
  private let service = "com.heysalad.opendotlet.openai"
  init() { hasKey = (try? readKey()) != nil }
  func readKey() throws -> String? {
    var result: CFTypeRef?
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service, kSecAttrAccount as String: "api-key",
      kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess, let data = result as? Data,
      let key = String(data: data, encoding: .utf8)
    else {
      throw NSError(
        domain: "Keychain", code: Int(status),
        userInfo: [
          NSLocalizedDescriptionKey: "OpenDotlet could not read its API key from Keychain."
        ])
    }
    return key
  }
  func saveKey() {
    let value = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty, !value.contains(where: { $0.isWhitespace }) else {
      errorMessage = "Paste an API key without spaces or line breaks."
      return
    }
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service, kSecAttrAccount as String: "api-key",
    ]
    var status = SecItemUpdate(
      query as CFDictionary, [kSecValueData as String: Data(value.utf8)] as CFDictionary)
    if status == errSecItemNotFound {
      var item = query
      item[kSecValueData as String] = Data(value.utf8)
      item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
      status = SecItemAdd(item as CFDictionary, nil)
    }
    guard status == errSecSuccess else {
      errorMessage = "The key could not be saved in Keychain."
      return
    }
    keyDraft = ""
    hasKey = true
    errorMessage = nil
  }
  func removeKey() {
    let status = SecItemDelete(
      [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service, kSecAttrAccount as String: "api-key",
      ] as CFDictionary)
    if status == errSecSuccess || status == errSecItemNotFound {
      hasKey = false
      errorMessage = nil
    } else {
      errorMessage = "The saved key could not be removed from Keychain."
    }
  }
}
