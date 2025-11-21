import Foundation
import SwiftUI

/// Container for all authentication-related dependencies
/// This is the only file that needs to be customized when using the authentication module in different apps
public final class AuthenticationContainer: ObservableObject {
    
    // MARK: - Dependencies
    public let authManager: AuthenticationManager
    public let googleProvider: GoogleAuthenticationProvider
    public let appleProvider: AppleAuthenticationProvider
    public let phoneProvider: PhoneAuthenticationProvider
    
    // MARK: - View Configuration
    /// Override these properties in your app to customize the UI
    public var theme: AuthenticationTheme
    public var features: AuthenticationFeatures
    public var content: AuthenticationContent
    
    // MARK: - Singleton
    public static let shared = AuthenticationContainer()
    
    private init() {
        // Initialize authentication services
        self.authManager = AuthenticationManager.shared
        self.googleProvider = GoogleAuthenticationProvider.shared
        self.appleProvider = AppleAuthenticationProvider.shared
        self.phoneProvider = PhoneAuthenticationProvider.shared
        
        // Initialize with theme from ThemeManager
        let activeTheme = ThemeManager.shared.activeTheme
        self.theme = AuthenticationTheme.from(theme: activeTheme)
        self.features = AuthenticationFeatures()
        self.content = AuthenticationContent()
        
        // Subscribe to theme changes
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ThemeChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.theme = AuthenticationTheme.from(theme: ThemeManager.shared.activeTheme)
        }
    }
    
    /// Configure the container with custom settings
    public func configure(
        theme: AuthenticationTheme? = nil,
        features: AuthenticationFeatures? = nil,
        content: AuthenticationContent? = nil
    ) {
        if let theme = theme {
            self.theme = theme
        }
        if let features = features {
            self.features = features
        }
        if let content = content {
            self.content = content
        }
    }
}

// MARK: - Theme Configuration
// This struct now serves as a bridge between the unified theme system and authentication-specific needs
public struct AuthenticationTheme {
    // Colors
    public var primaryColor: Color
    public var secondaryColor: Color
    public var backgroundColor: Color
    public var surfaceColor: Color
    public var errorColor: Color
    public var textColor: Color
    public var secondaryTextColor: Color
    
    // Typography
    public var titleFont: Font
    public var headlineFont: Font
    public var bodyFont: Font
    public var captionFont: Font
    
    // Dimensions
    public var cornerRadius: CGFloat
    public var buttonHeight: CGFloat
    public var horizontalPadding: CGFloat
    public var verticalSpacing: CGFloat
    
    // Animations
    public var animationDuration: Double
    
    // Factory method to create theme from AppTheme
    public static func from(theme: AppTheme) -> AuthenticationTheme {
        return AuthenticationTheme(
            primaryColor: theme.primary,
            secondaryColor: theme.secondary,
            backgroundColor: theme.background,
            surfaceColor: theme.surface,
            errorColor: theme.error,
            textColor: theme.text,
            secondaryTextColor: theme.textSecondary,
            titleFont: theme.fonts.largeTitle,
            headlineFont: theme.fonts.headline,
            bodyFont: theme.fonts.body,
            captionFont: theme.fonts.caption,
            cornerRadius: 12,
            buttonHeight: 56,
            horizontalPadding: theme.spacing.lg,
            verticalSpacing: theme.spacing.md,
            animationDuration: 0.3
        )
    }
    
    public init(
        primaryColor: Color = .blue,
        secondaryColor: Color = .orange,
        backgroundColor: Color = Color(.systemBackground),
        surfaceColor: Color = Color(.secondarySystemBackground),
        errorColor: Color = .red,
        textColor: Color = Color(.label),
        secondaryTextColor: Color = Color(.secondaryLabel),
        titleFont: Font = .largeTitle.weight(.bold),
        headlineFont: Font = .headline,
        bodyFont: Font = .body,
        captionFont: Font = .caption,
        cornerRadius: CGFloat = 12,
        buttonHeight: CGFloat = 56,
        horizontalPadding: CGFloat = 24,
        verticalSpacing: CGFloat = 16,
        animationDuration: Double = 0.3
    ) {
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.backgroundColor = backgroundColor
        self.surfaceColor = surfaceColor
        self.errorColor = errorColor
        self.textColor = textColor
        self.secondaryTextColor = secondaryTextColor
        self.titleFont = titleFont
        self.headlineFont = headlineFont
        self.bodyFont = bodyFont
        self.captionFont = captionFont
        self.cornerRadius = cornerRadius
        self.buttonHeight = buttonHeight
        self.horizontalPadding = horizontalPadding
        self.verticalSpacing = verticalSpacing
        self.animationDuration = animationDuration
    }
}

// MARK: - Feature Configuration
public struct AuthenticationFeatures {
    public var enableEmailAuth: Bool
    public var enablePhoneAuth: Bool
    public var enableGoogleAuth: Bool
    public var enableAppleAuth: Bool
    public var enableAnonymousAuth: Bool
    public var enablePasswordReset: Bool
    public var enableEmailVerification: Bool
    public var requireEmailVerification: Bool
    public var enableAccountDeletion: Bool
    public var enableProfileEditing: Bool
    public var enableBiometricAuth: Bool
    public var minimumPasswordLength: Int
    public var requireStrongPassword: Bool
    
    /// Computed property to check if any social auth is enabled
    public var enableSocialAuth: Bool {
        return enableGoogleAuth || enableAppleAuth
    }
    
    public init(
        enableEmailAuth: Bool = true,
        enablePhoneAuth: Bool = true,
        enableGoogleAuth: Bool = true,
        enableAppleAuth: Bool = true,
        enableAnonymousAuth: Bool = false,
        enablePasswordReset: Bool = true,
        enableEmailVerification: Bool = true,
        requireEmailVerification: Bool = false,
        enableAccountDeletion: Bool = true,
        enableProfileEditing: Bool = true,
        enableBiometricAuth: Bool = false,
        minimumPasswordLength: Int = 6,
        requireStrongPassword: Bool = false
    ) {
        self.enableEmailAuth = enableEmailAuth
        self.enablePhoneAuth = enablePhoneAuth
        self.enableGoogleAuth = enableGoogleAuth
        self.enableAppleAuth = enableAppleAuth
        self.enableAnonymousAuth = enableAnonymousAuth
        self.enablePasswordReset = enablePasswordReset
        self.enableEmailVerification = enableEmailVerification
        self.requireEmailVerification = requireEmailVerification
        self.enableAccountDeletion = enableAccountDeletion
        self.enableProfileEditing = enableProfileEditing
        self.enableBiometricAuth = enableBiometricAuth
        self.minimumPasswordLength = minimumPasswordLength
        self.requireStrongPassword = requireStrongPassword
    }
}

// MARK: - Content Configuration
public struct AuthenticationContent {
    // App Info
    public var appName: String
    public var appLogo: Image?
    
    // Sign In Screen
    public var signInTitle: String
    public var signInSubtitle: String
    public var emailPlaceholder: String
    public var passwordPlaceholder: String
    public var signInButtonTitle: String
    public var forgotPasswordButtonTitle: String
    public var noAccountText: String
    public var signUpLinkText: String
    
    // Sign Up Screen
    public var signUpTitle: String
    public var signUpSubtitle: String
    public var confirmPasswordPlaceholder: String
    public var signUpButtonTitle: String
    public var hasAccountText: String
    public var signInLinkText: String
    public var termsText: String
    public var privacyText: String
    
    // Social Sign In
    public var continueWithGoogle: String
    public var continueWithApple: String
    public var continueWithPhone: String
    public var orText: String
    
    // Phone Auth
    public var phoneTitle: String
    public var phoneSubtitle: String
    public var phonePlaceholder: String
    public var sendCodeButtonTitle: String
    public var verificationTitle: String
    public var verificationSubtitle: String
    public var verificationCodePlaceholder: String
    public var verifyButtonTitle: String
    public var resendCodeText: String
    
    // Password Reset
    public var resetPasswordTitle: String
    public var resetPasswordSubtitle: String
    public var resetPasswordButtonTitle: String
    public var resetPasswordSuccessMessage: String
    
    // Error Messages
    public var genericErrorMessage: String
    public var networkErrorMessage: String
    
    public init(
        appName: String = "App",
        appLogo: Image? = nil,
        signInTitle: String = "Welcome Back",
        signInSubtitle: String = "Sign in to continue",
        emailPlaceholder: String = "Email",
        passwordPlaceholder: String = "Password",
        signInButtonTitle: String = "Sign In",
        forgotPasswordButtonTitle: String = "Forgot Password?",
        noAccountText: String = "Don't have an account?",
        signUpLinkText: String = "Sign Up",
        signUpTitle: String = "Create Account",
        signUpSubtitle: String = "Sign up to get started",
        confirmPasswordPlaceholder: String = "Confirm Password",
        signUpButtonTitle: String = "Sign Up",
        hasAccountText: String = "Already have an account?",
        signInLinkText: String = "Sign In",
        termsText: String = "Terms of Service",
        privacyText: String = "Privacy Policy",
        continueWithGoogle: String = "Continue with Google",
        continueWithApple: String = "Continue with Apple",
        continueWithPhone: String = "Continue with Phone",
        orText: String = "OR",
        phoneTitle: String = "Enter Phone Number",
        phoneSubtitle: String = "We'll send you a verification code",
        phonePlaceholder: String = "Phone Number",
        sendCodeButtonTitle: String = "Send Code",
        verificationTitle: String = "Enter Verification Code",
        verificationSubtitle: String = "We sent a code to",
        verificationCodePlaceholder: String = "123456",
        verifyButtonTitle: String = "Verify",
        resendCodeText: String = "Resend Code",
        resetPasswordTitle: String = "Reset Password",
        resetPasswordSubtitle: String = "Enter your email to receive reset instructions",
        resetPasswordButtonTitle: String = "Send Reset Email",
        resetPasswordSuccessMessage: String = "Check your email for reset instructions",
        genericErrorMessage: String = "Something went wrong. Please try again.",
        networkErrorMessage: String = "Please check your internet connection."
    ) {
        self.appName = appName
        self.appLogo = appLogo
        self.signInTitle = signInTitle
        self.signInSubtitle = signInSubtitle
        self.emailPlaceholder = emailPlaceholder
        self.passwordPlaceholder = passwordPlaceholder
        self.signInButtonTitle = signInButtonTitle
        self.forgotPasswordButtonTitle = forgotPasswordButtonTitle
        self.noAccountText = noAccountText
        self.signUpLinkText = signUpLinkText
        self.signUpTitle = signUpTitle
        self.signUpSubtitle = signUpSubtitle
        self.confirmPasswordPlaceholder = confirmPasswordPlaceholder
        self.signUpButtonTitle = signUpButtonTitle
        self.hasAccountText = hasAccountText
        self.signInLinkText = signInLinkText
        self.termsText = termsText
        self.privacyText = privacyText
        self.continueWithGoogle = continueWithGoogle
        self.continueWithApple = continueWithApple
        self.continueWithPhone = continueWithPhone
        self.orText = orText
        self.phoneTitle = phoneTitle
        self.phoneSubtitle = phoneSubtitle
        self.phonePlaceholder = phonePlaceholder
        self.sendCodeButtonTitle = sendCodeButtonTitle
        self.verificationTitle = verificationTitle
        self.verificationSubtitle = verificationSubtitle
        self.verificationCodePlaceholder = verificationCodePlaceholder
        self.verifyButtonTitle = verifyButtonTitle
        self.resendCodeText = resendCodeText
        self.resetPasswordTitle = resetPasswordTitle
        self.resetPasswordSubtitle = resetPasswordSubtitle
        self.resetPasswordButtonTitle = resetPasswordButtonTitle
        self.resetPasswordSuccessMessage = resetPasswordSuccessMessage
        self.genericErrorMessage = genericErrorMessage
        self.networkErrorMessage = networkErrorMessage
    }
}