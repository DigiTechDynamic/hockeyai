import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

public final class AppleAuthenticationProvider: NSObject {
    public static let shared = AppleAuthenticationProvider()
    
    private var currentNonce: String?
    private var completionHandler: ((Result<AuthCredential, Error>) -> Void)?
    
    private override init() {
        super.init()
    }
    
    @MainActor
    public func signIn() async throws -> AuthCredential {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        return try await withCheckedThrowingContinuation { continuation in
            self.completionHandler = { result in
                switch result {
                case .success(let credential):
                    continuation.resume(returning: credential)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleAuthenticationProvider: ASAuthorizationControllerDelegate {
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                completionHandler?(.failure(AuthError.invalidCredential))
                return
            }
            
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )
            
            // Store user info if available
            if let fullName = appleIDCredential.fullName {
                let displayName = PersonNameComponentsFormatter().string(from: fullName)
                UserDefaults.standard.set(displayName, forKey: "appleUserDisplayName")
            }
            
            if let email = appleIDCredential.email {
                UserDefaults.standard.set(email, forKey: "appleUserEmail")
            }
            
            completionHandler?(.success(credential))
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let error = error as? ASAuthorizationError {
            switch error.code {
            case .canceled:
                completionHandler?(.failure(AuthError.operationNotAllowed))
            case .invalidResponse:
                completionHandler?(.failure(AuthError.invalidCredential))
            case .notHandled:
                completionHandler?(.failure(AuthError.operationNotAllowed))
            case .failed:
                completionHandler?(.failure(AuthError.unknownError("Apple Sign In failed")))
            default:
                completionHandler?(.failure(AuthError.unknownError(error.localizedDescription)))
            }
        } else {
            completionHandler?(.failure(AuthError.unknownError(error.localizedDescription)))
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleAuthenticationProvider: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
}