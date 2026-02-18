import Foundation
import SwiftTerm

/// Manages multiple terminal sessions, each backed by a local PTY process
@MainActor
final class TerminalSessionManager: ObservableObject {
    @Published var terminals: [String: TerminalInstance] = [:]

    func createTerminal(
        sessionId: String,
        workingDirectory: String = "~",
        shell: String? = nil
    ) -> TerminalInstance {
        let terminal = TerminalInstance(
            sessionId: sessionId,
            workingDirectory: workingDirectory,
            shell: shell
        )
        terminals[sessionId] = terminal
        return terminal
    }

    func removeTerminal(sessionId: String) {
        terminals[sessionId]?.stop()
        terminals.removeValue(forKey: sessionId)
    }

    func terminal(for sessionId: String) -> TerminalInstance? {
        terminals[sessionId]
    }
}

/// Wraps a SwiftTerm LocalProcessTerminalView with session metadata
final class TerminalInstance {
    let sessionId: String
    let workingDirectory: String
    let shell: String

    init(sessionId: String, workingDirectory: String, shell: String? = nil) {
        self.sessionId = sessionId
        self.workingDirectory = resolveHome(workingDirectory)
        self.shell = shell ?? ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
    }

    func stop() {
        // LocalProcessTerminalView handles cleanup when removed from view hierarchy
    }

    /// Build minimal environment for the shell process, matching current server.ts behavior
    var environment: [String] {
        let env = ProcessInfo.processInfo.environment
        return [
            "PATH=\(env["PATH"] ?? "/usr/local/bin:/usr/bin:/bin")",
            "HOME=\(env["HOME"] ?? "/")",
            "USER=\(env["USER"] ?? "")",
            "SHELL=\(shell)",
            "TERM=xterm-256color",
            "COLORTERM=truecolor",
            "LANG=\(env["LANG"] ?? "en_US.UTF-8")",
        ]
    }
}

private func resolveHome(_ path: String) -> String {
    if path == "~" || path.hasPrefix("~/") {
        let home = ProcessInfo.processInfo.environment["HOME"] ?? "/"
        if path == "~" { return home }
        return home + path.dropFirst(1)
    }
    return path
}
