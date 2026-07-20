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

                        Spacer(minLength: 22)
                    }
                    .padding(.top, 16)
                }

                bottomBar
            }
        }
        .alert(String(localized: "Purchase Error"), isPresented: $showError) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert(String(localized: "Purchase Successful"), isPresented: $showSuccessAlert) {
            Button(String(localized: "OK")) { dismiss() }
        } message: {
            Text(String(format: String(localized: "%lld credits have been added to your balance."), purchasedCredits))
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

            Text(String(localized: "Purchase Credits"))
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
            Text(String(format: String(localized: "%lld Credits"), subscription.credits))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appText)
                .monospacedDigit()

            Text(String(localized: "Available balance"))
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
            Text(String(localized: "Choose package"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appText)
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
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
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: String(localized: "%lld Credits"), selectedCredits))
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
                            Text(String(localized: "Purchase"))
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
            errorMessage = error?.localizedDescription ?? String(localized: "Purchase failed.")
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
            HStack(spacing: 14) {
                // Radio circle
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Color.appAccent : Color.appDivider,
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(Color.appAccent)
                            .frame(width: 14, height: 14)
                    }
                }

                // Credits + price
                VStack(alignment: .leading, spacing: 3) {
                    Text(String(format: String(localized: "%lld Credits"), credits))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appText)
                    Text(price)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)
                }

                Spacer()

                // Badge
                if let discount = discount {
                    Text(discount)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appBackground)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.appAccent)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
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
