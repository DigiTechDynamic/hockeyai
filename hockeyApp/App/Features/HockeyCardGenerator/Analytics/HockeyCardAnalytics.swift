import Foundation

// MARK: - Hockey Card Analytics
/// Tracks the hockey card creation funnel from start to completion
/// Measures user engagement with AI-powered card generation
enum HockeyCardAnalytics {

    // MARK: - Funnel Tracking

    /// Track when user starts hockey card creation (Step 1)
    /// Called when user enters HockeyCardCreationView
    static func trackStarted(source: String = "home_screen") {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "hockey_card",
            step: "started",
            stepNumber: 1,
            totalSteps: 7,
            metadata: ["source": source]
        )

        #if DEBUG
        print("[Hockey Card] 📊 Started from: \(source) (Step 1/7)")
        #endif
    }

    /// Track when user uploads/captures photo (Step 2)
    /// - Parameter source: "camera" or "library"
    static func trackPhotoUploaded(source: String) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "hockey_card",
            step: "photo_uploaded",
            stepNumber: 2,
            totalSteps: 7,
            metadata: ["photo_source": source]
        )

        #if DEBUG
        print("[Hockey Card] 📊 Photo uploaded: \(source) (Step 2/7)")
        #endif
    }

    /// Track when user completes player info (Step 3)
    /// - Parameters:
    ///   - hasNumber: Whether user entered jersey number
    ///   - hasPosition: Whether user entered position
    static func trackPlayerInfoCompleted(hasNumber: Bool, hasPosition: Bool) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "hockey_card",
            step: "player_info_completed",
            stepNumber: 3,
            totalSteps: 7,
            metadata: [
                "has_number": hasNumber,
                "has_position": hasPosition
            ]
        )

        #if DEBUG
        print("[Hockey Card] 📊 Player info completed (Step 3/7)")
        #endif
    }

    /// Track when user selects jersey style (Step 4)
    /// - Parameters:
    ///   - teamName: Selected team (e.g., "Bruins", "Maple Leafs")
    ///   - isPremium: Whether it's a premium branded design
    static func trackJerseySelected(teamName: String, isPremium: Bool) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "hockey_card",
            step: "jersey_selected",
            stepNumber: 4,
            totalSteps: 7,
            metadata: [
                "team": teamName,
                "is_premium": isPremium
            ]
        )

        #if DEBUG
        print("[Hockey Card] 📊 Jersey selected: \(teamName) (Step 4/7)")
        #endif
    }

    /// Track when AI card generation starts (Step 5)
    static func trackGenerationStarted() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "hockey_card",
            step: "generation_started",
            stepNumber: 5,
            totalSteps: 7
        )

        #if DEBUG
        print("[Hockey Card] 📊 AI generation started (Step 5/7)")
        #endif
    }

    /// Track when user views generated card (Step 6)
    /// - Parameter generationTime: How long generation took in seconds
    static func trackCardViewed(generationTime: Double) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "hockey_card",
            step: "card_viewed",
            stepNumber: 6,
            totalSteps: 7,
            metadata: [
                "generation_time_seconds": generationTime
            ]
        )

        #if DEBUG
        print("[Hockey Card] 📊 Card viewed (Step 6/7) - Generated in \(generationTime)s")
        #endif
    }

    /// Track when user saves card (Step 7 - Completion)
    static func trackCardSaved() {
        AnalyticsManager.shared.trackFunnelCompleted(
            funnel: "hockey_card",
            totalSteps: 7,
            metadata: [
                "action": "saved"
            ]
        )

        #if DEBUG
        print("[Hockey Card] ✅ Card saved (Step 7/7)")
        #endif
    }

    /// Track when user shares card (Alternative Completion)
    /// - Parameter platform: Where they shared (e.g., "instagram", "messages")
    static func trackCardShared(platform: String = "unknown") {
        AnalyticsManager.shared.trackFunnelCompleted(
            funnel: "hockey_card",
            totalSteps: 7,
            metadata: [
                "action": "shared",
                "platform": platform
            ]
        )

        #if DEBUG
        print("[Hockey Card] ✅ Card shared to: \(platform)")
        #endif
    }

    // MARK: - Additional Events (Non-Funnel)

    /// Track when AI generation fails
    /// - Parameter error: Error description
    static func trackGenerationFailed(error: String) {
        AnalyticsManager.shared.track(
            eventName: "hockey_card_generation_failed",
            properties: [
                "error": error
            ]
        )

        #if DEBUG
        print("[Hockey Card] ❌ Generation failed: \(error)")
        #endif
    }

    /// Track when user regenerates card
    /// - Parameter attempt: Which regeneration attempt (2, 3, etc.)
    static func trackRegeneration(attempt: Int) {
        AnalyticsManager.shared.track(
            eventName: "hockey_card_regenerated",
            properties: [
                "attempt_number": attempt
            ]
        )

        #if DEBUG
        print("[Hockey Card] 🔄 Regeneration attempt #\(attempt)")
        #endif
    }

    /// Track when user views card history
    static func trackHistoryViewed() {
        AnalyticsManager.shared.track(
            eventName: "hockey_card_history_viewed",
            properties: [:]
        )

        #if DEBUG
        print("[Hockey Card] 📚 History viewed")
        #endif
    }

    /// Track when user abandons the flow
    /// - Parameters:
    ///   - step: Which step they were on
    ///   - reason: Why they abandoned (optional)
    static func trackAbandoned(step: String, reason: String = "user_dismissed") {
        AnalyticsManager.shared.trackFunnelDropoff(
            funnel: "hockey_card",
            step: step,
            stepNumber: getStepNumber(for: step),
            totalSteps: 7,
            reason: reason
        )

        #if DEBUG
        print("[Hockey Card] ⏹️ Abandoned at: \(step)")
        #endif
    }

    // MARK: - Helper Methods

    private static func getStepNumber(for step: String) -> Int {
        switch step {
        case "started": return 1
        case "photo_uploaded": return 2
        case "player_info_completed": return 3
        case "jersey_selected": return 4
        case "generation_started": return 5
        case "card_viewed": return 6
        case "card_saved", "card_shared": return 7
        default: return 0
        }
    }
}
