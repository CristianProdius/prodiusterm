import SwiftUI
import Observation

@Observable
@MainActor
final class AppState {
    var selectedProject: Project?
    var selectedSession: Session?
    var projects: [Project] = []
    var sessions: [Session] = []
    var isInitialized = false
    var sidebarWidth: CGFloat = 260

    private var db: DatabaseManager?

    func initialize() async {
        do {
            let database = try DatabaseManager()
            self.db = database
            await refreshData()
            isInitialized = true
        } catch {
            print("Failed to initialize database: \(error)")
        }
    }

    var database: DatabaseManager? { db }

    func refreshData() async {
        guard let db else { return }
        do {
            self.projects = try db.fetchAllProjects()
            self.sessions = try db.fetchAllSessions()
        } catch {
            print("Failed to refresh data: \(error)")
        }
    }

    func createSession(name: String, projectId: String?, workingDirectory: String = "~") async -> Session? {
        guard let db else { return nil }
        do {
            let session = try db.createSession(
                name: name,
                projectId: projectId ?? "uncategorized",
                workingDirectory: workingDirectory
            )
            await refreshData()
            self.selectedSession = session
            return session
        } catch {
            print("Failed to create session: \(error)")
            return nil
        }
    }

    func deleteSession(_ session: Session) async {
        guard let db else { return }
        do {
            try db.deleteSession(id: session.id)
            if selectedSession?.id == session.id {
                selectedSession = nil
            }
            await refreshData()
        } catch {
            print("Failed to delete session: \(error)")
        }
    }

    func createProject(name: String, workingDirectory: String) async -> Project? {
        guard let db else { return nil }
        do {
            let project = try db.createProject(name: name, workingDirectory: workingDirectory)
            await refreshData()
            self.selectedProject = project
            return project
        } catch {
            print("Failed to create project: \(error)")
            return nil
        }
    }

    func deleteProject(_ project: Project) async {
        guard let db else { return }
        do {
            try db.deleteProject(id: project.id)
            if selectedProject?.id == project.id {
                selectedProject = nil
            }
            await refreshData()
        } catch {
            print("Failed to delete project: \(error)")
        }
    }

    func updateSessionStatus(_ session: Session, status: SessionStatus) async {
        guard let db else { return }
        do {
            try db.updateSessionStatus(id: session.id, status: status)
            await refreshData()
        } catch {
            print("Failed to update session status: \(error)")
        }
    }

    func sessionsForProject(_ projectId: String) -> [Session] {
        sessions.filter { $0.projectId == projectId }
    }
}
