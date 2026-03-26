import Foundation

struct ShopCreditPackage: Identifiable, Hashable {
    /// Matches `StoreProduct.productIdentifier` in RevenueCat.
    let id: String
    let credits: Int
    let discount: String?

    static let catalog: [ShopCreditPackage] = [
        ShopCreditPackage(id: "com.ai.image.starter", credits: 125, discount: "Starter"),
        ShopCreditPackage(id: "com.ai.image.explorer", credits: 250, discount: "Popular"),
        ShopCreditPackage(id: "com.ai.image.pro", credits: 350, discount: "Great deal"),
        ShopCreditPackage(id: "com.ai.image.ultimate", credits: 700, discount: "Best value"),
    ]

    /// Subscription product id -> credits granted after successful paywall purchase.
    /// Replace ids with your real RevenueCat/App Store subscription identifiers.
    static let subscriptionCredits: [String: Int] = [
        "com.ai.image.weekly": 100,
        "com.ai.image.yearly": 850,
    ]

    static func getCreditsForSubscription(_ subId: String) -> Int {
        subscriptionCredits[subId] ?? 0
    }

    /// For safety with multiple active products, grants the highest mapped credit package.
    static func getCreditsForPurchasedSubscriptions(_ productIds: [String]) -> Int {
        productIds.compactMap { subscriptionCredits[$0] }.max() ?? 0
    }
}
