import SwiftUI

struct TerminalContainerView: View {
    let session: Session
    @ObservedObject var terminalManager: TerminalSessionManager
    @State private var currentTheme = TerminalThemeRegistry.shared.theme(for: "dark-deep")

    var body: some View {
        VStack(spacing: 0) {
            // Terminal toolbar
            TerminalToolbar(session: session, theme: $currentTheme)

            // Terminal view
            SwiftTermView(
                session: session,
                terminalManager: terminalManager,
                theme: currentTheme
            )
        }
        .background(Color(nsColor: currentTheme.background))
    }
}

struct TerminalToolbar: View {
    let session: Session
    @Binding var theme: TerminalTheme

    @State private var showThemePicker = false

    var body: some View {
        HStack {
            // Session info
            HStack(spacing: 6) {
                Image(systemName: "terminal")
                    .foregroundStyle(.secondary)
                Text(session.name)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }

            Spacer()

            // Status
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                Text(session.status.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Theme picker
            Menu {
                Section("Dark Themes") {
                    ForEach(Array(TerminalThemeRegistry.shared.darkThemes.keys.sorted()), id: \.self) { key in
                        Button(key.capitalized) {
                            theme = TerminalThemeRegistry.shared.darkThemes[key]!
                        }
                    }
                }
                Section("Light Themes") {
                    ForEach(Array(TerminalThemeRegistry.shared.lightThemes.keys.sorted()), id: \.self) { key in
                        Button(key.capitalized) {
                            theme = TerminalThemeRegistry.shared.lightThemes[key]!
                        }
                    }
                }
            } label: {
                Image(systemName: "paintpalette")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }

    private var statusColor: Color {
        switch session.status {
        case .idle: .secondary
        case .running: .green
        case .waiting: .yellow
        case .error: .red
        }
    }
}
