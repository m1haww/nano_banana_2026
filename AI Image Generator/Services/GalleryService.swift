//
//  GalleryService.swift
//  AI Image Generator
//

import Foundation
import UIKit
import Combine

/// Saves generated images under **Documents/SavedImages/** and appends metadata to **Documents/galleryHistory.json**.
final class GalleryService: ObservableObject {
    static let shared = GalleryService()

    @Published private(set) var galleryHistory: [GalleryHistoryItem] = []
    
    @Published var selectedGalleryItem: GalleryHistoryItem?

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

    @discardableResult
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

    @discardableResult
    func saveImage(from imageURL: URL, withPrompt prompt: String) async -> String? {
        do {
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            let fileName = "\(UUID().uuidString).jpg"
            let fileURL = imagesDirectory.appendingPathComponent(fileName)
            try data.write(to: fileURL)
            let item = GalleryHistoryItem(
                imagePath: fileName,
                prompt: prompt,
                isAIGenerated: true
            )
            await MainActor.run {
                galleryHistory.insert(item, at: 0)
                saveGalleryHistory()
            }
            return fileName
        } catch {
            return nil
        }
    }

    /// Insert a pending placeholder item (no image yet) tied to a backend task ID.
    func addPendingItem(taskId: String, prompt: String) {
        let item = GalleryHistoryItem(
            imagePath: "",
            prompt: prompt,
            taskId: taskId,
            status: .pending
        )
        galleryHistory.insert(item, at: 0)
        saveGalleryHistory()
    }

    /// Update the pending gallery item once the image is ready. Downloads the image, saves it locally.
    @discardableResult
    func completeItem(taskId: String, imageURL: URL) async -> Bool {
        do {
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            let fileName = "\(UUID().uuidString).jpg"
            let fileURL = imagesDirectory.appendingPathComponent(fileName)
            try data.write(to: fileURL)

            await MainActor.run {
                if let index = galleryHistory.firstIndex(where: { $0.taskId == taskId }) {
                    galleryHistory[index].imagePath = fileName
                    galleryHistory[index].status = .success
                    self.selectedGalleryItem = self.galleryHistory[index]
                } else {
                    // Fallback: item was removed — re-add it
                    let item = GalleryHistoryItem(
                        imagePath: fileName,
                        prompt: "",
                        taskId: taskId,
                        status: .success
                    )
                    galleryHistory.insert(item, at: 0)
                    self.selectedGalleryItem = item
                }
                saveGalleryHistory()
            }
            return true
        } catch {
            await MainActor.run {
                markItemFailed(taskId: taskId)
            }
            return false
        }
    }

    /// Mark a pending item as failed.
    func markItemFailed(taskId: String) {
        if let index = galleryHistory.firstIndex(where: { $0.taskId == taskId }) {
            galleryHistory[index].status = .failed
            saveGalleryHistory()
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
