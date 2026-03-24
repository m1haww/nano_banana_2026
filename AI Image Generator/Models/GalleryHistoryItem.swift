//
//  GalleryHistoryItem.swift
//  AI Image Generator
//

import Foundation

struct GalleryHistoryItem: Codable, Identifiable {
    let id: UUID
    let imagePath: String
    let prompt: String
    let timestamp: Date
    let isAIGenerated: Bool
    let originalImagePath: String?

    init(
        id: UUID = UUID(),
        imagePath: String,
        prompt: String,
        timestamp: Date = Date(),
        isAIGenerated: Bool = true,
        originalImagePath: String? = nil
    ) {
        self.id = id
        self.imagePath = imagePath
        self.prompt = prompt
        self.timestamp = timestamp
        self.isAIGenerated = isAIGenerated
        self.originalImagePath = originalImagePath
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
