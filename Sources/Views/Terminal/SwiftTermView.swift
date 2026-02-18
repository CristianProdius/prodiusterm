import SwiftUI
import SwiftTerm
import AppKit

/// NSViewRepresentable wrapper for SwiftTerm's LocalProcessTerminalView
struct SwiftTermView: NSViewRepresentable {
    let session: Session
    @ObservedObject var terminalManager: TerminalSessionManager
    let theme: TerminalTheme

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let terminalView = LocalProcessTerminalView(frame: .zero)
        context.coordinator.terminalView = terminalView

        // Configure terminal appearance
        applyTheme(to: terminalView, theme: theme)

        // Set font
        terminalView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

        // Get or create terminal instance
        let instance = terminalManager.terminal(for: session.id)
            ?? terminalManager.createTerminal(
                sessionId: session.id,
                workingDirectory: session.workingDirectory
            )

        // Start the shell process
        let shellPath = instance.shell
        let cwd = instance.workingDirectory
        let env = instance.environment

        terminalView.startProcess(
            executable: shellPath,
            args: [],
            environment: env,
            execName: "-" + (shellPath as NSString).lastPathComponent // Login shell
        )

        // Set initial working directory
        if cwd != "/" && cwd != ProcessInfo.processInfo.environment["HOME"] {
            let escapedPath = cwd.replacingOccurrences(of: "'", with: "'\\''")
            terminalView.send(txt: "cd '\(escapedPath)'\r")
        }

        return terminalView
    }

    func updateNSView(_ terminalView: LocalProcessTerminalView, context: Context) {
        applyTheme(to: terminalView, theme: theme)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func applyTheme(to terminalView: LocalProcessTerminalView, theme: TerminalTheme) {
        let terminal = terminalView.getTerminal()

        // Set ANSI colors
        let colors = theme.ansiColors
        for (index, color) in colors.enumerated() {
            terminal.installColors(colors: [color], firstColorIndex: index)
        }

        // Set foreground/background
        terminalView.nativeForegroundColor = theme.foreground
        terminalView.nativeBackgroundColor = theme.background
        terminalView.caretColor = theme.cursor
        terminalView.selectedTextBackgroundColor = theme.selectionBackground
    }

    class Coordinator {
        var terminalView: LocalProcessTerminalView?
    }
}
