import SwiftUI
import FirebaseCore

/// Centralized app initialization logic following Clean Architecture principles
struct AppInitializer {
    
    /// Performs all app initialization tasks
    static func setup() {
        // Configure Firebase (must be first)
        configureFirebase()

        // Configure Authentication Providers
        configureAuthProviders()

        // Configure Module System
        configureModules()

        // Register Themes
        registerThemes()

        // Validate Configuration
        validateConfiguration()

        // Configure AI UX hooks (preflight notices, etc.)
        configureAIFeatureKitUX()

        // Start connectivity monitoring early so preflight can read accurate state
        Connectivity.shared.start()

        // Configure Firebase Remote Config for A/B testing
        configureRemoteConfig()
    }
    
    // MARK: - Private Initialization Methods
    
    static func configureFirebase() {
        FirebaseApp.configure()
        #if DEBUG
        print("✅ Firebase configured successfully")
        #endif
    }
    
    private static func configureAuthProviders() {
        GoogleAuthenticationProvider.configure()
        #if DEBUG
        print("✅ Google Sign-In configured successfully")
        #endif
    }
    
    private static func configureModules() {
        ModuleConfigurationManager.shared.setup(with: AppModuleConfiguration())
        #if DEBUG
        print("✅ Module system configured successfully")
        #endif
    }
    
    private static func registerThemes() {
        // Register base theme (STY Athletic only)
        let styTheme = STYThemeRegistration()

        // Register theme with ThemeManager
        ThemeManager.shared.registerTheme(styTheme)
        
        // Register all NHL team themes
        ThemeManager.shared.registerNHLTeams()
        
        // Check if user has a saved NHL team preference
        let currentTheme = ThemeManager.shared.getCurrentThemeId()
        if let savedTeamId = UserDefaults.standard.string(forKey: "selectedNHLTeam"),
           !savedTeamId.isEmpty {
            // Apply saved NHL team theme
            if let team = NHLTeams.team(byId: savedTeamId) {
                ThemeManager.shared.setNHLTeam(team)
            }
        } else if currentTheme.isEmpty || currentTheme == "hockey" {
            // Set STY as default theme if none is saved or if old hockey theme was selected
            ThemeManager.shared.setTheme(themeId: "sty")
        }
        
        #if DEBUG
        print("✅ Themes registered successfully (including \(NHLTeams.allTeams.count) NHL teams)")
        print("   Active theme: \(ThemeManager.shared.getCurrentThemeId())")
        #endif
    }
    
    private static func validateConfiguration() {
        #if DEBUG
        // Print configuration status in debug builds
        AppSecrets.shared.printStatus()
        #endif
        
        // Validate configuration and check for missing keys
        let missingKeys = AppSecrets.shared.validateConfiguration()
        if !missingKeys.isEmpty {
            print("⚠️ Warning: Missing API keys - \(missingKeys.joined(separator: ", "))")
            
            // In production, you might want to handle this more gracefully
            #if !DEBUG
            // Log to crash reporting service
            // CrashlyticsManager.shared.log("Missing API keys: \(missingKeys)")
            #endif
        } else {
            #if DEBUG
            print("✅ App configuration validated successfully")
            #endif
        }
    }

    // MARK: - AIFeatureKit UX Hooks
    private static func configureAIFeatureKitUX() {
        // Assign the cellular preflight hook so AI operations can trigger a SwiftUI notice without UI coupling
        AIUXHooks.preflightCellularNotice = {
            await NoticeCenter.shared.presentCellularNotice()
        }
    }

    // MARK: - Firebase Remote Config
    private static func configureRemoteConfig() {
        FirebaseRemoteConfigManager.shared.configure()
        #if DEBUG
        print("✅ Firebase Remote Config initialized for A/B testing")
        #endif
    }
}
