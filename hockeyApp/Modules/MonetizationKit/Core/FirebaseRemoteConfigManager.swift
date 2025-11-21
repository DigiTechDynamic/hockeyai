import Foundation
#if canImport(FirebaseRemoteConfig)
import FirebaseRemoteConfig
#endif

/// Manages Firebase Remote Config for A/B testing paywall variants
final class FirebaseRemoteConfigManager {
    static let shared = FirebaseRemoteConfigManager()

    private init() {}

    #if canImport(FirebaseRemoteConfig)
    private var remoteConfig: RemoteConfig?
    private var isConfigured = false
    #endif

    // MARK: - Configuration Keys

    /// Remote Config key for active paywall variants (comma-separated list)
    private let activePaywallVariantsKey = "active_paywall_variants"

    /// Default active paywall variants if Remote Config fails (comma-separated)
    private let defaultVariants = "paywall_50yr_trial_5wk,paywall_5wk_only"

    /// Cached user assignment to ensure consistency
    private var userAssignedVariant: String?

    // MARK: - Initialization

    /// Initialize Firebase Remote Config with default values
    func configure() {
        #if canImport(FirebaseRemoteConfig)
        remoteConfig = RemoteConfig.remoteConfig()

        // Configure settings
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0 // Set to 0 for testing, increase for production (e.g., 3600 for 1 hour)
        remoteConfig?.configSettings = settings

        // Set default values
        let defaults: [String: NSObject] = [
            activePaywallVariantsKey: defaultVariants as NSObject
        ]
        remoteConfig?.setDefaults(defaults)

        isConfigured = true

        #if DEBUG
        print("[FirebaseRemoteConfig] ✅ Configured with default variants: \(defaultVariants)")
        #endif

        // Fetch initial values
        fetchAndActivate()
        #else
        print("[FirebaseRemoteConfig] ⚠️ Firebase Remote Config not available - using local A/B testing")
        #endif
    }

    // MARK: - Fetch & Activate

    /// Fetch and activate remote config values
    func fetchAndActivate(completion: ((Bool) -> Void)? = nil) {
        #if canImport(FirebaseRemoteConfig)
        guard let remoteConfig = remoteConfig, isConfigured else {
            #if DEBUG
            print("[FirebaseRemoteConfig] Not configured yet")
            #endif
            completion?(false)
            return
        }

        remoteConfig.fetchAndActivate { status, error in
            if let error = error {
                #if DEBUG
                print("[FirebaseRemoteConfig] ❌ Fetch failed: \(error.localizedDescription)")
                #endif
                completion?(false)
                return
            }

            let success = status != .error
            #if DEBUG
            if success {
                print("[FirebaseRemoteConfig] ✅ Successfully fetched and activated")
                print("[FirebaseRemoteConfig] Fetch status: \(status.rawValue) (0=error, 1=success, 2=successUsingPreFetchedData)")

                // Debug: Print ALL Remote Config keys and values
                let keys = remoteConfig.allKeys(from: .remote)
                print("[FirebaseRemoteConfig] 🔍 ALL REMOTE VALUES (\(keys.count) keys):")
                for key in keys {
                    let value = remoteConfig.configValue(forKey: key)
                    print("  - \(key): \(value.stringValue ?? "nil") (source: \(value.source.rawValue))")
                }

                print("[FirebaseRemoteConfig] Current variant: \(self.getPaywallVariant())")
            }
            #endif

            completion?(success)
        }
        #else
        completion?(false)
        #endif
    }

    // MARK: - Get Values

    /// Get the current paywall variant from Remote Config
    /// Uses consistent hashing to assign user to one of the active variants
    func getPaywallVariant() -> String {
        #if canImport(FirebaseRemoteConfig)
        // Return cached assignment if available (ensures consistency)
        if let cached = userAssignedVariant {
            return cached
        }

        guard let remoteConfig = remoteConfig, isConfigured else {
            #if DEBUG
            print("[FirebaseRemoteConfig] ⚠️ Not configured, using default variants")
            #endif
            let assigned = assignVariant(from: defaultVariants)
            userAssignedVariant = assigned
            return assigned
        }

        let configValue = remoteConfig.configValue(forKey: activePaywallVariantsKey)
        let variantsString = configValue.stringValue.isEmpty ? defaultVariants : configValue.stringValue

        #if DEBUG
        print("[FirebaseRemoteConfig] Retrieved active variants: \(variantsString)")
        print("[FirebaseRemoteConfig] Source: \(configValue.source.rawValue) (0=static, 1=default, 2=remote)")
        #endif

        let assigned = assignVariant(from: variantsString)
        userAssignedVariant = assigned

        #if DEBUG
        print("[FirebaseRemoteConfig] Assigned variant: \(assigned)")
        #endif

        return assigned
        #else
        let assigned = assignVariant(from: defaultVariants)
        userAssignedVariant = assigned
        return assigned
        #endif
    }

    /// Assign user to a variant using consistent hashing
    private func assignVariant(from variantsString: String) -> String {
        // Parse comma-separated variants
        let variants = variantsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !variants.isEmpty else {
            return "paywall_50yr_trial_5wk" // Fallback to default
        }

        // If only one variant, return it
        if variants.count == 1 {
            return variants[0]
        }

        // Use device ID for consistent hashing
        let deviceID = getDeviceIdentifier()
        let hash = deviceID.hash

        // Distribute evenly across variants
        let index = abs(hash) % variants.count
        return variants[index]
    }

    /// Get or create a unique device identifier for consistent variant assignment
    private func getDeviceIdentifier() -> String {
        let key = "firebase_remote_config_device_id"
        if let existingID = UserDefaults.standard.string(forKey: key) {
            return existingID
        }

        // Generate truly random ID using UUID + timestamp to avoid hash collisions
        // This ensures different A/B test assignments on fresh installs
        let timestamp = Int(Date().timeIntervalSince1970 * 1000) // milliseconds
        let newID = "\(UUID().uuidString)-\(timestamp)"
        UserDefaults.standard.set(newID, forKey: key)

        #if DEBUG
        print("[FirebaseRemoteConfig] 🆕 Generated new device ID: \(newID)")
        #endif

        return newID
    }

    /// Get paywall variant for a specific source
    /// This allows for source-specific experiments in the future
    func getPaywallVariant(for source: String) -> String {
        // For now, all sources use the same variant from Remote Config
        // In the future, you could add source-specific keys like "paywall_variant_ai_coach"
        return getPaywallVariant()
    }

    // MARK: - Helper Methods

    /// Check if Remote Config is available and configured
    var isAvailable: Bool {
        #if canImport(FirebaseRemoteConfig)
        return isConfigured
        #else
        return false
        #endif
    }

    /// Get all config values for debugging
    func getAllValues() -> [String: String] {
        #if canImport(FirebaseRemoteConfig)
        guard let remoteConfig = remoteConfig else {
            return [:]
        }

        return [
            activePaywallVariantsKey: remoteConfig.configValue(forKey: activePaywallVariantsKey).stringValue ?? "nil",
            "assigned_variant": userAssignedVariant ?? "not_assigned"
        ]
        #else
        return [:]
        #endif
    }

    /// Reset cached variant assignment and device ID (for testing)
    func resetAssignment() {
        userAssignedVariant = nil

        // Clear device ID to get a fresh assignment on next call
        let key = "firebase_remote_config_device_id"
        UserDefaults.standard.removeObject(forKey: key)

        #if DEBUG
        print("[FirebaseRemoteConfig] 🔄 Reset cached assignment and device ID")
        #endif
    }
}
