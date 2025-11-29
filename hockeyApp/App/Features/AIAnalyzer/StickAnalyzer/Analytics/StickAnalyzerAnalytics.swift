import Foundation

// MARK: - Stick Analyzer Analytics
/// Tracks the stick recommendation flow with body scan integration
/// 7-step funnel: Profile → Body Scan → Preferences (3) → Processing → Results
enum StickAnalyzerAnalytics {

    // MARK: - Funnel Constants
    private static let funnel = "stick_analyzer"
    private static let totalSteps = 7

    // MARK: - Funnel Tracking

    /// Track when user starts Stick Analyzer (Step 1)
    static func trackStarted(source: String = "equipment_tab") {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: funnel,
            step: "started",
            stepNumber: 1,
            totalSteps: totalSteps,
            metadata: ["source": source]
        )

        #if DEBUG
        print("[Stick Analyzer] 📊 Started from: \(source) (Step 1/\(totalSteps))")
        #endif
    }

    /// Track when user views player profile page (Step 2)
    static func trackPlayerProfile() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: funnel,
            step: "player_profile",
            stepNumber: 2,
            totalSteps: totalSteps
        )

        #if DEBUG
        print("[Stick Analyzer] 📊 Player profile viewed (Step 2/\(totalSteps))")
        #endif
    }

    /// Track body scan stage completed (Step 3)
    /// - Parameter outcome: "captured", "skipped", or "loaded_from_storage"
    static func trackBodyScan(outcome: BodyScanOutcome) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: funnel,
            step: "body_scan",
            stepNumber: 3,
            totalSteps: totalSteps,
            metadata: ["body_scan_outcome": outcome.rawValue]
        )

        #if DEBUG
        print("[Stick Analyzer] 📊 Body scan: \(outcome.rawValue) (Step 3/\(totalSteps))")
        #endif
    }

    enum BodyScanOutcome: String {
        case captured = "captured"
        case skipped = "skipped"
        case loadedFromStorage = "loaded_from_storage"
    }

    /// Track when user reaches preferences section (Step 4)
    static func trackPreferencesStarted() {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: funnel,
            step: "preferences",
            stepNumber: 4,
            totalSteps: totalSteps
        )

        #if DEBUG
        print("[Stick Analyzer] 📊 Preferences started (Step 4/\(totalSteps))")
        #endif
    }

    /// Track when AI analysis starts (Step 5)
    static func trackAnalysisStarted(hasBodyScan: Bool) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: funnel,
            step: "analysis_started",
            stepNumber: 5,
            totalSteps: totalSteps,
            metadata: ["has_body_scan": hasBodyScan]
        )

        #if DEBUG
        print("[Stick Analyzer] 📊 Analysis started (body scan: \(hasBodyScan)) (Step 5/\(totalSteps))")
        #endif
    }

    /// Track when AI analysis completes (Step 6)
    static func trackAnalysisCompleted(
        processingTime: Double,
        hasBodyScan: Bool,
        recommendationCount: Int
    ) {
        AnalyticsManager.shared.trackFunnelStep(
            funnel: funnel,
            step: "analysis_completed",
            stepNumber: 6,
            totalSteps: totalSteps,
            metadata: [
                "processing_time_seconds": processingTime,
                "has_body_scan": hasBodyScan,
                "recommendation_count": recommendationCount
            ]
        )

        #if DEBUG
        print("[Stick Analyzer] 📊 Analysis completed in \(String(format: "%.1f", processingTime))s (Step 6/\(totalSteps))")
        #endif
    }

    /// Track when user views results and completes flow (Step 7)
    static func trackCompleted(
        topStickBrand: String?,
        topStickModel: String?,
        recommendedFlex: Int?,
        hasBodyScan: Bool
    ) {
        AnalyticsManager.shared.trackFunnelCompleted(
            funnel: funnel,
            totalSteps: totalSteps,
            metadata: [
                "top_stick_brand": topStickBrand ?? "unknown",
                "top_stick_model": topStickModel ?? "unknown",
                "recommended_flex": recommendedFlex ?? 0,
                "has_body_scan": hasBodyScan
            ]
        )

        #if DEBUG
        print("[Stick Analyzer] ✅ Completed - Top pick: \(topStickBrand ?? "?") \(topStickModel ?? "?") (Step 7/\(totalSteps))")
        #endif
    }

    // MARK: - Error & Dropout Events

    /// Track when analysis fails
    static func trackAnalysisFailed(error: String, hasBodyScan: Bool) {
        AnalyticsManager.shared.track(
            eventName: "stick_analyzer_analysis_failed",
            properties: [
                "error": error,
                "has_body_scan": hasBodyScan,
                "feature": "stick_analyzer"
            ]
        )

        #if DEBUG
        print("[Stick Analyzer] ❌ Analysis failed: \(error)")
        #endif
    }

    /// Track when user abandons the flow
    static func trackDropoff(atStep: String, stepNumber: Int) {
        AnalyticsManager.shared.trackFunnelDropoff(
            funnel: funnel,
            step: atStep,
            stepNumber: stepNumber,
            totalSteps: totalSteps,
            reason: "user_abandoned"
        )

        #if DEBUG
        print("[Stick Analyzer] ⏹️ Dropped off at: \(atStep)")
        #endif
    }
}
