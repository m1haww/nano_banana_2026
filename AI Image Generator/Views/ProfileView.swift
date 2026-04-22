import SwiftUI

struct ProfileView: View {
    @ObservedObject private var gallery = GalleryService.shared
    @ObservedObject private var subscription = SubscriptionService.shared

    @State private var selectedGalleryItem: GalleryHistoryItem?

    var body: some View {
        VStack(spacing: 0) {
            // Header fix (stil Nano Banana)
            profileHeader

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    imagesCard

                    shopEntryRow

                    if !gallery.galleryHistory.isEmpty {
                        recentSavedList
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 30)
            }
        }
        .background(Color.appBackground)
        .fullScreenCover(item: $selectedGalleryItem) { item in
            GalleryDetailView(
                item: item,
                onDismiss: { selectedGalleryItem = nil },
                onShare: {
                    if let img = gallery.loadImage(from: item.imagePath) {
                        ShareService.shared.present(items: [img, item.prompt])
                    }
                }
            )
        }
    }

    private var shopEntryRow: some View {
        Button {
            subscription.showShop = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "cart.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.appAccent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Credits & shop"))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appText)
                    Text(String(format: String(localized: "%lld credits available"), subscription.credits))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(18)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.appDivider.opacity(0.7), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var recentSavedList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(String(localized: "Your saves"))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appText)
                Spacer()
            }

            VStack(spacing: 16) {
                ForEach(gallery.galleryHistory.prefix(48)) { item in
                    Button {
                        selectedGalleryItem = item
                    } label: {
                        ProfileHistoryCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var profileHeader: some View {
        HStack {
            Spacer()
            Text(String(localized: "Profile"))
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.appText)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background(Color.appBackground)
    }

    // MARK: - Library summary (hero card)

    private var imagesCard: some View {
        let corner: CGFloat = 20
        let count = gallery.galleryHistory.count

        return ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appCard,
                            Color.appCard.opacity(0.92),
                            Color(hex: "232019"),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Soft accent glow (top-right)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.appAccent.opacity(0.22),
                            Color.appAccent.opacity(0.04),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 200, height: 200)
                .offset(x: 40, y: -70)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.appAccent.opacity(0.14))
                            .frame(width: 52, height: 52)
                        Circle()
                            .stroke(Color.appAccent.opacity(0.35), lineWidth: 1)
                            .frame(width: 52, height: 52)
                        Image(systemName: "photo.stack.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color.appAccent)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "Your library"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.appAccent.opacity(0.95))
                            .textCase(.uppercase)
                            .tracking(0.6)
                        Text(String(localized: "Creations kept on this device"))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.appTextSecondary)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.bottom, 20)

                Text("\(count)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appText)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .monospacedDigit()

                Text(count == 1 ? String(localized: "image saved") : String(localized: "images saved"))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
                    .padding(.top, 6)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.appAccent.opacity(0.5),
                            Color.appAccent.opacity(0.12),
                            Color.appDivider.opacity(0.45),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.45), radius: 18, x: 0, y: 10)
        .shadow(color: Color.appAccent.opacity(0.07), radius: 22, x: 0, y: 4)
    }

}

// MARK: - History row card

private struct ProfileHistoryCard: View {
    let item: GalleryHistoryItem
    @ObservedObject private var gallery = GalleryService.shared

    private let corner: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // Image content based on status
                Group {
                    switch item.status {
                    case .success:
                        if let img = gallery.loadImage(from: item.imagePath) {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 200, maxHeight: 260)
                                .clipped()
                        } else {
                            placeholderView
                        }
                    case .pending:
                        loadingView
                    case .failed:
                        placeholderView
                    }
                }

                LinearGradient(
                    colors: [
                        .clear,
                        Color.appBackground.opacity(0.15),
                        Color.appBackground.opacity(0.55),
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                // Status badge
                statusBadge
                    .padding(12)
            }
            .frame(maxWidth: .infinity)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: corner,
                    topTrailingRadius: corner
                )
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(item.prompt)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.appText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.appAccent.opacity(0.9))
                    Text(item.relativeDate)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appCard)
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .shadow(color: .black.opacity(0.45), radius: 18, x: 0, y: 10)
    }

    // MARK: - Status Badge

    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: 6) {
            switch item.status {
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(String(localized: "Success"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            case .pending:
                ProgressView()
                    .scaleEffect(0.7)
                Text(String(localized: "Pending"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(String(localized: "Failed"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
        }
        .foregroundStyle(statusForegroundColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(statusBackgroundColor)
        )
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }

    private var statusBackgroundColor: Color {
        switch item.status {
        case .success:
            return Color.green.opacity(0.2)
        case .pending:
            return Color.orange.opacity(0.2)
        case .failed:
            return Color.red.opacity(0.2)
        }
    }

    private var statusForegroundColor: Color {
        switch item.status {
        case .success:
            return Color.green
        case .pending:
            return Color.orange
        case .failed:
            return Color.red
        }
    }

    // MARK: - Placeholder Views

    private var placeholderView: some View {
        Color.appPromptBackground
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .overlay(
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.6))
            )
    }

    private var loadingView: some View {
        Color.appPromptBackground
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .overlay(
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color.appAccent)
                    Text(String(localized: "Generating..."))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)
                }
            )
    }
}
