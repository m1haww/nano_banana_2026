//
//  DiscoverImageCache.swift
//  AI Image Generator
//

import SwiftUI
import UIKit
import CryptoKit

/// Cache pe disk pentru imaginile Discover: o dată încărcate, se citesc din cache la următoarele deschideri.
final class DiscoverImageCache {
    static let shared = DiscoverImageCache()
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "DiscoverImageCache", qos: .userInitiated)
    private var memoryCache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 60
        c.totalCostLimit = 80 * 1024 * 1024 // ~80 MB
        return c
    }()

    private var diskCacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("discover_images", isDirectory: true)
    }

    private init() {
        queue.async { [weak self] in
            guard let self = self, let dir = self.diskCacheDirectory else { return }
            try? self.fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    private func fileURL(for urlString: String) -> URL? {
        let data = Data(urlString.utf8)
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return diskCacheDirectory?.appendingPathComponent("\(hash).dat")
    }

    func image(for urlString: String) -> UIImage? {
        if let cached = memoryCache.object(forKey: urlString as NSString) {
            return cached
        }
        guard let url = fileURL(for: urlString),
              fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let img = UIImage(data: data) else {
            return nil
        }
        memoryCache.setObject(img, forKey: urlString as NSString)
        return img
    }

    func setImage(_ image: UIImage, for urlString: String) {
        memoryCache.setObject(image, forKey: urlString as NSString)
        queue.async { [weak self] in
            guard let self = self,
                  let url = self.fileURL(for: urlString),
                  let data = image.jpegData(compressionQuality: 0.85) else { return }
            try? data.write(to: url)
        }
    }

    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        if let cached = image(for: urlString) {
            DispatchQueue.main.async { completion(cached) }
            return
        }
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let img = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            self?.setImage(img, for: urlString)
            DispatchQueue.main.async { completion(img) }
        }.resume()
    }
}
