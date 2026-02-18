import Foundation
import GRDB

struct ProjectRepository: Identifiable, Codable {
    var id: String
    var projectId: String
    var name: String
    var path: String
    var isPrimary: Bool
    var sortOrder: Int
}

extension ProjectRepository: FetchableRecord, PersistableRecord {
    static let databaseTableName = "project_repositories"

    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case name, path
        case isPrimary = "is_primary"
        case sortOrder = "sort_order"
    }
}
