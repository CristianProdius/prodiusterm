import SwiftUI
import SwiftTerm
import AppKit

/// NSViewRepresentable wrapper for SwiftTerm's LocalProcessTerminalView
struct SwiftTermView: NSViewRepresentable {
    let terminal: ProjectTerminal
    let terminalManager: TerminalSessionManager
    let theme: TerminalTheme
    let fontSize: CGFloat

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let terminalView = LocalProcessTerminalView(frame: .zero)
        context.coordinator.terminalView = terminalView

        // Configure terminal appearance
        applyTheme(to: terminalView, theme: theme)

        // Set font
        terminalView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

        // Get or create terminal instance
        let instance = terminalManager.terminal(for: terminal.id)
            ?? terminalManager.createTerminal(
                terminalId: terminal.id,
                workingDirectory: terminal.workingDirectory,
                shell: terminal.shell,
                command: terminal.resolvedCommand,
                envOverrides: terminal.envOverrides
            )

        instance.startIfNeeded(on: terminalView)

        return terminalView
    }

    func updateNSView(_ terminalView: LocalProcessTerminalView, context: Context) {
        applyTheme(to: terminalView, theme: theme)
        terminalView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func applyTheme(to terminalView: LocalProcessTerminalView, theme: TerminalTheme) {
        // Apply ANSI 0-15 color palette
        let colors = theme.ansiColors
        terminalView.installColors(colors)

        // Set foreground/background/cursor/selection
        terminalView.nativeForegroundColor = theme.foreground
        terminalView.nativeBackgroundColor = theme.background
        terminalView.caretColor = theme.cursor
        terminalView.selectedTextBackgroundColor = theme.selectionBackground
    }

    class Coordinator {
        var terminalView: LocalProcessTerminalView?
    }
}
