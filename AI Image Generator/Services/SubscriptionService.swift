import Combine
import SwiftUI
import RevenueCat

final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published var isSubscribed: Bool = false
    @Published var credits: Int = 0
    @Published var showPaywall: Bool = false
    @Published var showShop: Bool = false
    @Published private(set) var offering: Offering?

    private let creditsStorageKey = "com.nano.credits.balance"

    var hasActiveSubscription: Bool { isSubscribed }

    private init() {}

    private func persistCredits() {
        UserDefaults.standard.set(credits, forKey: creditsStorageKey)
    }

    func addCredits(_ amount: Int) {
        credits = max(0, credits + amount)
    }

    /// Replaces local cached credits with server truth.
    func setCredits(_ amount: Int) {
        credits = max(0, amount)
    }

    func fetchStatus() {
        Purchases.shared.getCustomerInfo { customerInfo, _ in
            DispatchQueue.main.async {
                self.isSubscribed = customerInfo?.entitlements.all["Pro"]?.isActive == true
            }
        }
    }

    /// Refreshes entitlement state, then presents the paywall only if the user is not **Pro** (e.g. after onboarding welcome flow).
    func presentPaywallAfterWelcomeIfNeeded() {
        Purchases.shared.getCustomerInfo { customerInfo, _ in
            DispatchQueue.main.async {
                self.isSubscribed = customerInfo?.entitlements.all["Pro"]?.isActive == true
                if !self.isSubscribed {
                    self.showPaywall = true
                }
            }
        }
    }

    func fetchOfferings(completion: ((Error?) -> Void)? = nil) {
        Purchases.shared.getOfferings { offerings, error in
            DispatchQueue.main.async {
                self.offering = offerings?.all["shop"]
                completion?(error)
            }
        }
    }

    func localizedPrice(forProductId productId: String) -> String? {
        package(forStoreProductId: productId)?.storeProduct.localizedPriceString
    }

    func isProductReadyForPurchase(productId: String) -> Bool {
        package(forStoreProductId: productId) != nil
    }

    func purchaseCredits(productId: String, creditsToGrant: Int, completion: @escaping (Bool, Error?) -> Void) {
        guard let package = package(forStoreProductId: productId) else {
            completion(false, SubscriptionPurchaseError.productNotAvailable)
            return
        }
        Purchases.shared.purchase(package: package) { _, customerInfo, error, cancelled in
            DispatchQueue.main.async {
                if cancelled {
                    completion(false, nil)
                    return
                }
                if let error = error {
                    completion(false, error)
                    return
                }
                _ = customerInfo
                self.addCredits(creditsToGrant)
                self.fetchStatus()
                completion(true, nil)
            }
        }
    }

    func restorePurchases(completion: @escaping (Bool, Error?) -> Void) {
        Purchases.shared.restorePurchases { customerInfo, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error)
                    return
                }
                _ = customerInfo
                self.fetchStatus()
                completion(true, nil)
            }
        }
    }

    private func package(forStoreProductId productId: String) -> Package? {
        guard let offering = offering else { return nil }
        for pkg in offering.availablePackages {
            if pkg.storeProduct.productIdentifier == productId {
                return pkg
            }
        }
        return nil
    }
}

enum SubscriptionPurchaseError: LocalizedError {
    case productNotAvailable

    var errorDescription: String? {
        switch self {
        case .productNotAvailable:
            return "This package isn’t available yet. Check your RevenueCat offering and App Store products."
        }
    }
}
