//
//  PlayerRaterAnalytics.swift
//  Snap Hockey
//
//  General analytics utilities for Player Rater (STY Check) feature
//  NOTE: Use STYValidationAnalytics for onboarding, STYCheckAnalytics for post-onboarding
//

import Foundation

/// General analytics utilities for Player Rater / STY Check feature
/// This file contains non-funnel events and helper methods
enum PlayerRaterAnalytics {

    // MARK: - General Events (Cross-Context)

    /// Track when analysis fails (any context)
    /// NOTE: For funnel-specific failures, use STYValidationAnalytics or STYCheckAnalytics
    /// - Parameters:
    ///   - context: The context (onboarding, homeScreen, tryAgain)
    ///   - error: Error description
    static func trackAnalysisFailed(context: RaterContext, error: String) {
        AnalyticsManager.shared.track(
            eventName: "sty_analysis_failed",
            properties: [
                "context": contextString(context),
                "error": error,
                "feature": "sty_check"
            ]
        )

        #if DEBUG
        print("📊 [PlayerRater] Analysis failed - context: \(contextString(context)), error: \(error)")
        #endif
    }

    /// Track when user shares their STY Check results (general event)
    /// - Parameters:
    ///   - score: The score being shared
    ///   - shareMethod: How they shared (instagram, snapchat, etc.)
    static func trackResultsShared(score: Int, shareMethod: String = "unknown") {
        AnalyticsManager.shared.track(
            eventName: "sty_results_shared",
            properties: [
                "score": score,
                "share_method": shareMethod,
                "feature": "sty_check"
            ]
        )

        #if DEBUG
        print("📊 [PlayerRater] Results shared - score: \(score), method: \(shareMethod)")
        #endif
    }

    /// Track when user saves their STY rating
    /// - Parameter score: The score being saved
    static func trackRatingSaved(score: Int, tier: String) {
        AnalyticsManager.shared.track(
            eventName: "sty_rating_saved",
            properties: [
                "score": score,
                "tier": tier,
                "feature": "sty_check"
            ]
        )

        #if DEBUG
        print("📊 [PlayerRater] Rating saved - score: \(score), tier: \(tier)")
        #endif
    }

    // MARK: - Helper Methods

    /// Convert RaterContext enum to string for analytics
    static func contextString(_ context: RaterContext) -> String {
        switch context {
        case .onboarding:
            return "onboarding"
        case .homeScreen:
            return "home_screen"
        case .tryAgain:
            return "try_again"
        }
    }
}
