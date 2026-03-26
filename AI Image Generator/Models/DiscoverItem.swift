import Foundation

struct DiscoverItem: Codable, Identifiable {
    let id: String
    let image: String
    let prompt: String
    let subtitle: String
}

struct DiscoverResponse: Codable {
    let items: [DiscoverItem]
}
