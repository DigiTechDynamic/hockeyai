import Foundation
import Combine

public protocol AuthenticationProtocol {
    var currentUser: AuthUser? { get }
    var authStatePublisher: AnyPublisher<AuthUser?, Never> { get }
    var isAuthenticated: Bool { get }
    
    // Email/Password Authentication
    func signIn(email: String, password: String) async throws -> AuthUser
    func signUp(email: String, password: String) async throws -> AuthUser
    func resetPassword(email: String) async throws
    
    // Phone Authentication
    func signIn(phoneNumber: String) async throws -> String // Returns verification ID
    func verifyPhoneNumber(verificationID: String, verificationCode: String) async throws -> AuthUser
    
    // Social Authentication
    func signInWithGoogle() async throws -> AuthUser
    func signInWithApple() async throws -> AuthUser
    
    // Anonymous Authentication
    func signInAnonymously() async throws -> AuthUser
    
    // Account Management
    func signOut() async throws
    func deleteAccount() async throws
    func updateProfile(displayName: String?, photoURL: URL?) async throws
    func updateEmail(to newEmail: String) async throws
    func updatePassword(to newPassword: String) async throws
    func sendEmailVerification() async throws
    
    // Account Linking
    func linkEmail(email: String, password: String) async throws
    func linkPhone(phoneNumber: String) async throws -> String // Returns verification ID
    func linkGoogle() async throws
    func linkApple() async throws
    func unlinkProvider(_ provider: AuthProvider) async throws
    
    // Token Management
    func refreshToken() async throws
    func getIDToken(forceRefresh: Bool) async throws -> String
}

public protocol AuthenticationStateListener: AnyObject {
    func authenticationStateDidChange(_ user: AuthUser?)
}