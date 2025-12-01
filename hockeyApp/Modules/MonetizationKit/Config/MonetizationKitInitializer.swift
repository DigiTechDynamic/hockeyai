import Foundation
import SwiftUI

/// Simplified MonetizationKit Initializer
/// Single paywall - no A/B testing complexity
enum MonetizationKitInitializer {

    // MARK: - Initialization

    static func initialize() {
        registerPaywalls()
        print("[MonetizationKit] ✅ Initialized with single paywall: \(MonetizationConfig.defaultPaywallVariant)")
    }

    // MARK: - Paywall Registration

    private static func registerPaywalls() {
        // Register the single paywall variant
        // $50/yr with 3-day trial + $5/wk option
        PaywallRegistry.register(HockeyPopularPaywall())

        #if DEBUG
        print("[MonetizationKit] Registered paywalls: \(PaywallRegistry.listRegisteredDesigns())")
        #endif
    }
}
