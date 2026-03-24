//
//  CachedDiscoverImageView.swift
//  AI Image Generator
//

import SwiftUI

/// Afișează o imagine Discover din cache sau o încarcă și o salvează în cache.
struct CachedDiscoverImageView: View {
    let urlString: String
    var contentMode: ContentMode = .fill
    @State private var image: UIImage?
    @State private var loading = true

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if loading {
                Color.appCard
                    .overlay(ProgressView().tint(Color.appAccent))
            } else {
                Color.appPromptBackground
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundStyle(Color.appTextSecondary)
                    )
            }
        }
        .onAppear {
            DiscoverImageCache.shared.loadImage(from: urlString) { img in
                image = img
                loading = false
            }
        }
    }
}
