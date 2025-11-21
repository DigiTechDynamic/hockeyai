import SwiftUI

// MARK: - Universal Theme Manager
// This manager is app-agnostic and works with any AppTheme implementation

public protocol ThemeRegistrable {
    var id: String { get }
    var displayName: String { get }
    func createTheme() -> AppTheme
}

public class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    
    @AppStorage(UserDefaults.moduleKey("selectedTheme")) private var selectedThemeId: String = ""
    @Published public var activeTheme: AppTheme
    @Published public var availableThemes: [ThemeRegistrable] = []
    
    private var themeRegistry: [String: ThemeRegistrable] = [:]
    private var defaultTheme: AppTheme
    
    private init() {
        // Initialize with a basic default theme - will be overridden by app registration
        if ModuleConfigurationManager.shared.isConfigured,
           let configuredTheme = ModuleConfigurationManager.shared.configuration.defaultTheme {
            self.defaultTheme = configuredTheme
        } else {
            self.defaultTheme = BasicTheme()
        }
        self.activeTheme = defaultTheme
    }
    
    // MARK: - Public API
    
    public func registerTheme(_ theme: ThemeRegistrable) {
        themeRegistry[theme.id] = theme
        availableThemes.append(theme)
        
        // Set as default if this is the first theme registered
        if availableThemes.count == 1 {
            setDefaultTheme(theme.createTheme())
        }
        
        // Load saved theme if it matches
        if selectedThemeId == theme.id {
            setTheme(themeId: theme.id)
        }
    }
    
    public func setDefaultTheme(_ theme: AppTheme) {
        defaultTheme = theme
        if selectedThemeId.isEmpty {
            activeTheme = theme
        }
    }
    
    public func setTheme(themeId: String) {
        guard let themeRegistrable = themeRegistry[themeId] else { return }
        
        selectedThemeId = themeId
        activeTheme = themeRegistrable.createTheme()
        
        // Post notification for theme change
        NotificationCenter.default.post(name: Notification.Name("ThemeChanged"), object: nil)
    }
    
    public func getCurrentThemeId() -> String {
        return selectedThemeId
    }

    /// Force reload theme from UserDefaults (useful after app reset)
    public func reloadThemeFromUserDefaults() {
        let themeKey = UserDefaults.moduleKey("selectedTheme")
        if let savedThemeId = UserDefaults.standard.string(forKey: themeKey), !savedThemeId.isEmpty {
            print("[ThemeManager] 🔄 Reloading theme from UserDefaults: \(savedThemeId)")
            setTheme(themeId: savedThemeId)
        } else {
            print("[ThemeManager] 🔄 No saved theme in UserDefaults, using STY default")
            setTheme(themeId: "sty")
        }
    }
}

// MARK: - Basic Default Theme (Fallback)
// This provides a minimal theme as a fallback before app-specific themes are registered

struct BasicTheme: AppTheme {
    // Using UnifiedColorSystem for consistency
    let primary: Color = UnifiedColorSystem.Core.primaryBrand
    let secondary: Color = UnifiedColorSystem.Core.gray400
    let accent: Color = UnifiedColorSystem.Core.accentOrange
    let background: Color = UnifiedColorSystem.Semantic.backgroundPrimary
    let surface: Color = UnifiedColorSystem.Semantic.surfacePrimary
    let text: Color = UnifiedColorSystem.Semantic.textPrimary
    let textSecondary: Color = UnifiedColorSystem.Semantic.textSecondary
    
    let textOnPrimary: Color = UnifiedColorSystem.Semantic.textOnBrand
    let textOnSecondary: Color = UnifiedColorSystem.Semantic.backgroundPrimary
    let textOnAccent: Color = UnifiedColorSystem.Semantic.textOnAccent
    
    let success: Color = UnifiedColorSystem.Semantic.success
    let warning: Color = UnifiedColorSystem.Semantic.warning
    let error: Color = UnifiedColorSystem.Semantic.error
    let info: Color = UnifiedColorSystem.Semantic.info
    let destructive: Color = UnifiedColorSystem.Core.accentRed
    
    let cardBackground: Color = UnifiedColorSystem.Component.cardBackground
    let buttonBackground: Color = UnifiedColorSystem.Component.buttonPrimaryBackground
    let inputBackground: Color = UnifiedColorSystem.Component.inputBackground
    let divider: Color = UnifiedColorSystem.Semantic.borderDefault
    
    var primaryGradient: LinearGradient {
        UnifiedColorSystem.Gradients.primaryButtonGradient
    }
    
    var backgroundGradient: LinearGradient {
        UnifiedColorSystem.Gradients.backgroundGradient
    }
    
    var pageBackgroundGradient: LinearGradient {
        UnifiedColorSystem.Gradients.backgroundGradient
    }
    
    var onboardingBackgroundGradient: LinearGradient {
        UnifiedColorSystem.Gradients.backgroundGradient
    }
    
    var onboardingGlowColor: Color { UnifiedColorSystem.Effects.glowPrimary }
    var onboardingAccentGlowColor: Color { UnifiedColorSystem.Effects.glowSecondary }
    
    var glowGradient: RadialGradient {
        UnifiedColorSystem.Gradients.glowGradient
    }
    
    let fonts = ThemeFonts()
    let logoFont: Font = .system(size: 48, weight: .black)
    let brandTitleFont: Font = .system(size: 34, weight: .bold)
    let brandSubtitleFont: Font = .system(size: 18, weight: .semibold)
    
    let textEffectColor: Color = UnifiedColorSystem.Core.primaryBrand
    let brandSubtitleTracking: CGFloat = 1
    
    let spacing = ThemeSpacing()
    let cornerRadius: CGFloat = AppSettings.Constants.Layout.cornerRadiusMedium
    let buttonHeight: CGFloat = AppSettings.Constants.Sizing.buttonLarge
    
    let animations = ThemeAnimations()
}
