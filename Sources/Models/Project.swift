import Foundation
import GRDB

struct Project: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var workingDirectory: String
    var agentType: AgentType
    var defaultModel: String
    var initialPrompt: String?
    var expanded: Bool
    var sortOrder: Int
    var isUncategorized: Bool
    var createdAt: String
    var updatedAt: String
}

extension Project: FetchableRecord, PersistableRecord {
    static let databaseTableName = "projects"

    enum Columns: String, ColumnExpression {
        case id, name
        case workingDirectory = "working_directory"
        case agentType = "agent_type"
        case defaultModel = "default_model"
        case initialPrompt = "initial_prompt"
        case expanded, sortOrder = "sort_order"
        case isUncategorized = "is_uncategorized"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    enum CodingKeys: String, CodingKey {
        case id, name
        case workingDirectory = "working_directory"
        case agentType = "agent_type"
        case defaultModel = "default_model"
        case initialPrompt = "initial_prompt"
        case expanded
        case sortOrder = "sort_order"
        case isUncategorized = "is_uncategorized"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // GRDB stores Bool as Int, handle the conversion
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        workingDirectory = try container.decode(String.self, forKey: .workingDirectory)
        agentType = try container.decodeIfPresent(AgentType.self, forKey: .agentType) ?? .claude
        defaultModel = try container.decodeIfPresent(String.self, forKey: .defaultModel) ?? "sonnet"
        initialPrompt = try container.decodeIfPresent(String.self, forKey: .initialPrompt)
        // Handle Int-to-Bool conversion for SQLite
        let expandedInt = try container.decodeIfPresent(Int.self, forKey: .expanded)
        expanded = (expandedInt ?? 1) != 0
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        let uncatInt = try container.decodeIfPresent(Int.self, forKey: .isUncategorized)
        isUncategorized = (uncatInt ?? 0) != 0
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
    }

    static func new(name: String, workingDirectory: String) -> Project {
        let id = UUID().uuidString.lowercased()
        let now = ISO8601DateFormatter().string(from: Date())
        return Project(
            id: id,
            name: name,
            workingDirectory: workingDirectory,
            agentType: .claude,
            defaultModel: "sonnet",
            expanded: true,
            sortOrder: 0,
            isUncategorized: false,
            createdAt: now,
            updatedAt: now
        )
    }
}
