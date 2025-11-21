import Foundation
import LocalAuthentication

public final class BiometricAuthHelper {
    
    public enum BiometricType {
        case none
        case touchID
        case faceID
    }
    
    public enum BiometricError: LocalizedError {
        case notAvailable
        case notEnrolled
        case authenticationFailed
        case userCancel
        case systemCancel
        case passcodeNotSet
        case lockout
        case unknown(String)
        
        public var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Biometric authentication is not available on this device"
            case .notEnrolled:
                return "No biometric authentication method is enrolled"
            case .authenticationFailed:
                return "Biometric authentication failed"
            case .userCancel:
                return "Authentication was cancelled"
            case .systemCancel:
                return "Authentication was cancelled by the system"
            case .passcodeNotSet:
                return "Device passcode is not set"
            case .lockout:
                return "Too many failed attempts. Please try again later"
            case .unknown(let message):
                return message
            }
        }
    }
    
    private let context = LAContext()
    
    public init() {}
    
    // MARK: - Public Methods
    
    public var biometricType: BiometricType {
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        default:
            return .none
        }
    }
    
    public var isAvailable: Bool {
        return biometricType != .none
    }
    
    public func authenticate(
        reason: String,
        fallbackTitle: String? = nil
    ) async throws {
        context.localizedFallbackTitle = fallbackTitle
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw mapError(error)
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if !success {
                throw BiometricError.authenticationFailed
            }
        } catch let laError as LAError {
            throw mapLAError(laError)
        } catch {
            throw BiometricError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Private Methods
    
    private func mapError(_ error: NSError?) -> BiometricError {
        guard let error = error else {
            return .unknown("Unknown error occurred")
        }
        
        guard let laError = error as? LAError else {
            return .unknown(error.localizedDescription)
        }
        
        return mapLAError(laError)
    }
    
    private func mapLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancel
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        case .biometryLockout:
            return .lockout
        default:
            return .unknown(error.localizedDescription)
        }
    }
}

// MARK: - UserDefaults Extension for Biometric Preferences
public extension UserDefaults {
    private enum Keys {
        static let biometricAuthEnabled = "biometricAuthEnabled"
        static let lastBiometricAuthDate = "lastBiometricAuthDate"
    }
    
    var isBiometricAuthEnabled: Bool {
        get { bool(forKey: Keys.biometricAuthEnabled) }
        set { set(newValue, forKey: Keys.biometricAuthEnabled) }
    }
    
    var lastBiometricAuthDate: Date? {
        get { object(forKey: Keys.lastBiometricAuthDate) as? Date }
        set { set(newValue, forKey: Keys.lastBiometricAuthDate) }
    }
}