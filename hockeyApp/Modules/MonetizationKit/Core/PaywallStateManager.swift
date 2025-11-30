import Foundation

/// Global paywall state manager for tracking dismissals
final class PaywallStateManager {
    static let shared = PaywallStateManager()

    private init() {}

    // MARK: - Keys
    private enum Keys {
        static let paywallDismissCount = "paywallDismissCount"
        static let lastPaywallDismissSource = "lastPaywallDismissSource"
        static let lastPaywallDismissDate = "lastPaywallDismissDate"
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

    // MARK: - Core Logic

    /// Record that user dismissed a paywall
    func recordDismissal(source: String) {
        paywallDismissCount += 1
        lastPaywallDismissSource = source
        lastPaywallDismissDate = Date()

        AnalyticsManager.shared.track(
            eventName: "paywall_dismissed",
            properties: [
                "source": source,
                "dismiss_count": paywallDismissCount
            ]
        )

        print("[PaywallState] Recorded dismissal at '\(source)' (total: \(paywallDismissCount))")
    }

    /// Reset all state (for testing only)
    func resetForTesting() {
        paywallDismissCount = 0
        lastPaywallDismissSource = nil
        lastPaywallDismissDate = nil
        print("[PaywallState] State reset for testing")
    }

    // MARK: - Debug Info

    func printCurrentState() {
        print("""
        [PaywallState] Current State:
        - Dismiss count: \(paywallDismissCount)
        - Last dismiss source: \(lastPaywallDismissSource ?? "none")
        """)
    }
}
