import Foundation
import FirebaseAuth
import UIKit

public final class PhoneAuthenticationProvider {
    public static let shared = PhoneAuthenticationProvider()
    
    private init() {}
    
    public func verifyPhoneNumber(_ phoneNumber: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            Auth.auth().settings?.isAppVerificationDisabledForTesting = false
            
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
                if let error = error {
                    continuation.resume(throwing: self.mapPhoneAuthError(error))
                    return
                }
                
                guard let verificationID = verificationID else {
                    continuation.resume(throwing: AuthError.internalError)
                    return
                }
                
                continuation.resume(returning: verificationID)
            }
        }
    }
    
    public func signIn(verificationID: String, verificationCode: String) async throws -> AuthCredential {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )
        return credential
    }
    
    // For testing purposes only
    public func enableTestMode(withPhoneNumber testPhoneNumber: String, verificationCode: String) {
        #if DEBUG
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
        // In test mode, Firebase accepts specific test phone numbers
        // Configure these in Firebase Console under Authentication > Sign-in method > Phone
        #endif
    }
    
    private func mapPhoneAuthError(_ error: Error) -> AuthError {
        let nsError = error as NSError
        
        if let errorCode = AuthErrorCode(rawValue: nsError.code) {
            switch errorCode {
            case .invalidPhoneNumber:
                return .invalidPhoneNumber
            case .invalidVerificationCode:
                return .invalidVerificationCode
            case .invalidVerificationID:
                return .invalidCredential
            case .missingPhoneNumber:
                return .invalidPhoneNumber
            case .quotaExceeded:
                return .tooManyRequests
            default:
                return .unknownError(error.localizedDescription)
            }
        }
        
        return .unknownError(error.localizedDescription)
    }
}

// MARK: - Phone Number Formatter
public extension PhoneAuthenticationProvider {
    static func formatPhoneNumber(_ phoneNumber: String, countryCode: String = "+1") -> String {
        // Remove all non-numeric characters
        let numbersOnly = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // Add country code if not present
        if numbersOnly.hasPrefix("1") && numbersOnly.count == 11 {
            return "+\(numbersOnly)"
        } else if numbersOnly.count == 10 {
            return "\(countryCode)\(numbersOnly)"
        } else if phoneNumber.hasPrefix("+") {
            return phoneNumber
        }
        
        return "\(countryCode)\(numbersOnly)"
    }
    
    static func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let phoneRegex = #"^\+[1-9]\d{1,14}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return predicate.evaluate(with: phoneNumber)
    }
}