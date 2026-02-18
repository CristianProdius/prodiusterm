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

        dbPool = try DatabasePool(path: dbPath, configuration: config)

        try migrator.migrate(dbPool)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        // v1: Initial schema — matches createSchema() in lib/db/schema.ts
        // Includes columns from the base schema only (no migration-added columns yet)
        migrator.registerMigration("v1_initial_schema") { db in
            // Sessions table (base columns only — matches TS schema.ts lines 6-20)
            try db.create(table: "sessions", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("name", .text).notNull()
                t.column("created_at", .text).notNull().defaults(sql: "(datetime('now'))")
                t.column("updated_at", .text).notNull().defaults(sql: "(datetime('now'))")
                t.column("status", .text).notNull().defaults(to: "idle")
                t.column("working_directory", .text).notNull().defaults(to: "~")
                t.column("parent_session_id", .text).references("sessions")
                t.column("claude_session_id", .text)
                t.column("model", .text).defaults(to: "sonnet")
                t.column("system_prompt", .text)
            }

            // Groups table
            try db.create(table: "groups", ifNotExists: true) { t in
                t.primaryKey("path", .text)
                t.column("name", .text).notNull()
                t.column("expanded", .integer).notNull().defaults(to: 1)
                t.column("sort_order", .integer).notNull().defaults(to: 0)
                t.column("created_at", .text).notNull().defaults(sql: "(datetime('now'))")
            }

            // Default group
            try db.execute(sql: "INSERT OR IGNORE INTO groups (path, name, sort_order) VALUES ('sessions', 'Sessions', 0)")

            // Messages table
            try db.create(table: "messages", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("session_id", .text).notNull().references("sessions", onDelete: .cascade)
                t.column("role", .text).notNull()
                t.column("content", .text).notNull()
                t.column("timestamp", .text).notNull().defaults(sql: "(datetime('now'))")
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
                t.column("timestamp", .text).notNull().defaults(sql: "(datetime('now'))")
            }

            // Dev servers table (base columns — no type/name/command/pid/working_directory yet)
            try db.create(table: "dev_servers", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("status", .text).notNull().defaults(to: "stopped")
                t.column("container_id", .text)
                t.column("ports", .text).notNull().defaults(to: "[]")
                t.column("created_at", .text).notNull().defaults(sql: "(datetime('now'))")
                t.column("updated_at", .text).notNull().defaults(sql: "(datetime('now'))")
            }

            // Projects table
            try db.create(table: "projects", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("name", .text).notNull()
                t.column("working_directory", .text).notNull()
                t.column("agent_type", .text).notNull().defaults(to: "claude")
                t.column("default_model", .text).notNull().defaults(to: "sonnet")
                t.column("expanded", .integer).notNull().defaults(to: 1)
                t.column("sort_order", .integer).notNull().defaults(to: 0)
                t.column("is_uncategorized", .integer).notNull().defaults(to: 0)
                t.column("created_at", .text).notNull().defaults(sql: "(datetime('now'))")
                t.column("updated_at", .text).notNull().defaults(sql: "(datetime('now'))")
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

            // Indexes for base columns only
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_messages_session ON messages(session_id)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_tool_calls_session ON tool_calls(session_id)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_tool_calls_message ON tool_calls(message_id)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_sessions_parent ON sessions(parent_session_id)")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_project_dev_servers_project ON project_dev_servers(project_id)")

            // Default Uncategorized project
            try db.execute(sql: """
                INSERT OR IGNORE INTO projects (id, name, working_directory, is_uncategorized, sort_order)
                VALUES ('uncategorized', 'Uncategorized', '~', 1, 999999)
            """)
        }

        // TS migration 1: add group_path to sessions
        migrator.registerMigration("v2_add_group_path") { db in
            try db.alter(table: "sessions") { t in
                t.add(column: "group_path", .text).notNull().defaults(to: "sessions")
            }
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_sessions_group ON sessions(group_path)")
        }

        // TS migration 2: add agent_type to sessions
        migrator.registerMigration("v3_add_agent_type") { db in
            try db.alter(table: "sessions") { t in
                t.add(column: "agent_type", .text).notNull().defaults(to: "claude")
            }
        }

        // TS migration 3: add worktree columns to sessions
        migrator.registerMigration("v4_worktree_columns") { db in
            try db.alter(table: "sessions") { t in
                t.add(column: "worktree_path", .text)
                t.add(column: "branch_name", .text)
                t.add(column: "base_branch", .text)
                t.add(column: "dev_server_port", .integer)
            }
        }

        // TS migration 4: add PR tracking to sessions
        migrator.registerMigration("v5_pr_tracking") { db in
            try db.alter(table: "sessions") { t in
                t.add(column: "pr_url", .text)
                t.add(column: "pr_number", .integer)
                t.add(column: "pr_status", .text)
            }
        }

        // TS migration 5: add group_path index (already created in v2, safe with IF NOT EXISTS)
        migrator.registerMigration("v6_group_path_index") { db in
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_sessions_group ON sessions(group_path)")
        }

        // TS migration 6: add orchestration columns to sessions
        migrator.registerMigration("v7_orchestration") { db in
            try db.alter(table: "sessions") { t in
                t.add(column: "conductor_session_id", .text).references("sessions")
                t.add(column: "worker_task", .text)
                t.add(column: "worker_status", .text)
            }
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_sessions_conductor ON sessions(conductor_session_id)")
        }

        // TS migration 7: add auto_approve to sessions
        migrator.registerMigration("v8_auto_approve") { db in
            try db.alter(table: "sessions") { t in
                t.add(column: "auto_approve", .integer).notNull().defaults(to: 0)
            }
        }

        // TS migration 8: add dev_server columns
        migrator.registerMigration("v9_dev_server_columns") { db in
            try db.alter(table: "dev_servers") { t in
                t.add(column: "type", .text).notNull().defaults(to: "node")
                t.add(column: "name", .text).notNull().defaults(to: "")
                t.add(column: "command", .text).notNull().defaults(to: "")
                t.add(column: "pid", .integer)
                t.add(column: "working_directory", .text).notNull().defaults(to: "")
            }
        }

        // TS migration 9: add project_id to sessions + backfill
        migrator.registerMigration("v10_session_project_id") { db in
            try db.alter(table: "sessions") { t in
                t.add(column: "project_id", .text).references("projects")
            }
            try db.execute(sql: "UPDATE sessions SET project_id = 'uncategorized' WHERE project_id IS NULL")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_sessions_project ON sessions(project_id)")
        }

        // TS migration 10: add project_id to dev_servers + backfill
        migrator.registerMigration("v11_dev_server_project_id") { db in
            try db.alter(table: "dev_servers") { t in
                t.add(column: "project_id", .text).references("projects", onDelete: .cascade)
            }
            // Migrate from session_id if it exists
            let cols = try db.columns(in: "dev_servers")
            if cols.contains(where: { $0.name == "session_id" }) {
                try db.execute(sql: """
                    UPDATE dev_servers
                    SET project_id = (
                        SELECT COALESCE(s.project_id, 'uncategorized')
                        FROM sessions s
                        WHERE s.id = dev_servers.session_id
                    )
                    WHERE project_id IS NULL
                """)
            }
            try db.execute(sql: "UPDATE dev_servers SET project_id = 'uncategorized' WHERE project_id IS NULL")
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_dev_servers_project ON dev_servers(project_id)")
        }

        // TS migration 11: add tmux_name to sessions + backfill
        migrator.registerMigration("v12_tmux_name") { db in
            try db.alter(table: "sessions") { t in
                t.add(column: "tmux_name", .text)
            }
            try db.execute(sql: "UPDATE sessions SET tmux_name = agent_type || '-' || id WHERE tmux_name IS NULL")
        }

        // TS migration 12: add initial_prompt to projects
        migrator.registerMigration("v13_initial_prompt") { db in
            try db.alter(table: "projects") { t in
                t.add(column: "initial_prompt", .text)
            }
        }

        // TS migration 13: add project_repositories table
        migrator.registerMigration("v14_project_repositories") { db in
            try db.create(table: "project_repositories", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("project_id", .text).notNull().references("projects", onDelete: .cascade)
                t.column("name", .text).notNull()
                t.column("path", .text).notNull()
                t.column("is_primary", .integer).notNull().defaults(to: 0)
                t.column("sort_order", .integer).notNull().defaults(to: 0)
            }
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_project_repositories_project ON project_repositories(project_id)")
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

    func createSession(name: String, projectId: String, workingDirectory: String = "~", agentType: AgentType = .claude) throws -> Session {
        let session = Session.new(name: name, projectId: projectId, workingDirectory: workingDirectory, agentType: agentType)
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
        let project = Project.new(name: name, workingDirectory: workingDirectory)
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

    // MARK: - Group Queries

    func fetchAllGroups() throws -> [Group] {
        try dbPool.read { db in
            try Group.order(Group.Columns.sortOrder.asc).fetchAll(db)
        }
    }
}
