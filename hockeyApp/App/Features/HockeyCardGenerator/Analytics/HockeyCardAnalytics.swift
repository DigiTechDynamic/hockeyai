import Foundation

// MARK: - Hockey Card Analytics
/// Simple 4-step funnel tracking for hockey card creation
enum HockeyCardAnalytics {

    // MARK: - Funnel Tracking (4 Steps)

    /// Track when user opens hockey card feature (Step 1)
    static func trackStarted(source: String = "home_screen") {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "hockey_card",
            step: "started",
            stepNumber: 1,
            totalSteps: 4,
            metadata: ["source": source]
        )

        #if DEBUG
        print("[Hockey Card] 📊 Started (Step 1/4)")
        #endif
    }

    /// Track when user uploads/captures photo (Step 2)
    static func trackPhotoUploaded(source: String) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "hockey_card",
            step: "photo_uploaded",
            stepNumber: 2,
            totalSteps: 4,
            metadata: ["photo_source": source]
        )

        #if DEBUG
        print("[Hockey Card] 📊 Photo uploaded: \(source) (Step 2/4)")
        #endif
    }

    /// Track when AI card generation starts (Step 3)
    static func trackGenerationStarted() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: "hockey_card",
            step: "generation_started",
            stepNumber: 3,
            totalSteps: 4
        )

        #if DEBUG
        print("[Hockey Card] 📊 Generation started (Step 3/4)")
        #endif
    }

    /// Track when user sees generated card (Step 4 - Completion)
    static func trackCompleted(generationTime: Double) {
        AnalyticsManager.shared.trackFunnelCompleted(
            funnel: "hockey_card",
            totalSteps: 4,
            metadata: ["generation_time_seconds": generationTime]
        )

        #if DEBUG
        print("[Hockey Card] ✅ Completed (Step 4/4) - Generated in \(generationTime)s")
        #endif
    }
}
