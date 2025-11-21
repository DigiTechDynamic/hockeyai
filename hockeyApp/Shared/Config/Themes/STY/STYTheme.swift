import SwiftUI

// MARK: - STY Athletic Co. Brand Theme
// This struct now serves as a namespace for STY-specific styles
// The actual theme implementation is in STYThemeStyle.swift
// Removed deprecated sections post-audit (no usages found)
public struct STYTheme {
    
    // MARK: - Brand Colors
    // These are used by STYThemeStyle to implement the AppTheme protocol
    public struct Colors {
        // Primary Brand Colors
        public static let neonGreen = Color(hex: "#39FF14")        // Bright neon green from logo
        public static let electricGreen = Color(hex: "#00FF41")    // Alternative green
        public static let darkGreen = Color(hex: "#1B8A00")        // Darker green for depth
        
        // Base Colors
        public static let black = Color(hex: "#000000")            // Pure black
        public static let charcoal = Color(hex: "#1A1A1A")         // Dark gray/charcoal
        public static let darkGray = Color(hex: "#2D2D2D")         // Brick wall color
        public static let mediumGray = Color(hex: "#404040")       // Medium gray
        
        // Light Colors
        public static let white = Color(hex: "#FFFFFF")            // Pure white
        public static let offWhite = Color(hex: "#F5F5F5")         // Light background
        public static let lightGray = Color(hex: "#E0E0E0")        // Light gray
        
        // Accent Colors
        public static let flame = neonGreen                        // Main accent
        public static let glow = neonGreen.opacity(0.7)           // Glow effect
        public static let subtle = neonGreen.opacity(0.3)         // Subtle accent
        
        // UI Colors
        public static let background = black
        public static let surface = charcoal
        public static let cardBackground = darkGray
        public static let primaryText = white
        public static let secondaryText = Color(hex: "#B0B0B0")
        
        // Status Colors
        public static let success = neonGreen
        public static let warning = Color(hex: "#FFB800")
        public static let error = Color(hex: "#FF6B35")  // Orange (for inline errors)
        // Destructive red for cancel/destructive actions (cleaner, slightly softer than pure crimson)
        // Deeper neon red for destructive actions
        public static let destructive = Color(hex: "#FF1744")
        public static let info = Color(hex: "#00C7FF")
    }
    
    // MARK: - Typography
    public struct Typography {
        // Brand Fonts
        public static let displayFont = Font.custom("Helvetica Neue", size: 48).weight(.black)
        public static let titleFont = Font.system(size: 34, weight: .black, design: .default)
        public static let headlineFont = Font.system(size: 24, weight: .bold, design: .default)
        public static let bodyBold = Font.system(size: 17, weight: .semibold, design: .default)
        public static let body = Font.system(size: 17, weight: .regular, design: .default)
        public static let caption = Font.system(size: 13, weight: .medium, design: .default)
        
        // Special Styles
        public static let logoStyle = Font.system(size: 60, weight: .black, design: .default)
        public static let buttonText = Font.system(size: 18, weight: .bold, design: .default)
        public static let scoreDisplay = Font.system(size: 72, weight: .black, design: .rounded)
    }
    
    // MARK: - Gradients
    public struct Gradients {
        // Background gradients
        public static let darkBackground = LinearGradient(
            colors: [Color.black, Colors.charcoal],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let premiumBackground = LinearGradient(
            colors: [
                Color.black,
                Colors.charcoal.opacity(0.8),
                Color.black
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        
        // Card gradients
        public static let cardGradient = LinearGradient(
            colors: [
                Colors.darkGray,
                Colors.charcoal
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Accent gradients
        public static let neonGradient = LinearGradient(
            colors: [
                Colors.neonGreen,
                Colors.electricGreen
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        public static let glowGradient = RadialGradient(
            colors: [
                Colors.neonGreen.opacity(0.8),
                Colors.neonGreen.opacity(0.4),
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 100
        )
    }
    
    // MARK: - Layout
    // These are used by STYThemeStyle for consistent spacing
    public struct Layout {
        public static let cornerRadius: CGFloat = 12
        public static let buttonHeight: CGFloat = 56
        public static let padding: CGFloat = 20
        public static let spacing: CGFloat = 16
        public static let iconSize: CGFloat = 24
    }
    
    // MARK: - Animations
    public struct Animation {
        public static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        public static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        public static let smooth = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        public static let bounce = SwiftUI.Animation.interpolatingSpring(stiffness: 200, damping: 15)
    }
}
