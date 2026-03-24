//
//  CreateViewModel.swift
//  AI Image Generator
//

import SwiftUI
import UIKit
import Combine

@MainActor
final class CreateViewModel: ObservableObject {
    @Published var prompt: String = ""
    @Published var referenceImage: UIImage?
    @Published var generatedImage: UIImage?
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    @Published var didJustGenerate: Bool = false
    /// Aspect ratio sent to API (e.g. "1:1", "16:9"). Must match Poyo/Nano Banana 2 allowed values.
    @Published var aspectRatio: String = "1:1"

    private let api = GeminiAPIService.shared
    private let gallery = ImagePromptManager.shared

    func clearReferenceImage() {
        referenceImage = nil
    }

    func setReferenceImage(_ image: UIImage?) {
        referenceImage = image
    }

    func generate() async {
        let text = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            errorMessage = "Enter a prompt"
            return
        }

        errorMessage = nil
        generatedImage = nil
        isGenerating = true
        didJustGenerate = false

        performGenerate(prompt: text, aspectRatio: aspectRatio)
    }

    private func performGenerate(prompt: String, aspectRatio: String) {
        api.createImage(prompt: prompt, image: referenceImage, aspectRatio: aspectRatio) { [weak self] result in
            guard let self = self else { return }
            self.isGenerating = false

            switch result {
            case .success(let response):
                if let images = response.result.images,
                   let first = images.first,
                   let img = first.toUIImage() {
                    self.generatedImage = img
                    self.didJustGenerate = true
                    if self.gallery.saveImage(img, withPrompt: prompt, originalImagePath: nil) != nil {
                        // saved to gallery
                    }
                } else if let text = response.result.text {
                    self.errorMessage = "No image: \(text)"
                } else {
                    self.errorMessage = "No image in response"
                }
            case .failure(let err):
                self.errorMessage = err.localizedDescription
            }
        }
    }

    func saveToPhotos(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    func resetAfterShare() {
        generatedImage = nil
        didJustGenerate = false
        errorMessage = nil
    }
}
