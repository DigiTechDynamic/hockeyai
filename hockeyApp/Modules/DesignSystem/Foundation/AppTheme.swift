import SwiftUI

// MARK: - Universal App Theme Protocol
public protocol AppTheme {
    // Core colors
    var primary: Color { get }
    var secondary: Color { get }
    var accent: Color { get }
    var background: Color { get }
    var surface: Color { get }
    var text: Color { get }
    var textSecondary: Color { get }
    
    // Contrast-aware text colors
    var textOnPrimary: Color { get }
    var textOnSecondary: Color { get }
    var textOnAccent: Color { get }
    
    // Semantic colors
    var success: Color { get }
    var warning: Color { get }
    var error: Color { get }
    var info: Color { get }
    // Destructive actions (distinct from generic error)
    var destructive: Color { get }
    
    // Component specific
    var cardBackground: Color { get }
    var buttonBackground: Color { get }
    var inputBackground: Color { get }
    var divider: Color { get }
    
    // Gradients
    var primaryGradient: LinearGradient { get }
    var backgroundGradient: LinearGradient { get }
    var pageBackgroundGradient: LinearGradient { get }
    
    // Onboarding/Auth specific
    var onboardingBackgroundGradient: LinearGradient { get }
    var onboardingGlowColor: Color { get }
    var onboardingAccentGlowColor: Color { get }
    var glowGradient: RadialGradient { get }
    
    // Typography
    var fonts: ThemeFonts { get }
    var logoFont: Font { get }
    var brandTitleFont: Font { get }
    var brandSubtitleFont: Font { get }
    
    // Text effects
    var textEffectColor: Color { get }
    var brandSubtitleTracking: CGFloat { get }
    
    // Spacing & Layout
    var spacing: ThemeSpacing { get }
    var cornerRadius: CGFloat { get }
    var buttonHeight: CGFloat { get }
    
    // Animations
    var animations: ThemeAnimations { get }
}

// MARK: - Universal Theme Support Structures

public struct ThemeSpacing {
    public let xs: CGFloat = 4
    public let sm: CGFloat = 8
    public let md: CGFloat = 16
    public let lg: CGFloat = 24
    public let xl: CGFloat = 32
    public let xxl: CGFloat = 48
    
    public init() {}
}

public struct ThemeFonts {
    // Using consistent typography system - max 3-4 weights as per best practices
    // Display & Branding
    public let display: Font = .system(size: 48, weight: .black, design: .default)  // SNAPHOCKEY logo only

    // Headers (Bold for impact)
    public let largeTitle: Font = .system(size: 34, weight: .bold, design: .default)  // Major sections
    public let title: Font = .system(size: 28, weight: .bold, design: .default)       // Screen titles
    public let headline: Font = .system(size: 22, weight: .semibold, design: .default) // Card titles

    // Body (Regular/Semibold only)
    public let body: Font = .system(size: 17, weight: .regular, design: .default)     // Main content
    public let bodyBold: Font = .system(size: 17, weight: .semibold, design: .default) // Emphasis
    public let callout: Font = .system(size: 16, weight: .regular, design: .default)   // Secondary
    public let caption: Font = .system(size: 14, weight: .regular, design: .default)   // Labels

    // Controls
    public let button: Font = .system(size: 17, weight: .semibold, design: .default)  // Buttons

    public init() {}
}

public struct ThemeAnimations {
    public let quick: Animation = .easeInOut(duration: 0.2)
    public let medium: Animation = .easeInOut(duration: 0.35)
    public let slow: Animation = .easeInOut(duration: 0.5)
    public let spring: Animation = .spring(response: 0.4, dampingFraction: 0.8)
    
    public init() {}
}

// MARK: - Theme Environment Key
public struct ThemeEnvironmentKey: EnvironmentKey {
    public static let defaultValue: AppTheme = BasicTheme()
}

extension EnvironmentValues {
    public var theme: AppTheme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - Theme-Aware View Extensions
extension View {
    public func theme(_ theme: AppTheme) -> some View {
        environment(\.theme, theme)
    }
    
    // Theme-aware text effects
    public func themeNeonText() -> some View {
        self.modifier(ThemeNeonTextModifier())
    }
    
    // Theme-aware card styles
    public func themeCard() -> some View {
        self.modifier(ThemeCardModifier())
    }
    
    // Theme-aware glass effect
    public func themeGlassEffect() -> some View {
        self.modifier(ThemeGlassEffect())
    }

    // Glowing header text effect for SNAPHOCKEY branding consistency
    public func glowingHeaderText() -> some View {
        self.modifier(GlowingHeaderTextModifier())
    }
}

// MARK: - Universal Theme-Aware View Modifiers

struct ThemeNeonTextModifier: ViewModifier {
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .foregroundColor(theme.textEffectColor)
                .shadow(color: theme.textEffectColor, radius: 3)
                .shadow(color: theme.textEffectColor, radius: 6)
                .shadow(color: theme.textEffectColor, radius: 12)
        }
    }
}

struct ThemeCardModifier: ViewModifier {
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        content
            .background(theme.cardBackground)
            .cornerRadius(AppSettings.Constants.Layout.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(theme.primary.opacity(0.1), lineWidth: 1)
            )
    }
}

struct ThemeGlassEffect: ViewModifier {
    @Environment(\.theme) var theme

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    theme.surface.opacity(0.8)
                        .blur(radius: 10)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .cornerRadius(AppSettings.Constants.Layout.cornerRadiusMedium)
    }
}

// MARK: - Glowing Header Text Modifier
struct GlowingHeaderTextModifier: ViewModifier {
    @Environment(\.theme) var theme

    func body(content: Content) -> some View {
        content
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color.white.opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: Color.white.opacity(0.5), radius: 0, x: 0, y: 0)
            .shadow(color: Color.white.opacity(0.3), radius: 4, x: 0, y: 0)
            .shadow(color: theme.primary.opacity(0.4), radius: 10, x: 0, y: 2)
    }
}
