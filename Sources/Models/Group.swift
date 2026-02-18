import Foundation
import GRDB

struct Group: Identifiable, Codable {
    var path: String
    var name: String
    var expanded: Bool
    var sortOrder: Int
    var createdAt: String

    var id: String { path }
}

extension Group: FetchableRecord, PersistableRecord {
    static let databaseTableName = "groups"

    enum Columns: String, ColumnExpression {
        case path, name, expanded
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }

    enum CodingKeys: String, CodingKey {
        case path, name, expanded
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        path = try container.decode(String.self, forKey: .path)
        name = try container.decode(String.self, forKey: .name)
        let expandedInt = try container.decodeIfPresent(Int.self, forKey: .expanded)
        expanded = (expandedInt ?? 1) != 0
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
    }
}
