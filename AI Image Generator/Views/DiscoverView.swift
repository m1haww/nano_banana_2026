import SwiftUI
import PhotosUI
import UIKit

struct DiscoverView: View {
    var onCreateVariant: (String) -> Void = { _ in }

    @ObservedObject private var gallery = GalleryService.shared
    @State private var discoverItems: [DiscoverItem] = []
    @State private var discoverLoading = true
    @State private var discoverError: String?
    @State private var selectedDiscoverItem: DiscoverItem?
    @State private var selectedItem: GalleryHistoryItem?

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    /// Înălțimi Pinterest: stânga tall–short–tall, dreapta short–tall–short.
    private let leftHeights: [CGFloat] = [240, 190, 240, 190, 240, 190]
    private let rightHeights: [CGFloat] = [190, 240, 190, 240, 190, 240]

    var body: some View {
        VStack(spacing: 0) {
            // Header fix (stil Nano Banana, ca Profile)
            galleryHeader

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Pinterest-style discover grid (din nano-banana)
                    if discoverLoading {
                        HStack(alignment: .top, spacing: 8) {
                            discoverColumnPlaceholder(heights: leftHeights)
                            discoverColumnPlaceholder(heights: rightHeights)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    } else if let err = discoverError {
                        Text(err)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.appTextSecondary)
                            .padding(.vertical, 20)
                    } else if !discoverItems.isEmpty {
                        DiscoverPinterestGrid(
                            items: discoverItems,
                            leftHeights: leftHeights,
                            rightHeights: rightHeights,
                            onSelect: { selectedDiscoverItem = $0 }
                        )
                    }

                    Spacer(minLength: 0)
                }
                .padding(.top, 24)
                .padding(.bottom, 20)
            }
        }
        .background(Color.appBackground)
        .onAppear {
            loadDiscover()
        }
        .fullScreenCover(item: $selectedDiscoverItem) { item in
            DiscoverDetailView(
                item: item,
                onDismiss: { selectedDiscoverItem = nil },
                onCreateVariant: {
                    onCreateVariant(item.prompt)
                    selectedDiscoverItem = nil
                }
            )
        }
        .fullScreenCover(item: $selectedItem) { item in
            GalleryDetailView(
                item: item,
                onDismiss: { selectedItem = nil },
                onShare: {
                    if let img = gallery.loadImage(from: item.imagePath) {
                        ShareService.shared.present(items: [img, item.prompt])
                    }
                }
            )
        }
    }

    // MARK: - Header (toolbar fix, ca Profile)

    private var galleryHeader: some View {
        VStack(spacing: 6) {
            Text(String(localized: "Discover"))
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.appText)
            Text(String(localized: "Get inspired"))
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background(Color.appBackground)
    }

    /// Afișează întâi din cache (instant), apoi revalidează în fundal; când backend-ul se schimbă, lista se actualizează.
    private func loadDiscover() {
        if let cached = DiscoverCache.load(), !cached.isEmpty {
            discoverItems = cached
            discoverLoading = false
            discoverError = nil
        } else {
            discoverLoading = true
            discoverError = nil
        }

        GeminiAPIService.shared.fetchDiscover { result in
            discoverLoading = false
            switch result {
            case .success(let items):
                DiscoverCache.save(items)
                discoverItems = items
                discoverError = nil
            case .failure(let err):
                if discoverItems.isEmpty {
                    discoverError = err.localizedDescription
                }
                // Dacă avem deja cache, îl păstrăm; doar nu afișăm eroare peste el
            }
        }
    }

    private func discoverColumnPlaceholder(heights: [CGFloat]) -> some View {
        let w = (UIScreen.main.bounds.width - 16 - 16 - 8) / 2
        return VStack(spacing: 8) {
            ForEach(Array(heights.prefix(3).enumerated()), id: \.offset) { _, h in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appCard)
                    .frame(width: w, height: h)
                    .overlay(ProgressView().tint(Color.appAccent))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Pinterest-style grid (design nano-banana: două coloane, înălțimi alternate)
private struct DiscoverPinterestGrid: View {
    let items: [DiscoverItem]
    let leftHeights: [CGFloat]
    let rightHeights: [CGFloat]
    let onSelect: (DiscoverItem) -> Void

    private var columnWidth: CGFloat {
        (UIScreen.main.bounds.width - 16 - 16 - 8) / 2
    }

    private var leftColumnItems: [(DiscoverItem, CGFloat)] {
        items.enumerated().compactMap { index, item in
            guard index % 2 == 0 else { return nil }
            let hIndex = index / 2
            let h = hIndex < leftHeights.count ? leftHeights[hIndex] : leftHeights.last ?? 180
            return (item, h)
        }
    }

    private var rightColumnItems: [(DiscoverItem, CGFloat)] {
        items.enumerated().compactMap { index, item in
            guard index % 2 == 1 else { return nil }
            let hIndex = index / 2
            let h = hIndex < rightHeights.count ? rightHeights[hIndex] : rightHeights.last ?? 180
            return (item, h)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(spacing: 8) {
                ForEach(leftColumnItems, id: \.0.id) { item, height in
                    Button {
                        onSelect(item)
                    } label: {
                        DiscoverCard(item: item, height: height, width: columnWidth)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                ForEach(rightColumnItems, id: \.0.id) { item, height in
                    Button {
                        onSelect(item)
                    } label: {
                        DiscoverCard(item: item, height: height, width: columnWidth)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Card discover (imagine + gradient + subtitle, ca în nano-banana GalleryPage)
private struct DiscoverCard: View {
    let item: DiscoverItem
    let height: CGFloat
    let width: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            CachedDiscoverImageView(urlString: item.image, contentMode: .fill)
                .frame(width: width, height: height)
                .clipped()

            Text(item.subtitle)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
    }
}

struct DiscoverDetailView: View {
    let item: DiscoverItem
    let onDismiss: () -> Void
    var onCreateVariant: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.appText)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        CachedDiscoverImageView(urlString: item.image, contentMode: .fit)
                            .frame(minHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.subtitle)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.appAccent)
                            Text(item.prompt)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.appText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        if onCreateVariant != nil {
                            Button {
                                onCreateVariant?()
                                onDismiss()
                            } label: {
                                Label(String(localized: "Create variant"), systemImage: "wand.and.stars")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.appBackground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.appAccent)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct GalleryDetailView: View {
    let item: GalleryHistoryItem
    let onDismiss: () -> Void
    let onShare: () -> Void
    @ObservedObject private var gallery = GalleryService.shared
    @State private var showSaveConfirmation = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.appText)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    Button(action: {
                        gallery.selectedGalleryItem = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onShare()
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color.appText)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if let img = gallery.loadImage(from: item.imagePath) {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(String(localized: "Prompt"))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.appTextSecondary)
                            Text(item.prompt)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.appText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)

                        VStack(spacing: 12) {
                            Button {
                                if let img = gallery.loadImage(from: item.imagePath) {
                                    UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                                    showSaveConfirmation = true
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 17, weight: .semibold))
                                    Text(String(localized: "Save to Photos"))
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(Color.appBackground)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.appAccent, Color.appAccentSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            Button {
                                showDeleteConfirm = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(String(localized: "Delete"))
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1, green: 0.38, blue: 0.38),
                                            Color(red: 0.85, green: 0.22, blue: 0.25),
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.red.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.red.opacity(0.55),
                                                    Color.red.opacity(0.25),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.2
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .alert(String(localized: "Saved"), isPresented: $showSaveConfirmation) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(String(localized: "Image saved to Photos."))
        }
        .alert(String(localized: "Delete image?"), isPresented: $showDeleteConfirm) {
            Button(String(localized: "Cancel"), role: .cancel) {}
            Button(String(localized: "Delete"), role: .destructive) {
                gallery.removeGalleryItem(id: item.id)
                onDismiss()
            }
        } message: {
            Text(String(localized: "This cannot be undone."))
        }
    }
}
