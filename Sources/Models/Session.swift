import Foundation
import GRDB

enum SessionStatus: String, Codable, DatabaseValueConvertible {
    case idle
    case running
    case waiting
    case error
}

/// Matches PROVIDER_IDS from lib/providers/registry.ts exactly
enum AgentType: String, Codable, DatabaseValueConvertible {
    case claude
    case codex
    case opencode
    case gemini
    case aider
    case cursor
    case amp
    case pi
    case shell
}

enum PRStatus: String, Codable, DatabaseValueConvertible {
    case open
    case merged
    case closed
}

enum WorkerStatus: String, Codable, DatabaseValueConvertible {
    case pending
    case running
    case completed
    case failed
}

struct Session: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var tmuxName: String
    var createdAt: String
    var updatedAt: String
    var status: SessionStatus
    var workingDirectory: String
    var parentSessionId: String?
    var claudeSessionId: String?
    var model: String
    var systemPrompt: String?
    var groupPath: String
    var projectId: String?
    var agentType: AgentType
    var autoApprove: Bool

    // Worktree fields
    var worktreePath: String?
    var branchName: String?
    var baseBranch: String?
    var devServerPort: Int?

    // PR tracking
    var prUrl: String?
    var prNumber: Int?
    var prStatus: PRStatus?

    // Orchestration
    var conductorSessionId: String?
    var workerTask: String?
    var workerStatus: WorkerStatus?
}

extension Session: FetchableRecord, PersistableRecord {
    static let databaseTableName = "sessions"

    enum Columns: String, ColumnExpression {
        case id, name, tmuxName = "tmux_name"
        case createdAt = "created_at", updatedAt = "updated_at"
        case status, workingDirectory = "working_directory"
        case parentSessionId = "parent_session_id"
        case claudeSessionId = "claude_session_id"
        case model, systemPrompt = "system_prompt"
        case groupPath = "group_path"
        case projectId = "project_id"
        case agentType = "agent_type"
        case autoApprove = "auto_approve"
        case worktreePath = "worktree_path"
        case branchName = "branch_name"
        case baseBranch = "base_branch"
        case devServerPort = "dev_server_port"
        case prUrl = "pr_url", prNumber = "pr_number", prStatus = "pr_status"
        case conductorSessionId = "conductor_session_id"
        case workerTask = "worker_task", workerStatus = "worker_status"
    }

    enum CodingKeys: String, CodingKey {
        case id, name
        case tmuxName = "tmux_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case status
        case workingDirectory = "working_directory"
        case parentSessionId = "parent_session_id"
        case claudeSessionId = "claude_session_id"
        case model
        case systemPrompt = "system_prompt"
        case groupPath = "group_path"
        case projectId = "project_id"
        case agentType = "agent_type"
        case autoApprove = "auto_approve"
        case worktreePath = "worktree_path"
        case branchName = "branch_name"
        case baseBranch = "base_branch"
        case devServerPort = "dev_server_port"
        case prUrl = "pr_url"
        case prNumber = "pr_number"
        case prStatus = "pr_status"
        case conductorSessionId = "conductor_session_id"
        case workerTask = "worker_task"
        case workerStatus = "worker_status"
    }

    static func new(name: String, projectId: String = "uncategorized", workingDirectory: String = "~", agentType: AgentType = .claude) -> Session {
        let id = UUID().uuidString.lowercased()
        let now = ISO8601DateFormatter().string(from: Date())
        return Session(
            id: id,
            name: name,
            tmuxName: "\(agentType.rawValue)-\(id)",
            createdAt: now,
            updatedAt: now,
            status: .idle,
            workingDirectory: workingDirectory,
            model: "sonnet",
            groupPath: "sessions",
            projectId: projectId,
            agentType: agentType,
            autoApprove: false
        )
    }
}
