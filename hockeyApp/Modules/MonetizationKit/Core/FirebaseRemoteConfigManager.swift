import Foundation
#if canImport(FirebaseRemoteConfig)
import FirebaseRemoteConfig
#endif

/// Simplified Firebase Remote Config manager
/// A/B testing removed - using single hardcoded paywall for simplicity
/// Can re-add A/B testing when app reaches scale (10K+ monthly users)
final class FirebaseRemoteConfigManager {
    static let shared = FirebaseRemoteConfigManager()

    private init() {}

    #if canImport(FirebaseRemoteConfig)
    private var remoteConfig: RemoteConfig?
    private var isConfigured = false
    #endif

    // MARK: - Configuration

    /// Initialize Firebase Remote Config (minimal setup, no A/B testing)
    func configure() {
        #if canImport(FirebaseRemoteConfig)
        remoteConfig = RemoteConfig.remoteConfig()

        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600 // 1 hour for production
        remoteConfig?.configSettings = settings

        isConfigured = true

        #if DEBUG
        print("[FirebaseRemoteConfig] ✅ Configured (A/B testing disabled - using single paywall)")
        #endif
        #else
        print("[FirebaseRemoteConfig] ⚠️ Firebase Remote Config not available")
        #endif
    }

    // MARK: - Paywall Variant (Simplified)

    /// Returns the single hardcoded paywall variant
    /// A/B testing removed for simplicity - can re-add at scale
    func getPaywallVariant() -> String {
        return MonetizationConfig.defaultPaywallVariant
    }

    func getPaywallVariant(for source: String) -> String {
        return MonetizationConfig.defaultPaywallVariant
    }

    // MARK: - Status

    var isAvailable: Bool {
        #if canImport(FirebaseRemoteConfig)
        return isConfigured
        #else
        return false
        #endif
    }
}
