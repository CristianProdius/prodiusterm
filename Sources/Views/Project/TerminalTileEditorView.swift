import SwiftUI
import AppKit

struct TerminalTileDraft {
    var title: String
    var kind: ProjectTerminalKind
    var workingDirectory: String
    var shell: String?
    var command: String?
    var agentType: AgentType?
    var autoStart: Bool
}

struct TerminalTileEditorView: View {
    let project: Project
    let terminal: ProjectTerminal?
    let onSave: (TerminalTileDraft) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var kind: ProjectTerminalKind
    @State private var workingDirectory: String
    @State private var shell: String
    @State private var command: String
    @State private var agentType: AgentType
    @State private var autoStart: Bool

    init(project: Project, terminal: ProjectTerminal?, onSave: @escaping (TerminalTileDraft) -> Void) {
        self.project = project
        self.terminal = terminal
        self.onSave = onSave
        _title = State(initialValue: terminal?.title ?? "Terminal")
        _kind = State(initialValue: terminal?.kind ?? .shell)
        _workingDirectory = State(initialValue: terminal?.workingDirectory ?? project.workingDirectory)
        _shell = State(initialValue: terminal?.shell ?? "/bin/zsh")
        _command = State(initialValue: terminal?.command ?? "")
        _agentType = State(initialValue: terminal?.agentType ?? .claude)
        _autoStart = State(initialValue: terminal?.autoStart ?? true)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(terminal == nil ? "New Terminal Tile" : "Edit Terminal Tile")
                .font(.headline)

            Form {
                TextField("Title", text: $title)

                Picker("Kind", selection: $kind) {
                    ForEach(ProjectTerminalKind.allCases, id: \.self) { kind in
                        Text(kind.rawValue.capitalized).tag(kind)
                    }
                }

                HStack {
                    TextField("Working Directory", text: $workingDirectory)
                    Button("Choose...") {
                        chooseDirectory()
                    }
                }

                if kind == .agent {
                    Picker("Agent", selection: $agentType) {
                        ForEach(agentOptions, id: \.0) { option in
                            Text(option.label).tag(option.agent)
                        }
                    }
                }

                TextField("Shell", text: $shell)

                TextField("Command", text: $command)
                    .textFieldStyle(.roundedBorder)

                Toggle("Auto-start", isOn: $autoStart)
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(terminal == nil ? "Create" : "Save") {
                    let resolvedCommand = resolveCommand()
                    let resolvedWorkingDirectory = workingDirectory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? project.workingDirectory
                        : workingDirectory
                    let draft = TerminalTileDraft(
                        title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Terminal" : title,
                        kind: kind,
                        workingDirectory: resolvedWorkingDirectory,
                        shell: shell.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : shell,
                        command: resolvedCommand,
                        agentType: kind == .agent ? agentType : nil,
                        autoStart: autoStart
                    )
                    onSave(draft)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 520)
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            workingDirectory = url.path
            if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                title = url.lastPathComponent
            }
        }
    }

    private func resolveCommand() -> String? {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        if kind == .agent {
            return defaultCommand(for: agentType)
        }
        return nil
    }

    private func defaultCommand(for agent: AgentType) -> String {
        switch agent {
        case .claude: return "claude"
        case .codex: return "codex"
        case .opencode: return "opencode"
        case .gemini: return "gemini"
        case .aider: return "aider"
        case .cursor: return "cursor-agent"
        case .amp: return "amp"
        case .pi: return "pi"
        case .shell: return ""
        }
    }

    private var agentOptions: [(agent: AgentType, label: String)] {
        [
            (.claude, "Claude"),
            (.codex, "Codex"),
            (.opencode, "OpenCode"),
            (.gemini, "Gemini"),
            (.aider, "Aider"),
            (.cursor, "Cursor"),
            (.amp, "Amp"),
            (.pi, "Pi"),
            (.shell, "Shell"),
        ]
    }
}
