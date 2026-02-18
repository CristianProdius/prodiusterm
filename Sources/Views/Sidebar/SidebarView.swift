import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @State private var showNewProjectSheet = false

    var body: some View {
        List(selection: Binding(
            get: { appState.selectedSession?.id },
            set: { newId in
                appState.selectedSession = appState.sessions.first { $0.id == newId }
            }
        )) {
            ForEach(sortedProjects, id: \.id) { project in
                Section(isExpanded: projectExpandedBinding(for: project)) {
                    let projectSessions = appState.sessionsForProject(project.id)
                    if projectSessions.isEmpty {
                        Text("No sessions")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    } else {
                        ForEach(projectSessions) { session in
                            SessionRow(session: session)
                                .tag(session.id)
                                .contextMenu {
                                    sessionContextMenu(session)
                                }
                        }
                    }
                } header: {
                    ProjectHeaderView(project: project)
                }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    Task {
                        _ = await appState.createSession(
                            name: "New Session",
                            projectId: appState.selectedProject?.id ?? "uncategorized"
                        )
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .help("New Session")

                Menu {
                    Button("New Project...") {
                        showNewProjectSheet = true
                    }
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
                .help("New Project")
            }
        }
        .sheet(isPresented: $showNewProjectSheet) {
            NewProjectSheet()
        }
    }

    private var sortedProjects: [Project] {
        appState.projects.sorted { a, b in
            if a.isUncategorized != b.isUncategorized {
                return !a.isUncategorized
            }
            return a.sortOrder < b.sortOrder
        }
    }

    private func projectExpandedBinding(for project: Project) -> Binding<Bool> {
        Binding(
            get: { project.expanded },
            set: { newValue in
                if let db = appState.database {
                    var updated = project
                    updated.expanded = newValue
                    try? db.updateProject(updated)
                    Task { await appState.refreshData() }
                }
            }
        )
    }

    @ViewBuilder
    private func sessionContextMenu(_ session: Session) -> some View {
        Button("Rename...") {
            // TODO: implement rename
        }

        Divider()

        Button("Delete", role: .destructive) {
            Task { await appState.deleteSession(session) }
        }
    }
}

struct ProjectHeaderView: View {
    let project: Project

    var body: some View {
        HStack {
            Image(systemName: project.isUncategorized ? "tray" : "folder")
                .foregroundStyle(.secondary)
            Text(project.name)
                .fontWeight(.medium)
        }
    }
}

struct SessionRow: View {
    let session: Session

    var body: some View {
        HStack(spacing: 8) {
            statusIndicator
            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)
                    .lineLimit(1)
                Text(session.workingDirectory)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
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
