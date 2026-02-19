import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @State private var showNewProjectSheet = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedProjects, id: \.id) { project in
                    Button {
                        openWindow(id: "project", value: project.id)
                    } label: {
                        ProjectRow(project: project)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        showNewProjectSheet = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                    .help("New Project")
                }
            }
            .sheet(isPresented: $showNewProjectSheet) {
                NewProjectSheet { project in
                    openWindow(id: "project", value: project.id)
                }
            }
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
}

struct ProjectRow: View {
    let project: Project

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: project.isUncategorized ? "tray" : "folder")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .fontWeight(.medium)
                Text(project.workingDirectory)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}
