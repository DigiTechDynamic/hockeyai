import Foundation

struct MonetizationConfig {
    // MARK: - Paywall Configuration
    struct PaywallConfig {
        let id: String
        let pricingTier: PricingTier
        let showFreeTrial: Bool
        let displayName: String
    }

    // MARK: - Pricing Tiers
    enum PricingTier: String, CaseIterable {
        case budget = "budget"
        case standard = "standard"
        case premium = "premium"
    }

    // MARK: - 2 Optimized Paywall Variations for Onboarding Testing
    static let paywallConfigurations: [String: PaywallConfig] = [
        "paywall_50yr_trial_5wk": PaywallConfig(
            id: "paywall_50yr_trial_5wk",
            pricingTier: .standard,
            showFreeTrial: true,  // Weekly + Yearly with trial toggle (2-option test)
            displayName: "Paywall $50/yr Trial + $5/wk"
        ),
        "paywall_5wk_only": PaywallConfig(
            id: "paywall_5wk_only",
            pricingTier: .standard,  // $4.99/week only
            showFreeTrial: false,  // No trial - single impulse purchase option
            displayName: "Paywall $5/wk Only"
        )
    ]

    // MARK: - Product IDs by Tier (with and without trials)
    struct ProductIDs {
        // Budget Tier (no trials)
        static let weeklyBudget = "snaphockey_weekly_399"
        static let monthlyBudget = "snaphockey_monthly_999"
        static let yearlyBudget = "snaphockey_yearly_3999"

        // Standard Tier (with and without trials)
        static let weeklyStandard = "snaphockey_weekly_499"  // No trial version
        static let monthlyStandardTrial = "snaphockey_monthly_1299_T"  // Has 3-day trial
        static let yearlyStandardTrial = "snaphockey_yearly_4999_T"   // Has 7-day trial
        static let monthlyStandardNoTrial = "snaphockey_monthly_1299"  // No trial
        static let yearlyStandardNoTrial = "snaphockey_yearly_4999"   // No trial

        // Premium Tier (with and without trials)
        static let weeklyPremium = "snaphockey_weekly_699"  // No trial version
        static let monthlyPremiumTrial = "snaphockey_monthly_1999_T"  // Has 3-day trial
        static let yearlyPremiumTrial = "snaphockey_yearly_5999_T"    // Has 7-day trial
        static let monthlyPremiumNoTrial = "snaphockey_monthly_1999"  // No trial
        static let yearlyPremiumNoTrial = "snaphockey_yearly_5999"   // No trial
    }

    // MARK: - Display Prices by Tier
    struct DisplayPrices {
        static let weekly: [PricingTier: String] = [
            .budget: "$3.99",
            .standard: "$4.99",
            .premium: "$6.99"
        ]

        static let monthly: [PricingTier: String] = [
            .budget: "$9.99",
            .standard: "$12.99",
            .premium: "$19.99"
        ]

        static let yearly: [PricingTier: String] = [
            .budget: "$39.99",
            .standard: "$49.99",
            .premium: "$59.99"
        ]
    }

    // MARK: - Get Product IDs for Paywall
    // Note: Monthly subscriptions removed - only weekly and yearly are available in App Store Connect
    static func getProductIDs(for paywallID: String, withTrial: Bool = false) -> (weekly: String, monthly: String?, yearly: String) {
        guard let config = paywallConfigurations[paywallID] else {
            // Default to standard if paywall not found (monthly not available)
            return (ProductIDs.weeklyStandard, nil, ProductIDs.yearlyStandardTrial)
        }

        switch config.pricingTier {
        case .budget:
            // Budget tier - no trials available, no monthly
            return (ProductIDs.weeklyBudget, nil, ProductIDs.yearlyBudget)

        case .standard:
            // Standard tier - only weekly and yearly (no monthly in App Store Connect)
            return (ProductIDs.weeklyStandard, nil, ProductIDs.yearlyStandardTrial)

        case .premium:
            // Premium tier - only weekly and yearly (no monthly in App Store Connect)
            return (ProductIDs.weeklyPremium, nil, ProductIDs.yearlyPremiumTrial)
        }
    }

    // MARK: - Legacy compatibility (for existing code)
    static var monthlySubscriptionID: String {
        ProductIDs.monthlyBudget // Default to budget for now
    }

    static var yearlySubscriptionID: String {
        ProductIDs.yearlyBudget // Default to budget for now
    }

    static var weeklySubscriptionID: String {
        ProductIDs.weeklyBudget // Default to budget for now
    }

    static var weeklyPrice: String { "$3.99" }
    static var monthlyPrice: String { "$9.99" }
    static var yearlyPrice: String { "$39.99" }

    // MARK: - Analytics event names
    static let paywallViewedEvent = "paywall_viewed"
    static let subscriptionPurchasedEvent = "subscription_purchased"
    static let aiAnalysisGatedEvent = "ai_analysis_gated"

    // MARK: - Feature gating
    // Coins removed: access is premium-only

    // MARK: - Paywall variants
    static let defaultPaywallVariant = "paywall_50yr_trial_5wk"

    // Mapping for debug UI and deal recovery
    static let sourceVariantOverrides: [String: String] = [
        // 2 optimized paywall variations for onboarding testing
        "paywall_50yr_trial_5wk_test": "paywall_50yr_trial_5wk",
        "paywall_5wk_only_test": "paywall_5wk_only",

        // Entry point mappings
        "ShotRaterView_AnalyzeButton": "paywall_50yr_trial_5wk",
        "onboarding": "paywall_50yr_trial_5wk"  // Default onboarding to $50/yr trial variant (with trial)
    ]

    // Special: Deal recovery sources (dynamically matched)
    static func isDealRecoverySource(_ source: String) -> Bool {
        return source.hasPrefix("deal_recovery_")
    }

    static var defaultDebugSource: String {
        "paywall_50yr_trial_5wk_test"
    }

    static var selectedPaywallVariant: String {
        get {
            UserDefaults.standard.string(forKey: "selectedPaywallVariant") ?? defaultPaywallVariant
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "selectedPaywallVariant")
        }
    }

    static func clearSelectedVariantOverride() {
        UserDefaults.standard.removeObject(forKey: "selectedPaywallVariant")
    }

    static func mappedVariant(forSource source: String) -> String? {
        sourceVariantOverrides[source]
    }

    // MARK: - Source aliasing for variant assignment
    // Use this to make multiple entry points resolve to the same paywall variant
    // while preserving the original `source` value for analytics.
    // Example: unify all AI analysis gates to one variant group.
    static let sourceAssignmentAliases: [String: String] = [
        // 3 AI flows share the same variant assignment
        "ShotRaterView_AnalyzeButton": "ai_unified",
        "ai_coach": "ai_unified",
        "equipment": "ai_unified",
        // Player Rater Beauty Check uses same AI variant
        "player_rater_beauty_check": "ai_unified",
        // Header + soft upsell + settings should match AI flows
        "home_screen": "ai_unified",
        "settings": "ai_unified",
        "go_pro_header": "ai_unified",
        "onboarding_upsell": "ai_unified",
        // Debug preview convenience
        "debug_preview": "ai_unified"
    ]

    static func assignmentSource(for source: String) -> String {
        sourceAssignmentAliases[source] ?? source
    }
}
