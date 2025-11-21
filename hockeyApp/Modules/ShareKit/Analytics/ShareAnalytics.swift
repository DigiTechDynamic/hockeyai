import Foundation

// MARK: - Share Analytics
/// Dedicated analytics tracking for share events
/// Integrates with existing AnalyticsKit for centralized tracking
public final class ShareAnalytics {
    // MARK: - Singleton
    public static let shared = ShareAnalytics()

    private init() {}

    // MARK: - Share Metrics Storage
    /// In-memory metrics for K-factor calculation
    private var sessionMetrics = ShareSessionMetrics()

    // MARK: - Event Tracking

    /// Track when user initiates a share
    public func trackShareInitiated(content: ShareContent) {
        var properties = content.analyticsProperties
        properties["action"] = "initiated"
        properties["share_text_length"] = content.shareText.count

        AnalyticsManager.shared.track(
            eventName: "share_initiated",
            properties: properties
        )

        // Update session metrics
        sessionMetrics.incrementInitiated(for: content.type)

        #if DEBUG
        print("📤 [ShareAnalytics] Share initiated: \(content.type.displayName)")
        #endif
    }

    /// Track when share completes successfully
    public func trackShareCompleted(content: ShareContent, platform: String) {
        var properties = content.analyticsProperties
        properties["action"] = "completed"
        properties["platform"] = platform

        AnalyticsManager.shared.track(
            eventName: "share_completed",
            properties: properties
        )

        // Track platform-specific event
        AnalyticsManager.shared.track(
            eventName: "share_to_\(platform.lowercased().replacingOccurrences(of: " ", with: "_"))",
            properties: properties
        )

        // Update session metrics
        sessionMetrics.incrementCompleted(for: content.type, platform: platform)

        #if DEBUG
        print("✅ [ShareAnalytics] Share completed to \(platform): \(content.type.displayName)")
        #endif
    }

    /// Track when share is cancelled
    public func trackShareCancelled(content: ShareContent) {
        var properties = content.analyticsProperties
        properties["action"] = "cancelled"

        AnalyticsManager.shared.track(
            eventName: "share_cancelled",
            properties: properties
        )

        // Update session metrics
        sessionMetrics.incrementCancelled(for: content.type)

        #if DEBUG
        print("❌ [ShareAnalytics] Share cancelled: \(content.type.displayName)")
        #endif
    }

    /// Track when share fails with error
    public func trackShareFailed(content: ShareContent, error: Error?) {
        var properties = content.analyticsProperties
        properties["action"] = "failed"
        if let error = error {
            properties["error"] = error.localizedDescription
        }

        AnalyticsManager.shared.track(
            eventName: "share_failed",
            properties: properties
        )

        #if DEBUG
        print("🚨 [ShareAnalytics] Share failed: \(content.type.displayName)")
        if let error = error {
            print("   Error: \(error.localizedDescription)")
        }
        #endif
    }

    // MARK: - Metrics & K-Factor

    /// Get current session metrics
    public func getSessionMetrics() -> ShareSessionMetrics {
        return sessionMetrics
    }

    /// Calculate share conversion rate (completed / initiated)
    public func getConversionRate(for type: ShareContentType? = nil) -> Double {
        if let type = type {
            let initiated = sessionMetrics.initiatedCounts[type] ?? 0
            let completed = sessionMetrics.completedCounts[type] ?? 0
            guard initiated > 0 else { return 0 }
            return Double(completed) / Double(initiated)
        } else {
            // Overall conversion
            let totalInitiated = sessionMetrics.totalInitiated
            let totalCompleted = sessionMetrics.totalCompleted
            guard totalInitiated > 0 else { return 0 }
            return Double(totalCompleted) / Double(totalInitiated)
        }
    }

    /// Get platform distribution (which platforms are most popular)
    public func getPlatformDistribution() -> [String: Int] {
        return sessionMetrics.platformCounts
    }

    /// Reset session metrics (call on app launch or after tracking window)
    public func resetSessionMetrics() {
        sessionMetrics = ShareSessionMetrics()
        #if DEBUG
        print("🔄 [ShareAnalytics] Session metrics reset")
        #endif
    }
}

// MARK: - Share Session Metrics
/// In-memory metrics for the current session
public struct ShareSessionMetrics {
    // Counters by content type
    var initiatedCounts: [ShareContentType: Int] = [:]
    var completedCounts: [ShareContentType: Int] = [:]
    var cancelledCounts: [ShareContentType: Int] = [:]

    // Platform distribution
    var platformCounts: [String: Int] = [:]

    // Totals
    var totalInitiated: Int = 0
    var totalCompleted: Int = 0
    var totalCancelled: Int = 0

    mutating func incrementInitiated(for type: ShareContentType) {
        initiatedCounts[type, default: 0] += 1
        totalInitiated += 1
    }

    mutating func incrementCompleted(for type: ShareContentType, platform: String) {
        completedCounts[type, default: 0] += 1
        platformCounts[platform, default: 0] += 1
        totalCompleted += 1
    }

    mutating func incrementCancelled(for type: ShareContentType) {
        cancelledCounts[type, default: 0] += 1
        totalCancelled += 1
    }

    /// Conversion rate for this session
    public var conversionRate: Double {
        guard totalInitiated > 0 else { return 0 }
        return Double(totalCompleted) / Double(totalInitiated)
    }

    /// Most popular platform
    public var topPlatform: String? {
        return platformCounts.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Viral Growth Metrics
public extension ShareAnalytics {
    /// Track when a user arrives from a share (attribution)
    func trackShareAttribution(source: String, contentType: ShareContentType? = nil) {
        var properties: [String: Any] = [
            "source": source,
            "attribution_type": "share"
        ]

        if let contentType = contentType {
            properties["content_type"] = contentType.rawValue
        }

        AnalyticsManager.shared.track(
            eventName: "user_from_share",
            properties: properties
        )

        #if DEBUG
        print("🔗 [ShareAnalytics] User attributed to share from: \(source)")
        #endif
    }

    /// Track viral coefficient metrics (for K-factor calculation)
    /// K-factor = (# of invites sent per user) × (% conversion rate)
    func trackViralCoefficient(invitesSent: Int, conversions: Int) {
        let kFactor = Double(invitesSent) * (Double(conversions) / Double(invitesSent))

        let properties: [String: Any] = [
            "invites_sent": invitesSent,
            "conversions": conversions,
            "k_factor": kFactor,
            "is_viral": kFactor > 1.0
        ]

        AnalyticsManager.shared.track(
            eventName: "viral_coefficient_calculated",
            properties: properties
        )

        #if DEBUG
        print("📊 [ShareAnalytics] K-Factor: \(kFactor) (invites: \(invitesSent), conversions: \(conversions))")
        #endif
    }
}

// MARK: - A/B Testing Support
public extension ShareAnalytics {
    /// Track which template variant was used (for A/B testing)
    func trackTemplateVariant(
        content: ShareContent,
        variant: String,
        metadata: [String: Any] = [:]
    ) {
        var properties = content.analyticsProperties
        properties["template_variant"] = variant

        for (key, value) in metadata {
            properties[key] = value
        }

        AnalyticsManager.shared.track(
            eventName: "share_template_variant",
            properties: properties
        )

        #if DEBUG
        print("🎨 [ShareAnalytics] Template variant: \(variant) for \(content.type.displayName)")
        #endif
    }

    /// Track share CTA button interactions
    func trackShareCTAClicked(
        contentType: ShareContentType,
        buttonStyle: String,
        location: String
    ) {
        let properties: [String: Any] = [
            "content_type": contentType.rawValue,
            "button_style": buttonStyle,
            "location": location
        ]

        AnalyticsManager.shared.track(
            eventName: "share_cta_clicked",
            properties: properties
        )

        #if DEBUG
        print("🎯 [ShareAnalytics] Share CTA clicked: \(buttonStyle) at \(location)")
        #endif
    }
}
