//
//  DiscoverCache.swift
//  AI Image Generator
//

import Foundation

/// Cache pentru lista Discover: salvare pe disk, încărcare instantă, revalidare în fundal.
/// Când schimbi JSON-ul pe backend, la următoarea intrare în tab se afișează întâi cache-ul (rapid), apoi se reîmprospătează cu datele noi.
enum DiscoverCache {
    private static let fileName = "discover_list.json"
    private static let fileManager = FileManager.default

    private static var cacheURL: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent(fileName)
    }

    /// Salvează lista pe disk (după un fetch reușit).
    static func save(_ items: [DiscoverItem]) {
        guard let url = cacheURL else { return }
        let container = DiscoverResponse(items: items)
        do {
            let data = try JSONEncoder().encode(container)
            try data.write(to: url)
        } catch {}
    }

    /// Încarcă lista din cache (instant). Returnează nil dacă nu există sau e invalid.
    static func load() -> [DiscoverItem]? {
        guard let url = cacheURL, fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let container = try? JSONDecoder().decode(DiscoverResponse.self, from: data) else {
            return nil
        }
        return container.items
    }
}
