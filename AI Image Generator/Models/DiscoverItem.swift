//
//  DiscoverItem.swift
//  AI Image Generator
//

import Foundation

/// Un item din feed-ul Discover (backend GET /v1/discover).
struct DiscoverItem: Codable, Identifiable {
    let id: String
    let image: String
    let prompt: String
    let subtitle: String
}

struct DiscoverResponse: Codable {
    let items: [DiscoverItem]
}
