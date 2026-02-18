import Foundation
import GRDB

final class DatabaseManager: Sendable {
    let dbPool: DatabasePool

    init() throws {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dbDir = appSupportURL.appendingPathComponent("ProdiusTerm", isDirectory: true)
        try FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)

        let dbPath = dbDir.appendingPathComponent("agent-os.db").path
        var config = Configuration()
        config.foreignKeysEnabled = true
        config.prepareDatabase { db in
            db.trace { print("SQL: \($0)") }
        }

        dbPool = try DatabasePool(path: dbPath, configuration: config)

        try migrator.migrate(dbPool)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        // Initial schema — corresponds to createSchema() in the TypeScript codebase
        migrator.registerMigration("v1_initial_schema") { db in
            // Sessions table
            try db.create(table: "sessions", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("name", .text).notNull()
                t.column("created_at", .text).notNull().defaults(sql: "datetime('now')")
                t.column("updated_at", .text).notNull().defaults(sql: "datetime('now')")
                t.column("status", .text).notNull().defaults(to: "idle")
                t.column("working_directory", .text).notNull().defaults(to: "~")
                t.column("parent_session_id", .text).references("sessions", onDelete: .setNull)
                t.column("claude_session_id", .text)
                t.column("model", .text).defaults(to: "sonnet")
                t.column("system_prompt", .text)
                t.column("group_path", .text).notNull().defaults(to: "sessions")
                t.column("agent_type", .text).notNull().defaults(to: "claude")
            }

            // Groups table
            try db.create(table: "groups", ifNotExists: true) { t in
                t.primaryKey("path", .text)
                t.column("name", .text).notNull()
                t.column("expanded", .integer).notNull().defaults(to: 1)
                t.column("sort_order", .integer).notNull().defaults(to: 0)
                t.column("created_at", .text).notNull().defaults(sql: "datetime('now')")
            }

            // Default group
            try db.execute(sql: "INSERT OR IGNORE INTO groups (path, name, sort_order) VALUES ('sessions', 'Sessions', 0)")

            // Messages table
            try db.create(table: "messages", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("session_id", .text).notNull().references("sessions", onDelete: .cascade)
                t.column("role", .text).notNull()
                t.column("content", .text).notNull()
                t.column("timestamp", .text).notNull().defaults(sql: "datetime('now')")
                t.column("duration_ms", .integer)
            }

            // Tool calls table
            try db.create(table: "tool_calls", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("message_id", .integer).notNull().references("messages", onDelete: .cascade)
                t.column("session_id", .text).notNull().references("sessions", onDelete: .cascade)
                t.column("tool_name", .text).notNull()
                t.column("tool_input", .text).notNull()
                t.column("tool_result", .text)
                t.column("status", .text).notNull().defaults(to: "pending")
                t.column("timestamp", .text).notNull().defaults(sql: "datetime('now')")
            }

            // Dev servers table
            try db.create(table: "dev_servers", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("project_id", .text).notNull()
                t.column("type", .text).notNull().defaults(to: "node")
                t.column("name", .text).notNull().defaults(to: "")
                t.column("command", .text).notNull().defaults(to: "")
                t.column("status", .text).notNull().defaults(to: "stopped")
                t.column("pid", .integer)
                t.column("container_id", .text)
                t.column("ports", .text).notNull().defaults(to: "[]")
                t.column("working_directory", .text).notNull().defaults(to: "")
                t.column("created_at", .text).notNull().defaults(sql: "datetime('now')")
                t.column("updated_at", .text).notNull().defaults(sql: "datetime('now')")
            }

            // Projects table
            try db.create(table: "projects", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("name", .text).notNull()
                t.column("working_directory", .text).notNull()
                t.column("agent_type", .text).notNull().defaults(to: "claude")
                t.column("default_model", .text).notNull().defaults(to: "sonnet")
                t.column("initial_prompt", .text)
                t.column("expanded", .integer).notNull().defaults(to: 1)
                t.column("sort_order", .integer).notNull().defaults(to: 0)
                t.column("is_uncategorized", .integer).notNull().defaults(to: 0)
                t.column("created_at", .text).notNull().defaults(sql: "datetime('now')")
                t.column("updated_at", .text).notNull().defaults(sql: "datetime('now')")
            }

            // Project dev servers (configuration templates)
            try db.create(table: "project_dev_servers", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("project_id", .text).notNull().references("projects", onDelete: .cascade)
                t.column("name", .text).notNull()
                t.column("type", .text).notNull().defaults(to: "node")
                t.column("command", .text).notNull()
                t.column("port", .integer)
                t.column("port_env_var", .text)
                t.column("sort_order", .integer).notNull().defaults(to: 0)
            }

            // Project repositories
            try db.create(table: "project_repositories", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("project_id", .text).notNull().references("projects", onDelete: .cascade)
                t.column("name", .text).notNull()
                t.column("path", .text).notNull()
                t.column("is_primary", .integer).notNull().defaults(to: 0)
                t.column("sort_order", .integer).notNull().defaults(to: 0)
            }

            // Add foreign key from dev_servers to projects now that projects table exists
            // (SQLite doesn't enforce FK creation order within same migration)

            // Indexes
            try db.create(indexOn: "messages", columns: ["session_id"], ifNotExists: true)
            try db.create(indexOn: "tool_calls", columns: ["session_id"], ifNotExists: true)
            try db.create(indexOn: "tool_calls", columns: ["message_id"], ifNotExists: true)
            try db.create(indexOn: "sessions", columns: ["parent_session_id"], ifNotExists: true)
            try db.create(indexOn: "project_dev_servers", columns: ["project_id"], ifNotExists: true)
            try db.create(indexOn: "project_repositories", columns: ["project_id"], ifNotExists: true)
            try db.create(indexOn: "sessions", columns: ["project_id"], ifNotExists: true)
            try db.create(indexOn: "sessions", columns: ["group_path"], ifNotExists: true)
            try db.create(indexOn: "sessions", columns: ["conductor_session_id"], ifNotExists: true)
            try db.create(indexOn: "dev_servers", columns: ["project_id"], ifNotExists: true)

            // Default Uncategorized project
            try db.execute(sql: """
                INSERT OR IGNORE INTO projects (id, name, working_directory, is_uncategorized, sort_order)
                VALUES ('uncategorized', 'Uncategorized', '~', 1, 999999)
            """)
        }

        // Migration 3: Worktree columns (migrations 1-2 from TS are in initial schema)
        migrator.registerMigration("v2_worktree_columns") { db in
            if try !db.columns(in: "sessions").contains(where: { $0.name == "worktree_path" }) {
                try db.alter(table: "sessions") { t in
                    t.add(column: "worktree_path", .text)
                    t.add(column: "branch_name", .text)
                    t.add(column: "base_branch", .text)
                    t.add(column: "dev_server_port", .integer)
                }
            }
        }

        // Migration 4: PR tracking
        migrator.registerMigration("v3_pr_tracking") { db in
            if try !db.columns(in: "sessions").contains(where: { $0.name == "pr_url" }) {
                try db.alter(table: "sessions") { t in
                    t.add(column: "pr_url", .text)
                    t.add(column: "pr_number", .integer)
                    t.add(column: "pr_status", .text)
                }
            }
        }

        // Migration 6: Orchestration
        migrator.registerMigration("v4_orchestration") { db in
            if try !db.columns(in: "sessions").contains(where: { $0.name == "conductor_session_id" }) {
                try db.alter(table: "sessions") { t in
                    t.add(column: "conductor_session_id", .text).references("sessions")
                    t.add(column: "worker_task", .text)
                    t.add(column: "worker_status", .text)
                }
            }
        }

        // Migration 7: Auto approve
        migrator.registerMigration("v5_auto_approve") { db in
            if try !db.columns(in: "sessions").contains(where: { $0.name == "auto_approve" }) {
                try db.alter(table: "sessions") { t in
                    t.add(column: "auto_approve", .integer).notNull().defaults(to: 0)
                }
            }
        }

        // Migration 11: tmux name
        migrator.registerMigration("v6_tmux_name") { db in
            if try !db.columns(in: "sessions").contains(where: { $0.name == "tmux_name" }) {
                try db.alter(table: "sessions") { t in
                    t.add(column: "tmux_name", .text)
                }
                try db.execute(sql: "UPDATE sessions SET tmux_name = agent_type || '-' || id WHERE tmux_name IS NULL")
            }
        }

        return migrator
    }

    // MARK: - Session Queries

    func fetchAllSessions() throws -> [Session] {
        try dbPool.read { db in
            try Session.order(Session.Columns.updatedAt.desc).fetchAll(db)
        }
    }

    func fetchSession(id: String) throws -> Session? {
        try dbPool.read { db in
            try Session.fetchOne(db, key: id)
        }
    }

    func fetchSessions(forProject projectId: String) throws -> [Session] {
        try dbPool.read { db in
            try Session
                .filter(Session.Columns.projectId == projectId)
                .order(Session.Columns.updatedAt.desc)
                .fetchAll(db)
        }
    }

    func createSession(name: String, projectId: String, workingDirectory: String = "~") throws -> Session {
        var session = Session.new(name: name, projectId: projectId, workingDirectory: workingDirectory)
        try dbPool.write { db in
            try session.insert(db)
        }
        return session
    }

    func deleteSession(id: String) throws {
        try dbPool.write { db in
            _ = try Session.deleteOne(db, key: id)
        }
    }

    func updateSessionStatus(id: String, status: SessionStatus) throws {
        try dbPool.write { db in
            if var session = try Session.fetchOne(db, key: id) {
                session.status = status
                session.updatedAt = ISO8601DateFormatter().string(from: Date())
                try session.update(db)
            }
        }
    }

    func updateSession(_ session: Session) throws {
        try dbPool.write { db in
            try session.update(db)
        }
    }

    // MARK: - Project Queries

    func fetchAllProjects() throws -> [Project] {
        try dbPool.read { db in
            try Project.order(Project.Columns.sortOrder.asc).fetchAll(db)
        }
    }

    func fetchProject(id: String) throws -> Project? {
        try dbPool.read { db in
            try Project.fetchOne(db, key: id)
        }
    }

    func createProject(name: String, workingDirectory: String) throws -> Project {
        var project = Project.new(name: name, workingDirectory: workingDirectory)
        try dbPool.write { db in
            try project.insert(db)
        }
        return project
    }

    func deleteProject(id: String) throws {
        try dbPool.write { db in
            _ = try Project.deleteOne(db, key: id)
        }
    }

    func updateProject(_ project: Project) throws {
        try dbPool.write { db in
            try project.update(db)
        }
    }

    // MARK: - Message Queries

    func fetchMessages(forSession sessionId: String) throws -> [Message] {
        try dbPool.read { db in
            try Message
                .filter(Message.Columns.sessionId == sessionId)
                .order(Message.Columns.timestamp.asc)
                .fetchAll(db)
        }
    }

    func insertMessage(_ message: inout Message) throws {
        try dbPool.write { db in
            try message.insert(db)
        }
    }

    // MARK: - DevServer Queries

    func fetchDevServers(forProject projectId: String) throws -> [DevServer] {
        try dbPool.read { db in
            try DevServer
                .filter(DevServer.Columns.projectId == projectId)
                .fetchAll(db)
        }
    }
}
