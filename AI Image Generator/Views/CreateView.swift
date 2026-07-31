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
    case twoThree = "2:3"
    case threeTwo = "3:2"
    case threeFour = "3:4"
    case fourThree = "4:3"
    case fourFive = "4:5"
    case fiveFour = "5:4"
    case nineSixteen = "9:16"
    case sixteenNine = "16:9"
    case twentyOneNine = "21:9"
    case fourToOne = "4:1"
    case oneToFour = "1:4"
    case eightToOne = "8:1"
    case oneToEight = "1:8"
}

enum ResolutionOption: String, CaseIterable {
    case oneK = "1K"
    case twoK = "2K"
    case fourK = "4K"

    var creditCost: Int {
        switch self {
        case .oneK: return 10
        case .twoK: return 15
        case .fourK: return 20
        }
    }
}

struct CreateView: View {
    let prefilledPrompt: String?
    let initialTool: ToolExample?
    @Binding var selectedTab: MainTab

    @Environment(\.dismiss) private var dismiss

    @State private var cards: [CategoryCard] = CategoryCard.homeCards
    @StateObject private var viewModel = CreateViewModel()
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var selectedAspectRatio: AspectRatioOption = .oneToOne
    @State private var selectedResolution: ResolutionOption = .oneK
    @State private var showSaveConfirmation = false
    @State private var showExplorePrompts = false
    @State private var selectedImageStyleId: CategoryCard.ID?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @FocusState private var promptFocused: Bool
    @State private var showErrorAlert = false
    @State private var errorAlertMessage = ""
    @State private var showTaskSubmittedAlert = false
    @State private var showAllAspectRatios = false
    @State private var showAllStyles = false
    @State private var didApplyPrefill = false
    @State private var currentTool: ToolExample?

    private let allTools: [ToolExample] = ToolExample.defaults

    /// The first N aspect ratios shown inline; the rest are behind "+N".
    private let visibleAspectRatioCount = 5
    /// The first N styles shown inline on the home screen.
    private let visibleStyleCount = 4

    init(prefilledPrompt: String? = nil, tool: ToolExample? = nil, selectedTab: Binding<MainTab>) {
        self.prefilledPrompt = prefilledPrompt ?? tool?.prompt
        self.initialTool = tool
        self._selectedTab = selectedTab
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                createHeader

                ZStack(alignment: .bottom) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            // ── Selected tool badge (dacă vine dintr-un tool card) ──
                            if let tool = currentTool {
                                selectedToolBadge(tool: tool)
                                    .padding(.horizontal, 18)
                                    .padding(.top, 4)
                            }

                            // ── Prompt card ──
                            promptCard
                                .padding(.horizontal, 18)
                                .padding(.top, 6)

                            // ── Aspect Ratio ──
                            aspectRatioSection

                            // ── Resolution ──
                            resolutionSection

                            // ── Style ──  DISABLED (înlocuit cu other tools)
                            // styleSection

                            // ── Other tools (switcher rapid) ──
                            otherToolsSection
                        }
                        // Extra bottom padding so content isn't hidden behind the docked button
                        .padding(.bottom, 90)
                    }
                    .onTapGesture { promptFocused = false }

                    // ── Docked Generate bar ──
                    dockedGenerateBar
                }
                .onAppear {
                    if !didApplyPrefill {
                        if let prompt = prefilledPrompt, !prompt.isEmpty {
                            viewModel.prompt = prompt
                        }
                        currentTool = initialTool
                        didApplyPrefill = true
                    }
                }
            }
            .background(Color.appBackground)
            .frame(width: UIScreen.main.bounds.width)

            if viewModel.isGenerating {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    GenerationLoadingOverlay()
                }
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .tint(alertActionsTint)
        .onChange(of: selectedPhotoItem) { newItem in
            Task { await loadPickedPhoto(newItem) }
        }
        .onChange(of: viewModel.errorMessage) { newValue in
            if let msg = newValue, !msg.isEmpty {
                errorAlertMessage = msg
                showErrorAlert = true
            }
        }
        .onChange(of: viewModel.taskSubmitted) { submitted in
            if submitted {
                showTaskSubmittedAlert = true
                viewModel.taskSubmitted = false
            }
        }
        .fullScreenCover(isPresented: $showExplorePrompts) {
            ExplorePromptsView(currentPrompt: viewModel.prompt) { selected in
                viewModel.prompt = selected
            }
        }
        .alert(String(localized: "Saved"), isPresented: $showSaveConfirmation) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(String(localized: "Image saved to Photos."))
        }
        .alert(String(localized: "Notice"), isPresented: $showErrorAlert) {
            Button(String(localized: "OK"), role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(errorAlertMessage)
        }
        .alert(String(localized: "Creating your image"), isPresented: $showTaskSubmittedAlert) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(String(localized: "Your image is being generated. Feel free to keep using the app — we'll notify you when it's ready!"))
        }
        .sheet(isPresented: $showAllAspectRatios) {
            allAspectRatiosSheet
        }
        .sheet(isPresented: $showAllStyles) {
            allStylesSheet
        }
    }

    // MARK: - Header (with back button)

    private var createHeader: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.appText)
                    .frame(width: 34, height: 34)
                    .background(Color(hex: "17150F"))
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Text(String(localized: "Create"))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appText)

            Spacer()

            HStack(spacing: 8) {
                Button {
                    subscriptionService.showShop = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "film")
                            .font(.system(size: 12, weight: .semibold))
                        Text("\(subscriptionService.credits)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundStyle(Color.appAccent)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.appAccent.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                if !subscriptionService.isSubscribed {
                    Button {
                        subscriptionService.showPaywall = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "mountain.2.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text(String(localized: "Pro"))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .lineLimit(1)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .foregroundStyle(Color(hex: "221B04"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "FFD75E"), Color(hex: "EFAF0C")],
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
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(Color.appBackground)
    }

    // MARK: - Prompt Card

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Reference image thumbnail (visible when a photo is attached)
            if let refImage = viewModel.referenceImage {
                HStack(spacing: 12) {
                    Image(uiImage: refImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appAccent.opacity(0.35), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "Reference photo"))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.appText)
                        Text(String(localized: "Your image will be based on this"))
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(Color(hex: "8F897D"))
                    }

                    Spacer()

                    Button {
                        clearReferencePhoto()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // Text area
            ZStack(alignment: .topLeading) {
                Text(String(localized: "Describe anything, let our AI create magic for you…"))
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(hex: "8F897D"))
                    .lineSpacing(4)
                    .padding(.vertical, 0)
                    .allowsHitTesting(false)
                    .opacity(viewModel.prompt.isEmpty ? 1 : 0)
                AlignedPromptField(
                    text: $viewModel.prompt,
                    placeholder: String(localized: "Describe anything..."),
                    font: .systemFont(ofSize: 16, weight: .regular),
                    textColor: .white,
                    tintColor: UIColor(Color.appAccent),
                    minHeight: 64,
                    maxHeight: 160
                )
                .frame(minHeight: 64, maxHeight: 160)
            }

            // Inline action buttons
            HStack(spacing: 8) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                    HStack(spacing: 7) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 14, weight: .semibold))
                        Text(viewModel.referenceImage == nil
                             ? String(localized: "Add photo")
                             : String(localized: "Change photo"))
                            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color.appAccent)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(Color.appAccent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button {
                    showExplorePrompts = true
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                        Text(String(localized: "Surprise me"))
                            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color(hex: "CFC9BD"))
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color(hex: "1F1C17"))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.appAccent.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Aspect Ratio

    private var aspectRatioSection: some View {
        let allOptions = AspectRatioOption.allCases
        let visibleOptions = Array(allOptions.prefix(visibleAspectRatioCount))
        let overflowCount = max(0, allOptions.count - visibleAspectRatioCount)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(String(localized: "Aspect Ratio"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appText)
                Spacer()
                Text(selectedAspectRatio.rawValue)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(hex: "8F897D"))
            }
            .padding(.horizontal, 18)

            HStack(spacing: 8) {
                ForEach(visibleOptions, id: \.self) { option in
                    AspectRatioButton(
                        option: option,
                        isSelected: selectedAspectRatio == option
                    ) {
                        selectedAspectRatio = option
                    }
                }

                if overflowCount > 0 {
                    Button {
                        showAllAspectRatios = true
                    } label: {
                        Text("+\(overflowCount)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: "D8AE1C"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 72)
                            .background(Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 13))
                            .overlay(
                                RoundedRectangle(cornerRadius: 13)
                                    .stroke(Color.appAccent.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
        }
    }

    // MARK: - Resolution

    private var resolutionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(String(localized: "Resolution"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appText)
                Spacer()
                Text("\(selectedResolution.rawValue) · \(selectedResolution.creditCost) credit\(selectedResolution.creditCost == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(hex: "8F897D"))
            }
            .padding(.horizontal, 18)

            HStack(spacing: 8) {
                ForEach(ResolutionOption.allCases, id: \.self) { option in
                    ResolutionButton(
                        option: option,
                        isSelected: selectedResolution == option,
                        isPro: option == .fourK
                    ) {
                        selectedResolution = option
                    }
                }
            }
            .padding(.horizontal, 18)
        }
    }

    // MARK: - Selected Tool Badge (top of Create page)

    private func selectedToolBadge(tool: ToolExample) -> some View {
        HStack(spacing: 12) {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "FFD75E"), Color(hex: "EFAF0C")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 11))

                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Color(hex: "141210"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Using tool"))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "8F897D"))
                    .textCase(.uppercase)
                Text(tool.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appText)
            }

            Spacer()

            Button {
                currentTool = nil
                viewModel.prompt = ""
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "8F897D"))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(hex: "1F1C17"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appAccent.opacity(0.28), lineWidth: 1)
        )
    }

    // MARK: - Other Tools (quick switcher, replaces Style)

    private var otherToolsSection: some View {
        let otherTools = allTools.filter { $0.id != currentTool?.id }

        return VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Try another tool"))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appText)
                .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(otherTools) { tool in
                        Button {
                            promptFocused = false
                            currentTool = tool
                            viewModel.prompt = tool.prompt
                        } label: {
                            OtherToolCard(tool: tool)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    // MARK: - Style

    private var styleSection: some View {
        let visibleCards = Array(cards.prefix(visibleStyleCount))

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(String(localized: "Style"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appText)
                Spacer()
                Button {
                    showAllStyles = true
                } label: {
                    Text(String(localized: "All styles →"))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appAccent)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(visibleCards) { card in
                        ImageStyleCardView(
                            card: card,
                            isSelected: selectedImageStyleId == card.id
                        ) {
                            selectedImageStyleId = selectedImageStyleId == card.id ? nil : card.id
                        }
                        .padding(.vertical, 1)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    // MARK: - Docked Generate Bar

    private var dockedGenerateBar: some View {
        VStack(spacing: 0) {
            // Gradient fade so content doesn't abruptly cut off
            LinearGradient(
                colors: [Color.appBackground.opacity(0), Color.appBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            .allowsHitTesting(false)

            Button {
                promptFocused = false

                guard !viewModel.prompt.isEmpty else { return }

                guard subscriptionService.credits >= selectedResolution.creditCost else {
                    if subscriptionService.isSubscribed {
                        subscriptionService.showShop = true
                    } else {
                        subscriptionService.showPaywall = true
                    }
                    return
                }

                viewModel.aspectRatio = selectedAspectRatio
                viewModel.resolution = selectedResolution.rawValue
                viewModel.generationCost = selectedResolution.creditCost
                let stylePrefix = selectedStyleCard.map { "\($0.category) style: " } ?? ""
                Task {
                    await viewModel.generate(stylePrefix: stylePrefix)
                    self.selectedAspectRatio = .oneToOne
                    self.selectedResolution = .oneK
                    viewModel.referenceImage = nil
                    viewModel.prompt = ""
                    try? await Task.sleep(for: .seconds(0.5))
                    selectedTab = .profile
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .heavy))
                    Text(viewModel.referenceImage == nil
                         ? String(localized: "Generate")
                         : String(localized: "Edit"))
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                    Text(String(localized: "1 image · \(selectedResolution.creditCost) credits"))
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        .opacity(0.65)
                }
                .foregroundStyle(Color(hex: "141210"))
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FFD75E"), Color(hex: "EFAF0C")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 30))
            }
            .disabled(viewModel.isGenerating)
            .opacity(viewModel.isGenerating ? 0.55 : 1)
            .padding(.horizontal, 18)
            .padding(.bottom, 4)
            .background(Color.appBackground)

            Text(creditsLeftHelperText)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(Color(hex: "6F6B66"))
                .padding(.bottom, 10)
                .background(Color.appBackground)
        }
    }

    private var creditsLeftHelperText: String {
        let credits = subscriptionService.credits
        let perImage = selectedResolution.creditCost
        let imagesLeft = perImage > 0 ? credits / perImage : 0
        return String(
            localized: "\(credits) credits left — about \(imagesLeft) more images at \(selectedResolution.rawValue)"
        )
    }

    // MARK: - All Aspect Ratios Sheet

    private var allAspectRatiosSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()), GridItem(.flexible()),
                    GridItem(.flexible()), GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(AspectRatioOption.allCases, id: \.self) { option in
                        Button {
                            selectedAspectRatio = option
                            showAllAspectRatios = false
                        } label: {
                            VStack(spacing: 8) {
                                AspectRatioShapeView(ratioString: option.rawValue)
                                    .foregroundStyle(selectedAspectRatio == option ? .white : Color.appAccent)
                                Text(option.rawValue)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(selectedAspectRatio == option ? .white : Color.appAccent)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                selectedAspectRatio == option
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [Color.appAccent, Color.appAccentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                : AnyShapeStyle(Color(hex: "1F1C17"))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        selectedAspectRatio == option
                                        ? Color.white.opacity(0.3)
                                        : Color.appAccent.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
            }
            .background(Color.appBackground)
            .navigationTitle(String(localized: "Aspect Ratio"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) {
                        showAllAspectRatios = false
                    }
                    .foregroundStyle(Color.appAccent)
                }
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - All Styles Sheet

    private var allStylesSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()), GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(cards) { card in
                        Button {
                            selectedImageStyleId = selectedImageStyleId == card.id ? nil : card.id
                            showAllStyles = false
                        } label: {
                            VStack(spacing: 8) {
                                Group {
                                    if let assetImage = UIImage(named: card.imageURL) {
                                        Image(uiImage: assetImage)
                                            .resizable()
                                            .scaledToFit()
                                    } else if let url = URL(string: card.imageURL), url.scheme?.hasPrefix("http") == true {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            case .failure:
                                                Color(hex: "1F1C17")
                                                    .overlay(
                                                        Image(systemName: "photo.fill")
                                                            .font(.system(size: 28))
                                                            .foregroundStyle(.white.opacity(0.4))
                                                    )
                                            default:
                                                ZStack {
                                                    Color.appPromptBackground
                                                    ProgressView().tint(Color.appAccent)
                                                }
                                            }
                                        }
                                    } else {
                                        Color(hex: "1F1C17")
                                    }
                                }
                                .frame(width: 170, height: 120)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            selectedImageStyleId == card.id ? Color.appAccent : Color.clear,
                                            lineWidth: 2
                                        )
                                )

                                Text(card.category.localized)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(
                                        selectedImageStyleId == card.id ? Color.appText : Color(hex: "B7B1A5")
                                    )
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
            }
            .background(Color.appBackground)
            .navigationTitle(String(localized: "All Styles"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) {
                        showAllStyles = false
                    }
                    .foregroundStyle(Color.appAccent)
                }
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Helpers

    private func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                await MainActor.run {
                    errorAlertMessage = String(localized: "Could not load this photo.")
                    showErrorAlert = true
                }
                return
            }
            await MainActor.run {
                viewModel.setReferenceImage(image)
            }
        } catch {
            await MainActor.run {
                errorAlertMessage = String(localized: "Could not load this photo.")
                showErrorAlert = true
            }
        }
    }

    private func clearReferencePhoto() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        selectedPhotoItem = nil
        viewModel.clearReferenceImage()
    }

    private var selectedStyleCard: CategoryCard? {
        cards.first(where: { $0.id == selectedImageStyleId })
    }

    private var alertActionsTint: Color {
        if showErrorAlert || showSaveConfirmation { return .black }
        return Color.appAccent
    }
}

private struct AspectRatioButton: View {
    let option: AspectRatioOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                AspectRatioShapeView(ratioString: option.rawValue)
                    .foregroundStyle(isSelected ? Color(hex: "221B04") : Color(hex: "D8AE1C"))
                Text(option.rawValue.localized)
                    .font(.system(size: 13, weight: isSelected ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? Color(hex: "221B04") : Color(hex: "D8AE1C"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color(hex: "FFD75E"), Color(hex: "EFAF0C")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.clear
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(
                        isSelected ? Color.clear : Color.appAccent.opacity(0.25),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ResolutionButton: View {
    let option: ResolutionOption
    let isSelected: Bool
    var isPro: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(option.rawValue.localized)
                    .font(.system(size: 14, weight: isSelected ? .bold : .semibold, design: .rounded))
                if isPro {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 10, weight: .semibold))
                }
            }
            .foregroundStyle(isSelected ? Color(hex: "221B04") : Color(hex: "D8AE1C"))
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color(hex: "FFD75E"), Color(hex: "EFAF0C")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.clear
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(
                        isSelected ? Color.clear : Color.appAccent.opacity(0.25),
                        lineWidth: 1
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

// MARK: - Style card: square image with title below
private struct ImageStyleCardView: View {
    let card: CategoryCard
    let isSelected: Bool
    let onTap: () -> Void
    private let size: CGFloat = 104

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
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
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color.appAccent : Color.clear, lineWidth: 2)
                )

                Text(card.category.localized)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? Color.appText : Color(hex: "B7B1A5"))
                    .lineLimit(1)
            }
            .frame(width: size)
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
                .font(.system(size: 28))
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

// MARK: - Other Tool Card (small chip in Create page)

private struct OtherToolCard: View {
    let tool: ToolExample
    private let size: CGFloat = 96

    var body: some View {
        VStack(spacing: 6) {
            Group {
                if let name = tool.afterImage, UIImage(named: name) != nil {
                    Image(name)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    LinearGradient(
                        colors: tool.afterGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.white.opacity(0.5))
                    )
                }
            }
            .frame(width: size, height: size)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            Text(tool.name)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "CFC9BD"))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(width: size)
    }
}
