import Foundation
import GRDB

enum ProjectTerminalKind: String, Codable, DatabaseValueConvertible, CaseIterable {
    case shell
    case agent
    case server
    case custom
}

struct ProjectTerminal: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var projectId: String
    var title: String
    var kind: ProjectTerminalKind
    var workingDirectory: String
    var shell: String?
    var command: String?
    var agentType: AgentType?
    var envJson: String?
    var sortOrder: Int
    var autoStart: Bool
    var createdAt: String
    var updatedAt: String
}

extension ProjectTerminal: FetchableRecord, PersistableRecord {
    static let databaseTableName = "project_terminals"

    enum Columns: String, ColumnExpression {
        case id
        case projectId = "project_id"
        case title, kind
        case workingDirectory = "working_directory"
        case shell, command
        case agentType = "agent_type"
        case envJson = "env_json"
        case sortOrder = "sort_order"
        case autoStart = "auto_start"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case title, kind
        case workingDirectory = "working_directory"
        case shell, command
        case agentType = "agent_type"
        case envJson = "env_json"
        case sortOrder = "sort_order"
        case autoStart = "auto_start"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        projectId = try container.decode(String.self, forKey: .projectId)
        title = try container.decode(String.self, forKey: .title)
        kind = try container.decode(ProjectTerminalKind.self, forKey: .kind)
        workingDirectory = try container.decodeIfPresent(String.self, forKey: .workingDirectory) ?? ""
        shell = try container.decodeIfPresent(String.self, forKey: .shell)
        command = try container.decodeIfPresent(String.self, forKey: .command)
        agentType = try container.decodeIfPresent(AgentType.self, forKey: .agentType)
        envJson = try container.decodeIfPresent(String.self, forKey: .envJson)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        let autoStartInt = try container.decodeIfPresent(Int.self, forKey: .autoStart)
        autoStart = (autoStartInt ?? 1) != 0
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
    }

    static func new(
        projectId: String,
        title: String,
        kind: ProjectTerminalKind,
        workingDirectory: String,
        shell: String? = nil,
        command: String? = nil,
        agentType: AgentType? = nil,
        sortOrder: Int = 0,
        autoStart: Bool = true
    ) -> ProjectTerminal {
        let id = UUID().uuidString.lowercased()
        let now = ISO8601DateFormatter().string(from: Date())
        return ProjectTerminal(
            id: id,
            projectId: projectId,
            title: title,
            kind: kind,
            workingDirectory: workingDirectory,
            shell: shell,
            command: command,
            agentType: agentType,
            envJson: nil,
            sortOrder: sortOrder,
            autoStart: autoStart,
            createdAt: now,
            updatedAt: now
        )
    }
}

extension ProjectTerminal {
    var resolvedShell: String {
        shell ?? ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
    }

    var resolvedCommand: String? {
        let trimmed = command?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    var envOverrides: [String: String] {
        guard let envJson,
              let data = envJson.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) else {
            return [:]
        }
        if let dict = object as? [String: String] {
            return dict
        }
        if let dict = object as? [String: Any] {
            return dict.compactMapValues { value in
                if let str = value as? String { return str }
                if let num = value as? NSNumber { return num.stringValue }
                return nil
            }
        }
        return [:]
    }
}
