import Foundation
import GRDB

enum DevServerType: String, Codable, DatabaseValueConvertible {
    case node
    case docker
}

enum DevServerStatus: String, Codable, DatabaseValueConvertible {
    case stopped
    case starting
    case running
    case failed
}

struct DevServer: Identifiable, Codable {
    var id: String
    var projectId: String
    var type: DevServerType
    var name: String
    var command: String
    var status: DevServerStatus
    var pid: Int?
    var containerId: String?
    var ports: String // JSON array
    var workingDirectory: String
    var createdAt: String
    var updatedAt: String
}

extension DevServer: FetchableRecord, PersistableRecord {
    static let databaseTableName = "dev_servers"

    enum Columns: String, ColumnExpression {
        case id
        case projectId = "project_id"
        case type, name, command, status
        case pid
        case containerId = "container_id"
        case ports
        case workingDirectory = "working_directory"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case type, name, command, status
        case pid
        case containerId = "container_id"
        case ports
        case workingDirectory = "working_directory"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
