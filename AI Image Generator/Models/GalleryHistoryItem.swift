import Foundation

enum GalleryItemStatus: String, Codable {
    case pending = "pending"
    case success = "success"
    case failed = "failed"
}

struct GalleryHistoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    var imagePath: String
    let prompt: String
    let timestamp: Date
    let isAIGenerated: Bool
    let originalImagePath: String?
    var taskId: String?
    var status: GalleryItemStatus

    init(
        id: UUID = UUID(),
        imagePath: String,
        prompt: String,
        timestamp: Date = Date(),
        isAIGenerated: Bool = true,
        originalImagePath: String? = nil,
        taskId: String? = nil,
        status: GalleryItemStatus = .success
    ) {
        self.id = id
        self.imagePath = imagePath
        self.prompt = prompt
        self.timestamp = timestamp
        self.isAIGenerated = isAIGenerated
        self.originalImagePath = originalImagePath
        self.taskId = taskId
        self.status = status
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

struct GalleryHistory: Codable {
    var items: [GalleryHistoryItem]
    let version: String
    let lastUpdated: Date

    init(items: [GalleryHistoryItem] = []) {
        self.items = items
        self.version = "1.0"
        self.lastUpdated = Date()
    }
}
