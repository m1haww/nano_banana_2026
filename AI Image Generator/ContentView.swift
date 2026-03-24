//
//  ContentView.swift
//  AI Image Generator
//

import SwiftUI

// Permite ascunderea tab bar-ului când e prezentă o pagină push (ex. Explore Prompts).
private struct HideTabBarKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}
extension EnvironmentValues {
    var hideTabBarBinding: Binding<Bool> {
        get { self[HideTabBarKey.self] }
        set { self[HideTabBarKey.self] = newValue }
    }
}

enum MainTab: String, CaseIterable {
    case home = "Home"
    case discover = "Discover"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .discover: return "circle.grid.2x2.fill"
        case .profile: return "person.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: MainTab = .home
    @State private var hideTabBar: Bool = false
    @State private var pendingPromptFromDiscover: String? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case .home:
                    HomeView(initialPromptFromDiscover: $pendingPromptFromDiscover)
                case .discover:
                    GalleryView(onCreateVariant: { prompt in
                        pendingPromptFromDiscover = prompt
                        selectedTab = .home
                    })
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(\.hideTabBarBinding, $hideTabBar)

            // Fixed bottom navigation bar (ascuns pe Explore Prompts etc.)
            if !hideTabBar {
            HStack(spacing: 0) {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                            Text(tab.rawValue)
                                .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .medium, design: .rounded))
                        }
                        .foregroundStyle(selectedTab == tab ? Color.appAccent : Color.appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 16)
            .background(Color.appCard)
            .overlay(
                Rectangle()
                    .fill(Color.appDivider)
                    .frame(height: 1),
                alignment: .top
            )
            }
        }
        .background(Color.appBackground)
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    ContentView()
}
