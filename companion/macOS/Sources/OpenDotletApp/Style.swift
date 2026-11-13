import AppKit
import CoreText
// Native shell lineage: NiceDeck (MIT), OpenStreamDeck contributors.
import SwiftUI

enum DeckStyle {
  static let background = adaptive("FFFFFF", "111312")
  static let sidebar = adaptive("F3F4F3", "191C1A")
  static let panel = adaptive("FFFFFF", "191C1A")
  static let raised = adaptive("E7EAE7", "2A2F2C")
  static let line = adaptive("DCE1DD", "3F4742")
  static let accent = Color(hex: "A4D866")
  static let tint = adaptive("27663F", "A4D866")
  static let ink = adaptive("111312", "FFFFFF")
  static let muted = adaptive("5D655F", "ADB7AF")
  static let shadow = adaptive("111312", "000000")
  private static func adaptive(_ light: String, _ dark: String) -> Color {
    Color(
      nsColor: NSColor(name: nil) { appearance in
        let value = UInt32(
          appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light, radix: 16)!
        return NSColor(
          srgbRed: Double((value >> 16) & 255) / 255,
          green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255, alpha: 1)
      })
  }
}
extension Color {
  init(hex: String) {
    let value = UInt32(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
    self.init(
      red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255,
      blue: Double(value & 255) / 255)
  }
}
/// Dotlet-green primary action with a neutral ink outline.
struct AccentButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) private var enabled
  func makeBody(configuration: Configuration) -> some View {
    let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
    let pressed = configuration.isPressed
    let ink = Color(hex: "111312")
    return configuration.label.font(.system(size: 13, weight: .semibold))
      .foregroundStyle(enabled ? ink : DeckStyle.muted)
      .padding(.horizontal, 16).padding(.vertical, 10)
      .background(shape.fill(enabled ? (pressed ? Color(hex: "91C465") : DeckStyle.accent) : DeckStyle.raised))
      .overlay(shape.strokeBorder(enabled ? ink : DeckStyle.line, lineWidth: 1.5))
      .animation(.easeOut(duration: 0.12), value: pressed)
  }
}
/// Secondary Peel button: panel fill with a 2px ink edge, no shadow.
struct StickerButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) private var enabled
  func makeBody(configuration: Configuration) -> some View {
    let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
    return configuration.label.font(.system(size: 13, weight: .semibold))
      .foregroundStyle(enabled ? DeckStyle.ink : DeckStyle.muted)
      .padding(.horizontal, 14).padding(.vertical, 8)
      .background(shape.fill(configuration.isPressed ? DeckStyle.raised : DeckStyle.panel))
      .overlay(shape.strokeBorder(enabled ? DeckStyle.ink : DeckStyle.line, lineWidth: 2))
  }
}
/// Nunito (SIL OFL 1.1) for display text, bundled under Peel/fonts and registered at launch.
enum PeelFonts {
  static func register() {
    let workspace =
      Bundle.main.object(forInfoDictionaryKey: "OpenDotletWorkspace") as? String
      ?? FileManager.default.currentDirectoryPath
    for name in ["Nunito-Black", "Nunito-ExtraBold"] {
      let bundled = Bundle.main.resourceURL?.appendingPathComponent("Peel/fonts/\(name).ttf")
      let url =
        bundled.flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil }
        ?? URL(fileURLWithPath: workspace + "/assets/Peel/fonts/\(name).ttf")
      CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
  }
}
extension DeckStyle {
  /// Peel display face. Falls back to the system rounded face if Nunito is missing.
  static func display(_ size: CGFloat, black: Bool = true) -> Font {
    NSFont(name: black ? "Nunito-Black" : "Nunito-ExtraBold", size: size) != nil
      ? .custom(black ? "Nunito-Black" : "Nunito-ExtraBold", size: size)
      : .system(size: size, weight: black ? .heavy : .bold, design: .rounded)
  }
}
struct BrandImage: View {
  var name: String
  var body: some View {
    if let image = Self.load(name == "symbol" ? "brand-neutral" : name) {
      Image(nsImage: image).resizable().scaledToFit()
    } else {
      Image(systemName: "face.smiling").resizable().scaledToFit()
    }
  }
  static func load(_ name: String) -> NSImage? {
    let resource = Bundle.main.resourceURL?.appendingPathComponent("Peel/\(name).png")
    if let resource, let image = NSImage(contentsOf: resource) { return image }
    let workspace =
      Bundle.main.object(forInfoDictionaryKey: "OpenDotletWorkspace") as? String
      ?? FileManager.default.currentDirectoryPath
    return NSImage(contentsOfFile: workspace + "/assets/Peel/\(name).png")
  }
}
/// Quiet panel with a neutral separator.
struct Surface<Content: View>: View {
  @ViewBuilder var content: Content
  var body: some View {
    let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
    content.padding(20).frame(maxWidth: .infinity, alignment: .leading)
      .background(shape.fill(DeckStyle.panel))
      .overlay(shape.strokeBorder(DeckStyle.line, lineWidth: 1))
  }
}
struct InlineNotice: View {
  var text: String
  var body: some View {
    Label(text, systemImage: "exclamationmark.triangle")
      .font(.system(size: 12)).foregroundStyle(DeckStyle.ink)
      .fixedSize(horizontal: false, vertical: true).padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(DeckStyle.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
      .textSelection(.enabled)
  }
}

// AppKit-backed SwiftUI fields dim native prompt colours; keep the input native
// and draw a noninteractive accessible-label-hidden hint at the actual token colour.
struct InputHint: ViewModifier {
  var text: String
  var empty: Bool
  var inset: CGFloat
  var size: CGFloat
  func body(content: Content) -> some View {
    content.overlay(alignment: .topLeading) {
      if empty {
        Text(text).font(.system(size: size)).foregroundStyle(DeckStyle.muted)
          .padding(.horizontal, inset).padding(.vertical, inset == 0 ? 0 : 3)
          .allowsHitTesting(false).accessibilityHidden(true)
      }
    }
  }
}
extension View {
  func inputHint(_ text: String, empty: Bool, inset: CGFloat = 6, size: CGFloat = 13) -> some View {
    modifier(InputHint(text: text, empty: empty, inset: inset, size: size))
  }
}
