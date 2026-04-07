import SwiftUI
import StoreKit

private struct OnboardingV2Page {
    let beforeAsset: String
    let afterAsset: String
    let title: String
    let subtitle: String
}

private enum OnboardingV2MainBody: Equatable {
    case compare
    case surveyComfort
    case surveyGoals
    case reviewPrompt
    case setupLoading
}

private struct OnboardingV2Testimonial: Identifiable {
    var id: String { name }
    let name: String
    let quote: String
}

/// Vertical split: leading side shows `before`, trailing side shows `after`. Drag horizontally to adjust.
private struct OnboardingCompareSlider: View {
    let beforeImage: String
    let afterImage: String
    @Binding var splitFraction: CGFloat

    private let cornerRadius: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            let w = max(geo.size.width, 1)
            let h = geo.size.height
            let split = min(max(splitFraction * w, 0), w)

            ZStack(alignment: .leading) {
                Image(afterImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()

                Image(beforeImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(width: split)
                    }

                Rectangle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 3)
                    .shadow(color: .black.opacity(0.35), radius: 4, y: 0)
                    .offset(x: split - 1.5)

                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                        .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(Color.appAccentSecondary)
                }
                .offset(x: split - 22)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        splitFraction = min(max(value.location.x / w, 0), 1)
                    }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "Before and after comparison"))
            .accessibilityHint(String(localized: "Drag horizontally to compare images"))
            .accessibilityValue(String(format: String(localized: "%lld percent before visible on the left"), Int(splitFraction * 100)))
        }
    }
}

private struct OnboardingV2SelectableOptionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Text(title.localized)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.appText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.appAccent)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.appCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isSelected ? Color.appAccent.opacity(0.9) : Color.appDivider.opacity(0.45),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingViewV2: View {
    let onFinished: () -> Void

    @State private var mainBody: OnboardingV2MainBody = .compare
    @State private var currentPage = 0
    @State private var splitFraction: CGFloat = 0.5
    @State private var comfortSelection: String?
    @State private var goalSelections: Set<String> = []
    @State private var setupProgress: Double = 0

    @Environment(\.requestReview) private var requestReview

    private let setupStepTitles = [
        "Preparing your workspace...",
        "Analyzing your preferences...",
        "Powering up smart features...",
        "Customizing your experience...",
        "Loading AI models...",
        "Almost there..."
    ]

    private let setupStepThresholds: [Double] = [0.12, 0.26, 0.44, 0.58, 0.74, 0.9]

    private let testimonials: [OnboardingV2Testimonial] = [
        OnboardingV2Testimonial(name: "Sarah M.", quote: "This app is incredible! The AI editing is so realistic."),
        OnboardingV2Testimonial(name: "James T.", quote: "Fast results and polished looks—my go-to for social posts."),
        OnboardingV2Testimonial(name: "Elena R.", quote: "Love how simple it is to get pro-level images in seconds.")
    ]

    private let comfortOptions = [
        "I'm new",
        "I know the basics",
        "I know what I'm doing"
    ]

    private let goalOptions = [
        "Edited photos and videos",
        "Social media content",
        "Logos and graphics",
        "Product photos",
        "YouTube/Shorts thumbnails",
        "Portraits & headshots"
    ]

    private let pages: [OnboardingV2Page] = [
        OnboardingV2Page(
            beforeAsset: "onb2_1_1",
            afterAsset: "onb2_1_2",
            title: "Remove Background",
            subtitle: "Drag the slider to compare the original with a clean AI cutout—perfect for products and profiles."
        ),
        OnboardingV2Page(
            beforeAsset: "onb2_2_1",
            afterAsset: "onb2_2_2",
            title: "Glam Makeover",
            subtitle: "Swipe to reveal subtle lighting and tone enhancements in one smooth motion."
        ),
        OnboardingV2Page(
            beforeAsset: "onb2_3_1",
            afterAsset: "onb2_3_2",
            title: "Portrait Polish",
            subtitle: "See how AI refines faces and details while keeping a natural look."
        ),
        OnboardingV2Page(
            beforeAsset: "onb2_4_1",
            afterAsset: "onb2_4_2",
            title: "Landscape Boost",
            subtitle: "Compare before and after as color, depth, and clarity come forward."
        ),
        OnboardingV2Page(
            beforeAsset: "onb2_5_1",
            afterAsset: "onb2_5_2",
            title: "Car Modify",
            subtitle: "Transform your car with custom modifications. See the power of AI."
        )
    ]

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            Group {
                switch mainBody {
                case .compare:
                    compareSection
                case .surveyComfort:
                    comfortSurveySection
                case .surveyGoals:
                    goalsSurveySection
                case .reviewPrompt:
                    reviewPromptSection
                case .setupLoading:
                    setupLoadingSection
                }
            }
            .animation(.easeInOut(duration: 0.28), value: mainBody)
        }
        .onChange(of: currentPage) { _ in
            guard mainBody == .compare else { return }
            splitFraction = 0.5
        }
        .task(id: mainBody) {
            guard mainBody == .setupLoading else { return }
            await runPersonalizedSetupSequence()
        }
    }

    private var compareSection: some View {
        let page = pages[currentPage]

        return VStack(spacing: 0) {
            OnboardingCompareSlider(
                beforeImage: page.beforeAsset,
                afterImage: page.afterAsset,
                splitFraction: $splitFraction
            )
            .aspectRatio(3 / 4, contentMode: .fit)
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Spacer(minLength: 16)

            VStack(alignment: .leading, spacing: 10) {
                Text(page.title.localized)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appText)

                Text(page.subtitle.localized)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.appTextSecondary)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)

            Spacer(minLength: 20)

            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(currentPage == index ? Color.appAccent : Color.appDivider.opacity(0.6))
                        .frame(width: currentPage == index ? 22 : 7, height: 7)
                        .animation(.easeInOut(duration: 0.25), value: currentPage)
                }
            }
            .padding(.bottom, 20)

            HStack(spacing: 14) {
                if currentPage > 0 {
                    Button(action: goBackCompare) {
                        Text(String(localized: "Back"))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.appAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(Color.appAccent.opacity(0.55), lineWidth: 1.5)
                            )
                    }
                }

                Button(action: goNextCompare) {
                    Text(String(localized: "Next"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color.appAccent)
                        )
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 22)
        }
    }

    // MARK: - Survey shared

    private func surveyProgressDots(activeIndex: Int) -> some View {
        HStack(spacing: 10) {
            ForEach(0..<2, id: \.self) { index in
                Circle()
                    .fill(index == activeIndex ? Color.appAccent : Color.appDivider.opacity(0.55))
                    .frame(width: index == activeIndex ? 9 : 8, height: index == activeIndex ? 9 : 8)
            }
        }
    }

    // MARK: - Comfort (Q1)

    private var comfortSurveySection: some View {
        VStack(spacing: 0) {
            surveyProgressDots(activeIndex: 0)
                .padding(.top, 28)

            Text(String(localized: "QUESTION 1 OF 2"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.appTextSecondary)
                .tracking(0.8)
                .padding(.top, 20)

            Text(String(localized: "What is your comfort level with editing apps?"))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)

            VStack(spacing: 12) {
                ForEach(comfortOptions, id: \.self) { option in
                    OnboardingV2SelectableOptionRow(
                        title: option,
                        isSelected: comfortSelection == option
                    ) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        comfortSelection = option
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)

            Spacer(minLength: 24)

            HStack(spacing: 12) {
                Spacer(minLength: 8)

                Button(action: goNextComfort) {
                    HStack(spacing: 6) {
                        Text(String(localized: "Next"))
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.appAccent)
                    )
                }
                .disabled(comfortSelection == nil)
                .opacity(comfortSelection == nil ? 0.45 : 1)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 22)
        }
    }

    // MARK: - Goals (Q2)

    private var goalsSurveySection: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 28)

            surveyProgressDots(activeIndex: 1)

            Text(String(localized: "QUESTION 2 OF 2"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.appTextSecondary)
                .tracking(0.8)
                .padding(.top, 20)

            Text(String(localized: "What are you going to create? (multiple selection allowed)"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 14)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(goalOptions, id: \.self) { option in
                        OnboardingV2SelectableOptionRow(
                            title: option,
                            isSelected: goalSelections.contains(option)
                        ) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if goalSelections.contains(option) {
                                goalSelections.remove(option)
                            } else {
                                goalSelections.insert(option)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 12)
            }

            Spacer(minLength: 12)

            HStack(spacing: 10) {
                Button(action: goBackFromGoals) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text(String(localized: "Back"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(Color.appTextSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 14)
                }

                Spacer(minLength: 4)

                Button(action: finishGoalsTapped) {
                    HStack(spacing: 6) {
                        Text(String(localized: "Finish"))
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.appAccent)
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 22)
        }
    }

    // MARK: - Review

    private var reviewPromptSection: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Text(String(localized: "We Need Your Help!"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 32)
                        .padding(.horizontal, 24)

                    starRow(filled: 5, size: 22)
                        .padding(.top, 16)

                    Text(String(localized: "Your feedback will help us to reach more people. Would you mind taking a moment to give us a positive review? It really helps us!"))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 28)
                        .padding(.top, 18)

                    VStack(spacing: 12) {
                        ForEach(testimonials) { item in
                            testimonialCard(item)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 28)
                    .padding(.bottom, 24)
                }
            }

            VStack(spacing: 12) {
                Button(action: rateOnAppStoreTapped) {
                    HStack(spacing: 10) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 18))
                        Text(String(localized: "Rate us"))
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.appAccent, Color.appAccentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                }

                Button(action: maybeLaterReviewTapped) {
                    Text(String(localized: "Maybe Later"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color.appCard)
                        )
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 22)
            .background(Color.appBackground.opacity(0.98))
        }
    }

    private func starRow(filled: Int, size: CGFloat) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: index < filled ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(
                        index < filled ? Color.appAccent : Color.appDivider.opacity(0.55)
                    )
            }
        }
    }

    private func testimonialCard(_ item: OnboardingV2Testimonial) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(item.name.localized)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.appText)
                Spacer()
                starRow(filled: 5, size: 12)
            }
            Text(item.quote.localized)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.appPromptBackground.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.appDivider.opacity(0.35), lineWidth: 1)
                )
        )
    }

    // MARK: - Setup loading

    private var setupLoadingSection: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 36)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appAccent.opacity(0.35),
                                Color.appAccentSecondary.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.appAccent)
            }
            .padding(.bottom, 28)

            Text(String(localized: "Setting up your personalized experience"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 10) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.appDivider.opacity(0.4))
                            .frame(height: 8)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.appAccent, Color.appAccentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, geo.size.width * setupProgress), height: 8)
                    }
                }
                .frame(height: 8)
                .padding(.top, 28)

                Text(String(format: String(localized: "%lld%%"), Int((setupProgress * 100).rounded())))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 36)
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(setupStepTitles.indices, id: \.self) { index in
                    setupStepRow(title: setupStepTitles[index], isComplete: isSetupStepComplete(index: index))
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 32)

            Spacer(minLength: 40)
        }
    }

    private func setupStepRow(title: String, isComplete: Bool) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                if isComplete {
                    Circle()
                        .fill(Color.green.opacity(0.92))
                        .frame(width: 26, height: 26)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Circle()
                        .strokeBorder(Color.appDivider.opacity(0.7), lineWidth: 2)
                        .frame(width: 26, height: 26)
                }
            }
            Text(title.localized)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isComplete ? Color.appText : Color.appTextSecondary.opacity(0.5))
            Spacer(minLength: 0)
        }
    }

    private func isSetupStepComplete(index: Int) -> Bool {
        guard index < setupStepThresholds.count else { return setupProgress >= 1 }
        return setupProgress >= setupStepThresholds[index]
    }

    // MARK: - Actions

    private func goBackCompareInternal() {
        guard currentPage > 0 else { return }
        withAnimation(.easeInOut(duration: 0.28)) {
            currentPage -= 1
        }
    }

    private func goBackCompare() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        goBackCompareInternal()
    }

    private func goNextCompare() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if currentPage < pages.count - 1 {
            withAnimation(.easeInOut(duration: 0.28)) {
                currentPage += 1
            }
        } else {
            withAnimation(.easeInOut(duration: 0.28)) {
                mainBody = .surveyComfort
            }
        }
    }

    private func goBackFromGoals() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.28)) {
            mainBody = .surveyComfort
        }
    }

    private func goNextComfort() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        guard comfortSelection != nil else { return }
        withAnimation(.easeInOut(duration: 0.28)) {
            mainBody = .surveyGoals
        }
    }

    private func finishGoalsTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        proceedToReviewPrompt()
    }

    private func proceedToReviewPrompt() {
        withAnimation(.easeInOut(duration: 0.28)) {
            mainBody = .reviewPrompt
        }
    }

    private func rateOnAppStoreTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        requestReview()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            proceedToSetupLoading()
        })
    }

    private func maybeLaterReviewTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        proceedToSetupLoading()
    }

    private func proceedToSetupLoading() {
        withAnimation(.easeInOut(duration: 0.28)) {
            setupProgress = 0
            mainBody = .setupLoading
        }
    }

    private func runPersonalizedSetupSequence() async {
        await MainActor.run {
            setupProgress = 0
        }
        let ticks = 48
        for i in 0...ticks {
            try? await Task.sleep(nanoseconds: 68_000_000)
            if Task.isCancelled { return }
            let p = Double(i) / Double(ticks)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.1)) {
                    setupProgress = p
                }
            }
        }
        if Task.isCancelled { return }
        await MainActor.run {
            setupProgress = 1
        }
        try? await Task.sleep(nanoseconds: 420_000_000)
        if Task.isCancelled { return }
        await MainActor.run {
            onFinished()
        }
    }
}

#Preview {
    OnboardingViewV2(onFinished: {})
}
