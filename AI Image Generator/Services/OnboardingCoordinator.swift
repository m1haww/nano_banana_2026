import Combine
import SwiftUI

@MainActor
final class OnboardingCoordinator: ObservableObject {
    static let shared = OnboardingCoordinator()

    private let introKey = "onboarding.intro.completed"
    private let welcomeKey = "onboarding.welcome.completed"

    @Published private(set) var hasCompletedIntro: Bool
    @Published private(set) var hasCompletedWelcomeFlow: Bool

    private init() {
        hasCompletedIntro = UserDefaults.standard.bool(forKey: introKey)
        hasCompletedWelcomeFlow = UserDefaults.standard.bool(forKey: welcomeKey)
    }

    func completeIntro() {
        UserDefaults.standard.set(true, forKey: introKey)
        hasCompletedIntro = true
    }

    func completeWelcomeFlow() {
        UserDefaults.standard.set(true, forKey: welcomeKey)
        hasCompletedWelcomeFlow = true
        UserService.shared.registerIfNeeded()
        SubscriptionService.shared.presentPaywallAfterWelcomeIfNeeded()
    }
}
