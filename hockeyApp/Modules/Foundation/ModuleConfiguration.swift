import Foundation

// MARK: - Module Configuration Protocol
/// Configuration protocol for making modules reusable across different apps
public protocol ModuleConfiguration {
    /// The app's bundle identifier for namespacing
    var bundleIdentifier: String { get }
    
    /// The bundle containing resources (sounds, images, etc.)
    var resourceBundle: Bundle { get }
    
    /// Prefix for UserDefaults keys to avoid conflicts
    var userDefaultsPrefix: String { get }
    
    /// Optional Google Service plist name for authentication
    var googleServicePlistName: String? { get }
    
    /// Default theme to use as fallback
    var defaultTheme: AppTheme? { get }
}

// MARK: - Default Module Configuration
/// Default implementation with sensible defaults
public struct DefaultModuleConfiguration: ModuleConfiguration {
    public let bundleIdentifier: String
    public let resourceBundle: Bundle
    public let userDefaultsPrefix: String
    public let googleServicePlistName: String?
    public let defaultTheme: AppTheme?
    
    public init(
        bundleIdentifier: String? = nil,
        resourceBundle: Bundle = .main,
        userDefaultsPrefix: String? = nil,
        googleServicePlistName: String? = "GoogleService-Info",
        defaultTheme: AppTheme? = nil
    ) {
        self.bundleIdentifier = bundleIdentifier ?? Bundle.main.bundleIdentifier ?? "com.app"
        self.resourceBundle = resourceBundle
        self.userDefaultsPrefix = userDefaultsPrefix ?? self.bundleIdentifier
        self.googleServicePlistName = googleServicePlistName
        self.defaultTheme = defaultTheme
    }
}

// MARK: - Module Configuration Manager
/// Singleton manager for module configuration
public class ModuleConfigurationManager {
    public static let shared = ModuleConfigurationManager()
    
    private var _configuration: ModuleConfiguration?
    
    /// The current module configuration
    public var configuration: ModuleConfiguration {
        get {
            guard let config = _configuration else {
                fatalError("ModuleConfiguration not set. Call ModuleConfigurationManager.shared.setup() in your app delegate or app initialization.")
            }
            return config
        }
    }
    
    private init() {}
    
    /// Set up the module configuration
    public func setup(with configuration: ModuleConfiguration) {
        self._configuration = configuration
    }
    
    /// Check if configuration is set
    public var isConfigured: Bool {
        return _configuration != nil
    }
}

// MARK: - UserDefaults Extension
public extension UserDefaults {
    /// Get a prefixed key using the module configuration
    static func moduleKey(_ key: String) -> String {
        let prefix = ModuleConfigurationManager.shared.configuration.userDefaultsPrefix
        return "\(prefix).\(key)"
    }
}