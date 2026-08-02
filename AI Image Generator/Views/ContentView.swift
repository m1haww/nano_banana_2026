import SwiftUI
import RevenueCatUI

enum MainTab: String, Hashable {
    case home = "Home"
    case chat = "Chat"
    case discover = "Discover"
    case gallery = "Gallery"

    var localizedTitle: String {
        switch self {
        case .home: return String(localized: "Home")
        case .chat: return String(localized: "Chat")
        case .discover: return String(localized: "Discover")
        case .gallery: return String(localized: "Gallery")
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .discover: return "circle.grid.2x2.fill"
        case .gallery: return "photo.stack.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: MainTab = .home
    @State private var pendingPromptFromDiscover: String? = nil
    @StateObject private var shareService = ShareService.shared
    @StateObject private var galleryService = GalleryService.shared
    @State private var showGalleryDetails = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(initialPromptFromDiscover: $pendingPromptFromDiscover, selectedTab: $selectedTab)
                .tabItem {
                    Label(MainTab.home.localizedTitle, systemImage: MainTab.home.icon)
                        .tint(Color.appAccent)
                }
                .tag(MainTab.home)
            
            ChatView()
                .tabItem {
                    Label(MainTab.chat.localizedTitle, systemImage: MainTab.chat.icon)
                }
                .tag(MainTab.chat)

            DiscoverView(onCreateVariant: { prompt in
                pendingPromptFromDiscover = prompt
                selectedTab = .home
            })
            .tabItem {
                Label(MainTab.discover.localizedTitle, systemImage: MainTab.discover.icon)
                    .tint(Color.appAccent)
            }
            .tag(MainTab.discover)
            
            GalleryView()
                .tabItem {
                    Label(MainTab.gallery.localizedTitle, systemImage: MainTab.gallery.icon)
                        .tint(Color.appAccent)
                }
                .tag(MainTab.gallery)
        }
        .toolbarBackground(.visible, for: .tabBar)
        .sheet(isPresented: $shareService.isPresented, onDismiss: {
            shareService.clearPayload()
        }) {
            if !shareService.items.isEmpty {
                ShareSheet(items: shareService.items)
            }
        }
        .onChange(of: galleryService.selectedGalleryItem) { _ in
            showGalleryDetails = galleryService.selectedGalleryItem != nil
        }
        .fullScreenCover(isPresented: $showGalleryDetails) {
            if let item = galleryService.selectedGalleryItem {
                GalleryDetailView(
                    item: item,
                    onDismiss: { galleryService.selectedGalleryItem = nil },
                    onShare: {
                        if let img = galleryService.loadImage(from: item.imagePath) {
                            ShareService.shared.present(items: [img, item.prompt])
                        }
                    }
                )
            }
        }
    }
}
