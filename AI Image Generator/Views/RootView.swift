import RevenueCatUI
import RevenueCat
import SwiftUI

struct RootView: View {
    @StateObject private var onboarding = OnboardingCoordinator.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var didSyncCreditsOnLaunch = false

    var body: some View {
        Group {
            if !onboarding.hasCompletedIntro {
                OnboardingView {
                    onboarding.completeIntro()
                }
            } else if !onboarding.hasCompletedWelcomeFlow {
                WelcomeFreeGenerationView {
                    onboarding.completeWelcomeFlow()
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
        .task {
            guard !didSyncCreditsOnLaunch else { return }
            didSyncCreditsOnLaunch = true
            UserService.shared.fetchUserCreditsIfRegistered { credits in
                guard let credits else { return }
                subscriptionService.setCredits(credits)
                print("Fetched credits for user: \(credits)")
            }
        }
    }
}
