import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Firebase is already configured in AppInitializer.setup() (called from SnapHockey.init())
        // No need to configure again here

        // Configure notifications - ONE LINE! That's it!
        NotificationKit.configure()

        // Clear badge on app launch
        UIApplication.shared.applicationIconBadgeNumber = 0

        // Track first install
        if UserDefaults.standard.object(forKey: "first_install_date") == nil {
            let installDate = Date()
            UserDefaults.standard.set(installDate, forKey: "first_install_date")

            AnalyticsManager.shared.track(
                eventName: "app_installed",
                properties: [
                    "install_date": installDate,
                    "app_version": AppSettings.appVersion
                ]
            )
        }

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Clear badge when app comes to foreground
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear badge when app becomes active
        UIApplication.shared.applicationIconBadgeNumber = 0

        // Track app open for retention analysis
        let installDate = UserDefaults.standard.object(forKey: "first_install_date") as? Date ?? Date()
        let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0

        AnalyticsManager.shared.track(
            eventName: "app_opened",
            properties: [
                "days_since_install": daysSinceInstall,
                "has_completed_onboarding": UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"),
                "is_premium": false // Will be updated by MonetizationManager
            ]
        )
    }
}
