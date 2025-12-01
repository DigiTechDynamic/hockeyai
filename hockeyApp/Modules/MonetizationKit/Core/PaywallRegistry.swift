import Foundation

/// Simplified PaywallRegistry - single paywall, no A/B testing
/// Can re-add A/B testing when app reaches scale (10K+ monthly users)
final class PaywallRegistry {
    private static var designs: [String: PaywallDesign] = [:]

    // MARK: - Registration

    static func register(_ design: PaywallDesign) {
        designs[design.id] = design
        #if DEBUG
        print("[PaywallRegistry] Registered paywall: \(design.id)")
        #endif
    }

    static func registerMultiple(_ paywalls: [PaywallDesign]) {
        paywalls.forEach { register($0) }
    }

    // MARK: - Design Selection (Simplified)

    /// Returns the single configured paywall design
    /// No A/B testing - just returns the default paywall
    static func getDesign(for source: String) -> PaywallDesign {
        let paywallID = MonetizationConfig.defaultPaywallVariant

        if let design = designs[paywallID] {
            #if DEBUG
            print("[PaywallRegistry] Returning paywall '\(paywallID)' for source '\(source)'")
            #endif
            trackPaywallShown(source: source, variant: paywallID)
            return design
        }

        // Fallback to first registered design if default not found
        if let fallback = designs.values.first {
            #if DEBUG
            print("[PaywallRegistry] ⚠️ Default paywall '\(paywallID)' not found, using fallback '\(fallback.id)'")
            #endif
            trackPaywallShown(source: source, variant: fallback.id)
            return fallback
        }

        // This should never happen if paywalls are registered properly
        fatalError("[PaywallRegistry] No paywalls registered!")
    }

    // MARK: - Analytics

    private static func trackPaywallShown(source: String, variant: String) {
        AnalyticsManager.shared.track(
            eventName: "paywall_shown",
            properties: [
                "source": source,
                "variant": variant
            ]
        )
    }

    // MARK: - Debug

    static func listRegisteredDesigns() -> [String] {
        Array(designs.keys).sorted()
    }
}
