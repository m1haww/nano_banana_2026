import SwiftUI

struct ShopView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscription = SubscriptionService.shared

    @State private var selectedProductId: String = ShopCreditPackage.catalog.first?.id ?? ""
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccessAlert = false
    @State private var purchasedCredits = 0

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        balanceCard

                        choosePackageSection

                        if !subscription.hasActiveSubscription {
                            proPlanCard
                        }

                        Spacer(minLength: 22)
                    }
                    .padding(.top, 16)
                }

                bottomBar
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Purchase Successful", isPresented: $showSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("\(purchasedCredits) credits have been added to your balance.")
        }
        .onAppear {
            subscription.fetchStatus()
            subscription.fetchOfferings()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(width: 40, height: 40)
                    .background(Color.appCard)
                    .clipShape(Circle())
            }

            Spacer()

            Text("Purchase Credits")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.appText)

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Balance

    private var balanceCard: some View {
        VStack(spacing: 10) {
            Text("\(subscription.credits) Credits")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appText)
                .monospacedDigit()

            Text("Available balance")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color.appText.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "8B7500"), Color(hex: "5C4D00")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.appAccent.opacity(0.55), lineWidth: 1.5)
                )
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Packages

    private var choosePackageSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose package")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appText)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ShopCreditPackage.catalog) { package in
                        ShopCreditPackageCard(
                            credits: package.credits,
                            price: subscription.localizedPrice(forProductId: package.id) ?? "—",
                            discount: package.discount,
                            isSelected: selectedProductId == package.id
                        ) {
                            selectedProductId = package.id
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Pro

    private var proPlanCard: some View {
        Button {
            subscription.showShop = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                subscription.showPaywall = true
            })
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.appCard)
                            .frame(width: 50, height: 50)
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color.appAccent)
                    }

                    Text("AI Pro")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appText)

                    Spacer()
                }

                Text("Unlock premium generation:")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)

                VStack(spacing: 12) {
                    proFeatureRow("Priority processing")
                    proFeatureRow("Pro models & styles")
                    proFeatureRow("No watermark")
                }

                Text("Upgrade to Pro")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.appAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.top, 20)
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.appCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.appAccent.opacity(0.6), Color.appAccent.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    private func proFeatureRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.appAccent)
            Text(text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color.appText)
            Spacer()
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(selectedCredits) Credits")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appText)
                        .monospacedDigit()
                    Text(selectedPriceDisplay)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)
                }
                Spacer()
                Button(action: handlePurchase) {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .tint(Color.appBackground)
                                .scaleEffect(0.9)
                        } else {
                            Text("Purchase")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                    }
                    .foregroundStyle(Color.appBackground)
                    .frame(width: 140, height: 50)
                    .background(
                        subscription.isProductReadyForPurchase(productId: selectedProductId) && !isPurchasing
                            ? Color.appAccent
                            : Color.appAccent.opacity(0.45)
                    )
                    .clipShape(Capsule())
                }
                .disabled(
                    isPurchasing || !subscription.isProductReadyForPurchase(productId: selectedProductId)
                )
            }
            .padding(.horizontal, 20)

            Button {
                handleRestore()
            } label: {
                Text("Restore purchases")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.bottom, 10)
        }
        .padding(.top, 14)
        .background(Color.appBackground.ignoresSafeArea(edges: .bottom))
    }

    private var selectedCredits: Int {
        ShopCreditPackage.catalog.first(where: { $0.id == selectedProductId })?.credits ?? 0
    }

    private var selectedPriceDisplay: String {
        subscription.localizedPrice(forProductId: selectedProductId)
            ?? ""
    }

    private func handlePurchase() {
        guard let pkg = ShopCreditPackage.catalog.first(where: { $0.id == selectedProductId }) else { return }
        isPurchasing = true
        subscription.purchaseCredits(productId: pkg.id, creditsToGrant: pkg.credits) { success, error in
            isPurchasing = false
            if success {
                purchasedCredits = pkg.credits
                showSuccessAlert = true
                return
            }
            if error == nil {
                return
            }
            errorMessage = error?.localizedDescription ?? "Purchase failed."
            showError = true
        }
    }

    private func handleRestore() {
        isPurchasing = true
        subscription.restorePurchases { success, error in
            isPurchasing = false
            if success {
                dismiss()
                return
            }
            errorMessage = error?.localizedDescription ?? "Nothing to restore."
            showError = true
        }
    }
}

// MARK: - Package card

private struct ShopCreditPackageCard: View {
    let credits: Int
    let price: String
    let discount: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if let discount = discount {
                        Text(discount)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.appBackground)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.appAccent)
                            .clipShape(Capsule())
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(
                                isSelected ? Color.appAccent : Color.appDivider,
                                lineWidth: 2
                            )
                            .frame(width: 24, height: 24)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.appAccent)
                        }
                    }
                }

                Spacer(minLength: 0)

                Text("\(credits) Credits")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appText)

                Text(price)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(18)
            .frame(width: 248, height: 152)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                isSelected ? Color.appAccent : Color.appDivider.opacity(0.8),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
