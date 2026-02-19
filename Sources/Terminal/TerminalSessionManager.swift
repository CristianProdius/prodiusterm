import Foundation
import SwiftTerm

/// Manages multiple terminal sessions, each backed by a local PTY process
@MainActor
final class TerminalSessionManager {
    var terminals: [String: TerminalInstance] = [:]

    func createTerminal(
        terminalId: String,
        workingDirectory: String = "~",
        shell: String? = nil,
        command: String? = nil,
        envOverrides: [String: String] = [:]
    ) -> TerminalInstance {
        let terminal = TerminalInstance(
            terminalId: terminalId,
            workingDirectory: workingDirectory,
            shell: shell,
            command: command,
            envOverrides: envOverrides
        )
        terminals[terminalId] = terminal
        return terminal
    }

    func removeTerminal(terminalId: String) {
        terminals[terminalId]?.stop()
        terminals.removeValue(forKey: terminalId)
    }

    func terminal(for terminalId: String) -> TerminalInstance? {
        terminals[terminalId]
    }
}

/// Wraps a SwiftTerm LocalProcessTerminalView with session metadata
@MainActor
final class TerminalInstance {
    let terminalId: String
    let workingDirectory: String
    let shell: String
    let command: String?
    let envOverrides: [String: String]

    private var hasStarted = false
    private var didBootstrap = false

    init(
        terminalId: String,
        workingDirectory: String,
        shell: String? = nil,
        command: String? = nil,
        envOverrides: [String: String] = [:]
    ) {
        self.terminalId = terminalId
        self.workingDirectory = resolveHome(workingDirectory)
        self.shell = shell ?? ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        self.command = command
        self.envOverrides = envOverrides
    }

    func stop() {
        // LocalProcessTerminalView handles cleanup when removed from view hierarchy
    }

    func startIfNeeded(on terminalView: LocalProcessTerminalView) {
        guard !hasStarted else { return }
        hasStarted = true

        terminalView.startProcess(
            executable: shell,
            args: [],
            environment: environment,
            execName: "-" + (shell as NSString).lastPathComponent // Login shell
        )

        bootstrapIfNeeded(on: terminalView)
    }

    func bootstrapIfNeeded(on terminalView: LocalProcessTerminalView) {
        guard !didBootstrap else { return }
        didBootstrap = true

        if workingDirectory != "/" && workingDirectory != (ProcessInfo.processInfo.environment["HOME"] ?? "/") {
            let escapedPath = workingDirectory.replacingOccurrences(of: "'", with: "'\\''")
            terminalView.send(txt: "cd '\(escapedPath)'\r")
        }

        if let command, !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            terminalView.send(txt: "\(command)\r")
        }
    }

    /// Build minimal environment for the shell process, matching current server.ts behavior
    var environment: [String] {
        let env = ProcessInfo.processInfo.environment
        var merged: [String: String] = [
            "PATH": env["PATH"] ?? "/usr/local/bin:/usr/bin:/bin",
            "HOME": env["HOME"] ?? "/",
            "USER": env["USER"] ?? "",
            "SHELL": shell,
            "TERM": "xterm-256color",
            "COLORTERM": "truecolor",
            "LANG": env["LANG"] ?? "en_US.UTF-8",
        ]
        for (key, value) in envOverrides { merged[key] = value }
        return merged.map { "\($0.key)=\($0.value)" }
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
