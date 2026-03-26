import SwiftUI
import RevenueCat
import AdSupport
import AppTrackingTransparency

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Purchases.logLevel = .info
        Purchases.configure(withAPIKey: "appl_wfjeylCpgzCljHTFnUcXFrnMqob", appUserID: UserService.shared.userId)
        
        applyTabBarAppearance()
        
        SubscriptionService.shared.fetchStatus()
        
        if ATTrackingManager.trackingAuthorizationStatus != .notDetermined {
            Task {
                await setAppleSearchAdsAttribution()
            }
        }
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await requestATTPermission()
        }
        
        return true
    }
    
    @MainActor
    private func requestATTPermission() async {
        guard #available(iOS 14, *) else { return }
        
        let status = await ATTrackingManager.requestTrackingAuthorization()
        switch status {
        case .authorized:
            print("IDFA: \(ASIdentifierManager.shared().advertisingIdentifier)")
        case .denied:
            print("ATT permission denied")
        case .restricted:
            print("ATT permission restricted")
        case .notDetermined:
            print("ATT permission still not determined")
        @unknown default:
            print("Unknown ATT status")
        }

        await setAppleSearchAdsAttribution()
    }
    
    @MainActor
    private func setAppleSearchAdsAttribution() async {
        guard #available(iOS 14.3, *) else { return }
        guard !UserDefaults.standard.bool(forKey: "hasSetAppleSearchAdsAttributionToRevenueCat") else { return }
        UserDefaults.standard.set(true, forKey: "hasSetAppleSearchAdsAttributionToRevenueCat")

        guard let data = await AppleAttributionService.shared.fetchAttributionData() else { return }
        guard data.attribution else { return }
        setRevenuecatAttributes(data: data)
    }
    
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    private func setRevenuecatAttributes(data: AppleAttributionData) {
        Purchases.shared.attribution.setKeyword(data.keywordId.map { String($0) })
        Purchases.shared.attribution.setAdGroup(data.adGroupId.map { String($0) })
        Purchases.shared.attribution.setCampaign(data.campaignId.map { String($0) })
        Purchases.shared.attribution.setAttributes(["installDate": data.clickDate ?? getCurrentDate()])
        Purchases.shared.attribution.setMediaSource("Apple Search Ads")
        Purchases.shared.attribution.setAd(data.adId.map { String($0) })
    }
    
    private func applyTabBarAppearance() {
        let background = UIColor(Color.appBackground)
        let secondary = UIColor(Color.appTextSecondary)
        let accent = UIColor(Color.appAccent)

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = background

        let item = UITabBarItemAppearance()
        item.normal.iconColor = secondary
        item.normal.titleTextAttributes = [.foregroundColor: secondary]
        item.selected.iconColor = accent
        item.selected.titleTextAttributes = [.foregroundColor: accent]

        appearance.stackedLayoutAppearance = item
        appearance.inlineLayoutAppearance = item
        appearance.compactInlineLayoutAppearance = item

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = accent
        tabBar.unselectedItemTintColor = secondary
    }
}
