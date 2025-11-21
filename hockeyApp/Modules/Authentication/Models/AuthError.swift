import Foundation

public enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case invalidPassword
    case emailAlreadyInUse
    case userNotFound
    case wrongPassword
    case userDisabled
    case operationNotAllowed
    case tooManyRequests
    case networkError
    case invalidPhoneNumber
    case invalidVerificationCode
    case invalidCredential
    case credentialAlreadyInUse
    case requiresRecentLogin
    case providerAlreadyLinked
    case noSuchProvider
    case invalidUserToken
    case userTokenExpired
    case invalidAPIKey
    case appNotAuthorized
    case keychainError
    case internalError
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "The email address is invalid."
        case .invalidPassword:
            return "The password is invalid. It must be at least 6 characters."
        case .emailAlreadyInUse:
            return "An account already exists with this email address."
        case .userNotFound:
            return "No account found with this email address."
        case .wrongPassword:
            return "The password is incorrect."
        case .userDisabled:
            return "This account has been disabled."
        case .operationNotAllowed:
            return "This operation is not allowed."
        case .tooManyRequests:
            return "Too many requests. Please try again later."
        case .networkError:
            return "Network error. Please check your connection."
        case .invalidPhoneNumber:
            return "The phone number is invalid."
        case .invalidVerificationCode:
            return "The verification code is invalid."
        case .invalidCredential:
            return "The credential is invalid or has expired."
        case .credentialAlreadyInUse:
            return "This credential is already associated with another account."
        case .requiresRecentLogin:
            return "This operation requires recent authentication. Please sign in again."
        case .providerAlreadyLinked:
            return "This provider is already linked to your account."
        case .noSuchProvider:
            return "This provider is not linked to your account."
        case .invalidUserToken:
            return "The user token is invalid."
        case .userTokenExpired:
            return "The user token has expired."
        case .invalidAPIKey:
            return "The API key is invalid."
        case .appNotAuthorized:
            return "This app is not authorized."
        case .keychainError:
            return "Error accessing secure storage."
        case .internalError:
            return "An internal error occurred."
        case .unknownError(let message):
            return message
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .invalidPassword:
            return "Password must be at least 6 characters long."
        case .emailAlreadyInUse:
            return "Try signing in or use a different email."
        case .userNotFound:
            return "Check your email or create a new account."
        case .wrongPassword:
            return "Try again or reset your password."
        case .userDisabled:
            return "Contact support for assistance."
        case .tooManyRequests:
            return "Wait a few minutes before trying again."
        case .networkError:
            return "Check your internet connection and try again."
        case .invalidPhoneNumber:
            return "Enter a valid phone number with country code."
        case .invalidVerificationCode:
            return "Check the code and try again."
        case .requiresRecentLogin:
            return "Please sign out and sign in again."
        default:
            return nil
        }
    }
    
    /// User-friendly error message
    public var userMessage: String {
        return errorDescription ?? "An unexpected error occurred. Please try again."
    }
}