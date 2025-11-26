import Foundation
import Security

// MARK: - App Secrets Manager
/// Manages sensitive runtime secrets like API keys using Keychain
final class AppSecrets {
    
    // MARK: - Singleton
    static let shared = AppSecrets()
    
    // MARK: - Properties
    private let secretsPlist: NSDictionary?
    private let keychainService = "com.snaphockey.secrets"
    
    // MARK: - Initialization
    private init() {
        // Load secrets from plist (for initial migration)
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) {
            self.secretsPlist = dict
            print("[AppSecrets] Successfully loaded Secrets.plist")
            
            // Migrate secrets to Keychain on first run
            migrateToKeychainIfNeeded()
        } else {
            self.secretsPlist = nil
            print("[AppSecrets] Warning: Failed to load Secrets.plist")
        }
    }
    
    // MARK: - Keychain Management
    
    /// Save value to Keychain
    private func saveToKeychain(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        // Delete any existing item first
        deleteFromKeychain(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        #if DEBUG
        if status == errSecSuccess {
            print("[AppSecrets] Successfully saved \(key) to Keychain")
        } else {
            print("[AppSecrets] Failed to save \(key) to Keychain: \(status)")
        }
        #endif
        
        return status == errSecSuccess
    }
    
    /// Load value from Keychain
    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }
        
        return nil
    }
    
    /// Delete value from Keychain
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    /// Load secure key with fallback to plist
    private func loadSecureKey(_ key: String) -> String? {
        // Try Keychain first
        if let keychainValue = loadFromKeychain(key: key) {
            return keychainValue
        }
        // Fallback to plist (for backward compatibility)
        return secretsPlist?[key] as? String
    }
    
    /// Migrate secrets from plist to Keychain if needed
    private func migrateToKeychainIfNeeded() {
        // Check if migration has already been done
        let migrationKey = "AppSecretsMigratedToKeychain"
        if UserDefaults.standard.bool(forKey: migrationKey) {
            print("[AppSecrets] Secrets already migrated to Keychain")
            return
        }
        
        print("[AppSecrets] Starting migration to Keychain...")
        
        // Migrate each secret
        let keysToMigrate = [
            "OpenAIAPIKey",
            "GeminiAPIKey",
            "GEMINI_API_KEY",
            "FalAPIKey",
            "MixpanelTokenDev",
            "MixpanelTokenProd",
            "RevenueCatAPIKey",
            "BranchKeyDev",
            "BranchKeyProd"
        ]
        
        var migrationSuccess = true
        
        for key in keysToMigrate {
            if let value = secretsPlist?[key] as? String, !value.isEmpty {
                if !saveToKeychain(key: key, value: value) {
                    migrationSuccess = false
                    print("[AppSecrets] Failed to migrate \(key)")
                }
            }
        }
        
        if migrationSuccess {
            UserDefaults.standard.set(true, forKey: migrationKey)
            print("[AppSecrets] Migration to Keychain completed successfully")
        } else {
            print("[AppSecrets] Migration to Keychain completed with errors")
        }
    }
    
    // MARK: - API Keys
    
    /// OpenAI API Key
    var openAIAPIKey: String? {
        loadSecureKey("OpenAIAPIKey")
    }
    
    /// Gemini API Key
    var geminiAPIKey: String? {
        // Try multiple key names for flexibility
        loadSecureKey("GeminiAPIKey") ?? loadSecureKey("GEMINI_API_KEY")
    }

    /// fal.ai API Key
    var falAPIKey: String? {
        loadSecureKey("FalAPIKey")
    }
    
    /// Mixpanel Token (Development)
    var mixpanelTokenDev: String? {
        loadSecureKey("MixpanelTokenDev")
    }
    
    /// Mixpanel Token (Production)
    var mixpanelTokenProd: String? {
        loadSecureKey("MixpanelTokenProd")
    }
    
    /// RevenueCat API Key
    var revenueCatAPIKey: String? {
        loadSecureKey("RevenueCatAPIKey")
    }
    
    /// Branch Key (Development)
    var branchKeyDev: String? {
        loadSecureKey("BranchKeyDev")
    }
    
    /// Branch Key (Production)
    var branchKeyProd: String? {
        loadSecureKey("BranchKeyProd")
    }
    
    // MARK: - Environment
    
    /// Check if running in debug mode
    var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Get appropriate Mixpanel token based on environment
    var mixpanelToken: String? {
        return isDebug ? mixpanelTokenDev : mixpanelTokenProd
    }
    
    /// Get appropriate Branch key based on environment
    var branchKey: String? {
        return isDebug ? branchKeyDev : branchKeyProd
    }
    
    // MARK: - Validation
    
    /// Check if all required API keys are present
    func validateConfiguration() -> [String] {
        var missingKeys: [String] = []
        
        if geminiAPIKey == nil {
            missingKeys.append("Gemini API Key")
        }
        
        if openAIAPIKey == nil {
            missingKeys.append("OpenAI API Key")
        }
        
        if mixpanelToken == nil {
            missingKeys.append("Mixpanel Token")
        }
        
        if revenueCatAPIKey == nil {
            missingKeys.append("RevenueCat API Key")
        }
        
        if branchKey == nil {
            missingKeys.append("Branch Key")
        }
        
        return missingKeys
    }
    
    /// Print configuration status for debugging
    func printStatus() {
        print("\n=== App Secrets Status ===")
        print("Environment: \(isDebug ? "Debug" : "Release")")
        print("Secrets.plist loaded: \(secretsPlist != nil ? "✅" : "❌")")
        print("Keychain migration: \(UserDefaults.standard.bool(forKey: "AppSecretsMigratedToKeychain") ? "✅" : "❌")")
        
        print("\nAPI Keys:")
        print("- OpenAI: \(openAIAPIKey != nil ? "✅ (Secure)" : "❌")")
        print("- Gemini: \(geminiAPIKey != nil ? "✅ (Secure)" : "❌")")
        print("- Mixpanel: \(mixpanelToken != nil ? "✅ (Secure)" : "❌")")
        print("- RevenueCat: \(revenueCatAPIKey != nil ? "✅ (Secure)" : "❌")")
        print("- Branch: \(branchKey != nil ? "✅ (Secure)" : "❌")")
        
        let missingKeys = validateConfiguration()
        if !missingKeys.isEmpty {
            print("\n⚠️ Missing Keys: \(missingKeys.joined(separator: ", "))")
        } else {
            print("\n✅ All required keys are present")
        }
        
        print("================================\n")
    }
}

// MARK: - Helper Extension
extension AppSecrets {
    /// Update an API key in Keychain (useful for runtime updates)
    func updateKey(_ keyName: String, value: String) -> Bool {
        return saveToKeychain(key: keyName, value: value)
    }
    
    /// Remove an API key from Keychain
    func removeKey(_ keyName: String) {
        deleteFromKeychain(key: keyName)
    }
    
    /// Clear all secrets from Keychain (use with caution)
    func clearAll() {
        #if DEBUG
        print("[AppSecrets] Clearing all secrets from Keychain...")
        let keysToDelete = [
            "OpenAIAPIKey",
            "GeminiAPIKey",
            "GEMINI_API_KEY",
            "FalAPIKey",
            "MixpanelTokenDev",
            "MixpanelTokenProd",
            "RevenueCatAPIKey",
            "BranchKeyDev",
            "BranchKeyProd"
        ]
        
        for key in keysToDelete {
            deleteFromKeychain(key: key)
        }
        
        // Reset migration flag
        UserDefaults.standard.set(false, forKey: "AppSecretsMigratedToKeychain")
        #endif
    }
}