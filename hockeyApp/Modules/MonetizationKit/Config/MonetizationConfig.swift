import Foundation

/// Simplified Monetization Configuration
/// Single paywall variant - no A/B testing complexity
/// Can re-add A/B testing when app reaches scale (10K+ monthly users)
struct MonetizationConfig {

    // MARK: - RevenueCat Configuration

    /// The entitlement identifier for premium access in RevenueCat
    static let premiumEntitlementID = "pro"

    // MARK: - Single Paywall Configuration

    /// The one paywall variant used across the app
    /// Shows: $50/year with 3-day trial + $5/week option
    static let defaultPaywallVariant = "paywall_50yr_trial_5wk"

    // MARK: - Product IDs (App Store Connect)

    struct ProductIDs {
        /// Weekly subscription - $4.99/week, no trial
        static let weekly = "hockeyapp_weekly_499"

        /// Yearly subscription - $49.99/year with 3-day free trial
        static let yearly = "hockeyapp_yearly_4999_T"
    }

    // MARK: - Display Prices

    struct DisplayPrices {
        static let weekly = "$4.99"
        static let yearly = "$49.99"
        static let yearlySavings = "Save 80%" // vs weekly
    }

    // MARK: - Analytics Events

    static let paywallViewedEvent = "paywall_viewed"
    static let purchaseStartedEvent = "purchase_started"
    static let purchaseCompletedEvent = "purchase_completed"
    static let purchaseFailedEvent = "purchase_failed"

    // MARK: - Legacy Compatibility

    // These are kept for any existing code that references them
    static var weeklySubscriptionID: String { ProductIDs.weekly }
    static var yearlySubscriptionID: String { ProductIDs.yearly }
    static var weeklyPrice: String { DisplayPrices.weekly }
    static var yearlyPrice: String { DisplayPrices.yearly }
}
