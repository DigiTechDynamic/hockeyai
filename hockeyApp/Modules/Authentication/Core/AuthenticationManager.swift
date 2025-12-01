import Foundation
import FirebaseAuth
import FirebaseCore
import Combine
#if canImport(RevenueCat)
import RevenueCat
#endif

public final class AuthenticationManager: ObservableObject {
    @Published public private(set) var currentUser: AuthUser?
    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var isLoading: Bool = true
    
    private var handle: AuthStateDidChangeListenerHandle?
    private let auth = Auth.auth()
    private var cancellables = Set<AnyCancellable>()
    
    public var authStatePublisher: AnyPublisher<AuthUser?, Never> {
        $currentUser.eraseToAnyPublisher()
    }
    
    public static let shared = AuthenticationManager()
    
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = handle {
            auth.removeStateDidChangeListener(handle)
        }
    }
    
    private func setupAuthStateListener() {
        handle = auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            self?.updateUser(from: firebaseUser)
        }
    }
    
    private func updateUser(from firebaseUser: User?) {
        if let firebaseUser = firebaseUser {
            currentUser = AuthUser(
                uid: firebaseUser.uid,
                email: firebaseUser.email,
                phoneNumber: firebaseUser.phoneNumber,
                displayName: firebaseUser.displayName,
                photoURL: firebaseUser.photoURL,
                isEmailVerified: firebaseUser.isEmailVerified,
                isAnonymous: firebaseUser.isAnonymous,
                creationDate: firebaseUser.metadata.creationDate,
                lastSignInDate: firebaseUser.metadata.lastSignInDate,
                providerID: firebaseUser.providerData.first?.providerID
            )
            isAuthenticated = true

            // Align identities across providers
            let uid = firebaseUser.uid
            Task { @MainActor in
                // Merge any pre-identity events (e.g., app_installed) to this UID,
                // then identify across analytics providers
                AnalyticsManager.shared.aliasAndIdentifyIfNeeded(newDistinctId: uid)
            }
            #if canImport(RevenueCat)
            Task {
                // Log into RevenueCat with Firebase UID for consistent attribution
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    Purchases.shared.logIn(uid) { _, _, _ in
                        continuation.resume(returning: ())
                    }
                }
                // After RC login, sync Mixpanel distinctId to the RC appUserID
                await MainActor.run {
                    AnalyticsManager.shared.syncRevenueCatIdentity()
                }
            }
            #endif
        } else {
            currentUser = nil
            isAuthenticated = false
            // Switch analytics to a fresh anonymous user and log out of RevenueCat
            #if canImport(RevenueCat)
            Task {
                await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                    Purchases.shared.logOut { _, _ in
                        cont.resume(returning: ())
                    }
                }
                await MainActor.run {
                    AnalyticsManager.shared.syncRevenueCatIdentity() // will use RC anonymous id
                }
            }
            #else
            Task { @MainActor in
                let anon = "anon_" + UUID().uuidString
                AnalyticsManager.shared.setGlobalUserID(anon)
            }
            #endif
        }
        isLoading = false
    }
}

// MARK: - AuthenticationProtocol
extension AuthenticationManager: AuthenticationProtocol {
    
    // MARK: Email/Password Authentication
    public func signIn(email: String, password: String) async throws -> AuthUser {
        let result = try await auth.signIn(withEmail: email, password: password)
        guard let user = mapFirebaseUser(result.user) else {
            throw AuthError.internalError
        }
        return user
    }
    
    public func signUp(email: String, password: String) async throws -> AuthUser {
        let result = try await auth.createUser(withEmail: email, password: password)
        guard let user = mapFirebaseUser(result.user) else {
            throw AuthError.internalError
        }
        return user
    }
    
    public func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    // MARK: Phone Authentication
    public func signIn(phoneNumber: String) async throws -> String {
        return try await PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil)
    }
    
    public func verifyPhoneNumber(verificationID: String, verificationCode: String) async throws -> AuthUser {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )
        let result = try await auth.signIn(with: credential)
        guard let user = mapFirebaseUser(result.user) else {
            throw AuthError.internalError
        }
        return user
    }
    
    // MARK: Social Authentication
    public func signInWithGoogle() async throws -> AuthUser {
        let credential = try await GoogleAuthenticationProvider.shared.signIn()
        let result = try await auth.signIn(with: credential)
        guard let user = mapFirebaseUser(result.user) else {
            throw AuthError.internalError
        }
        return user
    }
    
    public func signInWithApple() async throws -> AuthUser {
        let credential = try await AppleAuthenticationProvider.shared.signIn()
        let result = try await auth.signIn(with: credential)
        guard let user = mapFirebaseUser(result.user) else {
            throw AuthError.internalError
        }
        return user
    }
    
    // MARK: Anonymous Authentication
    public func signInAnonymously() async throws -> AuthUser {
        let result = try await auth.signInAnonymously()
        guard let user = mapFirebaseUser(result.user) else {
            throw AuthError.internalError
        }
        return user
    }
    
    // MARK: Account Management
    public func signOut() async throws {
        // Perform complete reset BEFORE signing out
        // This ensures UserDefaults are cleared before the auth state changes
        await performCompleteReset()

        // Sign out from Firebase (this triggers auth state change)
        try auth.signOut()
    }

    /// Resets the app to behave like a fresh install
    private func performCompleteReset() async {
        print("[Auth] 🔄 Performing complete app reset...")

        let defaults = UserDefaults.standard

        // 1. Define keys to preserve
        let keysToPreserve = [
            // Keep haptics and sound settings - use correct moduleKey prefixes
            UserDefaults.moduleKey("hapticsEnabled"),
            UserDefaults.moduleKey("soundsEnabled"),
            UserDefaults.moduleKey("soundEffectsEnabled"),
            // Keep theme settings - use correct moduleKey for selectedTheme
            "selectedNHLTeam",
            UserDefaults.moduleKey("selectedTheme")
        ]

        // 2. Save values to preserve
        var preservedValues: [String: Any] = [:]
        for key in keysToPreserve {
            if let value = defaults.object(forKey: key) {
                preservedValues[key] = value
            }
        }

        // 3. Clear ALL UserDefaults
        print("[Auth] 🗑️ Clearing UserDefaults...")
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)

        // 4. Restore preserved values
        print("[Auth] 💾 Restoring preserved settings...")
        for (key, value) in preservedValues {
            defaults.set(value, forKey: key)
        }

        // 5. Ensure STY theme is set if no theme was preserved
        let themeKey = UserDefaults.moduleKey("selectedTheme")
        if preservedValues[themeKey] == nil {
            print("[Auth] 🎨 No saved theme found, setting default STY theme")
            defaults.set("sty", forKey: themeKey)
        } else if let savedTheme = preservedValues[themeKey] as? String {
            print("[Auth] 🎨 Restored theme preference: \(savedTheme)")
        }

        // 6. Force synchronize UserDefaults to ensure values are persisted before restart
        print("[Auth] 💾 Synchronizing UserDefaults...")
        defaults.synchronize()

        // 7. Delete Firebase anonymous user to get fresh UID on next launch
        print("[Auth] 🔥 Deleting Firebase user...")
        if let currentUser = auth.currentUser, currentUser.isAnonymous {
            do {
                try await currentUser.delete()
                print("[Auth] ✅ Deleted Firebase anonymous user")
            } catch {
                print("[Auth] ⚠️ Failed to delete Firebase user: \(error.localizedDescription)")
            }
        }

        // 8. Clear RevenueCat completely
        print("[Auth] 💰 Logging out RevenueCat...")
        #if canImport(RevenueCat)
        await withCheckedContinuation { continuation in
            Purchases.shared.logOut { _, _ in
                continuation.resume()
            }
        }
        print("[Auth] ✅ RevenueCat logged out")
        #endif

        // 9. Clear monetization state
        print("[Auth] 🎯 Clearing monetization state...")

        await MainActor.run {
            MonetizationManager.shared.isPremium = false
            MonetizationManager.shared.coinBalance = 0
            MonetizationManager.shared.availablePackages = []
        }

        // 10. Reset Mixpanel (clear all cached data and generate fresh distinct ID)
        print("[Auth] 📈 Resetting Mixpanel...")
        AnalyticsManager.shared.resetMixpanel()

        // 11. Clear keychain items (app secrets, stored credentials)
        print("[Auth] 🔐 Clearing keychain...")
        AppSecrets.shared.clearAll()

        // 12. Clear any cached data
        print("[Auth] 🧹 Clearing URL cache...")
        URLCache.shared.removeAllCachedResponses()

        // 13. Post notification to reload app state
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("AppStateReset"), object: nil)
        }

        print("[Auth] ✅ Complete reset finished - app is now in fresh state")

        // Terminate app to ensure truly fresh state on next launch
        // This clears:
        // - In-memory singleton state (PaywallRegistry, FirebaseRemoteConfigManager)
        // - Firebase Remote Config cache
        // - SwiftUI environment objects
        // User will see onboarding + get new A/B test assignment on relaunch
        print("[Auth] 🔄 Terminating app for complete fresh start...")
        print("[Auth] ℹ️ User will need to reopen app manually")

        // Small delay to ensure logs are written
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Terminate (user-initiated action, allowed by Apple)
        await MainActor.run {
            exit(0)
        }
    }

    public func deleteAccount() async throws {
        guard let user = auth.currentUser else {
            throw AuthError.userNotFound
        }
        
        try await user.delete()
    }
    
    public func updateProfile(displayName: String?, photoURL: URL?) async throws {
        guard let user = auth.currentUser else {
            throw AuthError.userNotFound
        }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        changeRequest.photoURL = photoURL
        try await changeRequest.commitChanges()
        
        // Update local user
        updateUser(from: auth.currentUser)
    }
    
    public func updateEmail(to newEmail: String) async throws {
        guard let user = auth.currentUser else {
            throw AuthError.userNotFound
        }
        try await user.updateEmail(to: newEmail)
    }
    
    public func updatePassword(to newPassword: String) async throws {
        guard let user = auth.currentUser else {
            throw AuthError.userNotFound
        }
        try await user.updatePassword(to: newPassword)
    }
    
    public func sendEmailVerification() async throws {
        guard let user = auth.currentUser else {
            throw AuthError.userNotFound
        }
        try await user.sendEmailVerification()
    }
    
    // MARK: Account Linking
    public func linkEmail(email: String, password: String) async throws {
        guard let user = auth.currentUser else {
            throw AuthError.userNotFound
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.link(with: credential)
    }
    
    public func linkPhone(phoneNumber: String) async throws -> String {
        return try await PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil)
    }
    
    public func linkGoogle() async throws {
        guard let user = auth.currentUser else {
            throw AuthError.userNotFound
        }
        let credential = try await GoogleAuthenticationProvider.shared.signIn()
        try await user.link(with: credential)
    }
    
    public func linkApple() async throws {
        guard let user = auth.currentUser else {
            throw AuthError.userNotFound
        }
        let credential = try await AppleAuthenticationProvider.shared.signIn()
        try await user.link(with: credential)
    }
    
    public func unlinkProvider(_ provider: AuthProvider) async throws {
        guard let user = auth.currentUser else {
            throw AuthError.userNotFound
        }
        try await user.unlink(fromProvider: provider.rawValue)
    }
    
    // MARK: Token Management
    public func refreshToken() async throws {
        guard let user = auth.currentUser else {
            throw AuthError.userNotFound
        }
        try await user.getIDTokenResult(forcingRefresh: true)
    }
    
    public func getIDToken(forceRefresh: Bool) async throws -> String {
        guard let user = auth.currentUser else {
            throw AuthError.userNotFound
        }
        return try await user.getIDToken(forcingRefresh: forceRefresh)
    }
}

// MARK: - Private Helpers
private extension AuthenticationManager {
    func mapFirebaseUser(_ firebaseUser: User) -> AuthUser? {
        return AuthUser(
            uid: firebaseUser.uid,
            email: firebaseUser.email,
            phoneNumber: firebaseUser.phoneNumber,
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL,
            isEmailVerified: firebaseUser.isEmailVerified,
            isAnonymous: firebaseUser.isAnonymous,
            creationDate: firebaseUser.metadata.creationDate,
            lastSignInDate: firebaseUser.metadata.lastSignInDate,
            providerID: firebaseUser.providerData.first?.providerID
        )
    }
    
}

// MARK: - Firebase Error Mapping
extension AuthenticationManager {
    func mapFirebaseError(_ error: Error) -> AuthError {
        guard let errorCode = AuthErrorCode(rawValue: (error as NSError).code) else {
            return .unknownError(error.localizedDescription)
        }
        
        switch errorCode {
        case .invalidEmail:
            return .invalidEmail
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .userNotFound:
            return .userNotFound
        case .wrongPassword:
            return .wrongPassword
        case .userDisabled:
            return .userDisabled
        case .operationNotAllowed:
            return .operationNotAllowed
        case .tooManyRequests:
            return .tooManyRequests
        case .networkError:
            return .networkError
        case .invalidPhoneNumber:
            return .invalidPhoneNumber
        case .invalidVerificationCode:
            return .invalidVerificationCode
        case .invalidCredential:
            return .invalidCredential
        case .credentialAlreadyInUse:
            return .credentialAlreadyInUse
        case .requiresRecentLogin:
            return .requiresRecentLogin
        case .providerAlreadyLinked:
            return .providerAlreadyLinked
        case .noSuchProvider:
            return .noSuchProvider
        case .invalidUserToken:
            return .invalidUserToken
        case .userTokenExpired:
            return .userTokenExpired
        case .invalidAPIKey:
            return .invalidAPIKey
        case .appNotAuthorized:
            return .appNotAuthorized
        case .keychainError:
            return .keychainError
        case .internalError:
            return .internalError
        default:
            return .unknownError(error.localizedDescription)
        }
    }
}
