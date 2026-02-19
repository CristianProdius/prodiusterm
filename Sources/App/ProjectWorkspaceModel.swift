import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class ProjectWorkspaceModel {
    let projectId: String
    private let db: DatabaseManager

    var project: Project?
    var terminals: [ProjectTerminal] = []
    var layouts: [String: ProjectTerminalLayout] = [:]
    var isLoaded = false

    init(projectId: String, database: DatabaseManager) {
        self.projectId = projectId
        self.db = database
    }

    func load() async {
        do {
            project = try db.fetchProject(id: projectId)
            terminals = try db.fetchProjectTerminals(forProject: projectId)
            let layoutList = try db.fetchProjectTerminalLayouts(forProject: projectId)
            layouts = Dictionary(uniqueKeysWithValues: layoutList.map { ($0.terminalId, $0) })

            if terminals.isEmpty, let project {
                let terminal = ProjectTerminal.new(
                    projectId: project.id,
                    title: "Shell",
                    kind: .shell,
                    workingDirectory: project.workingDirectory,
                    shell: nil,
                    command: nil
                )
                try db.insertProjectTerminal(terminal)
                terminals = [terminal]
            }

            ensureLayoutsForTerminals()
            isLoaded = true
        } catch {
            print("Failed to load project workspace: \(error)")
        }
    }

    func createTerminal(
        title: String,
        kind: ProjectTerminalKind,
        workingDirectory: String,
        shell: String?,
        command: String?,
        agentType: AgentType?,
        autoStart: Bool
    ) async {
        let terminal = ProjectTerminal.new(
            projectId: projectId,
            title: title,
            kind: kind,
            workingDirectory: workingDirectory,
            shell: shell,
            command: command,
            agentType: agentType,
            sortOrder: terminals.count,
            autoStart: autoStart
        )
        do {
            try db.insertProjectTerminal(terminal)
            terminals.append(terminal)
            let layout = ProjectTerminalLayout.new(projectId: projectId, terminalId: terminal.id, index: terminals.count - 1)
            layouts[terminal.id] = layout
            try db.upsertProjectTerminalLayout(layout)
        } catch {
            print("Failed to create terminal: \(error)")
        }
    }

    func updateTerminal(_ terminal: ProjectTerminal) async {
        var updated = terminal
        updated.updatedAt = ISO8601DateFormatter().string(from: Date())
        do {
            try db.updateProjectTerminal(updated)
            if let idx = terminals.firstIndex(where: { $0.id == updated.id }) {
                terminals[idx] = updated
            }
        } catch {
            print("Failed to update terminal: \(error)")
        }
    }

    func deleteTerminal(_ terminal: ProjectTerminal) async {
        do {
            try db.deleteProjectTerminal(id: terminal.id)
            terminals.removeAll { $0.id == terminal.id }
            if let layout = layouts[terminal.id] {
                try db.deleteProjectTerminalLayout(id: layout.id)
            }
            layouts.removeValue(forKey: terminal.id)
        } catch {
            print("Failed to delete terminal: \(error)")
        }
    }

    func updateLayout(_ layout: ProjectTerminalLayout) async {
        var updated = layout
        updated.updatedAt = ISO8601DateFormatter().string(from: Date())
        layouts[layout.terminalId] = updated
        do {
            try db.upsertProjectTerminalLayout(updated)
        } catch {
            print("Failed to persist layout: \(error)")
        }
    }

    func bringToFront(terminalId: String) async {
        guard var layout = layouts[terminalId] else { return }
        let maxZ = layouts.values.map { $0.zIndex }.max() ?? 0
        if layout.zIndex == maxZ { return }
        layout.zIndex = maxZ + 1
        await updateLayout(layout)
    }

    func layoutBinding(for terminal: ProjectTerminal) -> Binding<ProjectTerminalLayout> {
        guard let layout = layouts[terminal.id] else {
            let index = terminals.firstIndex(where: { $0.id == terminal.id }) ?? 0
            return .constant(ProjectTerminalLayout.new(projectId: projectId, terminalId: terminal.id, index: index))
        }
        return Binding(
            get: { self.layouts[terminal.id] ?? layout },
            set: { self.layouts[terminal.id] = $0 }
        )
    }

    private func ensureLayoutsForTerminals() {
        let existing = layouts
        var needsPersist: [ProjectTerminalLayout] = []

        for (index, terminal) in terminals.enumerated() {
            if existing[terminal.id] != nil { continue }
            let layout = ProjectTerminalLayout.new(projectId: projectId, terminalId: terminal.id, index: index)
            layouts[terminal.id] = layout
            needsPersist.append(layout)
        }

        if needsPersist.isEmpty { return }
        do {
            try needsPersist.forEach { try db.upsertProjectTerminalLayout($0) }
        } catch {
            print("Failed to create default layouts: \(error)")
        }
    }
}
