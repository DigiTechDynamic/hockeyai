import Foundation
import SwiftUI

// MARK: - Screen Tracking ViewModifier

/// Automatic screen tracking that fires when a view appears
/// Usage: .trackScreen("home")
public struct ScreenTrackingModifier: ViewModifier {
    let screenName: String
    let properties: [String: Any]

    @State private var entryTime: Date?
    @State private var hasTrackedView = false

    public init(screenName: String, properties: [String: Any] = [:]) {
        self.screenName = screenName
        self.properties = properties
    }

    public func body(content: Content) -> some View {
        content
            .onAppear {
                guard !hasTrackedView else { return }
                entryTime = Date()
                hasTrackedView = true

                // Track screen view
                ScreenTracker.shared.trackScreenView(
                    screenName: screenName,
                    properties: properties
                )
            }
            .onDisappear {
                // Track time spent on screen
                if let entry = entryTime {
                    let timeSpent = Date().timeIntervalSince(entry)
                    ScreenTracker.shared.trackScreenExit(
                        screenName: screenName,
                        timeSpent: timeSpent
                    )
                }
                hasTrackedView = false
            }
    }
}

// MARK: - View Extension

public extension View {
    /// Track when this screen is viewed
    /// - Parameters:
    ///   - screenName: Unique identifier for this screen (use snake_case)
    ///   - properties: Additional properties to track with the view
    func trackScreen(_ screenName: String, properties: [String: Any] = [:]) -> some View {
        modifier(ScreenTrackingModifier(screenName: screenName, properties: properties))
    }
}

// MARK: - Screen Tracker Manager

/// Centralized screen tracking manager
public final class ScreenTracker: ObservableObject {
    public static let shared = ScreenTracker()

    @Published public var debugEntries: [DebugEntry] = []
    @Published public var screenViewCounts: [String: Int] = [:]
    @Published public var uniqueScreens: Set<String> = []
    @Published public var isDebugEnabled: Bool = false

    private var screenStartTimes: [String: Date] = [:]
    private let userDefaultsKey = "com.hockeyapp.screen_tracking"
    private let debugEnabledKey = "com.hockeyapp.screen_tracking.debug_enabled"

    public struct DebugEntry: Identifiable {
        public let id = UUID()
        public let timestamp: Date
        public let screenName: String
        public let properties: [String: Any]

        public var formattedTime: String {
            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            return formatter.string(from: timestamp)
        }
    }

    private init() {
        loadPersistedData()
        isDebugEnabled = UserDefaults.standard.bool(forKey: debugEnabledKey)
    }

    // MARK: - Screen View Tracking

    /// Track a screen view
    public func trackScreenView(screenName: String, properties: [String: Any] = [:]) {
        var enrichedProps = properties
        enrichedProps["screen_name"] = screenName
        enrichedProps["timestamp"] = Date().timeIntervalSince1970

        // Track if this is the first time user has seen this screen
        let isFirstView = !uniqueScreens.contains(screenName)
        enrichedProps["is_first_view"] = isFirstView

        // Add to unique screens set
        uniqueScreens.insert(screenName)

        // Increment view count
        screenViewCounts[screenName, default: 0] += 1
        enrichedProps["view_count"] = screenViewCounts[screenName]

        // Track in analytics
        AnalyticsManager.shared.trackScreenView(
            screenName: screenName,
            properties: enrichedProps
        )

        // Optionally also emit an event with the screen name itself so
        // funnels can be constructed by event name without property filters.
        if AppSettings.Analytics.emitNamedScreenEvents {
            AnalyticsManager.shared.track(
                eventName: screenName,
                properties: enrichedProps
            )
        }

        // Update user properties with screens viewed
        updateUserProperties()

        // Persist data
        persistData()

        // Track start time for duration calculation
        screenStartTimes[screenName] = Date()

        // Add debug entry
        if isDebugEnabled {
            addDebugEntry(screenName: screenName, properties: enrichedProps)
        }
    }

    /// Track when user exits a screen
    public func trackScreenExit(screenName: String, timeSpent: TimeInterval) {
        // Only track if time spent is reasonable (> 0.5 seconds, < 1 hour)
        guard timeSpent > 0.5 && timeSpent < 3600 else { return }

        AnalyticsManager.shared.track(
            eventName: "screen_exited",
            properties: [
                "screen_name": screenName,
                "time_spent_seconds": Int(timeSpent),
                "time_spent_formatted": formatDuration(timeSpent)
            ]
        )
    }

    // MARK: - Tab Tracking

    /// Track tab selection changes
    public func trackTabChange(from previousTab: Int?, to currentTab: Int, tabName: String) {
        var properties: [String: Any] = [
            "current_tab_index": currentTab,
            "current_tab_name": tabName
        ]

        if let previous = previousTab {
            properties["previous_tab_index"] = previous
        }

        AnalyticsManager.shared.track(
            eventName: "tab_changed",
            properties: properties
        )

        // Also track as a screen view
        trackScreenView(screenName: "tab_\(tabName.lowercased().replacingOccurrences(of: " ", with: "_"))")
    }

    // MARK: - Navigation Tracking

    /// Track navigation push
    public func trackNavigation(to screenName: String, from sourceScreen: String) {
        AnalyticsManager.shared.track(
            eventName: "navigation",
            properties: [
                "destination": screenName,
                "source": sourceScreen,
                "action": "push"
            ]
        )
    }

    /// Track modal presentation
    public func trackModal(presented screenName: String, from sourceScreen: String) {
        AnalyticsManager.shared.track(
            eventName: "modal_presented",
            properties: [
                "modal": screenName,
                "source": sourceScreen
            ]
        )
    }

    /// Track modal dismissal
    public func trackModalDismissed(screenName: String) {
        AnalyticsManager.shared.track(
            eventName: "modal_dismissed",
            properties: [
                "modal": screenName
            ]
        )
    }

    // MARK: - User Properties

    private func updateUserProperties() {
        AnalyticsManager.shared.setUserProperties([
            "total_screens_viewed": uniqueScreens.count,
            "total_screen_views": screenViewCounts.values.reduce(0, +),
            "most_viewed_screen": mostViewedScreen()
        ])
    }

    private func mostViewedScreen() -> String {
        guard let max = screenViewCounts.max(by: { $0.value < $1.value }) else {
            return "none"
        }
        return max.key
    }

    // MARK: - Persistence

    private func persistData() {
        let data: [String: Any] = [
            "unique_screens": Array(uniqueScreens),
            "screen_view_counts": screenViewCounts
        ]
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }

    private func loadPersistedData() {
        guard let data = UserDefaults.standard.dictionary(forKey: userDefaultsKey) else { return }

        if let screens = data["unique_screens"] as? [String] {
            uniqueScreens = Set(screens)
        }

        if let counts = data["screen_view_counts"] as? [String: Int] {
            screenViewCounts = counts
        }
    }

    // MARK: - Debug Support

    public func toggleDebug() {
        isDebugEnabled.toggle()
        UserDefaults.standard.set(isDebugEnabled, forKey: debugEnabledKey)
    }

    private func addDebugEntry(screenName: String, properties: [String: Any] = [:]) {
        let entry = DebugEntry(
            timestamp: Date(),
            screenName: screenName,
            properties: properties
        )

        DispatchQueue.main.async {
            self.debugEntries.insert(entry, at: 0)

            // Keep only last 50 entries
            if self.debugEntries.count > 50 {
                self.debugEntries = Array(self.debugEntries.prefix(50))
            }
        }
    }

    public func clearDebugEntries() {
        debugEntries.removeAll()
    }

    public func resetAllData() {
        uniqueScreens.removeAll()
        screenViewCounts.removeAll()
        debugEntries.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    // MARK: - Analytics Report

    /// Generate a comprehensive analytics report
    public func generateReport() -> ScreenAnalyticsReport {
        ScreenAnalyticsReport(
            totalUniqueScreens: uniqueScreens.count,
            totalViews: screenViewCounts.values.reduce(0, +),
            topScreens: screenViewCounts.sorted { $0.value > $1.value }.prefix(10).map { ($0.key, $0.value) },
            allScreens: Array(uniqueScreens).sorted()
        )
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Analytics Report

public struct ScreenAnalyticsReport {
    public let totalUniqueScreens: Int
    public let totalViews: Int
    public let topScreens: [(String, Int)]
    public let allScreens: [String]

    public var summary: String {
        """
        Screen Analytics Report
        =======================
        Total Unique Screens: \(totalUniqueScreens)
        Total Screen Views: \(totalViews)
        Average Views per Screen: \(totalViews / max(totalUniqueScreens, 1))

        Top 10 Screens:
        \(topScreens.map { "  • \($0.0): \($0.1) views" }.joined(separator: "\n"))

        All Screens:
        \(allScreens.map { "  • \($0)" }.joined(separator: "\n"))
        """
    }
}
