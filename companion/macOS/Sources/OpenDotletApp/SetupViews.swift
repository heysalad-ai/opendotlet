import AppKit
import DotletCore
import SwiftUI

struct ScreenSetupView: View {
  @ObservedObject var screen: ScreenStore
  @Binding var character: String
  @Binding var name: String
  @AppStorage("faceLibrary") private var libraryName = "opendotlet"
  @AppStorage("previewFaceIndex") private var savedIndex = 0
  private let characters = ["coral", "mint", "sky", "lilac", "sun", "ink", "paper"]
  private var library: FaceLibrary { FaceLibrary(rawValue: libraryName) ?? .opendotlet }
  private var index: Int { library.frames.indices.contains(savedIndex) ? savedIndex : 0 }
  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(alignment: .leading, spacing: 26) {
          if geometry.size.width > 800 {
            HStack(alignment: .top, spacing: 24) {
              identity.frame(maxWidth: .infinity)
              preview.frame(width: 238)
            }
          } else {
            identity
            preview.frame(maxWidth: .infinity)
          }
          libraryPicker
          usbConnection
        }.padding(28).frame(maxWidth: 1100, alignment: .leading).frame(
          maxWidth: .infinity, alignment: .leading)
      }
    }
  }
  private var identity: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("Make it yours.").font(DeckStyle.display(30))
      Text("Pick a character for the app, then choose what appears on the round display.")
        .font(.system(size: 13)).foregroundStyle(DeckStyle.muted).fixedSize(
          horizontal: false, vertical: true)
      VStack(alignment: .leading, spacing: 7) {
        Text("Dotlet name").font(.system(size: 12, weight: .semibold))
        TextField("", text: $name).textFieldStyle(.roundedBorder)
          .inputHint("My Dotlet", empty: name.isEmpty).accessibilityLabel("Dotlet name")
          .onChange(of: name) { _, value in if value.count > 40 { name = String(value.prefix(40)) }
          }
      }
      Text("Character").font(.system(size: 12, weight: .semibold))
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 9)], spacing: 14) {
        ForEach(characters, id: \.self) { colour in
          Button {
            character = colour
            libraryName = "opendotlet"
            savedIndex = 8 + (characters.firstIndex(of: colour) ?? 0)
          } label: {
            VStack(spacing: 7) {
              BrandImage(name: "characters/dotlet-\(colour)").frame(width: 42, height: 42)
                .padding(6).background(
                  character == colour ? DeckStyle.raised : .clear, in: Circle()
                )
                .overlay(
                  Circle().strokeBorder(character == colour ? DeckStyle.ink : .clear, lineWidth: 2))
              Text(colour.capitalized).font(.system(size: 10))
            }
          }.buttonStyle(.plain).accessibilityLabel("\(colour.capitalized) character").help(
            "Preview \(colour.capitalized)")
        }
      }
      Text("App preferences save automatically. Applying to hardware is a separate step below.")
        .font(.system(size: 11)).foregroundStyle(DeckStyle.muted).fixedSize(
          horizontal: false, vertical: true)
    }
  }
  private var preview: some View {
    Surface {
      VStack(spacing: 14) {
        Text("Screen preview").font(.system(size: 12, weight: .semibold)).foregroundStyle(
          DeckStyle.muted)
        previewImage.frame(width: 180, height: 180).background(.black, in: Circle())
          .clipShape(Circle()).overlay(Circle().strokeBorder(Color(hex: "3A3430"), lineWidth: 5))
        Text(library.frames[index].capitalized).font(.system(size: 16, weight: .semibold))
        Text("412 × 412 · \(library.title)").font(.system(size: 10)).foregroundStyle(
          DeckStyle.muted)
        Text("Preview only").font(.system(size: 11, weight: .medium)).foregroundStyle(
          DeckStyle.muted)
      }.frame(maxWidth: .infinity)
    }
  }
  @ViewBuilder private var previewImage: some View {
    if library == .opendotlet {
      BrandImage(name: "faces/\(index < 8 ? "state" : "boot")-\(library.frames[index])-412")
    } else {
      BrandImage(name: "faces/openai-\(index)")
    }
  }
  private var libraryPicker: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Face library").font(DeckStyle.display(19, black: false))
      HStack(spacing: 10) {
        ForEach(FaceLibrary.allCases) { item in
          Button {
            libraryName = item.rawValue
            savedIndex = 0
          } label: {
            HStack(spacing: 9) {
              Image(systemName: library == item ? "checkmark.circle.fill" : "circle")
              VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(.system(size: 13, weight: .semibold))
                Text(item == .opendotlet ? "Original faces · 15 views" : "Event artwork · 28 views")
                  .font(.system(size: 10)).foregroundStyle(DeckStyle.muted)
              }
              Spacer(minLength: 0)
            }.padding(14).background(
              library == item ? DeckStyle.raised : DeckStyle.panel,
              in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
              RoundedRectangle(cornerRadius: 12).strokeBorder(
                library == item ? DeckStyle.ink : DeckStyle.line, lineWidth: 1.5))
          }.buttonStyle(.plain)
        }
      }
      Picker("Face", selection: Binding(get: { index }, set: { savedIndex = $0 })) {
        ForEach(Array(library.frames.enumerated()), id: \.offset) { item in
          Text(item.element.capitalized).tag(item.offset)
        }
      }.pickerStyle(.menu).frame(maxWidth: 390, alignment: .leading)
      Toggle(isOn: $screen.liveFaces) {
        VStack(alignment: .leading, spacing: 3) {
          Text("Live faces").font(.system(size: 13, weight: .semibold))
          Text(
            "The screen follows your Dotlet: listening while you hold the key, thinking while it transcribes or waits for OpenAI, done when a reply lands, then back to your character. Uses the Peel library."
          )
          .font(.system(size: 11)).foregroundStyle(DeckStyle.muted).fixedSize(
            horizontal: false, vertical: true)
        }
      }.toggleStyle(.switch).disabled(library != .opendotlet)
    }
  }
  private var usbConnection: some View {
    Surface {
      VStack(alignment: .leading, spacing: 15) {
        Label("Waveshare display", systemImage: "display").font(
          .system(size: 16, weight: .semibold))
        Text("Connect the round display over USB. It needs the selectable-face-libraries firmware.")
          .font(.system(size: 12)).foregroundStyle(DeckStyle.muted).fixedSize(
            horizontal: false, vertical: true)
        HStack(spacing: 12) {
          Picker("Port", selection: $screen.port) {
            if screen.ports.isEmpty { Text("No USB serial ports found").tag("") }
            ForEach(screen.ports, id: \.self) { port in
              Text(port.replacingOccurrences(of: "/dev/", with: "")).tag(port)
            }
          }.disabled(screen.connected)
          Button {
            screen.refreshPorts()
          } label: {
            Image(systemName: "arrow.clockwise")
          }
          .accessibilityLabel("Refresh serial ports").help("Refresh serial ports").disabled(
            screen.connected)
          Button(screen.maintainingConnection ? "Disconnect" : "Connect screen") {
            if screen.maintainingConnection { screen.disconnect() } else { screen.connect() }
          }.disabled(!screen.maintainingConnection && screen.port.isEmpty)
        }
        Text(screen.status).font(.system(size: 12, weight: .medium))
        if let confirmed = screen.confirmed {
          Text(
            "Last reported: \(confirmed.selection.library.title) · \(confirmed.selection.library.frames[confirmed.selection.index].capitalized)"
          )
          .font(.system(size: 11)).foregroundStyle(DeckStyle.muted)
        }
        if let error = screen.errorMessage { InlineNotice(text: error) }
        Button {
          screen.apply(ScreenSelection(library: library, index: index))
        } label: {
          Label(
            screen.applying ? "Applying…" : "Apply to screen", systemImage: "arrow.down.to.line")
        }.buttonStyle(AccentButtonStyle()).disabled(!screen.ready || screen.applying)
      }
    }
  }
}

struct DeviceSetupView: View {
  @ObservedObject var store: DotletStore
  @ObservedObject var screen: ScreenStore
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        Text("Two devices. One companion.").font(DeckStyle.display(30))
        Surface {
          VStack(alignment: .leading, spacing: 14) {
            Label("Voice button", systemImage: "keyboard").font(
              .system(size: 17, weight: .semibold))
            Text("XIAO MG24 Sense + NeoKey · Bluetooth").font(.system(size: 12)).foregroundStyle(
              DeckStyle.muted)
            Text(store.status).font(.system(size: 14, weight: .medium))
            Text(store.detail).font(.system(size: 12)).foregroundStyle(DeckStyle.muted).fixedSize(
              horizontal: false, vertical: true)
            HStack {
              Button(store.maintainingConnection ? "Disconnect button" : "Connect button") {
                if store.maintainingConnection { store.disconnect() } else { store.connect() }
              }
              Button(store.sessionEnabled ? "Pause button" : "Enable button") {
                store.setEnabled(!store.sessionEnabled)
              }
              .disabled(!store.ready || store.busy)
              if store.recording { Button("Cancel recording") { store.setEnabled(false) } }
            }
            if let error = store.errorMessage { InlineNotice(text: error) }
            Text(
              "Hold to record; release to transcribe locally. Raw audio is never sent to OpenAI by this app."
            )
            .font(.system(size: 11)).foregroundStyle(DeckStyle.muted)
          }
        }
        Surface {
          VStack(alignment: .leading, spacing: 14) {
            Label("Round screen", systemImage: "display").font(.system(size: 17, weight: .semibold))
            Text("Waveshare ESP32-S3-Touch-LCD-1.46 · USB").font(.system(size: 12)).foregroundStyle(
              DeckStyle.muted)
            Text(screen.status).font(.system(size: 13))
            Text(
              "Use Screen setup to choose a face library, preview expressions and apply a face to compatible firmware."
            )
            .font(.system(size: 12)).foregroundStyle(DeckStyle.muted).fixedSize(
              horizontal: false, vertical: true)
          }
        }
        Button {
          store.revealAll()
        } label: {
          Label("Show recordings and chat files", systemImage: "folder")
        }
      }.padding(28).frame(maxWidth: 900, alignment: .leading).frame(
        maxWidth: .infinity, alignment: .leading)
    }
  }
}

struct AISetupView: View {
  @ObservedObject var settings: AISettings
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        BrandImage(name: "symbol").frame(width: 58, height: 58)
        Text("A conversation with your Dotlet.").font(DeckStyle.display(30))
        Text(
          "Connect your OpenAI API key to get replies in chats. Your API account is billed for usage; a ChatGPT subscription is separate."
        )
        .font(.system(size: 13)).foregroundStyle(DeckStyle.muted).fixedSize(
          horizontal: false, vertical: true)
        Surface {
          VStack(alignment: .leading, spacing: 16) {
            Label(
              settings.hasKey ? "Key saved in Keychain" : "No API key saved", systemImage: "key"
            )
            .font(.system(size: 14, weight: .semibold))
            SecureField("", text: $settings.keyDraft)
              .textFieldStyle(.roundedBorder)
              .inputHint(
                settings.hasKey ? "Paste a replacement API key" : "Paste your OpenAI API key",
                empty: settings.keyDraft.isEmpty
              )
              .accessibilityLabel("OpenAI API key")
            HStack {
              Button("Save key in Keychain") { settings.saveKey() }.buttonStyle(AccentButtonStyle())
                .disabled(settings.keyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
              if settings.hasKey { Button("Remove saved key") { settings.removeKey() } }
            }
            Text(
              "The key stays in this Mac’s Keychain. It is not saved in chat history or project files."
            )
            .font(.system(size: 11)).foregroundStyle(DeckStyle.muted)
            Divider().overlay(DeckStyle.line)
            TextField("", text: $settings.model).textFieldStyle(.roundedBorder)
              .inputHint("Model", empty: settings.model.isEmpty).accessibilityLabel("Model")
            Text("Default: gpt-5.4-mini. Use a model available to your API project.")
              .font(.system(size: 11)).foregroundStyle(DeckStyle.muted)
            if let error = settings.errorMessage { InlineNotice(text: error) }
          }
        }
        VStack(alignment: .leading, spacing: 10) {
          Label("You choose what to send", systemImage: "hand.raised").font(
            .system(size: 14, weight: .semibold))
          Text(
            "Send shares the most recent 40 AI messages in the current chat with OpenAI. Save note keeps text local. Voice transcripts stay local until you choose Send transcript to OpenAI. Raw audio is kept on this Mac."
          )
          .font(.system(size: 12)).foregroundStyle(DeckStyle.muted).lineSpacing(4)
          Text(
            "Requests use store: false. The app has no tools, background agents or automatic external actions."
          )
          .font(.system(size: 11)).foregroundStyle(DeckStyle.muted)
        }
      }.padding(28).frame(maxWidth: 800, alignment: .leading).frame(
        maxWidth: .infinity, alignment: .leading)
    }
  }
}
