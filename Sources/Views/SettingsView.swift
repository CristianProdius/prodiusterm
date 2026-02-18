import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            TerminalSettingsView()
                .tabItem {
                    Label("Terminal", systemImage: "terminal")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("defaultShell") private var defaultShell = "/bin/zsh"
    @AppStorage("defaultModel") private var defaultModel = "sonnet"

    var body: some View {
        Form {
            TextField("Default Shell", text: $defaultShell)
            Picker("Default Model", selection: $defaultModel) {
                Text("Sonnet").tag("sonnet")
                Text("Opus").tag("opus")
                Text("Haiku").tag("haiku")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("terminalTheme") private var terminalTheme = "dark-deep"
    @AppStorage("terminalFontSize") private var fontSize = 13.0

    var body: some View {
        Form {
            Picker("Theme", selection: $terminalTheme) {
                Section("Dark") {
                    ForEach(Array(TerminalThemeRegistry.shared.darkThemes.keys.sorted()), id: \.self) { key in
                        Text(key.capitalized).tag("dark-\(key)")
                    }
                }
                Section("Light") {
                    ForEach(Array(TerminalThemeRegistry.shared.lightThemes.keys.sorted()), id: \.self) { key in
                        Text(key.capitalized).tag("light-\(key)")
                    }
                }
            }

            Slider(value: $fontSize, in: 10...24, step: 1) {
                Text("Font Size: \(Int(fontSize))pt")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct TerminalSettingsView: View {
    @AppStorage("scrollbackLines") private var scrollbackLines = 10000
    @AppStorage("cursorBlink") private var cursorBlink = true

    var body: some View {
        Form {
            Stepper("Scrollback Lines: \(scrollbackLines)", value: $scrollbackLines, in: 1000...100000, step: 1000)
            Toggle("Cursor Blink", isOn: $cursorBlink)
        }
        .formStyle(.grouped)
        .padding()
    }
}
