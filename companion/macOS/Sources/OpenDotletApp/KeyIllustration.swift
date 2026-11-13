import SwiftUI

struct KeyIllustration: Decodable {
  let matrixKey: Int
  let name: String
  let kind: String
  let color: String
  let leftEye: String
  let rightEye: String
  private struct Layout: Decodable { let keys: [KeyIllustration] }
  static let all: [KeyIllustration] = {
    let workspace = Bundle.main.object(forInfoDictionaryKey: "OpenDotletWorkspace") as? String
      ?? FileManager.default.currentDirectoryPath
    let url = Bundle.main.resourceURL?.appendingPathComponent("Peel/keypad/layout.json")
    let fallback = URL(fileURLWithPath: workspace + "/assets/Peel/keypad/layout.json")
    guard let data = try? Data(contentsOf: url.flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil } ?? fallback),
          let layout = try? JSONDecoder().decode(Layout.self, from: data) else { return [] }
    return layout.keys
  }()
  static func forKey(_ key: Int) -> KeyIllustration? { all.first { $0.matrixKey == key } }
}

struct IllustratedKeycap: View {
  let key: KeyIllustration
  var body: some View {
    GeometryReader { geometry in
      let size = min(geometry.size.width, geometry.size.height)
      ZStack {
        if key.kind == "blank" || key.kind == "embossed-logo" {
          RoundedRectangle(cornerRadius: size * 0.14)
            .fill(LinearGradient(colors: [Color(hex: key.color), Color(hex: "14181D")], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(RoundedRectangle(cornerRadius: size * 0.14).stroke(.white.opacity(0.1), lineWidth: 1))
          if key.kind == "embossed-logo" {
            BrandImage(name: "keypad/openai-logo").opacity(0.15).padding(size * 0.14)
          }
        } else if key.kind.contains("logo") {
          if key.kind == "white-logo" {
            BrandImage(name: "keypad/openai-logo").colorInvert().clipShape(Circle())
              .background(.white, in: Circle())
          } else {
            BrandImage(name: "keypad/openai-logo").clipShape(Circle())
              .background(Color(hex: "11151A"), in: Circle())
          }
        } else {
          Circle().fill(Color(hex: key.color).gradient)
            .overlay(Circle().strokeBorder(.white.opacity(0.2), lineWidth: 1))
          HStack(spacing: size * 0.12) {
            eye(key.leftEye, size: size)
            eye(key.rightEye, size: size)
          }.foregroundStyle(Color(hex: "15191C"))
        }
      }.frame(width: size, height: size)
        .shadow(color: .black.opacity(0.45), radius: 1, x: 0, y: 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }.accessibilityHidden(true)
  }
  private func eye(_ value: String, size: CGFloat) -> some View {
    Text(value).font(.system(size: size * (value == "•" ? 0.36 : 0.40), weight: .medium, design: .rounded))
      .frame(width: size * 0.26).minimumScaleFactor(0.7)
  }
}
