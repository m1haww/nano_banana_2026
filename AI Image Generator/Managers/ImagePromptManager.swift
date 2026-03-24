//
//  ImagePromptManager.swift
//  AI Image Generator
//

import Foundation
import UIKit
import Combine

final class ImagePromptManager: ObservableObject {
    static let shared = ImagePromptManager()

    @Published var galleryHistory: [GalleryHistoryItem] = []

    private let documentsDirectory: URL
    private let galleryHistoryFileURL: URL
    private let imagesDirectory: URL

    private init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        galleryHistoryFileURL = documentsDirectory.appendingPathComponent("galleryHistory.json")
        imagesDirectory = documentsDirectory.appendingPathComponent("SavedImages")
        createImagesDirectoryIfNeeded()
        loadGalleryHistory()
    }

    private func createImagesDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
            try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        }
    }

    private func saveGalleryHistory() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        let history = GalleryHistory(items: galleryHistory)
        guard let data = try? encoder.encode(history) else { return }
        try? data.write(to: galleryHistoryFileURL)
    }

    private func loadGalleryHistory() {
        guard FileManager.default.fileExists(atPath: galleryHistoryFileURL.path),
              let data = try? Data(contentsOf: galleryHistoryFileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let history = try? decoder.decode(GalleryHistory.self, from: data) {
            galleryHistory = history.items
        }
    }

    func saveImage(_ image: UIImage, withPrompt prompt: String, originalImagePath: String? = nil) -> String? {
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        do {
            try imageData.write(to: fileURL)
            let item = GalleryHistoryItem(
                imagePath: fileName,
                prompt: prompt,
                isAIGenerated: true,
                originalImagePath: originalImagePath
            )
            galleryHistory.insert(item, at: 0)
            saveGalleryHistory()
            return fileName
        } catch {
            return nil
        }
    }

    func loadImage(from fileName: String) -> UIImage? {
        let url = imagesDirectory.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: url.path)
    }

    func removeGalleryItem(id: UUID) {
        guard let index = galleryHistory.firstIndex(where: { $0.id == id }) else { return }
        let item = galleryHistory[index]
        let url = imagesDirectory.appendingPathComponent(item.imagePath)
        try? FileManager.default.removeItem(at: url)
        galleryHistory.remove(at: index)
        saveGalleryHistory()
    }
}
