import SwiftUI
import UIKit
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var input: String = ""
    @Published var attachedImage: UIImage?
    @Published var isTyping: Bool = false
    @Published var errorMessage: String?

    /// Momentan MOCKED — răspunde local până când backend-ul de chat e gata.
    /// Când e gata, înlocuiește implementarea `sendToBackend(...)` cu apelul real.
    private let isBackendReady = false

    // MARK: - Public API

    func send() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasText = !trimmed.isEmpty
        let hasImage = attachedImage != nil
        guard hasText || hasImage else { return }

        // 1. Append user message
        let userImageData = attachedImage?.jpegData(compressionQuality: 0.9)
        let userMsg = ChatMessage(
            role: .user,
            text: hasText ? trimmed : nil,
            imageData: userImageData
        )
        messages.append(userMsg)

        // 2. Reset input
        input = ""
        let sentImage = attachedImage
        attachedImage = nil

        // 3. Show typing placeholder
        let placeholderId = UUID()
        messages.append(
            ChatMessage(
                id: placeholderId,
                role: .ai,
                text: nil,
                imageData: nil,
                isPlaceholder: true
            )
        )
        isTyping = true

        // 4. Fetch response
        Task {
            await respond(
                to: trimmed,
                userImage: sentImage,
                replacingPlaceholder: placeholderId
            )
        }
    }

    func clearConversation() {
        messages.removeAll()
        input = ""
        attachedImage = nil
        errorMessage = nil
    }

    // MARK: - Response pipeline

    private func respond(
        to userText: String,
        userImage: UIImage?,
        replacingPlaceholder placeholderId: UUID
    ) async {
        do {
            let response: ChatMessage
            if isBackendReady {
                response = try await sendToBackend(text: userText, image: userImage)
            } else {
                response = try await mockedResponse(text: userText, image: userImage)
            }
            replacePlaceholder(placeholderId, with: response)
        } catch {
            let errMsg = ChatMessage(
                role: .ai,
                text: "Something went wrong: \(error.localizedDescription)"
            )
            replacePlaceholder(placeholderId, with: errMsg)
            errorMessage = error.localizedDescription
        }
        isTyping = false
    }

    private func replacePlaceholder(_ id: UUID, with newMessage: ChatMessage) {
        if let idx = messages.firstIndex(where: { $0.id == id }) {
            messages[idx] = newMessage
        } else {
            messages.append(newMessage)
        }
    }

    // MARK: - Backend (TODO — conectare reală)

    private func sendToBackend(text: String, image: UIImage?) async throws -> ChatMessage {
        // TODO: apel real la backend când endpoint-ul e gata.
        //
        // Necesar pe backend:
        //  - POST /chat cu body: { history: [Message], text: String, image?: base64 }
        //  - Response: { role: "ai", text?: String, image?: base64 }
        //  - Server-side păstrează istoricul pentru context multi-turn cu Gemini/Nano Banana
        //
        // Când e gata, decomentează și înlocuiește mockedResponse:
        //
        // let history = messages.map { ... }
        // let response = try await GeminiAPIService.shared.chat(
        //     history: history, text: text, image: image
        // )
        // return ChatMessage(role: .ai, text: response.text, imageData: response.imageData)

        throw NSError(
            domain: "ChatViewModel",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Backend not connected yet."]
        )
    }

    // MARK: - Mocked response (until backend is ready)

    private func mockedResponse(text: String, image: UIImage?) async throws -> ChatMessage {
        // Simulate latency
        try? await Task.sleep(for: .milliseconds(900 + Int.random(in: 0...600)))

        let lower = text.lowercased()
        let userSentImage = image != nil

        // If user attached an image and asked to edit → echo back their image with note
        if userSentImage {
            return ChatMessage(
                role: .ai,
                text: "I'd love to edit this image for you — but the chat backend isn't connected yet. Once it is, you'll see the edited version here in seconds.",
                imageData: image?.jpegData(compressionQuality: 0.9)
            )
        }

        // Simple canned answers based on user text
        if lower.isEmpty {
            return ChatMessage(
                role: .ai,
                text: "Hi! Once the chat backend is live, you'll be able to chat freely and edit any image you send me. What would you like to try?"
            )
        }

        if lower.contains("hello") || lower.contains("hi") || lower.contains("salut") || lower.contains("hey") {
            return ChatMessage(
                role: .ai,
                text: "Hey there! 👋 This is a preview of the AI chat. Backend integration is coming next — attach a photo and try describing an edit you'd want."
            )
        }

        if lower.contains("edit") || lower.contains("change") || lower.contains("remove") || lower.contains("background") {
            return ChatMessage(
                role: .ai,
                text: "Great idea — that's exactly what this chat will do. Send me a photo along with your instruction and I'll return the edited version (once the backend is wired)."
            )
        }

        return ChatMessage(
            role: .ai,
            text: "You said: \"\(text)\"\n\n(Preview mode — the real AI chat with image editing is coming soon.)"
        )
    }
}
