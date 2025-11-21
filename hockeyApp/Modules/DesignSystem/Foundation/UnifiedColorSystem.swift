import SwiftUI

// MARK: - Unified Color System
/// A consolidated color system that reduces duplication and provides semantic color tokens
public struct UnifiedColorSystem {
    
    // MARK: - Core Color Palette
    /// The fundamental colors used throughout the app
    public struct Core {
        // Grayscale
        public static let black = Color(hex: "#000000")
        public static let gray900 = Color(hex: "#0A0A0A")
        public static let gray800 = Color(hex: "#141414")
        public static let gray700 = Color(hex: "#1A1A1A")
        public static let gray600 = Color(hex: "#2A2A2A")
        public static let gray500 = Color(hex: "#808080")
        public static let gray400 = Color(hex: "#8C8C8C")
        public static let gray300 = Color(hex: "#B8B8B8")
        public static let gray200 = Color(hex: "#C0C0C0")
        public static let gray100 = Color(hex: "#E5E5E5")
        public static let white = Color(hex: "#FFFFFF")
        
        // Brand Colors
        public static let primaryBrand = Color(hex: "#C0C0C0") // Silver
        public static let secondaryBrand = Color(hex: "#4169E1") // Royal Blue
        
        // Accent Colors
        public static let accentRed = Color(hex: "#DC143C")
        public static let accentGreen = Color(hex: "#00A86B")
        public static let accentBlue = Color(hex: "#4169E1")
        public static let accentOrange = Color(hex: "#FF8C00")
        public static let accentYellow = Color(hex: "#FFCA28")
    }
    
    // MARK: - Semantic Colors
    /// Colors with specific meaning/usage
    public struct Semantic {
        // Backgrounds
        public static let backgroundPrimary = Core.black
        public static let backgroundSecondary = Core.gray900
        public static let backgroundTertiary = Core.gray800
        public static let backgroundElevated = Core.gray700
        
        // Surfaces
        public static let surfacePrimary = Core.gray800
        public static let surfaceSecondary = Core.gray700
        public static let surfaceCard = Color(hex: "#0D0D0D")
        
        // Text
        public static let textPrimary = Core.white
        public static let textSecondary = Core.gray300
        public static let textTertiary = Core.gray500
        public static let textOnBrand = Core.white
        public static let textOnAccent = Core.white
        
        // Interactive
        public static let interactivePrimary = Core.primaryBrand
        public static let interactiveSecondary = Core.gray600
        public static let interactiveDisabled = Core.gray500.opacity(0.5)
        
        // Borders
        public static let borderDefault = Core.gray600
        public static let borderSubtle = Core.gray600.opacity(0.5)
        public static let borderStrong = Core.primaryBrand
        
        // States
        public static let success = Core.accentGreen
        public static let warning = Core.accentYellow
        public static let error = Core.accentRed
        public static let info = Core.accentBlue
    }
    
    // MARK: - Component Colors
    /// Pre-defined colors for specific components
    public struct Component {
        // Buttons
        public static let buttonPrimaryBackground = Semantic.interactivePrimary
        public static let buttonPrimaryText = Semantic.textOnBrand
        public static let buttonSecondaryBackground = Semantic.surfaceSecondary
        public static let buttonSecondaryText = Semantic.textPrimary
        
        // Cards
        public static let cardBackground = Semantic.surfaceCard
        public static let cardBorder = Semantic.borderSubtle
        
        // Inputs
        public static let inputBackground = Core.gray900
        public static let inputBorder = Semantic.borderDefault
        public static let inputText = Semantic.textPrimary
        public static let inputPlaceholder = Semantic.textTertiary
        
        // Navigation
        public static let navBackground = Semantic.backgroundSecondary.opacity(0.95)
        public static let navItemActive = Semantic.interactivePrimary
        public static let navItemInactive = Semantic.textSecondary
    }
    
    // MARK: - Effects
    /// Colors for visual effects
    public struct Effects {
        public static let shadowDefault = Core.black.opacity(0.8)
        public static let shadowLight = Core.black.opacity(0.4)
        public static let glowPrimary = Core.primaryBrand.opacity(0.3)
        public static let glowSecondary = Core.white.opacity(0.1)
        public static let overlayDark = Core.black.opacity(0.5)
        public static let overlayLight = Core.white.opacity(0.1)
    }
    
    // MARK: - Gradients
    /// Pre-defined gradients
    public struct Gradients {
        public static let backgroundGradient = LinearGradient(
            colors: [Semantic.backgroundPrimary, Semantic.backgroundSecondary, Semantic.backgroundPrimary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let cardGradient = LinearGradient(
            colors: [Component.cardBackground, Component.cardBackground.opacity(0.8)],
            startPoint: .top,
            endPoint: .bottom
        )
        
        public static let primaryButtonGradient = LinearGradient(
            colors: [Core.primaryBrand, Core.gray400],
            startPoint: .top,
            endPoint: .bottom
        )
        
        public static let glassGradient = LinearGradient(
            colors: [Effects.overlayLight, Core.white.opacity(0.02)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let glowGradient = RadialGradient(
            colors: [Effects.glowPrimary, Color.clear],
            center: .center,
            startRadius: 0,
            endRadius: 100
        )
    }
}


// MARK: - Theme Protocol Conformance Helper
/// Helper to create AppTheme implementations using the unified color system
public struct UnifiedTheme: AppTheme {
    // Core colors mapped from UnifiedColorSystem
    public let primary = UnifiedColorSystem.Core.primaryBrand
    public let secondary = UnifiedColorSystem.Core.gray400
    public let accent = UnifiedColorSystem.Core.accentBlue
    public let background = UnifiedColorSystem.Semantic.backgroundPrimary
    public let surface = UnifiedColorSystem.Semantic.surfacePrimary
    public let text = UnifiedColorSystem.Semantic.textPrimary
    public let textSecondary = UnifiedColorSystem.Semantic.textSecondary
    
    // Contrast-aware text colors
    public let textOnPrimary = UnifiedColorSystem.Semantic.textOnBrand
    public let textOnSecondary = UnifiedColorSystem.Semantic.textOnBrand
    public let textOnAccent = UnifiedColorSystem.Semantic.textOnAccent
    
    // Semantic colors
    public let success = UnifiedColorSystem.Semantic.success
    public let warning = UnifiedColorSystem.Semantic.warning
    public let error = UnifiedColorSystem.Semantic.error
    public let info = UnifiedColorSystem.Semantic.info
    public let destructive = UnifiedColorSystem.Core.accentRed
    
    // Component specific
    public let cardBackground = UnifiedColorSystem.Component.cardBackground
    public let buttonBackground = UnifiedColorSystem.Component.buttonPrimaryBackground
    public let inputBackground = UnifiedColorSystem.Component.inputBackground
    public let divider = UnifiedColorSystem.Semantic.borderDefault
    
    // Gradients
    public var primaryGradient: LinearGradient {
        UnifiedColorSystem.Gradients.primaryButtonGradient
    }
    
    public var backgroundGradient: LinearGradient {
        UnifiedColorSystem.Gradients.backgroundGradient
    }
    
    public var pageBackgroundGradient: LinearGradient {
        UnifiedColorSystem.Gradients.backgroundGradient
    }
    
    // Onboarding/Auth specific
    public var onboardingBackgroundGradient: LinearGradient {
        UnifiedColorSystem.Gradients.backgroundGradient
    }
    
    public var onboardingGlowColor: Color {
        UnifiedColorSystem.Effects.glowPrimary
    }
    
    public var onboardingAccentGlowColor: Color {
        UnifiedColorSystem.Effects.glowSecondary
    }
    
    public var glowGradient: RadialGradient {
        UnifiedColorSystem.Gradients.glowGradient
    }
    
    // Typography
    public let fonts = ThemeFonts()
    public let logoFont: Font = .system(size: 60, weight: .black, design: .rounded)
    public let brandTitleFont: Font = .system(size: 48, weight: .black, design: .rounded)
    public let brandSubtitleFont: Font = .system(size: 18, weight: .bold, design: .rounded)
    
    // Text effects
    public let textEffectColor = UnifiedColorSystem.Core.primaryBrand
    public let brandSubtitleTracking: CGFloat = 2
    
    // Layout
    public let spacing = ThemeSpacing()
    public let cornerRadius: CGFloat = 16
    public let buttonHeight: CGFloat = 52
    
    public let animations = ThemeAnimations()
    
    public init() {}
}
