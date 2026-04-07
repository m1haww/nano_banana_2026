import AVFoundation
import SwiftUI
import StoreKit

// MARK: - Looping muted video (aspect fill), for carousel cards

/// Hosts `AVPlayerLayer` and keeps its frame in sync with SwiftUI/TabView layout (avoids zero-size layers).
private final class LoopingVideoHostingView: UIView {
    var playerLayer: AVPlayerLayer? {
        didSet {
            oldValue?.removeFromSuperlayer()
            if let playerLayer {
                layer.addSublayer(playerLayer)
            }
            setNeedsLayout()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}

private struct LoopingFillVideoView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> LoopingVideoHostingView {
        let view = LoopingVideoHostingView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        context.coordinator.attach(to: view, url: url)
        return view
    }

    func updateUIView(_ uiView: LoopingVideoHostingView, context: Context) {
        context.coordinator.attachIfNeeded(to: uiView, url: url)
    }

    static func dismantleUIView(_ uiView: LoopingVideoHostingView, coordinator: Coordinator) {
        coordinator.cleanup()
        uiView.playerLayer = nil
    }

    final class Coordinator {
        private var boundURL: URL?
        private var player: AVPlayer?
        private var endObserver: NSObjectProtocol?
        private var statusObservation: NSKeyValueObservation?

        func attachIfNeeded(to view: LoopingVideoHostingView, url: URL) {
            if boundURL == url, player != nil { return }
            attach(to: view, url: url)
        }

        func attach(to view: LoopingVideoHostingView, url: URL) {
            cleanup()
            boundURL = url
            let player = AVPlayer(url: url)
            player.isMuted = true
            let avLayer = AVPlayerLayer(player: player)
            avLayer.videoGravity = .resizeAspectFill
            view.playerLayer = avLayer
            self.player = player

            guard let item = player.currentItem else {
                return
            }
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak player] _ in
                player?.seek(to: .zero)
                player?.play()
            }

            beginPlaybackWhenReady(player: player, item: item)
        }

        private func beginPlaybackWhenReady(player: AVPlayer, item: AVPlayerItem) {
            if item.status == .readyToPlay {
                player.play()
                return
            }
            statusObservation = item.observe(\.status, options: [.new]) { [weak player] avItem, _ in
                guard avItem.status == .readyToPlay else { return }
                player?.play()
            }
        }

        func cleanup() {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
            endObserver = nil
            statusObservation?.invalidate()
            statusObservation = nil
            player?.pause()
            player = nil
            boundURL = nil
        }
    }
}

// MARK: - Carousel card (image or video)

private struct OnboardingCarouselMediaCard: View {
    let item: OnboardingV3ContentItem
    private let cornerRadius: CGFloat = 28

    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                switch item.type {
                case .image:
                    if let name = item.imageAssetName {
                        Image(name)
                            .resizable()
                            .scaledToFill()
                    } else if let url = item.url {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .fill(Color.appCard)
                            case .empty:
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .fill(Color.appPromptBackground)
                                    .overlay {
                                        ProgressView()
                                            .tint(Color.appAccent)
                                    }
                            @unknown default:
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .fill(Color.appCard)
                            }
                        }
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.appCard)
                    }
                case .video:
                    if let url = item.url {
                        LoopingFillVideoView(url: url)
                            .id("\(item.id)-\(url.absoluteString)")
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.appCard)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct OnboardingViewV3: View {
    private let steps: [OnboardingV3Step]
    let onFinished: () -> Void

    @Environment(\.requestReview) private var requestReview
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var stepPageIndex = 0
    /// Paging `TabView` selection (user swipe or auto-advance).
    @State private var carouselIndex = 0
    @State private var autoAdvanceTask: Task<Void, Never>?

    private var currentStep: OnboardingV3Step {
        guard stepPageIndex >= 0, stepPageIndex < steps.count else {
            return steps.first ?? OnboardingV3Step.defaultGemini
        }
        return steps[stepPageIndex]
    }

    /// Full flow: first carousel + second carousel step.
    init(steps: [OnboardingV3Step] = OnboardingV3Step.defaultFlow, onFinished: @escaping () -> Void) {
        self.steps = steps
        self.onFinished = onFinished
    }

    init(step: OnboardingV3Step, onFinished: @escaping () -> Void) {
        self.steps = [step]
        self.onFinished = onFinished
    }

    private let headlineGradient = LinearGradient(
        colors: [Color.appAccent, Color.appAccentSecondary],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                headlineView
                    .padding(.horizontal, 24)

                Text(currentStep.subtitle.localized)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 32)
                    .padding(.top, 18)

                Spacer(minLength: 28)

                carouselSection

                Spacer(minLength: 20)

                Button(action: primaryAction) {
                    Text(stepPageIndex < steps.count - 1 ? String(localized: "Continue") : String(localized: "Get started"))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.appAccent, Color.appAccentSecondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)
                .padding(.bottom, 36)
            }
        }
        .onChange(of: stepPageIndex) { _ in
            carouselIndex = 0
            scheduleNextAutoAdvance(count: currentStep.contents.count)
        }
    }

    @ViewBuilder
    private var headlineView: some View {
        let localizedTitle = currentStep.title.localized
        if let localizedEmphasis = currentStep.titleEmphasis?.localized,
           let range = localizedTitle.range(of: localizedEmphasis) {
            let before = String(localizedTitle[..<range.lowerBound])
            let after = String(localizedTitle[range.upperBound...])
            Group {
                if #available(iOS 17.0, *) {
                    (
                        Text(before)
                            .foregroundStyle(Color.appText)
                        + Text(localizedEmphasis)
                            .foregroundStyle(headlineGradient)
                        + Text(after)
                            .foregroundStyle(Color.appText)
                    )
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                } else {
                    (
                        Text(before)
                            .foregroundColor(Color.appText)
                        + Text(localizedEmphasis)
                            .foregroundColor(Color.appAccent)
                        + Text(after)
                            .foregroundColor(Color.appText)
                    )
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                }
            }
        } else {
            Text(localizedTitle)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(Color.appText)
                .multilineTextAlignment(.center)
        }
    }
    
    private var accentBorder: LinearGradient {
        LinearGradient(
            colors: [Color.appAccent.opacity(0.95), Color.appAccentSecondary.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var carouselSection: some View {
        GeometryReader { geo in
            let items = currentStep.contents
            let count = items.count
            let cardWidth = geo.size.width * 0.88
            let cardHeight = min(cardWidth * 1.12, geo.size.height * 0.92)

            VStack(spacing: 14) {
                TabView(selection: $carouselIndex) {
                    ForEach(0..<count, id: \.self) { index in
                        OnboardingCarouselMediaCard(item: items[index])
                            .frame(width: cardWidth, height: cardHeight)
                            .clipped()
                            .cornerRadius(28)
                            .overlay {
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(accentBorder.opacity(0.5), lineWidth: 1)
                            }
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .id(currentStep.id)

                if count > 1 {
                    HStack(spacing: 8) {
                        ForEach(0..<count, id: \.self) { index in
                            Capsule()
                                .fill(index == carouselIndex ? Color.appAccent : Color.appDivider.opacity(0.55))
                                .frame(width: index == carouselIndex ? 22 : 7, height: 7)
                                .animation(.easeInOut(duration: 0.25), value: carouselIndex)
                        }
                    }
                }
            }
            .onAppear {
                carouselIndex = min(carouselIndex, max(0, count - 1))
                scheduleNextAutoAdvance(count: count)
            }
            .onChange(of: carouselIndex) { _ in
                scheduleNextAutoAdvance(count: count)
            }
            .onChange(of: reduceMotion) { _ in
                scheduleNextAutoAdvance(count: count)
            }
            .onDisappear {
                autoAdvanceTask?.cancel()
                autoAdvanceTask = nil
            }
        }
        .frame(height: min(UIScreen.main.bounds.width * 0.85 * 1.12 + 8, 420) + 28)
    }

    /// Wait 5 seconds from the last `carouselIndex` change, then advance from **that** page.
    private func scheduleNextAutoAdvance(count: Int) {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil
        guard count > 1, !reduceMotion else { return }

        autoAdvanceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            let next = (carouselIndex + 1) % count
            withAnimation(.easeInOut(duration: 0.45)) {
                carouselIndex = next
            }
        }
    }

    private func primaryAction() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if stepPageIndex < steps.count - 1 {
            withAnimation {
                stepPageIndex += 1
            }
        } else {
            requestReview()
            onFinished()
        }
    }
}
