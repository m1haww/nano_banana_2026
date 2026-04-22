import Foundation

enum VideoTaskStatus: String, Codable {
    case pending = "pending"
    case success = "success"
    case failed = "failed"
}

struct VideoTask: Codable, Identifiable {
    let id: String
    let userId: String
    var status: VideoTaskStatus
    let prompt: String
    var fileURL: String?
    let date: Date?
    let createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case status
        case prompt
        case fileURL = "file_url"
        case date
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: String = UUID().uuidString,
        userId: String,
        status: VideoTaskStatus = .pending,
        prompt: String,
        fileURL: String? = nil,
        date: Date? = Date(),
        createdAt: Date? = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.status = status
        self.prompt = prompt
        self.fileURL = fileURL
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        prompt = try container.decode(String.self, forKey: .prompt)
        fileURL = try container.decodeIfPresent(String.self, forKey: .fileURL)

        let statusString = try container.decode(String.self, forKey: .status)
        status = VideoTaskStatus(rawValue: statusString) ?? .pending

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let dateString = try container.decodeIfPresent(String.self, forKey: .date) {
            date = formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
        } else {
            date = nil
        }

        if let createdString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = formatter.date(from: createdString) ?? ISO8601DateFormatter().date(from: createdString)
        } else {
            createdAt = nil
        }

        if let updatedString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = formatter.date(from: updatedString) ?? ISO8601DateFormatter().date(from: updatedString)
        } else {
            updatedAt = nil
        }
    }
}
