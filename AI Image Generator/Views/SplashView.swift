import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var logoVisible = false
    @State private var titleVisible = false
    @State private var bottomProgressVisible = false
    @StateObject private var subscriptionService = SubscriptionService.shared

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: 20) {
                    Image("Icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: Color.appAccent.opacity(0.35), radius: 24, y: 12)
                        .opacity(logoVisible ? 1 : 0)
                        .scaleEffect(logoVisible ? 1 : 0.88)

                    VStack(spacing: 6) {
                        Text(String(localized: "AI Image"))
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.appText)

                        Text(String(localized: "Create with AI"))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .opacity(titleVisible ? 1 : 0)
                    .offset(y: titleVisible ? 0 : 8)
                }

                Spacer(minLength: 0)

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.appAccent)
                    .scaleEffect(1.05)
                    .opacity(bottomProgressVisible ? 1 : 0)
                    .accessibilityLabel(String(localized: "Loading"))
                    .padding(.bottom, 44)
            }
            .padding(.horizontal, 32)
        }
        .ignoresSafeArea()
        .task {
            await runIntro()
        }
    }

    private func runIntro() async {
        let openDuration: CGFloat = reduceMotion ? 0.2 : 0.55
        let titleDelay: UInt64 = reduceMotion ? 150_000_000 : 220_000_000
        let holdDuration: UInt64 = reduceMotion ? 400_000_000 : 850_000_000

        withAnimation(.spring(response: openDuration, dampingFraction: 0.82)) {
            logoVisible = true
        }
        try? await Task.sleep(nanoseconds: titleDelay)
        withAnimation(.easeOut(duration: reduceMotion ? 0.15 : 0.35)) {
            titleVisible = true
        }
        withAnimation(.easeOut(duration: reduceMotion ? 0.12 : 0.28)) {
            bottomProgressVisible = true
        }
        try? await Task.sleep(nanoseconds: holdDuration)
        
        await OnboardingCoordinator.shared.fetchOnboardingValue()
        
        if let userData = await UserService.shared.fetchUserData() {
            subscriptionService.setCredits(userData.user?.credits ?? 0)
            if let tasks = userData.tasks {
                VideoTaskService.shared.syncTasks(tasks)
            }
        }
        VideoTaskService.shared.resumePollingForPendingTasks()
        
        AnalyticsManager.shared.logEvent(name: "app_launch")
        
        onFinished()
    }
}

#Preview {
    SplashView(onFinished: {})
}
