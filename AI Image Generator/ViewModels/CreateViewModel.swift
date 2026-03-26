import SwiftUI
import UIKit
import Combine

@MainActor
final class CreateViewModel: ObservableObject {
    private let generationCost = 10

    @Published var prompt: String = ""
    @Published var referenceImage: UIImage?
    @Published var generatedImage: UIImage?
    @Published var isGenerating: Bool = true
    @Published var errorMessage: String?
    @Published var didJustGenerate: Bool = false
    @Published var aspectRatio: String = "1:1"

    private let api = GeminiAPIService.shared
    private let gallery = GalleryService.shared
    private let subscription = SubscriptionService.shared

    func clearReferenceImage() {
        referenceImage = nil
    }

    func setReferenceImage(_ image: UIImage?) {
        referenceImage = image
    }

    /// `stylePrefix` is only a label (e.g. image style); generation is blocked unless the user’s prompt is non-empty after trimming.
    func generate(stylePrefix: String = "") async {
        let userPart = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userPart.isEmpty else {
            errorMessage = "Please enter a prompt before generating."
            return
        }

        let text = stylePrefix + userPart

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
                        print("Image was saved to the gallery")
                    }
                    UserService.shared.addCredits(-self.generationCost) { success in
                        guard success else { return }
                        DispatchQueue.main.async {
                            self.subscription.addCredits(-self.generationCost)
                        }
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
