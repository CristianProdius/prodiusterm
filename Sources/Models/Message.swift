import Foundation
import GRDB

enum MessageRole: String, Codable, DatabaseValueConvertible {
    case user
    case assistant
}

struct Message: Identifiable, Codable {
    var id: Int64?
    var sessionId: String
    var role: MessageRole
    var content: String // JSON array
    var timestamp: String
    var durationMs: Int?
}

extension Message: FetchableRecord, PersistableRecord {
    static let databaseTableName = "messages"

    enum Columns: String, ColumnExpression {
        case id
        case sessionId = "session_id"
        case role, content, timestamp
        case durationMs = "duration_ms"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case role, content, timestamp
        case durationMs = "duration_ms"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
