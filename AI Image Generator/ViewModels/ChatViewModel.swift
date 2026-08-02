import SwiftUI
import UIKit
import PhotosUI
import Combine

// MARK: - Models

enum ChatBubble: Identifiable {
    case user(id: UUID = UUID(), text: String, image: UIImage?)
    case assistant(id: UUID = UUID(), text: String)
    case imageGenerating(id: UUID = UUID(), prompt: String)
    case imageReady(id: UUID = UUID(), prompt: String, imageURL: String)
    case imageFailed(id: UUID = UUID(), prompt: String)

    var id: UUID {
        switch self {
        case .user(let id, _, _): return id
        case .assistant(let id, _): return id
        case .imageGenerating(let id, _): return id
        case .imageReady(let id, _, _): return id
        case .imageFailed(let id, _): return id
        }
    }
}

// MARK: - ViewModel

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var bubbles: [ChatBubble] = []
    @Published var inputText: String = ""
    @Published var isStreaming: Bool = false
    @Published var isUploadingImage: Bool = false
    @Published var attachedImage: UIImage? = nil
    @Published var aspectRatio: AspectRatioOption = .oneToOne
    @Published var resolution: ResolutionOption = .oneK
    @Published var imageSourceType: UIImagePickerController.SourceType?
    @Published var showImagePicker = false

    // history sent to the backend (text only — no images in chat context)
    private var messageHistory: [ChatMessage] = []

    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || attachedImage != nil else { return }
        guard !isStreaming else { return }

        let userImage = attachedImage
        inputText = ""
        attachedImage = nil
        isStreaming = true

        Task {
            // Upload image if attached, get a public URL
            var uploadedImageURL: String? = nil
            if let image = userImage {
                isUploadingImage = true
                do {
                    let uploaded = try await FileService.shared.uploadImage(image, uploadPrefix: "chat-input")
                    if let key = uploaded.key, !key.isEmpty {
                        uploadedImageURL = FileService.shared.getFileUrl(key: key)
                    }
                } catch {
                    print("Failed to upload image: \(error.localizedDescription)")
                }
                isUploadingImage = false
            }

            // Add user bubble (shows local UIImage immediately)
            bubbles.append(.user(text: text, image: userImage))

            // Build multipart message for the backend
            let userMessage = ChatMessage(role: "user", text: text, imageURL: uploadedImageURL)
            messageHistory.append(userMessage)

            // Placeholder assistant bubble
            let assistantBubbleId = UUID()
            bubbles.append(.assistant(id: assistantBubbleId, text: ""))

            var accumulatedText = ""

            for await event in GeminiAPIService.shared.streamChat(messages: messageHistory) {
                switch event {
                case .text(let delta):
                    accumulatedText += delta
                    updateAssistantBubble(id: assistantBubbleId, text: accumulatedText)

                case .toolCall(let prompt):
                    if accumulatedText.isEmpty {
                        removeBubble(id: assistantBubbleId)
                    }
                    let genId = UUID()
                    bubbles.append(.imageGenerating(id: genId, prompt: prompt))
                    let imageURLsForGen = uploadedImageURL.map { [$0] }
                    triggerImageGeneration(bubbleId: genId, prompt: prompt, imageURLs: imageURLsForGen)

                case .done:
                    if !accumulatedText.isEmpty {
                        messageHistory.append(ChatMessage(role: "assistant", text: accumulatedText))
                    }
                    isStreaming = false

                case .error(let msg):
                    updateAssistantBubble(id: assistantBubbleId, text: "Something went wrong: \(msg)")
                    isStreaming = false
                }
            }

            isStreaming = false
        }
    }

    // MARK: - Private helpers

    private func updateAssistantBubble(id: UUID, text: String) {
        if let idx = bubbles.firstIndex(where: { $0.id == id }) {
            bubbles[idx] = .assistant(id: id, text: text)
        }
    }

    private func removeBubble(id: UUID) {
        bubbles.removeAll { $0.id == id }
    }

    private func triggerImageGeneration(bubbleId: UUID, prompt: String, imageURLs: [String]? = nil) {
        let cost = resolution.creditCost
        Task {
            do {
                let imageURL = try await GeminiAPIService.shared.generateImageAndPoll(
                    prompt: prompt,
                    imageURLs: imageURLs,
                    aspectRatio: aspectRatio.rawValue,
                    resolution: resolution.rawValue
                )
                if let idx = bubbles.firstIndex(where: { $0.id == bubbleId }) {
                    bubbles[idx] = .imageReady(id: bubbleId, prompt: prompt, imageURL: imageURL)
                }
                UserService.shared.addCredits(-cost) { success in
                    guard success else { return }
                    DispatchQueue.main.async {
                        SubscriptionService.shared.addCredits(-cost)
                    }
                }
            } catch {
                if let idx = bubbles.firstIndex(where: { $0.id == bubbleId }) {
                    bubbles[idx] = .imageFailed(id: bubbleId, prompt: prompt)
                }
            }
        }
    }

    /// Called from push notification handler when a task finishes
    func handleTaskComplete(taskId: String, imageURL: String, prompt: String) {
        if let idx = bubbles.firstIndex(where: {
            if case .imageGenerating = $0 { return true }
            return false
        }) {
            let existingPrompt: String
            if case .imageGenerating(_, let p) = bubbles[idx] {
                existingPrompt = p
            } else {
                existingPrompt = prompt
            }
            bubbles[idx] = .imageReady(prompt: existingPrompt, imageURL: imageURL)
        }
    }
}
