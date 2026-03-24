//
//  HomeView.swift
//  AI Image Generator
//

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

    @State private var cards: [CategoryCard] = []
    @State private var isLoadingImageStyles = true
    @StateObject private var viewModel = CreateViewModel()
    @State private var selectedAspectRatio: AspectRatioOption = .oneToOne
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    @State private var showSaveConfirmation = false
    @State private var showAllImageStyles = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @FocusState private var promptFocused: Bool
    @State private var showResultPage = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header: icon, app name, Pro
                    HStack(spacing: 12) {
                        appIcon
                        Text("PigFig")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.appText)
                        Spacer()
                        Button { } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12))
                                Text("Pro")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.white)
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    // Enter Prompt
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Enter Prompt")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.appText)
                            Spacer()
                            NavigationLink {
                                ExplorePromptsView(currentPrompt: viewModel.prompt) { selected in
                                    viewModel.prompt = selected
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text("Explore Prompts")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundStyle(Color.appAccent)
                            }
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

                    // Aspect Ratio
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Aspect Ratio")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.appText)
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
                            .padding(.horizontal, 2)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Image Style – horizontal square cards; tap pe săgeată → pagină cu toate cardurile
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            showAllImageStyles = true
                        } label: {
                            HStack {
                                Text("Image Style")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.appText)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.appAccent)
                            }
                        }
                        .buttonStyle(.plain)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                if isLoadingImageStyles {
                                    ForEach(0..<5, id: \.self) { _ in
                                        ImageStyleSkeletonCard()
                                    }
                                } else {
                                    ForEach(cards) { card in
                                        ImageStyleCardView(card: card)
                                    }
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Result area (when generating or has image)
                    if viewModel.isGenerating || viewModel.generatedImage != nil {
                        resultSection
                            .padding(.horizontal, 20)
                    }

                    if let err = viewModel.errorMessage {
                        Text(err)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 20)
                    }

                    // Get Started button
                    Button {
                        promptFocused = false
                        viewModel.aspectRatio = selectedAspectRatio.rawValue
                        Task { await viewModel.generate() }
                    } label: {
                        HStack(spacing: 10) {
                            if viewModel.isGenerating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Get Started")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundStyle(.white)
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
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
            .background(Color.appBackground)
            .onTapGesture { promptFocused = false }
            .onAppear {
                if let prompt = initialPromptFromDiscover {
                    viewModel.prompt = prompt
                    initialPromptFromDiscover = nil
                }
                print("[HomeView] onAppear: pornim loading, apelăm MockDataLoader.loadCards")
                isLoadingImageStyles = true
                MockDataLoader.loadCards { loaded in
                    print("[HomeView] loadCards completion: \(loaded.count) carduri → cards = loaded")
                    cards = loaded
                    withAnimation(.easeOut(duration: 0.3)) {
                        isLoadingImageStyles = false
                    }
                }
            }
        }
        }
        .sheet(isPresented: $showShareSheet) {
            if !shareItems.isEmpty {
                ShareSheet(items: shareItems)
            }
        }
        .sheet(isPresented: $showAllImageStyles) {
            AllImageStylesView(cards: cards)
        }
        .alert("Saved", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Image saved to Photos.")
        }
        .fullScreenCover(isPresented: $showResultPage) {
            if let img = viewModel.generatedImage {
                ResultView(
                    image: img,
                    prompt: $viewModel.prompt,
                    initialAspectRatio: viewModel.aspectRatio,
                    onFinalize: { },
                    onReGenerate: {
                        Task { await viewModel.generate() }
                    },
                    onShare: {
                        shareItems = [img, viewModel.prompt]
                        showShareSheet = true
                        showResultPage = false
                    },
                    onDownload: {
                        viewModel.saveToPhotos(img)
                        showSaveConfirmation = true
                    }
                )
            }
        }
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

    @ViewBuilder
    private var resultSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appPromptBackground)
                .frame(minHeight: 220)
                .overlay {
                    if viewModel.isGenerating {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(Color.appAccent)
                            Text("Generating…")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.appTextSecondary)
                        }
                    } else if let img = viewModel.generatedImage {
                        Button {
                            showResultPage = true
                        } label: {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .buttonStyle(.plain)
                    }
                }
            if viewModel.generatedImage != nil && !viewModel.isGenerating {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Button {
                            showResultPage = true
                        } label: {
                            Text("Finalize")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.appAccent)
                        }
                        Button {
                            if let img = viewModel.generatedImage {
                                viewModel.saveToPhotos(img)
                                showSaveConfirmation = true
                            }
                        } label: {
                            Label("Save", systemImage: "square.and.arrow.down")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.appAccent)
                        }
                        Button {
                            if let img = viewModel.generatedImage {
                                shareItems = [img, viewModel.prompt]
                                showShareSheet = true
                            }
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.appAccent)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.bottom, 16)
                }
            }
        }
    }
}

// MARK: - Aspect Ratio button: desen proporțional + text, toate rapoartele Nano Banana
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
            .shadow(
                color: isSelected ? Color.appAccent.opacity(0.35) : .clear,
                radius: 8,
                x: 0,
                y: 4
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

// MARK: - Pagină cu toate cardurile Image Style (la tap pe săgeată)
private struct AllImageStylesView: View {
    let cards: [CategoryCard]
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(cards) { card in
                        ImageStyleCardView(card: card)
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground)
            .navigationTitle("Image Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Square Image Style card: image on top, title (category) below
private struct ImageStyleCardView: View {
    let card: CategoryCard
    private let size: CGFloat = 140

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Group {
                if let uiImage = UIImage(named: card.image) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
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
            }
            .frame(width: size, height: size)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(card.category)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.appText)
                .lineLimit(1)
        }
        .frame(width: size)
    }
}

#Preview {
    HomeView(initialPromptFromDiscover: .constant(nil))
}
