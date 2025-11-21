import Foundation
import FirebaseAuth
import GoogleSignIn
import UIKit

public final class GoogleAuthenticationProvider: NSObject {
    public static let shared = GoogleAuthenticationProvider()
    
    private override init() {
        super.init()
    }
    
    public func signIn() async throws -> AuthCredential {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootViewController = windowScene.windows.first?.rootViewController else {
                    continuation.resume(throwing: AuthError.internalError)
                    return
                }
                
                GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
                    if let error = error {
                        continuation.resume(throwing: self?.mapGoogleError(error) ?? AuthError.unknownError(error.localizedDescription))
                        return
                    }
                    
                    guard let result = result,
                          let idToken = result.user.idToken?.tokenString else {
                        continuation.resume(throwing: AuthError.invalidCredential)
                        return
                    }
                    
                    let credential = GoogleAuthProvider.credential(
                        withIDToken: idToken,
                        accessToken: result.user.accessToken.tokenString
                    )
                    
                    continuation.resume(returning: credential)
                }
            }
        }
    }
    
    public func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
    
    public static func credential(withIDToken idToken: String, accessToken: String) -> AuthCredential {
        return GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
    }
    
    private func mapGoogleError(_ error: Error) -> AuthError {
        let nsError = error as NSError
        
        switch nsError.code {
        case GIDSignInError.canceled.rawValue:
            return .operationNotAllowed
        case GIDSignInError.hasNoAuthInKeychain.rawValue:
            return .userNotFound
        case GIDSignInError.unknown.rawValue:
            return .unknownError(error.localizedDescription)
        default:
            return .unknownError(error.localizedDescription)
        }
    }
}

// MARK: - Configuration Helper
public extension GoogleAuthenticationProvider {
    static func configure() {
        let plistName = ModuleConfigurationManager.shared.isConfigured ? 
                       ModuleConfigurationManager.shared.configuration.googleServicePlistName : 
                       "GoogleService-Info"
        
        guard let plistName = plistName,
              let path = Bundle.main.path(forResource: plistName, ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            fatalError("\(plistName ?? "GoogleService-Info").plist not found or CLIENT_ID missing")
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }
}