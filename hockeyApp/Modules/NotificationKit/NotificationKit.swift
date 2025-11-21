import Foundation
import UserNotifications
import UIKit

// MARK: - NotificationKit
/// Completely decoupled notification system
/// Handles everything internally - no external dependencies needed
public final class NotificationKit: NSObject {


    // MARK: - Singleton
    private static let shared = NotificationKit()

    // MARK: - Public API (Super Simple!)

    /// Call this once in AppDelegate - that's it!
    public static func configure() {
        let instance = shared
        UNUserNotificationCenter.current().delegate = instance
        instance.setupCategories()
        print("✅ NotificationKit: Configured and ready")
    }

    /// Send shot analysis notification (ShotRater calls this)
    public static func sendShotAnalysisNotification(
        shotType: String,
        score: Int?,
        analysisId: String = UUID().uuidString,
        delay: TimeInterval = 1
    ) {
        Task {
            await shared.sendShotNotification(
                shotType: shotType,
                score: score,
                analysisId: analysisId,
                delay: delay
            )
        }
    }

    /// Request permission (can be called from anywhere)
    public static func requestPermission() async -> Bool {
        await shared.requestNotificationPermission()
    }

    // MARK: - Private Implementation

    private override init() {
        super.init()
    }

    private func setupCategories() {
        // Shot analysis category
        let viewAction = UNNotificationAction(
            identifier: "VIEW",
            title: "View Results",
            options: .foreground
        )

        let shotCategory = UNNotificationCategory(
            identifier: "SHOT_ANALYSIS",
            actions: [viewAction],
            intentIdentifiers: []
        )

        // Training reminder category
        let startAction = UNNotificationAction(
            identifier: "START",
            title: "Start Now",
            options: .foreground
        )
        let trainingCategory = UNNotificationCategory(
            identifier: "TRAINING_REMINDER",
            actions: [startAction],
            intentIdentifiers: []
        )

        // Marketing category
        let openAction = UNNotificationAction(
            identifier: "OPEN",
            title: "Open App",
            options: .foreground
        )
        let marketingCategory = UNNotificationCategory(
            identifier: "MARKETING",
            actions: [openAction],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([shotCategory, trainingCategory, marketingCategory])
    }

    private func sendShotNotification(
        shotType: String,
        score: Int?,
        analysisId: String,
        delay: TimeInterval
    ) async {
        // Request permission if not already granted
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = await requestNotificationPermission()
        }

        // Only send if authorized
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            print("⚠️ NotificationKit: Notifications not authorized")
            return
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "🏒 Shot Analysis Complete!"
        if let score = score {
            content.subtitle = "Score: \(score)/100"
        }
        content.body = "Tap to view your \(shotType) results"
        content.sound = .default
        content.categoryIdentifier = "SHOT_ANALYSIS"

        // Store deep link info
        content.userInfo = [
            "type": "shot-analysis",
            "analysisId": analysisId,
            "shotType": shotType
        ]

        // Schedule notification
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, delay),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "shot-\(analysisId)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ NotificationKit: Scheduled shot analysis notification")
        } catch {
            print("❌ NotificationKit: Failed to schedule notification: \(error)")
        }
    }

    private func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("❌ NotificationKit: Permission request failed: \(error)")
            return false
        }
    }

}

// MARK: - Public helpers
public extension NotificationKit {
    /// Generic local notification scheduler with calendar trigger and thread/category support
    static func scheduleLocalNotification(
        title: String,
        body: String,
        id: String = UUID().uuidString,
        at date: Date,
        categoryId: String? = nil,
        threadId: String? = nil,
        userInfo: [AnyHashable: Any] = [:],
        interruption: UNNotificationInterruptionLevel = .active
    ) async {
        await shared.schedule(
            title: title,
            body: body,
            id: id,
            at: date,
            categoryId: categoryId,
            threadId: threadId,
            userInfo: userInfo,
            interruption: interruption
        )
    }

    private func schedule(
        title: String,
        body: String,
        id: String,
        at date: Date,
        categoryId: String?,
        threadId: String?,
        userInfo: [AnyHashable: Any],
        interruption: UNNotificationInterruptionLevel
    ) async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            print("⚠️ NotificationKit: Not authorized to schedule \(id)")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let categoryId { content.categoryIdentifier = categoryId }
        if let threadId { content.threadIdentifier = threadId }
        if #available(iOS 15.0, *) { content.interruptionLevel = interruption }
        if !userInfo.isEmpty { content.userInfo = userInfo }

        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        components.second = components.second ?? 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ NotificationKit: Scheduled \(id) at \(date)")
        } catch {
            print("❌ NotificationKit: Failed to schedule \(id): \(error)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationKit: UNUserNotificationCenterDelegate {

    /// Show notifications even when app is open
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// Handle notification tap
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("🔔 NotificationKit: User tapped notification with info: \(userInfo)")

        // Just log it - user will use the Results button in the app
        if let type = userInfo["type"] as? String {
            print("📱 NotificationKit: Notification type: \(type)")
        }

        // Clear badge
        UIApplication.shared.applicationIconBadgeNumber = 0

        completionHandler()
    }
}
