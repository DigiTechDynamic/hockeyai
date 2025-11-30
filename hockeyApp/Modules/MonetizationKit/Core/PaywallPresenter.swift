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
    @State private var showFreeTrial = false // Toggle state for trial

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
                let _ = print("[PaywallPresenter] 🎨 Showing design: \(design.id) for source: \(source)")

                design.build(
                    products: products,
                    actions: PaywallActions(
                        purchase: handlePurchase,
                        restore: handleRestore,
                        dismiss: handleDismiss,
                        toggleTrial: canShowTrialToggle(for: design.id) ? handleTrialToggle : nil,
                        canShowTrialToggle: canShowTrialToggle(for: design.id),
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

        // Get the paywall design and its configuration
        let design = PaywallRegistry.getDesign(for: source)
        let paywallConfig = MonetizationConfig.paywallConfigurations[design.id]

        // Get product IDs based on paywall configuration and trial state
        let productIDs = MonetizationConfig.getProductIDs(for: design.id, withTrial: showFreeTrial)

        // Map packages based on the paywall's pricing tier
        let packages = monetization.availablePackages

        // Initialize showFreeTrial based on paywall config
        if let config = paywallConfig {
            showFreeTrial = config.showFreeTrial
        }

        // Load products based on current trial toggle state
        updateProductsForTrialState(packages: packages, productIDs: productIDs)

        isLoading = false
    }

    private func updateProductsForTrialState(packages: [Package], productIDs: (weekly: String, monthly: String?, yearly: String)) {
        products = LoadedProducts(
            monthly: productIDs.monthly != nil
                ? (packages.first { $0.storeProduct.productIdentifier == productIDs.monthly }
                    ?? packages.first { $0.identifier.contains("monthly") })
                : nil,  // Don't load monthly if not configured
            yearly: packages.first { $0.storeProduct.productIdentifier == productIDs.yearly }
                ?? packages.first { $0.identifier.contains("annual") },
            weekly: packages.first { $0.storeProduct.productIdentifier == productIDs.weekly }
                ?? packages.first { $0.identifier.contains("weekly") },
            threeMonth: nil,
            sixMonth: nil,
            lifetime: nil
        )
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

    // MARK: - Trial Toggle Helpers

    private func canShowTrialToggle(for paywallID: String) -> Bool {
        // Only show toggle for Standard and Premium tiers
        guard let config = MonetizationConfig.paywallConfigurations[paywallID] else {
            return false
        }

        // Budget tier doesn't have trial options
        // Also check if this specific paywall should show trials
        return config.pricingTier != .budget && config.showFreeTrial
    }

    private func handleTrialToggle(_ enabled: Bool) {
        showFreeTrial = enabled

        // Get updated product IDs based on new trial state
        let design = PaywallRegistry.getDesign(for: source)
        let productIDs = MonetizationConfig.getProductIDs(for: design.id, withTrial: showFreeTrial)

        // Update products with new IDs
        let packages = monetization.availablePackages
        updateProductsForTrialState(packages: packages, productIDs: productIDs)

        // Track the toggle event
        trackEvent("trial_toggle", ["enabled": enabled, "paywall_id": design.id])
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

        // Note: trial_started event is automatically tracked by RevenueCat webhook as "rc_trial_started_event"
        // We don't duplicate it here to avoid double-counting in Mixpanel
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
