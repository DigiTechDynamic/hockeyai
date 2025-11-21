import SwiftUI

// MARK: - NHL Team Theme Implementation
// Implements AppTheme protocol for NHL teams with smart color adaptation

class NHLTeamTheme: AppTheme {
    
    private let team: NHLTeam
    private let adaptedColors: AdaptedColorSet
    
    init(team: NHLTeam) {
        self.team = team
        
        // Create adapted color set with accessibility in mind
        self.adaptedColors = ColorAdaptation.createAdaptiveTheme(
            primary: team.primaryColor,
            secondary: team.secondaryColor,
            accent: team.accentColor,
            useDarkBackground: true  // Hockey apps look better in dark mode
        )
    }
    
    // MARK: - Core Colors (from AppTheme)
    var primary: Color { adaptedColors.primary }
    var secondary: Color { adaptedColors.secondary }
    var accent: Color { adaptedColors.accent }
    var background: Color { adaptedColors.background }
    var surface: Color { adaptedColors.surface }
    var text: Color { adaptedColors.textPrimary }
    var textSecondary: Color { adaptedColors.textSecondary }
    
    // MARK: - Contrast-aware text colors
    var textOnPrimary: Color { adaptedColors.textOnPrimary }
    var textOnSecondary: Color { adaptedColors.textOnSecondary }
    var textOnAccent: Color { 
        ColorAdaptation.ensureContrast(
            foreground: Color.white,
            background: accent,
            minRatio: 4.5
        )
    }
    
    // MARK: - Semantic colors
    var success: Color { Color(hex: "#10B981") }  // Standard green
    var warning: Color { Color(hex: "#F59E0B") }  // Standard amber
    var error: Color { Color(hex: "#EF4444") }    // Standard red
    var info: Color { adaptedColors.secondary }   // Use team secondary
    // Destructive action red (distinct token)
    var destructive: Color { Color(hex: "#DC143C") }
    
    // MARK: - Component specific
    var cardBackground: Color {
        // Slightly lighter than surface for depth
        adaptedColors.surface.opacity(0.95)
    }
    
    var buttonBackground: Color {
        adaptedColors.primary
    }
    
    var inputBackground: Color {
        adaptedColors.surface.opacity(0.7)
    }
    
    var divider: Color {
        adaptedColors.textSecondary.opacity(0.2)
    }
    
    // MARK: - Gradients
    var primaryGradient: LinearGradient {
        adaptedColors.primaryGradient
    }
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                adaptedColors.background,
                adaptedColors.background.opacity(0.95),
                adaptedColors.surface.opacity(0.3)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var pageBackgroundGradient: LinearGradient {
        // Subtle team color influence
        LinearGradient(
            colors: [
                adaptedColors.background,
                adaptedColors.background.blended(with: adaptedColors.primary, by: 0.05),
                adaptedColors.background
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Onboarding/Auth specific
    var onboardingBackgroundGradient: LinearGradient {
        // More prominent team colors for onboarding
        LinearGradient(
            colors: [
                adaptedColors.background,
                adaptedColors.primary.opacity(0.15),
                adaptedColors.secondary.opacity(0.1),
                adaptedColors.background
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var onboardingGlowColor: Color {
        adaptedColors.primary.opacity(0.4)
    }
    
    var onboardingAccentGlowColor: Color {
        adaptedColors.secondary.opacity(0.3)
    }
    
    var glowGradient: RadialGradient {
        adaptedColors.teamGlow
    }
    
    // MARK: - Typography
    var fonts: ThemeFonts { ThemeFonts() }
    
    var logoFont: Font {
        .system(size: 48, weight: .black, design: .default)
    }
    
    var brandTitleFont: Font {
        .system(size: 34, weight: .bold, design: .default)
    }
    
    var brandSubtitleFont: Font {
        .system(size: 18, weight: .semibold, design: .default)
    }
    
    // MARK: - Text effects
    var textEffectColor: Color {
        adaptedColors.primary
    }
    
    var brandSubtitleTracking: CGFloat { 1 }
    
    // MARK: - Spacing & Layout
    var spacing: ThemeSpacing { ThemeSpacing() }
    var cornerRadius: CGFloat { AppSettings.Constants.Layout.cornerRadiusMedium }
    var buttonHeight: CGFloat { AppSettings.Constants.Sizing.buttonLarge }
    
    // MARK: - Animations
    var animations: ThemeAnimations { ThemeAnimations() }
}

// MARK: - Theme Registration
struct NHLTeamThemeRegistration: ThemeRegistrable {
    let team: NHLTeam
    
    var id: String { team.id }
    var displayName: String { "\(team.city) \(team.name)" }
    
    func createTheme() -> AppTheme {
        NHLTeamTheme(team: team)
    }
}

// MARK: - Color Blending Extension
extension Color {
    /// Blends two colors together by the specified amount (0-1)
    func blended(with color: Color, by amount: Double) -> Color {
        let clampedAmount = max(0, min(1, amount))
        
        let uiColor1 = UIColor(self)
        let uiColor2 = UIColor(color)
        
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        uiColor1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiColor2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let r = r1 * (1 - clampedAmount) + r2 * clampedAmount
        let g = g1 * (1 - clampedAmount) + g2 * clampedAmount
        let b = b1 * (1 - clampedAmount) + b2 * clampedAmount
        let a = a1 * (1 - clampedAmount) + a2 * clampedAmount
        
        return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Theme Manager Extension
extension ThemeManager {
    /// Registers all NHL team themes
    func registerNHLTeams() {
        for team in NHLTeams.allTeams {
            let registration = NHLTeamThemeRegistration(team: team)
            registerTheme(registration)
        }
    }
    
    /// Sets theme for a specific NHL team
    func setNHLTeam(_ team: NHLTeam) {
        setTheme(themeId: team.id)
    }
    
    /// Gets the current NHL team if one is selected
    func getCurrentNHLTeam() -> NHLTeam? {
        let currentId = getCurrentThemeId()
        return NHLTeams.team(byId: currentId)
    }
}
