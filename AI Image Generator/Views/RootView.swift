import RevenueCatUI
import RevenueCat
import SwiftUI

struct RootView: View {
    @StateObject private var onboarding = OnboardingCoordinator.shared
    @StateObject private var subscriptionService = SubscriptionService.shared

    var body: some View {
        Group {
            if !onboarding.hasCompletedOnboarding {
                switch onboarding.onboardingValue {
                case .v1:
                    OnboardingViewV1() {
                        onboarding.completeIntro()
                    }
                case .v2:
                    OnboardingViewV2() {
                        onboarding.completeIntro()
                    }
                case .v3:
                    OnboardingViewV3() {
                        onboarding.completeIntro()
                    }
                }
            } else {
                ContentView()
            }
        }
        .fullScreenCover(isPresented: $subscriptionService.showPaywall) {
            PaywallView()
                .onPurchaseCompleted { customerInfo in
                    let activeProductIds = Array(customerInfo.activeSubscriptions)
                    let credits = ShopCreditPackage.getCreditsForPurchasedSubscriptions(activeProductIds)
                    if credits > 0 {
                        UserService.shared.addCredits(credits) { success in
                            if success {
                                subscriptionService.addCredits(credits)
                            }
                        }
                    }
                    subscriptionService.fetchStatus()
                    subscriptionService.showPaywall = false
                }
                .onRestoreCompleted { customerInfo in
                    let activeProductIds = Array(customerInfo.activeSubscriptions)
                    let credits = ShopCreditPackage.getCreditsForPurchasedSubscriptions(activeProductIds)
                    if credits > 0 {
                        UserService.shared.addCredits(credits) { success in
                            if success {
                                subscriptionService.addCredits(credits)
                            }
                        }
                    }
                    subscriptionService.fetchStatus()
                    subscriptionService.showPaywall = false
                }
        }
        .fullScreenCover(isPresented: $subscriptionService.showShop) {
            ShopView()
        }
    }
}
