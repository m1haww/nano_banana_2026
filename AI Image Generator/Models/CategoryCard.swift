//
//  CategoryCard.swift
//  AI Image Generator
//

import Foundation

struct CategoryCard: Codable, Identifiable {
    let image: String
    let category: String
    let subtitle: String

    var id: String { image + category + subtitle }
}

/// Răspuns backend: toate datele Image Style dintr-un singur JSON (data/image_styles.json).
struct ImageStyleResponse: Codable {
    let cards: [CategoryCard]
}

/// Încarcă categoriile Image Style doar de pe backend.
enum ImageStyleLoader {
    static func loadCards(completion: @escaping ([CategoryCard]) -> Void) {
        GeminiAPIService.shared.fetchImageStyles { result in
            switch result {
            case .success(let cards):
                completion(cards)
            case .failure:
                completion([])
            }
        }
    }
}

/// Încarcă carduri: încearcă API-ul (nano-banana), la eșec folosește MockData.json din bundle.
enum MockDataLoader {
    static func loadCards(completion: @escaping ([CategoryCard]) -> Void) {
        print("[MockDataLoader] loadCards: începem, apelăm fetchImageStyles...")
        GeminiAPIService.shared.fetchImageStyles { result in
            switch result {
            case .success(let cards):
                print("[MockDataLoader] API success: \(cards.count) carduri primite")
                cards.forEach { print("  - \($0.category) | image: \($0.image)") }
                completion(cards)
            case .failure(let err):
                print("[MockDataLoader] API failure: \(err.localizedDescription) → încărcăm din bundle")
                let fromBundle = Self.loadCardsFromBundle()
                print("[MockDataLoader] Din bundle: \(fromBundle.count) carduri")
                completion(fromBundle)
            }
        }
    }

    static func loadCardsFromBundle() -> [CategoryCard] {
        guard let url = Bundle.main.url(forResource: "MockData", withExtension: "json") else {
            print("[MockDataLoader] loadCardsFromBundle: MockData.json NU a fost găsit în bundle")
            return []
        }
        print("[MockDataLoader] loadCardsFromBundle: URL = \(url.path)")
        guard let data = try? Data(contentsOf: url) else {
            print("[MockDataLoader] loadCardsFromBundle: nu s-a putut citi data")
            return []
        }
        print("[MockDataLoader] loadCardsFromBundle: data size = \(data.count) bytes")
        guard let container = try? JSONDecoder().decode(ImageStyleResponse.self, from: data) else {
            print("[MockDataLoader] loadCardsFromBundle: decode eșuat. Raw (primele 300 chars): \(String(data: data, encoding: .utf8)?.prefix(300) ?? "nil")")
            return []
        }
        print("[MockDataLoader] loadCardsFromBundle: decode OK, \(container.cards.count) carduri")
        return container.cards
    }
}
