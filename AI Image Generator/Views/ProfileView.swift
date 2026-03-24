//
//  ProfileView.swift
//  AI Image Generator
//
//  Design inspirat din Nano Banana Settings: header fix, card cu bordură aurie, rânduri cu icon + chevron.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject private var api = GeminiAPIService.shared
    @ObservedObject private var gallery = ImagePromptManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header fix (stil Nano Banana)
            profileHeader

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Card tip „Credits” – Images saved
                    imagesCard

                    // Card / rânduri setări (Version, API, link-uri)
                    settingsRows
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .background(Color.appBackground)
    }

    // MARK: - Header (toolbar fix, ca în Nano Banana)

    private var profileHeader: some View {
        HStack {
            Spacer()
            Text("Profile")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.appText)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background(Color.appBackground)
    }

    // MARK: - Card „Images” (ca Credits card din Nano Banana)

    private var imagesCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.appAccent)
                        .frame(width: 36, height: 36)

                    Text("Images")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(gallery.galleryHistory.count)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appText)
                    Text("saved")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.appAccent, lineWidth: 1.5)
                    )
            )

            // API status sub card (scurt)
            HStack(spacing: 8) {
                Image(systemName: api.getAPIKey() != nil ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(api.getAPIKey() != nil ? Color.appAccent : Color.orange)
                Text(api.getAPIKey() != nil ? "API connected" : "API key not set")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
    }

    // MARK: - Rânduri setări (un card cu Version, App, Backend – stil Nano Banana)

    private var settingsRows: some View {
        VStack(spacing: 20) {
            VStack(spacing: 0) {
                settingsRow(icon: "checkmark.circle.fill", title: "Version", value: "1.0")
                Rectangle().fill(Color.appDivider).frame(height: 1).padding(.leading, 56)
                settingsRow(icon: "sparkles", title: "App", value: "PigFig")
                Rectangle().fill(Color.appDivider).frame(height: 1).padding(.leading, 56)
                settingsRow(icon: "server.rack", title: "Backend", value: "Railway")
            }
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appDivider.opacity(0.6), lineWidth: 1)
            )

            // Footer text (ca în Nano Banana)
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("Made with")
                        .foregroundStyle(Color.appTextSecondary)
                    Text("❤️")
                    Text("by PigFig")
                        .foregroundStyle(Color.appTextSecondary)
                }
                .font(.system(size: 15, weight: .medium, design: .rounded))

                Text("Powered by Poyo · OpenAI")
                    .foregroundStyle(Color.appTextSecondary)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
            }
            .padding(.top, 12)
        }
    }

    private func settingsRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color.appAccent)
                .font(.system(size: 18, weight: .bold))
                .frame(width: 24)

            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color.appText)

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    ProfileView()
}
