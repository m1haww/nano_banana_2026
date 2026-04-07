import Combine
import SwiftUI
import FirebaseRemoteConfig

enum OnboardingValue: String {
    case v1 = "v1"
    case v2 = "v2"
    case v3 = "v3"
}

@MainActor
final class OnboardingCoordinator: ObservableObject {
    static let shared = OnboardingCoordinator()

    private let introKey = "onboarding.intro.completed"

    @Published var hasCompletedOnboarding: Bool = false
    @Published var onboardingValue: OnboardingValue = .v3
    
    private let remoteConfigKey = "onboardingValue"
    private var remoteConfig: RemoteConfig {
        RemoteConfig.remoteConfig()
    }

    private init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: introKey)
    }
    
    func fetchOnboardingValue() async {
        do {
            let remoteConfig = RemoteConfig.remoteConfig()
            let settings = RemoteConfigSettings()
            settings.minimumFetchInterval = 0
            remoteConfig.configSettings = settings
            
            _ = try await remoteConfig.fetch()
            _ = try await remoteConfig.activate()
            
            let value = remoteConfig.configValue(forKey: remoteConfigKey).stringValue.lowercased()
            guard let variant = OnboardingValue(rawValue: value) else { return }
            
            await MainActor.run {
                self.onboardingValue = variant
            }
            
            print("Fetched onboarding variant: \(variant.rawValue)")
        } catch {
            print("Failed to fetch/activate remote config: \(error.localizedDescription)")
        }
    }

    func completeIntro() {
        UserDefaults.standard.set(true, forKey: introKey)
        hasCompletedOnboarding = true
        UserService.shared.registerIfNeeded()
        SubscriptionService.shared.presentPaywallAfterWelcomeIfNeeded()
    }
}
