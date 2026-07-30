import SwiftUI
import RevenueCatUI

struct SettingsView: View {
    @ObservedObject private var subscription = SubscriptionService.shared

    @State private var showCustomerCenter = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text(String(localized: "Settings"))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appText)
                    Text(String(localized: "App preferences and info"))
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)
                }
                .padding(.top, 20)

                // Credits & shop
                Button {
                    subscription.showShop = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "cart.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Color.appAccent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "Credits & shop"))
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.appText)
                            Text(String(format: String(localized: "%lld credits available"), subscription.credits))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .padding(18)
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.appDivider.opacity(0.7), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                // Subscription + legal
                VStack(spacing: 12) {
                    Button {
                        showCustomerCenter = true
                    } label: {
                        settingsActionRow(
                            icon: "creditcard.circle.fill",
                            title: String(localized: "Manage Subscription")
                        )
                    }
                    .buttonStyle(.plain)

                    settingsLinkRow(
                        icon: "lock.shield.fill",
                        title: String(localized: "Privacy Policy"),
                        url: URL(string: "https://www.termsfeed.com/live/4dd4b9b2-ed74-49ec-b26a-1255ac6321fd")!
                    )

                    settingsLinkRow(
                        icon: "envelope.circle.fill",
                        title: String(localized: "Contact Us"),
                        url: URL(string: "mailto:annislaster@gmail.com")!
                    )
                }
                .padding(.horizontal, 20)

            }
        }
        .background(Color.appBackground)
        .sheet(isPresented: $showCustomerCenter) {
            CustomerCenterView()
        }
    }

    private func settingsActionRow(icon: String, title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(Color.appAccent)
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.appText)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(18)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appDivider.opacity(0.7), lineWidth: 1)
        )
    }

    private func settingsLinkRow(icon: String, title: String, url: URL) -> some View {
        Button {
            UIApplication.shared.open(url)
        } label: {
            settingsActionRow(icon: icon, title: title)
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    SettingsView()
}
