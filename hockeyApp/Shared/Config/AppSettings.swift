import SwiftUI

// MARK: - App Settings
/// Centralized static settings, flags, and constants for the app
struct AppSettings {
    
    // MARK: - App Info
    static let appName = "Snap Hockey"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - Feature Flags
    struct Features {
        static let enableAICoaching = true
        static let enableSocialSharing = false
        static let enableOfflineMode = true
        static let enableBetaFeatures = false
        static let enableDetailedFrameAnalysis = true // Enable for debug builds to see frame-by-frame analysis
    }
    
    // MARK: - API Settings
    struct API {
        static let baseURL = "https://api.snaphockey.com"
        static let timeout: TimeInterval = 30
        static let maxRetries = 3
    }
    
    // MARK: - Analytics
    struct Analytics {
        static let enabled = true
        static let debugMode = false
        /// When true, every screen view also emits an event named after the screen
        /// (e.g., `ai_coach_flow`) in addition to the generic `screen_viewed` event.
        /// This makes it easier to build funnels by event name in Mixpanel.
        static let emitNamedScreenEvents = true
    }
    
    // MARK: - Hockey Settings
    struct Hockey {
        static let defaultRinkSize = "NHL" // NHL, International, Custom
        static let defaultPeriodLength = 20 // minutes
        static let defaultPeriodsPerGame = 3
        
        static let positions = [
            "Center",
            "Left Wing", 
            "Right Wing",
            "Left Defense",
            "Right Defense",
            "Goalie"
        ]
        
        static let skillLevels = [
            "Beginner",
            "Intermediate",
            "Advanced",
            "Elite"
        ]
    }
    
    // MARK: - Training Settings
    struct Training {
        static let defaultWorkoutDuration = 60 // minutes
        static let restBetweenDrills = 30 // seconds
        static let warmupDuration = 10 // minutes
        static let cooldownDuration = 10 // minutes
        
        static let drillCategories = [
            "Skating",
            "Shooting",
            "Passing",
            "Stickhandling",
            "Conditioning",
            "Game Situations"
        ]
    }
    
    // MARK: - UI Settings
    struct UI {
        static let animationsEnabled = true
        static let hapticFeedbackEnabled = true
        static let soundEffectsEnabled = true
        
        static let mainTabs = ["Home", "Train", "Stats", "Profile"]
    }
    
    // MARK: - Storage Keys
    struct StorageKeys {
        static let currentTheme = "current_theme"
        static let userProfile = "user_profile"
        static let onboardingCompleted = "onboarding_completed"
        static let lastSyncDate = "last_sync_date"
        static let notificationsEnabled = "notifications_enabled"
        static let defaultRestDuration = "train_default_rest_duration"
    }
    
    // MARK: - Constants (from AppSettings.Constants.swift)
    enum Constants {
        
        // MARK: - Sizing
        enum Sizing {
            // Icon sizes
            static let iconTiny: CGFloat = 16
            static let iconSmall: CGFloat = 20
            static let iconMedium: CGFloat = 32
            static let iconLarge: CGFloat = 40
            static let iconXLarge: CGFloat = 60
            static let iconHuge: CGFloat = 120
            
            // Button/Component sizes
            static let buttonSmall: CGFloat = 60
            static let buttonMedium: CGFloat = 80
            static let buttonLarge: CGFloat = 120
            
            // Common component dimensions
            static let progressBarHeight: CGFloat = 8
            static let avatarSmall: CGFloat = 40
            static let avatarMedium: CGFloat = 80
            static let avatarLarge: CGFloat = 120
            
            // Special components
            static let circularTimerSize: CGFloat = 280
            static let radarChartSize: CGFloat = 200
            static let glowCircleSize: CGFloat = 300
            
            // Minimum touch targets
            static let minimumTouchTarget: CGFloat = 44
        }
        
        // MARK: - Typography
        enum Typography {
            // Font sizes beyond theme defaults
            static let tiny: CGFloat = 10
            static let small: CGFloat = 12
            static let caption: CGFloat = 14
            static let body: CGFloat = 16
            static let headline: CGFloat = 20
            static let title: CGFloat = 24
            static let largeTitle: CGFloat = 36
            static let display: CGFloat = 40
            static let hero: CGFloat = 60
            static let giant: CGFloat = 72
        }
        
        // MARK: - Spacing
        enum Spacing {
            // Additional spacing beyond theme defaults
            static let hairline: CGFloat = 1
            static let tiny: CGFloat = 2
            static let compact: CGFloat = 6
            static let tabBarBottom: CGFloat = 100
            static let keyboardOffset: CGFloat = 20
        }
        
        // MARK: - Animation
        enum Animation {
            static let instant: Double = 0.1
            static let quick: Double = 0.2
            static let fast: Double = 0.3
            static let standard: Double = 0.4
            static let medium: Double = 0.6
            static let slow: Double = 0.8
            static let lazy: Double = 1.0
            static let glacial: Double = 2.0
            
            // Spring animation parameters
            static let springResponse: Double = 0.3
            static let springDamping: Double = 0.8
            static let springDampingBouncy: Double = 0.6
        }
        
        // MARK: - Opacity
        enum Opacity {
            static let invisible: Double = 0
            static let barelyVisible: Double = 0.05
            static let veryLight: Double = 0.1
            static let light: Double = 0.2
            static let lightMedium: Double = 0.3
            static let medium: Double = 0.5
            static let mediumHeavy: Double = 0.7
            static let heavy: Double = 0.8
            static let almostOpaque: Double = 0.9
            static let opaque: Double = 1.0
        }
        
        // MARK: - Layout
        enum Layout {
            // Corner radius
            static let cornerRadiusSmall: CGFloat = 8
            static let cornerRadiusMedium: CGFloat = 12
            static let cornerRadiusLarge: CGFloat = 16
            static let cornerRadiusXLarge: CGFloat = 24
            
            // Border/Line widths
            static let borderThin: CGFloat = 1
            static let borderMedium: CGFloat = 2
            static let borderThick: CGFloat = 3
            static let borderXThick: CGFloat = 4
            
            // Shadows
            static let shadowRadiusSmall: CGFloat = 3
            static let shadowRadiusMedium: CGFloat = 6
            static let shadowRadiusLarge: CGFloat = 10
            static let shadowRadiusXLarge: CGFloat = 12
            static let shadowRadiusHuge: CGFloat = 20
            
            // Blur
            static let blurLight: CGFloat = 10
            static let blurMedium: CGFloat = 20
            static let blurHeavy: CGFloat = 60
            static let blurXHeavy: CGFloat = 80
        }
        
        // MARK: - Timing
        enum Timing {
            // Delays
            static let debounceDelay: Double = 0.5
            static let splashScreenDuration: Double = 3.0
            static let tooltipDuration: Double = 2.0
            static let hapticDelay: Double = 0.1
            
            // Intervals
            static let timerUpdateInterval: Double = 0.01
            static let progressUpdateInterval: Double = 0.1
        }
        
        // MARK: - Media
        enum Media {
            static let videoMaxDuration: TimeInterval = 120
            static let videoQuality: UIImagePickerController.QualityType = .typeHigh
            static let imageCompressionQuality: CGFloat = 0.8
        }
        
        // MARK: - Chart/Visualization
        enum Chart {
            static let pieChartInnerRadius: CGFloat = 70
            static let chartAnimationDuration: Double = 0.8
            static let barChartBarWidth: CGFloat = 40
            static let chartCornerRadius: CGFloat = 8
            static let chartShadowRadius: CGFloat = 5
        }
        
        // MARK: - Header
        enum Header {
            static let height: CGFloat = 80
            static let avatarSize: CGFloat = 40
            static let animationDuration: Double = 0.3
            static let glowOffset: CGFloat = 200
            static let glowCircleSize: CGFloat = 400
            static let glowBlurRadius: CGFloat = 150
        }
        
        // MARK: - Components
        enum Components {
            // Quick Action Button
            static let quickActionIconSize: CGFloat = 72
            static let quickActionIconFontSize: CGFloat = 32
            static let quickActionWidth: CGFloat = 90
            static let quickActionSpacing: CGFloat = 8
            static let quickActionFontSize: CGFloat = 14
            static let quickActionScalePressed: CGFloat = 0.92
            
            // Home Stat Card
            static let statCardIconSize: CGFloat = 44
            static let statCardIconFontSize: CGFloat = 20
            static let statCardTitleSize: CGFloat = 12
            static let statCardValueSize: CGFloat = 18
            static let statCardSubtitleSize: CGFloat = 14
            static let statCardTrendSize: CGFloat = 11
            static let statCardSpacing: CGFloat = 2
            
            // General
            static let defaultOpacity: Double = 0.15
            static let surfaceOpacity: Double = 0.5
            static let glowOpacity: Double = 0.3
            static let subtleGlowOpacity: Double = 0.2
        }
        
        // MARK: - Animation Timing
        enum AnimationTiming {
            static let quickResponse: Double = 0.1
            static let buttonSpringResponse: Double = 0.2
            static let buttonSpringDamping: Double = 0.8
            static let glowAnimationShort: Double = 12
            static let glowAnimationMedium: Double = 15
            static let glowAnimationLong: Double = 20
        }
    }
}

// MARK: - Environment Extension
extension EnvironmentValues {
    var appSettings: AppSettings.Type { AppSettings.self }
}

// MARK: - Convenience Extensions
extension CGFloat {
    /// Common icon sizes
    static let iconSmall = AppSettings.Constants.Sizing.iconSmall
    static let iconMedium = AppSettings.Constants.Sizing.iconMedium
    static let iconLarge = AppSettings.Constants.Sizing.iconLarge
}

extension Double {
    /// Common animation durations
    static let animationQuick = AppSettings.Constants.Animation.quick
    static let animationStandard = AppSettings.Constants.Animation.standard
    static let animationSlow = AppSettings.Constants.Animation.slow
}

// MARK: - View Extensions
extension View {
    /// Apply standard shadow
    func standardShadow(radius: CGFloat = AppSettings.Constants.Layout.shadowRadiusMedium) -> some View {
        self.shadow(
            color: .black.opacity(AppSettings.Constants.Opacity.veryLight),
            radius: radius,
            x: 0,
            y: 2
        )
    }
    
    /// Apply standard corner radius
    func standardCornerRadius(_ radius: CGFloat = AppSettings.Constants.Layout.cornerRadiusMedium) -> some View {
        self.cornerRadius(radius)
    }
    
    /// Apply header style with consistent height and animation
    func headerStyle() -> some View {
        self
            .frame(height: AppSettings.Constants.Header.height)
            .animation(.easeInOut(duration: AppSettings.Constants.Header.animationDuration), value: AppSettings.Constants.Header.height)
    }
    
    /// Apply quick action button style
    func quickActionStyle(isPressed: Bool = false) -> some View {
        self
            .scaleEffect(isPressed ? AppSettings.Constants.Components.quickActionScalePressed : 1.0)
            .animation(.spring(response: AppSettings.Constants.AnimationTiming.buttonSpringResponse, 
                             dampingFraction: AppSettings.Constants.AnimationTiming.buttonSpringDamping), 
                      value: isPressed)
    }
    
    /// Apply component opacity
    func componentOpacity(_ opacity: Double = AppSettings.Constants.Components.defaultOpacity) -> some View {
        self.opacity(opacity)
    }
    
    /// Apply glow effect with standard values
    func glowEffect(color: Color, opacity: Double = AppSettings.Constants.Components.glowOpacity) -> some View {
        self
            .background(
                Circle()
                    .fill(color)
                    .blur(radius: AppSettings.Constants.Header.glowBlurRadius)
                    .opacity(opacity)
            )
    }
}
