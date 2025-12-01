import Foundation
import RevenueCat
import Combine

final class MonetizationManager: NSObject, ObservableObject {
    @Published var isPremium: Bool = false
    @Published var coinBalance: Int = 0 // retained for backward compatibility; unused
    @Published var availablePackages: [Package] = []
    @Published var isLoadingPackages: Bool = false

    /// Track whether user has ever seen a paywall (used to show/hide "Go Pro" button)
    @Published var hasSeenPaywall: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenPaywall, forKey: "hasSeenPaywall")
        }
    }

    static let shared = MonetizationManager()

    private let premiumEntitlementID = "pro"

    private override init() {
        // Load hasSeenPaywall from UserDefaults before super.init()
        self.hasSeenPaywall = UserDefaults.standard.bool(forKey: "hasSeenPaywall")

        super.init()

        // Set up delegate for real-time subscription updates
        Purchases.shared.delegate = self

        // Check initial status
        Purchases.shared.getCustomerInfo { [weak self] info, _ in
            guard let self else { return }
            self.updatePremiumStatus(from: info)
        }
    }

    private func updatePremiumStatus(from customerInfo: CustomerInfo?) {
        let isActive = customerInfo?.entitlements[self.premiumEntitlementID]?.isActive == true
        DispatchQueue.main.async {
            self.isPremium = isActive
        }
    }

    func checkAccess(featureIdentifier: String, consumeAccess: Bool = true) -> Bool {
        // Coins removed: access is premium-only
        return isPremium
    }

    @MainActor
    func purchaseSubscription(productID: String) async -> Bool {
        // Check if user already owns this product
        if let customerInfo = try? await Purchases.shared.customerInfo() {
            let hasActiveEntitlement = customerInfo.entitlements[premiumEntitlementID]?.isActive == true
            if hasActiveEntitlement {
                print("[Monetization] User already has premium access")
                AnalyticsManager.shared.track(
                    eventName: "purchase_already_owned",
                    properties: ["product_id": productID]
                )
                return true
            }
        }

        if availablePackages.first(where: { $0.storeProduct.productIdentifier == productID }) == nil {
            await refreshOfferings(force: true)
        }

        guard let package = availablePackages.first(where: { $0.storeProduct.productIdentifier == productID }) else {
            print("[Monetization] Package not available for product id: \(productID)")
            return false
        }

        return await performPurchase(of: package, productID: productID)
    }

    @MainActor
    func refreshOfferings(force: Bool = false) async {
        if !force, !availablePackages.isEmpty { return }
        if isLoadingPackages { return }

        isLoadingPackages = true

        let packages: [Package] = await withCheckedContinuation { continuation in
            Purchases.shared.getOfferings { offerings, error in
                if let error {
                    print("[Monetization] offerings error: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }

                // Try to get packages from current offering, then default, then any offering
                let fetched = offerings?.current?.availablePackages
                    ?? offerings?.offering(identifier: "$rc_weekly")?.availablePackages
                    ?? offerings?.all.values.first?.availablePackages
                    ?? []
                continuation.resume(returning: fetched)
            }
        }

        availablePackages = packages
        isLoadingPackages = false
    }

    private func performPurchase(of package: Package, productID: String) async -> Bool {
        // Add timeout to prevent infinite loading
        return await withTimeout(seconds: 30) {
            await withCheckedContinuation { continuation in
                Purchases.shared.purchase(package: package) { [weak self] _, info, error, userCancelled in
                    guard let self else {
                        continuation.resume(returning: false)
                        return
                    }

                    if userCancelled {
                        AnalyticsManager.shared.track(
                            eventName: "purchase_cancelled",
                            properties: ["product_id": productID]
                        )
                        continuation.resume(returning: false)
                        return
                    }

                    if let error {
                        print("[Monetization] purchase failed: \(error.localizedDescription)")

                        // Track failed purchase with error details
                        AnalyticsManager.shared.track(
                            eventName: "purchase_failed",
                            properties: [
                                "product_id": productID,
                                "error_code": (error as NSError).code,
                                "error_domain": (error as NSError).domain,
                                "error_description": error.localizedDescription
                            ]
                        )

                        continuation.resume(returning: false)
                        return
                    }

                    let hasEntitlement = info?.entitlements[self.premiumEntitlementID]?.isActive == true

                    Task { @MainActor in
                        self.isPremium = hasEntitlement
                        if hasEntitlement {
                            // Note: Purchase analytics with revenue are tracked by PaywallPresenter
                            // No need to duplicate tracking here
                            await self.refreshOfferings(force: true)
                        }
                    }

                    continuation.resume(returning: hasEntitlement)
                }
            }
        } ?? false  // Return false if timeout occurs
    }

    // MARK: - Timeout Helper
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask {
                await operation()
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }

            let result = await group.next()
            group.cancelAll()
            return result ?? nil
        }
    }

    // Coins removed; no coin purchase or spending
}

// MARK: - PurchasesDelegate
extension MonetizationManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        updatePremiumStatus(from: customerInfo)
    }
}
