import SwiftUI
import Foundation

// MARK: - STY Theme Implementation
public struct STYThemeStyle: AppTheme {
    // Using STYTheme color definitions for consistency
    public let primary = STYTheme.Colors.neonGreen
    public let secondary = STYTheme.Colors.lightGray
    public let accent = STYTheme.Colors.error // Orange accent
    public let background = STYTheme.Colors.background
    public let surface = STYTheme.Colors.surface
    public let text = STYTheme.Colors.primaryText
    public let textSecondary = STYTheme.Colors.secondaryText
    
    // Contrast-aware text colors
    public let textOnPrimary = STYTheme.Colors.black // Black on neon green
    public let textOnSecondary = STYTheme.Colors.black // Black on light gray
    public let textOnAccent = STYTheme.Colors.white // White on orange
    
    // Semantic colors from STYTheme
    public let success = STYTheme.Colors.success
    public let warning = STYTheme.Colors.warning
    public let error = STYTheme.Colors.error
    public let info = STYTheme.Colors.info
    public let destructive = STYTheme.Colors.destructive
    
    // Component specific colors
    public let cardBackground = STYTheme.Colors.cardBackground
    public let buttonBackground = STYTheme.Colors.neonGreen
    public let inputBackground = Color(hex: "2A2A2A")
    public let divider = Color(hex: "4A4A4A") // Lighter divider for visibility
    
    public var primaryGradient: LinearGradient {
        STYTheme.Gradients.neonGradient
    }
    
    public var backgroundGradient: LinearGradient {
        STYTheme.Gradients.darkBackground
    }
    
    public var pageBackgroundGradient: LinearGradient {
        STYTheme.Gradients.darkBackground
    }
    
    // Onboarding/Auth specific
    public var onboardingBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#0F0F0F"),
                Color(hex: "#0F0F0F")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    public var onboardingGlowColor: Color {
        primary.opacity(0.4)
    }
    
    public var onboardingAccentGlowColor: Color {
        accent.opacity(0.3)
    }
    
    public var glowGradient: RadialGradient {
        STYTheme.Gradients.glowGradient
    }
    
    // Typography with athletic bold fonts
    public let fonts = ThemeFonts()
    public let logoFont = STYTheme.Typography.logoStyle
    public let brandTitleFont = STYTheme.Typography.displayFont
    public let brandSubtitleFont: Font = .system(size: 18, weight: .bold)
    
    // Text effects
    public let textEffectColor = STYTheme.Colors.neonGreen
    public let brandSubtitleTracking: CGFloat = 3
    
    // Layout
    public let spacing = ThemeSpacing()
    public let cornerRadius: CGFloat = 16
    public let buttonHeight: CGFloat = 52
    
    public let animations = ThemeAnimations()
    
    public init() {}
}
