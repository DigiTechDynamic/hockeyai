import Foundation

// MARK: - App-Specific Feature Limits
// These methods define feature access limits for this app.
// Customize per-app as needed.

extension MonetizationManager {

    // MARK: - Hockey Card Limits

    private static let proDailyLimit = 5

    func canGenerateHockeyCard() -> Bool {
        if isPremium {
            checkAndResetDailyLimit()
            let count = UserDefaults.standard.integer(forKey: "dailyHockeyCardCount")
            return count < MonetizationManager.proDailyLimit
        } else {
            // Non-premium: 1 lifetime free card
            return !UserDefaults.standard.bool(forKey: "hasUsedFreeHockeyCard")
        }
    }

    func incrementHockeyCardGenerationCount() {
        if isPremium {
            checkAndResetDailyLimit()
            let current = UserDefaults.standard.integer(forKey: "dailyHockeyCardCount")
            UserDefaults.standard.set(current + 1, forKey: "dailyHockeyCardCount")
        }

        // Always mark free card as used (even for pros, so if they churn they don't get another free one)
        if !UserDefaults.standard.bool(forKey: "hasUsedFreeHockeyCard") {
            UserDefaults.standard.set(true, forKey: "hasUsedFreeHockeyCard")
        }
    }

    private func checkAndResetDailyLimit() {
        let lastDate = UserDefaults.standard.object(forKey: "lastHockeyCardGenerationDate") as? Date ?? Date.distantPast
        if !Calendar.current.isDateInToday(lastDate) {
            // Reset for new day
            UserDefaults.standard.set(0, forKey: "dailyHockeyCardCount")
            UserDefaults.standard.set(Date(), forKey: "lastHockeyCardGenerationDate")
        }
    }

    // MARK: - Deprecated Methods

    func hasUsedFreeHockeyCard() -> Bool {
        return UserDefaults.standard.bool(forKey: "hasUsedFreeHockeyCard")
    }

    func markFreeHockeyCardUsed() {
        incrementHockeyCardGenerationCount()
    }
}
