import SwiftUI
import RevenueCat
import AdSupport
import AppTrackingTransparency
import FirebaseCore
import FirebaseMessaging
import FirebaseAnalytics

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        Purchases.logLevel = .info
        Purchases.configure(withAPIKey: "appl_wfjeylCpgzCljHTFnUcXFrnMqob", appUserID: UserService.shared.userId)
        
        applyTabBarAppearance()
        
        UNUserNotificationCenter.current().delegate = self
        
        SubscriptionService.shared.fetchStatus()
        
        if ATTrackingManager.trackingAuthorizationStatus != .notDetermined {
            Task {
                await setAppleSearchAdsAttribution()
            }
        }
        
        let instanceID = Analytics.appInstanceID()
        if let unwrapped = instanceID {
            Purchases.shared.attribution.setFirebaseAppInstanceID(unwrapped)
        }
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await requestATTPermission()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await handleNotificationPermissions(application: application)
        }
        
        return true
    }
    
    @MainActor
    private func handleNotificationPermissions(application: UIApplication) async {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: authOptions)
            print("Notification authorization granted: \(granted)")
        } catch {
            print("Notification authorization error: \(error.localizedDescription)")
        }
        
        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
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
        
        Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
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

extension AppDelegate: UNUserNotificationCenterDelegate {
    /// Foreground: show banner + pass data to VideoTaskService.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
    -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        await MainActor.run {
            VideoTaskService.shared.handleNotification(userInfo: userInfo)
        }
        return [[.banner, .badge, .sound]]
    }

    /// Background tap: pass data to VideoTaskService so the UI navigates to the result.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        // Small delay to let the UI finish launching if coming from a cold start.
        try? await Task.sleep(nanoseconds: 500_000_000)
        await MainActor.run {
            VideoTaskService.shared.handleNotification(userInfo: userInfo)
        }
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("No FCM token received")
            return
        }
        
        UserService.shared.fcmToken = fcmToken
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

