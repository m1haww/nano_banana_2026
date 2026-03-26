import SwiftUI
import PhotosUI
import UIKit

/// TextEditor cu cursor aliniat la prima linie (fără inset sus).
struct AlignedPromptField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var font: UIFont
    var textColor: UIColor
    var tintColor: UIColor
    var minHeight: CGFloat
    var maxHeight: CGFloat
    var onFocusChange: ((Bool) -> Void)?

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.font = font
        tv.textColor = textColor
        tv.tintColor = tintColor
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tv.textContainer.lineFragmentPadding = 0
        tv.delegate = context.coordinator
        tv.isScrollEnabled = true
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: AlignedPromptField
        init(_ parent: AlignedPromptField) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text ?? ""
        }
        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.onFocusChange?(true)
        }
        func textViewDidEndEditing(_ textView: UITextView) {
            parent.onFocusChange?(false)
        }
    }
}

/// Aspect ratios allowed by Poyo / Nano Banana 2 API (see docs.poyo.ai).
enum AspectRatioOption: String, CaseIterable {
    case oneToOne = "1:1"
    case nineSixteen = "9:16"
    case sixteenNine = "16:9"
    case fourThree = "4:3"
    case threeFour = "3:4"
    case twoThree = "2:3"
    case threeTwo = "3:2"
    case fourFive = "4:5"
    case fiveFour = "5:4"
    case twentyOneNine = "21:9"
}

struct HomeView: View {
    @Binding var initialPromptFromDiscover: String?
    @State private var cards: [CategoryCard] = CategoryCard.homeCards
    @StateObject private var viewModel = CreateViewModel()
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var selectedAspectRatio: AspectRatioOption = .oneToOne
    @State private var showSaveConfirmation = false
    @State private var showExplorePrompts = false
    @State private var selectedImageStyleId: CategoryCard.ID?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @FocusState private var promptFocused: Bool
    @State private var showGenerationResult = false
    @State private var showErrorAlert = false
    @State private var errorAlertMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                homeHeader

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Enter Prompt
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Enter Prompt")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.appText)
                                Spacer()
                                Button {
                                    showExplorePrompts = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("Explore Prompts")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundStyle(Color.appAccent)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            ZStack(alignment: .topLeading) {
                                Text("Describe anything, let our AI robot create magic for you...")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundStyle(Color.appTextSecondary)
                                    .padding(12)
                                    .allowsHitTesting(false)
                                    .opacity(viewModel.prompt.isEmpty ? 1 : 0)
                                AlignedPromptField(
                                    text: $viewModel.prompt,
                                    placeholder: "Describe anything...",
                                    font: .systemFont(ofSize: 16, weight: .regular),
                                    textColor: .white,
                                    tintColor: .yellow,
                                    minHeight: 80,
                                    maxHeight: 200
                                )
                                .frame(minHeight: 80, maxHeight: 200)
                                .padding(12)
                            }
                            .background(Color.appPromptBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.appDivider, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                        // Aspect Ratio — ScrollView pe toată lățimea; padding doar pe titlu și pe conținutul scroll-ului (stânga+dreapta simetric)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Aspect Ratio")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.appText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(AspectRatioOption.allCases, id: \.self) { option in
                                        AspectRatioButton(
                                            option: option,
                                            isSelected: selectedAspectRatio == option
                                        ) {
                                            selectedAspectRatio = option
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 2)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Image Style")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.appText)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(cards) { card in
                                        ImageStyleCardView(
                                            card: card,
                                            isSelected: selectedImageStyleId == card.id
                                        ) {
                                            selectedImageStyleId = selectedImageStyleId == card.id ? nil : card.id
                                        }
                                    }
                                }
                                .padding(.top, 8)
                                .padding(.horizontal, 20)
                            }
                        }

                        Button {
                            promptFocused = false
                            
                            guard subscriptionService.credits > 0 else {
                                if subscriptionService.isSubscribed {
                                    subscriptionService.showShop = true
                                } else {
                                    subscriptionService.showPaywall = true
                                }
                                return
                            }
                            
                            viewModel.aspectRatio = selectedAspectRatio.rawValue
                            let stylePrefix = selectedStyleCard.map { "\($0.category) style: " } ?? ""
                            Task { await viewModel.generate(stylePrefix: stylePrefix) }
                        } label: {
                            HStack(spacing: 3) {
                                Text("Generate 10")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                Image(systemName: "film")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [Color.appAccent, Color.appAccentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .disabled(viewModel.isGenerating)
                        .opacity(viewModel.isGenerating ? 0.55 : 1)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                }
                .onTapGesture { promptFocused = false }
                .onAppear {
                    subscriptionService.fetchStatus()
                    if let prompt = initialPromptFromDiscover {
                        viewModel.prompt = prompt
                        initialPromptFromDiscover = nil
                    }
                }
                }
                .background(Color.appBackground)

                if viewModel.isGenerating {
                    GenerationLoadingOverlay()
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
        }
        /// System `.alert` action labels use the environment tint; switch to black while an alert is up.
        .tint(alertActionsTint)
        .onChange(of: viewModel.errorMessage) { newValue in
            if let msg = newValue, !msg.isEmpty {
                errorAlertMessage = msg
                showErrorAlert = true
            }
        }
        .onChange(of: viewModel.didJustGenerate) { did in
            if did {
                showGenerationResult = true
            }
        }
        .onChange(of: viewModel.isGenerating) { isGen in
            if isGen {
                showGenerationResult = false
            }
        }
        .fullScreenCover(isPresented: $showExplorePrompts) {
            ExplorePromptsView(currentPrompt: viewModel.prompt) { selected in
                viewModel.prompt = selected
            }
        }
        .alert("Saved", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Image saved to Photos.")
        }
        .alert("Notice", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(errorAlertMessage)
        }
        .fullScreenCover(isPresented: $showGenerationResult, onDismiss: {
            viewModel.didJustGenerate = false
        }) {
            if let img = viewModel.generatedImage {
                HomeGenerationResultView(
                    image: img,
                    prompt: $viewModel.prompt,
                    onShare: {
                        ShareService.shared.present(items: [img, viewModel.prompt])
                    },
                    onSave: {
                        viewModel.saveToPhotos(img)
                        showSaveConfirmation = true
                    }
                )
            }
        }
    }

    private var selectedStyleCard: CategoryCard? {
        cards.first(where: { $0.id == selectedImageStyleId })
    }

    private var alertActionsTint: Color {
        if showErrorAlert || showSaveConfirmation { return .black }
        return Color.appAccent
    }

    private var homeHeader: some View {
        HStack(spacing: 12) {
            appIcon
            Text("AI Image")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appText)
            Spacer()

            HStack(spacing: 8) {
                Button {
                    subscriptionService.showShop = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "film")
                            .font(.system(size: 12, weight: .semibold))
                        Text("\(subscriptionService.credits)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundStyle(Color.appAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.appCard)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.appAccent.opacity(0.45), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                if !subscriptionService.isSubscribed {
                    Button {
                        subscriptionService.showPaywall = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 14, alignment: .center)
                            Text("Pro")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color.appAccent, Color.appAccentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .layoutPriority(1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background(Color.appBackground)
    }

    private var appIcon: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color.appAccent, Color.appAccent.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 22, height: 22)
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color.appAccentSecondary, Color.appAccentSecondary.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 22, height: 22)
        }
    }

}

/// Full-screen result after home generation (DiscoverDetailView-style: image, prompt card, Share / Save).
struct HomeGenerationResultView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    @Binding var prompt: String
    let onShare: () -> Void
    let onSave: () -> Void
    var onContinueToApp: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.appText)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your creation")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.appAccent)
                            Text(prompt)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.appText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        HStack(spacing: 12) {
                            Button(action: onShare) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.appAccent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.appAccent.opacity(0.18))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)

                            Button(action: onSave) {
                                Label("Save", systemImage: "square.and.arrow.down")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.appBackground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.appAccent)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }

                        if onContinueToApp != nil {
                            Button {
                                onContinueToApp?()
                                dismiss()
                            } label: {
                                Text("Continue to app")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.appBackground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.appAccent, Color.appAccentSecondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
}

private struct AspectRatioButton: View {
    let option: AspectRatioOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                AspectRatioShapeView(ratioString: option.rawValue)
                    .foregroundStyle(isSelected ? .white : Color.appAccent)
                Text(option.rawValue)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : Color.appAccent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.appAccent, Color.appAccentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.appPromptBackground.opacity(0.6)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.white.opacity(0.3) : Color.appAccent.opacity(0.5),
                        lineWidth: isSelected ? 1 : 1.2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

/// Desenează forma proporțională pentru orice raport "a:b" — pătrat, vertical sau orizontal, cu colțuri rotunjite.
private struct AspectRatioShapeView: View {
    let ratioString: String
    private let maxSize: CGFloat = 36
    private let strokeWidth: CGFloat = 2.2
    private let cornerRadius: CGFloat = 5

    private var width: CGFloat {
        let (w, h) = parsedRatio
        if w >= h {
            return maxSize
        }
        return maxSize * (CGFloat(w) / CGFloat(h))
    }

    private var height: CGFloat {
        let (w, h) = parsedRatio
        if w >= h {
            return maxSize * (CGFloat(h) / CGFloat(w))
        }
        return maxSize
    }

    private var parsedRatio: (Int, Int) {
        let parts = ratioString.split(separator: ":")
        guard parts.count == 2,
              let a = Int(parts[0]),
              let b = Int(parts[1]),
              a > 0, b > 0 else { return (1, 1) }
        return (a, b)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(lineWidth: strokeWidth)
            .frame(width: width, height: height)
            .frame(width: maxSize, height: maxSize)
    }
}

// MARK: - Skeleton loading pentru Image Style cards (pulse)
private struct ImageStyleSkeletonCard: View {
    private let size: CGFloat = 140
    @State private var opacity: Double = 0.4

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appPromptBackground)
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appAccent.opacity(opacity * 0.35))
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))

            RoundedRectangle(cornerRadius: 6)
                .fill(Color.appPromptBackground)
                .frame(width: size * 0.6, height: 14)
                .opacity(0.8 + opacity * 0.2)
        }
        .frame(width: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                opacity = 0.9
            }
        }
    }
}

// MARK: - Square Image Style card: image on top, title (category) below
private struct ImageStyleCardView: View {
    let card: CategoryCard
    let isSelected: Bool
    let onTap: () -> Void
    private let size: CGFloat = 140

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                Group {
                    if let assetImage = UIImage(named: card.imageURL) {
                        Image(uiImage: assetImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if let url = URL(string: card.imageURL), url.scheme?.hasPrefix("http") == true {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                fallbackImage
                            case .empty:
                                loadingImage
                            default:
                                loadingImage
                            }
                        }
                    } else {
                        fallbackImage
                    }
                }
                .frame(width: size, height: size)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.appAccent : Color.clear, lineWidth: 2)
                )

                Text(card.category)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? Color.appAccent : Color.appText)
                    .lineLimit(1)
            }
            .frame(width: size)
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var fallbackImage: some View {
        LinearGradient(
            colors: [Color.appAccent.opacity(0.5), Color.appAccentSecondary.opacity(0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: "photo.fill")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.7))
        )
    }

    @ViewBuilder
    private var loadingImage: some View {
        ZStack {
            Color.appPromptBackground
            ProgressView()
                .tint(Color.appAccent)
        }
    }
}
