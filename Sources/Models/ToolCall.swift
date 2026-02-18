import Foundation
import GRDB

enum ToolCallStatus: String, Codable, DatabaseValueConvertible {
    case pending
    case running
    case completed
    case error
}

struct ToolCall: Identifiable, Codable {
    var id: Int64?
    var messageId: Int64
    var sessionId: String
    var toolName: String
    var toolInput: String  // JSON
    var toolResult: String? // JSON
    var status: ToolCallStatus
    var timestamp: String
}

extension ToolCall: FetchableRecord, PersistableRecord {
    static let databaseTableName = "tool_calls"

    enum Columns: String, ColumnExpression {
        case id
        case messageId = "message_id"
        case sessionId = "session_id"
        case toolName = "tool_name"
        case toolInput = "tool_input"
        case toolResult = "tool_result"
        case status, timestamp
    }

    enum CodingKeys: String, CodingKey {
        case id
        case messageId = "message_id"
        case sessionId = "session_id"
        case toolName = "tool_name"
        case toolInput = "tool_input"
        case toolResult = "tool_result"
        case status, timestamp
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
