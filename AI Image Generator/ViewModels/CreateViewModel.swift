import SwiftUI
import UIKit
import Combine

@MainActor
final class CreateViewModel: ObservableObject {
    var generationCost: Int = 10

    @Published var prompt: String = ""
    @Published var referenceImage: UIImage?
    @Published var generatedImage: UIImage?
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    @Published var taskSubmitted: Bool = false
    @Published var aspectRatio: AspectRatioOption = .oneToOne
    @Published var resolution: String = "1K"

    private let api = GeminiAPIService.shared
    private let gallery = GalleryService.shared
    private let subscription = SubscriptionService.shared

    func clearReferenceImage() {
        referenceImage = nil
    }

    func setReferenceImage(_ image: UIImage?) {
        referenceImage = image
    }

    /// `stylePrefix` is only a label (e.g. image style); generation is blocked unless the user's prompt is non-empty after trimming.
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
        taskSubmitted = false

        await performGenerate(prompt: text, aspectRatio: aspectRatio.rawValue, resolution: resolution)
    }

    private func performGenerate(prompt: String, aspectRatio: String, resolution: String) async {
        await api.createImage(prompt: prompt, image: referenceImage, aspectRatio: aspectRatio, resolution: resolution) { [weak self] result in
            guard let self = self else { return }
            self.isGenerating = false

            switch result {
            case .success:
                self.taskSubmitted = true

                UserService.shared.addCredits(-self.generationCost) { success in
                    guard success else { return }
                    DispatchQueue.main.async {
                        self.subscription.addCredits(-self.generationCost)
                    }
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
        taskSubmitted = false
        errorMessage = nil
    }
}
