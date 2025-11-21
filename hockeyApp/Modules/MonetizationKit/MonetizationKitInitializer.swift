import Foundation
import SwiftUI

enum MonetizationKitInitializer {

    // MARK: - Initialization

    static func initialize() {
        registerPaywalls()
        configureABTests()
        print("[MonetizationKit] Initialized with \(PaywallRegistry.listRegisteredDesigns().count) paywalls")
    }

    // MARK: - Paywall Registration

    private static func registerPaywalls() {
        // Register 2 optimized paywall variations for onboarding testing
        PaywallRegistry.register(HockeyPopularPaywall())        // $50/yr trial + $5/wk: Weekly + Yearly with trial toggle (2-option)
        PaywallRegistry.register(HockeyUltraWeeklyPaywall())    // $5/wk only: Weekly-only $4.99, no trial (single-option)

        // Register default (uses paywall_50yr_trial_5wk as fallback)
        PaywallRegistry.register(DefaultPaywallDesign())
    }

    // MARK: - A/B Test Configuration

    private static func configureABTests() {
        // 50/50 SPLIT: Test 2 onboarding-optimized paywalls
        // Variant A: $50/yr trial + $5/wk (Weekly + Yearly, trial toggle)
        // Variant B: $5/wk only (Weekly only, no trial)
        let onboardingPaywalls = [
            "paywall_50yr_trial_5wk",  // 50% - Weekly + Yearly with trial (2-option)
            "paywall_5wk_only"          // 50% - Weekly-only impulse (single-option)
        ]

        // Onboarding → 50/50 split test
        PaywallRegistry.configureABTest(
            source: "onboarding",
            designIDs: onboardingPaywalls
        )

        // Beauty Check (viral traffic) → 50/50 split test
        PaywallRegistry.configureABTest(
            source: "player_rater_beauty_check",
            designIDs: onboardingPaywalls
        )

        // All other entry points → 50/50 split test
        let mainEntryPoints = [
            "ai_unified",
            "ShotRaterView_AnalyzeButton",
            "home_screen",
            "settings",
            "ai_coach",
            "equipment"
        ]

        for source in mainEntryPoints {
            PaywallRegistry.configureABTest(
                source: source,
                designIDs: onboardingPaywalls
            )
        }
    }

    // MARK: - Debug Helpers

    static func listActiveTests() {
        print("[MonetizationKit] Active A/B Tests:")
        for (source, designs) in PaywallRegistry.listConfiguredTests() {
            print("  - \(source): \(designs.joined(separator: ", "))")
        }
    }

    static func forcePaywallVariant(source: String, designID: String) {
        PaywallRegistry.forceVariant(source: source, designID: designID)
        print("[MonetizationKit] Forced \(source) to use \(designID)")
    }

    static func resetAllAssignments() {
        PaywallRegistry.clearAssignments()
        print("[MonetizationKit] Reset all A/B test assignments")
    }
}

// MARK: - Default Paywall (fallback)

private struct DefaultPaywallDesign: PaywallDesign {
    let id = "default"

    func build(products: LoadedProducts, actions: PaywallActions) -> AnyView {
        // Use paywall_50yr_trial_5wk as the default (loss aversion messaging with trial)
        AnyView(
            HockeyPopularPaywall().build(products: products, actions: actions)
        )
    }
}
