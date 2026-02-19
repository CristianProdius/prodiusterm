import Foundation
import GRDB

struct ProjectTerminalLayout: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var projectId: String
    var terminalId: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var zIndex: Int
    var isHidden: Bool
    var updatedAt: String
}

extension ProjectTerminalLayout: FetchableRecord, PersistableRecord {
    static let databaseTableName = "project_terminal_layouts"

    enum Columns: String, ColumnExpression {
        case id
        case projectId = "project_id"
        case terminalId = "terminal_id"
        case x, y, width, height
        case zIndex = "z_index"
        case isHidden = "is_hidden"
        case updatedAt = "updated_at"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case terminalId = "terminal_id"
        case x, y, width, height
        case zIndex = "z_index"
        case isHidden = "is_hidden"
        case updatedAt = "updated_at"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        projectId = try container.decode(String.self, forKey: .projectId)
        terminalId = try container.decode(String.self, forKey: .terminalId)
        x = try container.decodeIfPresent(Double.self, forKey: .x) ?? 0
        y = try container.decodeIfPresent(Double.self, forKey: .y) ?? 0
        width = try container.decodeIfPresent(Double.self, forKey: .width) ?? 0.5
        height = try container.decodeIfPresent(Double.self, forKey: .height) ?? 0.5
        zIndex = try container.decodeIfPresent(Int.self, forKey: .zIndex) ?? 0
        let isHiddenInt = try container.decodeIfPresent(Int.self, forKey: .isHidden)
        isHidden = (isHiddenInt ?? 0) != 0
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
    }

    static func new(projectId: String, terminalId: String, index: Int) -> ProjectTerminalLayout {
        let now = ISO8601DateFormatter().string(from: Date())
        let offset = min(Double(index) * 0.04, 0.4)
        let width = 0.48
        let height = 0.38
        return ProjectTerminalLayout(
            id: terminalId,
            projectId: projectId,
            terminalId: terminalId,
            x: min(offset, 1.0 - width),
            y: min(offset, 1.0 - height),
            width: width,
            height: height,
            zIndex: index,
            isHidden: false,
            updatedAt: now
        )
    }
}
