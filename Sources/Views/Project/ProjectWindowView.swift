import SwiftUI

struct ProjectWindowView: View {
    @Environment(AppState.self) private var appState
    let projectId: String
    @State private var model: ProjectWorkspaceModel?

    var body: some View {
        SwiftUI.Group {
            if let model {
                ProjectWorkspaceView(model: model)
            } else {
                ProgressView("Loading project...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: appState.isInitialized) {
            guard appState.isInitialized, model == nil, let db = appState.database else { return }
            let workspace = ProjectWorkspaceModel(projectId: projectId, database: db)
            model = workspace
            await workspace.load()
        }
    }
}

struct ProjectWorkspaceView: View {
    @Bindable var model: ProjectWorkspaceModel
    @State private var terminalManager = TerminalSessionManager()
    @AppStorage("terminalTheme") private var terminalTheme = "dark-deep"
    @AppStorage("terminalFontSize") private var terminalFontSize = 13.0

    @State private var showEditor = false
    @State private var editingTerminal: ProjectTerminal?

    private var theme: TerminalTheme {
        TerminalThemeRegistry.shared.theme(for: terminalTheme)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if model.isLoaded {
                    BentoGridView(
                        model: model,
                        terminalManager: terminalManager,
                        theme: theme,
                        fontSize: terminalFontSize,
                        onEdit: { terminal in
                            editingTerminal = terminal
                            showEditor = true
                        },
                        onDelete: { terminal in
                            Task {
                                await model.deleteTerminal(terminal)
                                terminalManager.removeTerminal(terminalId: terminal.id)
                            }
                        },
                        onLayoutCommit: { layout in
                            Task { await model.updateLayout(layout) }
                        },
                        onBringToFront: { terminalId in
                            Task { await model.bringToFront(terminalId: terminalId) }
                        }
                    )
                } else {
                    ProgressView("Loading terminals...")
                }
            }
            .background(Color(nsColor: theme.background))
            .navigationTitle(model.project?.name ?? "Project")
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        editingTerminal = nil
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .help("Add Terminal Tile")
                }
            }
            .sheet(isPresented: $showEditor) {
                if let project = model.project {
                    TerminalTileEditorView(project: project, terminal: editingTerminal) { draft in
                        Task {
                            if let existing = editingTerminal {
                                var updated = existing
                                updated.title = draft.title
                                updated.kind = draft.kind
                                updated.workingDirectory = draft.workingDirectory
                                updated.shell = draft.shell
                                updated.command = draft.command
                                updated.agentType = draft.agentType
                                updated.autoStart = draft.autoStart
                                await model.updateTerminal(updated)
                            } else {
                                await model.createTerminal(
                                    title: draft.title,
                                    kind: draft.kind,
                                    workingDirectory: draft.workingDirectory,
                                    shell: draft.shell,
                                    command: draft.command,
                                    agentType: draft.agentType,
                                    autoStart: draft.autoStart
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
