import SwiftUI
import RevenueCat
#if canImport(Mixpanel)
import Mixpanel
#endif

@main
struct HockeyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var monetization = MonetizationContainer.shared.monetizationManager

    init() {
        // Centralized app initialization
        AppInitializer.setup()

        // Configure RevenueCat for monetization
        if let revenueCatKey = AppSecrets.shared.revenueCatAPIKey, !revenueCatKey.isEmpty {
            Purchases.configure(withAPIKey: revenueCatKey)
            Purchases.shared.collectDeviceIdentifiers()
        } else {
            print("⚠️ RevenueCat API key not found in AppSecrets")
        }

        // Initialize MonetizationKit with paywall designs and A/B tests
        MonetizationKitInitializer.initialize()

        // Initialize analytics pipeline (Mixpanel) using secure token
        if let mixpanelToken = AppSecrets.shared.mixpanelToken, !mixpanelToken.isEmpty {
            AnalyticsManager.shared.initializeMixpanel(token: mixpanelToken)
        } else {
            print("[Analytics] Mixpanel token missing – skipping initialization")
        }
        // Align Mixpanel distinctId with RevenueCat appUserID
        AnalyticsManager.shared.syncRevenueCatIdentity()

        #if DEBUG
        // Suppress accessibility debug warnings that don't affect functionality
        UserDefaults.standard.set(false, forKey: "AXInspectorEnabled")
        UserDefaults.standard.set(false, forKey: "NSApplicationCrashOnExceptions")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ThemeAwareContentView()
                .environmentObject(themeManager)
                .environmentObject(monetization)
                .environmentObject(NoticeCenter.shared)
                .preferredColorScheme(.dark) // Use dark mode for all themes
                .onOpenURL { url in
                    // Handle URL schemes if needed
                }
        }
    }
}

// MARK: - Theme-Aware Content Wrapper
struct ThemeAwareContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ContentView()
            .environment(\.theme, themeManager.activeTheme)
    }
}
