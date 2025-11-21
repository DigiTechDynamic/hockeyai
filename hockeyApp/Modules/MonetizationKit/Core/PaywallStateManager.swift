import Foundation

/// Global paywall state manager for tracking deal paywall eligibility
/// and preventing over-showing of discount offers
final class PaywallStateManager {
    static let shared = PaywallStateManager()

    private init() {}

    // MARK: - Keys
    private enum Keys {
        static let hasSeenDealPaywall = "hasSeenDealPaywall"
        static let dealPaywallShownAt = "dealPaywallShownAt"
        static let dealPaywallSource = "dealPaywallSource"
        static let paywallDismissCount = "paywallDismissCount"
        static let lastPaywallDismissSource = "lastPaywallDismissSource"
        static let lastPaywallDismissDate = "lastPaywallDismissDate"
    }

    // MARK: - Deal Paywall State

    /// Has user ever seen the deal paywall? (One-time only)
    var hasSeenDealPaywall: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasSeenDealPaywall) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hasSeenDealPaywall) }
    }

    /// When was deal paywall shown?
    var dealPaywallShownAt: Date? {
        get { UserDefaults.standard.object(forKey: Keys.dealPaywallShownAt) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Keys.dealPaywallShownAt) }
    }

    /// Which source triggered the deal paywall?
    var dealPaywallSource: String? {
        get { UserDefaults.standard.string(forKey: Keys.dealPaywallSource) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.dealPaywallSource) }
    }

    // MARK: - Dismissal Tracking

    /// Total count of paywall dismissals
    var paywallDismissCount: Int {
        get { UserDefaults.standard.integer(forKey: Keys.paywallDismissCount) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.paywallDismissCount) }
    }

    /// Last source where user dismissed paywall
    var lastPaywallDismissSource: String? {
        get { UserDefaults.standard.string(forKey: Keys.lastPaywallDismissSource) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastPaywallDismissSource) }
    }

    /// Last date when user dismissed paywall
    var lastPaywallDismissDate: Date? {
        get { UserDefaults.standard.object(forKey: Keys.lastPaywallDismissDate) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastPaywallDismissDate) }
    }

    // MARK: - Valid Sources

    /// Feature gate sources eligible for deal paywall
    /// These are the ACTUAL sources used by monetization gates in the app
    private let featureGateSources: Set<String> = [
        "ShotRaterView_AnalyzeButton",  // Shot Rater analyze button
        "ai_coach",                     // AI Coach flow gate
        "equipment"                     // Stick Analyzer (equipment) gate
    ]

    /// Sources that should NEVER show deal paywall
    private let excludedSources: Set<String> = [
        "onboarding_upsell",  // Too early, user hasn't experienced value
        "go_pro_header"       // High-intent, don't devalue
    ]

    // MARK: - Core Logic

    /// Should we show deal paywall after user action?
    /// - Parameters:
    ///   - source: Where the paywall was shown (e.g., "ai_coach_gate")
    ///   - action: What user did ("dismissed", "transaction_abandoned")
    /// - Returns: True if deal paywall should be shown
    func shouldShowDealPaywall(source: String, action: PaywallAction) -> Bool {
        // Rule #1: Only show once ever (global flag)
        if hasSeenDealPaywall {
            print("[PaywallState] ❌ Deal paywall already shown - never show again")
            return false
        }

        // Rule #2: Never show at excluded sources
        if excludedSources.contains(source) {
            print("[PaywallState] ❌ Source '\(source)' is excluded from deal paywall")
            return false
        }

        // Rule #3: Prioritize transaction abandonment (safest with Apple)
        if action == .transactionAbandoned {
            // Transaction abandonment works at ANY source (even onboarding)
            print("[PaywallState] ✅ Transaction abandoned - show deal paywall")
            return true
        }

        // Rule #4: For simple dismissal, only at feature gates
        if action == .dismissed {
            let isFeatureGate = featureGateSources.contains(source)
            if isFeatureGate {
                print("[PaywallState] ✅ Dismissed at feature gate '\(source)' - show deal paywall")
                return true
            } else {
                print("[PaywallState] ❌ Dismissed at '\(source)' (not a feature gate) - no deal")
                return false
            }
        }

        // Rule #5: No other actions trigger deal paywall
        print("[PaywallState] ❌ Action '\(action.rawValue)' doesn't trigger deal paywall")
        return false
    }

    /// Record that user dismissed a paywall
    func recordDismissal(source: String) {
        paywallDismissCount += 1
        lastPaywallDismissSource = source
        lastPaywallDismissDate = Date()

        AnalyticsManager.shared.track(
            eventName: "paywall_dismissed",
            properties: [
                "source": source,
                "dismiss_count": paywallDismissCount,
                "has_seen_deal": hasSeenDealPaywall
            ]
        )

        print("[PaywallState] 📊 Recorded dismissal at '\(source)' (total: \(paywallDismissCount))")
    }

    /// Record that deal paywall was shown
    func recordDealPaywallShown(source: String) {
        hasSeenDealPaywall = true
        dealPaywallShownAt = Date()
        dealPaywallSource = source

        AnalyticsManager.shared.track(
            eventName: "deal_paywall_shown",
            properties: [
                "source": source,
                "dismiss_count_before": paywallDismissCount
            ]
        )

        print("[PaywallState] 💰 Deal paywall shown from '\(source)' - will NEVER show again")
    }

    /// Reset all state (for testing only)
    func resetForTesting() {
        hasSeenDealPaywall = false
        dealPaywallShownAt = nil
        dealPaywallSource = nil
        paywallDismissCount = 0
        lastPaywallDismissSource = nil
        lastPaywallDismissDate = nil

        print("[PaywallState] 🔄 State reset for testing")
    }

    // MARK: - Debug Info

    func printCurrentState() {
        print("""
        [PaywallState] Current State:
        - Has seen deal: \(hasSeenDealPaywall)
        - Dismiss count: \(paywallDismissCount)
        - Last dismiss source: \(lastPaywallDismissSource ?? "none")
        - Deal shown at: \(dealPaywallSource ?? "never")
        """)
    }
}

// MARK: - Paywall Action Types

enum PaywallAction: String {
    case dismissed = "dismissed"
    case transactionAbandoned = "transaction_abandoned"
    case subscribed = "subscribed"
}