import SwiftUI
import RevenueCat

struct PaywallPresenter: View {
    let source: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var monetization = MonetizationManager.shared
    @State private var products = LoadedProducts(
        monthly: nil,
        yearly: nil,
        weekly: nil,
        threeMonth: nil,
        sixMonth: nil,
        lifetime: nil
    )
    @State private var isLoading = true
    @State private var purchaseInProgress = false

    var body: some View {
        ZStack {
            if isLoading {
                // Loading state while products are being fetched
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Get the appropriate design from registry
                let design = PaywallRegistry.getDesign(for: source)

                design.build(
                    products: products,
                    actions: PaywallActions(
                        purchase: handlePurchase,
                        restore: handleRestore,
                        dismiss: handleDismiss,
                        toggleTrial: nil,
                        canShowTrialToggle: false,
                        trackEvent: trackEvent,
                        trackPurchaseStart: trackPurchaseStart,
                        trackPurchaseComplete: trackPurchaseComplete,
                        trackDismiss: trackDismiss
                    )
                )
            }

            // Purchase in progress overlay
            if purchaseInProgress {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)

                        Text("Processing...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(Color.gray.opacity(0.9))
                    .cornerRadius(16)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await loadProducts()
        }
        .onAppear {
            // Mark that user has seen a paywall (enables "Go Pro" button in header)
            if !monetization.hasSeenPaywall {
                monetization.hasSeenPaywall = true
            }

            let variant = PaywallRegistry.getDesign(for: source).id
            AnalyticsManager.shared.track(
                eventName: MonetizationConfig.paywallViewedEvent,
                properties: ["variant": variant, "source": source]
            )
        }
        .onChange(of: scenePhase) { newPhase in
            // Handle interrupted purchases - re-check premium status when app returns to foreground
            if newPhase == .active && purchaseInProgress {
                Task {
                    // Give RevenueCat a moment to sync
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                    // Re-check premium status
                    if monetization.isPremium {
                        purchaseInProgress = false
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Product Loading

    private func loadProducts() async {
        isLoading = true
        await monetization.refreshOfferings(force: false)

        let packages = monetization.availablePackages

        // Load products - weekly and yearly only
        products = LoadedProducts(
            monthly: nil,
            yearly: packages.first { $0.storeProduct.productIdentifier == MonetizationConfig.ProductIDs.yearly }
                ?? packages.first { $0.identifier.contains("annual") },
            weekly: packages.first { $0.storeProduct.productIdentifier == MonetizationConfig.ProductIDs.weekly }
                ?? packages.first { $0.identifier.contains("weekly") },
            threeMonth: nil,
            sixMonth: nil,
            lifetime: nil
        )

        isLoading = false
    }

    // MARK: - Action Handlers

    private func handlePurchase(_ productId: String) async -> Bool {
        guard !purchaseInProgress else { return false }

        purchaseInProgress = true

        trackPurchaseStart(productId)

        let success = await monetization.purchaseSubscription(productID: productId)

        // Ensure we're on main actor for UI updates
        await MainActor.run {
            purchaseInProgress = false

            if success {
                trackPurchaseComplete(productId)
                dismiss()
            }
        }

        return success
    }

    private func handleRestore() async -> Bool {
        guard !purchaseInProgress else { return false }

        purchaseInProgress = true
        defer { purchaseInProgress = false }

        return await withCheckedContinuation { continuation in
            Purchases.shared.restorePurchases { info, error in
                if let error = error {
                    print("[PaywallPresenter] Restore failed: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                    return
                }

                let hasActiveSubscription = info?.entitlements.active.isEmpty == false
                if hasActiveSubscription {
                    DispatchQueue.main.async {
                        dismiss()
                    }
                }
                continuation.resume(returning: hasActiveSubscription)
            }
        }
    }

    private func handleDismiss() {
        trackDismiss()
        PaywallStateManager.shared.recordDismissal(source: source)
        dismiss()
    }

    // MARK: - Analytics

    private func trackEvent(_ name: String, _ properties: [String: Any]) {
        var enrichedProps = properties
        enrichedProps["source"] = source
        enrichedProps["variant"] = PaywallRegistry.getDesign(for: source).id
        AnalyticsManager.shared.track(eventName: name, properties: enrichedProps)
    }

    private func trackPurchaseStart(_ productId: String) {
        trackEvent("paywall_purchase_started", ["product_id": productId])
    }

    private func trackPurchaseComplete(_ productId: String) {
        let variant = PaywallRegistry.getDesign(for: source).id

        // Get revenue from RevenueCat product
        let package = findPackage(for: productId)
        let revenueDouble: Double
        if let price = package?.storeProduct.price {
            revenueDouble = NSDecimalNumber(decimal: price).doubleValue
        } else {
            revenueDouble = 0.0
        }
        let currencyCode = package?.storeProduct.priceFormatter?.currencyCode ?? "USD"

        #if DEBUG
        if let package = package {
            print("[PaywallPresenter] 💰 Purchase completed - Product: \(productId), Revenue: \(currencyCode) \(revenueDouble)")
        } else {
            print("[PaywallPresenter] ⚠️ Warning: Could not find package for \(productId), revenue will be $0")
        }
        #endif

        // Track purchase completion WITH REVENUE from RevenueCat
        let purchaseProperties: [String: Any] = [
            "product_id": productId,
            "variant": variant,
            "revenue": revenueDouble,
            "currency": currencyCode,
            "source": source
        ]

        trackEvent("purchase_completed", purchaseProperties)
    }

    // Helper to find package by product ID from loaded products
    private func findPackage(for productId: String) -> Package? {
        let allPackages = [
            products.weekly,
            products.monthly,
            products.yearly,
            products.threeMonth,
            products.sixMonth,
            products.lifetime
        ].compactMap { $0 }

        return allPackages.first { $0.storeProduct.productIdentifier == productId }
    }

    private func trackDismiss() {
        trackEvent("paywall_dismissed", [:])
    }
}
