import Foundation

/// Un mesaj din conversația chatului AI.
struct ChatMessage: Identifiable, Equatable, Hashable {
    enum Role: String, Codable {
        case user
        case ai
    }

    let id: UUID
    let role: Role
    let text: String?
    /// Imagine atașată de utilizator sau returnată de AI (raw PNG/JPEG data).
    let imageData: Data?
    let timestamp: Date
    /// `true` pentru bubble-ul de "typing…" temporar.
    let isPlaceholder: Bool

    init(
        id: UUID = UUID(),
        role: Role,
        text: String? = nil,
        imageData: Data? = nil,
        timestamp: Date = Date(),
        isPlaceholder: Bool = false
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.imageData = imageData
        self.timestamp = timestamp
        self.isPlaceholder = isPlaceholder
    }
}
