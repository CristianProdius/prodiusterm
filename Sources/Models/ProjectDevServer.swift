import Foundation
import GRDB

struct ProjectDevServer: Identifiable, Codable {
    var id: String
    var projectId: String
    var name: String
    var type: DevServerType
    var command: String
    var port: Int?
    var portEnvVar: String?
    var sortOrder: Int
}

extension ProjectDevServer: FetchableRecord, PersistableRecord {
    static let databaseTableName = "project_dev_servers"

    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case name, type, command, port
        case portEnvVar = "port_env_var"
        case sortOrder = "sort_order"
    }
}
