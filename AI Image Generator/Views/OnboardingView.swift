import SwiftUI

struct OnboardingView: View {
    var onFinished: () -> Void

    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "wand.and.stars",
            title: "Create from words",
            subtitle: "Describe a scene, character, or style — your prompt becomes a unique AI image in moments."
        ),
        OnboardingPage(
            symbol: "slider.horizontal.3",
            title: "Shape every render",
            subtitle: "Pick aspect ratio and image styles so every generation matches how you imagine it."
        ),
        OnboardingPage(
            symbol: "photo.on.rectangle.angled",
            title: "Bring a reference",
            subtitle: "Add a photo to guide the look: edit, restyle, or combine ideas with what you upload."
        ),
        OnboardingPage(
            symbol: "square.grid.2x2",
            title: "Discover & save",
            subtitle: "Browse prompts for inspiration, remix ideas, and keep favorites in your personal library."
        ),
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip") {
                        onFinished()
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        OnboardingPageView(page: item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageIndicator

                Button(action: advance) {
                    Text(page >= pages.count - 1 ? "Get started" : "Next")
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
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Color.appAccent : Color.appDivider)
                    .frame(width: i == page ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: page)
            }
        }
        .padding(.vertical, 20)
    }

    private func advance() {
        if page >= pages.count - 1 {
            onFinished()
        } else {
            page += 1
        }
    }
}

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let subtitle: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 12)

            ZStack {
                Circle()
                    .fill(Color.appAccent.opacity(0.12))
                    .frame(width: 140, height: 140)
                Circle()
                    .stroke(Color.appAccent.opacity(0.35), lineWidth: 1.5)
                    .frame(width: 140, height: 140)
                Image(systemName: page.symbol)
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appAccent, Color.appAccentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appText)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            Spacer(minLength: 24)
        }
    }
}
