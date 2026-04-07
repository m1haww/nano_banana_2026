import SwiftUI
import UIKit

@main
struct AI_Image_GeneratorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            AppLaunchContainer()
        }
    }
}

private struct AppLaunchContainer: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            } else {
                RootView()
            }
        }
    }
}

