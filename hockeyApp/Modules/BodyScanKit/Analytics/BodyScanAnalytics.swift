import Foundation

// MARK: - Body Scan Analytics
/// Tracks body scan capture flow from any entry point
/// Sources: stick_analyzer, profile_page
enum BodyScanAnalytics {

    // MARK: - Source Tracking

    enum Source: String {
        case stickAnalyzer = "stick_analyzer"
        case profilePage = "profile_page"
    }

    // MARK: - Event Tracking

    /// Track when body scan camera opens
    static func trackStarted(source: Source) {
        AnalyticsManager.shared.track(
            eventName: "body_scan_started",
            properties: [
                "source": source.rawValue,
                "feature": "body_scan"
            ]
        )

        #if DEBUG
        print("[Body Scan] 📊 Started from: \(source.rawValue)")
        #endif
    }

    /// Track when body scan is successfully captured
    static func trackCaptured(source: Source) {
        AnalyticsManager.shared.track(
            eventName: "body_scan_captured",
            properties: [
                "source": source.rawValue,
                "feature": "body_scan"
            ]
        )

        #if DEBUG
        print("[Body Scan] ✅ Captured from: \(source.rawValue)")
        #endif
    }

    /// Track when user cancels body scan
    static func trackCancelled(source: Source) {
        AnalyticsManager.shared.track(
            eventName: "body_scan_cancelled",
            properties: [
                "source": source.rawValue,
                "feature": "body_scan"
            ]
        )

        #if DEBUG
        print("[Body Scan] ⏹️ Cancelled from: \(source.rawValue)")
        #endif
    }

    /// Track when camera permission is denied
    static func trackPermissionDenied(source: Source) {
        AnalyticsManager.shared.track(
            eventName: "body_scan_permission_denied",
            properties: [
                "source": source.rawValue,
                "feature": "body_scan"
            ]
        )

        #if DEBUG
        print("[Body Scan] ❌ Permission denied from: \(source.rawValue)")
        #endif
    }

    /// Track when existing body scan is loaded from storage
    static func trackLoadedFromStorage() {
        AnalyticsManager.shared.track(
            eventName: "body_scan_loaded_from_storage",
            properties: [
                "feature": "body_scan"
            ]
        )

        #if DEBUG
        print("[Body Scan] 📂 Loaded from storage")
        #endif
    }
}
