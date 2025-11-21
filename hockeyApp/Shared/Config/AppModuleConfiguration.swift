import Foundation

// MARK: - App Module Configuration
/// App-specific configuration for the reusable modules
struct AppModuleConfiguration: ModuleConfiguration {
    let bundleIdentifier = "com.hockeyapp"
    let resourceBundle = Bundle.main
    let userDefaultsPrefix = "com.hockeyapp"
    let googleServicePlistName: String? = "GoogleService-Info"
    
    // Use STY theme as default
    var defaultTheme: AppTheme? {
        return STYThemeStyle()
    }
}