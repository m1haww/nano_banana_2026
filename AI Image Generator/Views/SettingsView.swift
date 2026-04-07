//
//  SettingsView.swift
//  AI Image Generator
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var api = GeminiAPIService.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text(String(localized: "Profile"))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appText)
                    Text(String(localized: "App preferences and info"))
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)
                }
                .padding(.top, 20)

                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "key.fill",
                        title: String(localized: "Image generation"),
                        value: api.isBackendImageProxyEnabled ? String(localized: "Server proxy") : String(localized: "Not configured")
                    )
                    .foregroundStyle(api.isBackendImageProxyEnabled ? Color.appAccent : Color.appTextSecondary)

                    Divider()
                        .background(Color.appDivider)
                        .padding(.leading, 56)

                    SettingsRow(
                        icon: "info.circle.fill",
                        title: String(localized: "App"),
                        value: String(localized: "AI Image Generator")
                    )
                }
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .background(Color.appBackground)
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.appAccent)
                .frame(width: 28, alignment: .center)
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color.appText)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    SettingsView()
}
