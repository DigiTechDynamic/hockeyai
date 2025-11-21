import SwiftUI
import UIKit

// MARK: - Color Adaptation System
// Ensures NHL team colors meet accessibility standards while maintaining team identity

struct ColorAdaptation {
    
    // MARK: - WCAG Contrast Requirements
    private static let minContrastNormalText: Double = 4.5
    private static let minContrastLargeText: Double = 3.0
    private static let minContrastUI: Double = 3.0
    
    // MARK: - Adaptation Methods
    
    /// Adapts a color for use on dark backgrounds while maintaining its identity
    static func adaptForDarkMode(_ color: Color, minimumLuminance: Double = 0.4) -> Color {
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // If color is too dark, increase brightness
        if brightness < minimumLuminance {
            brightness = min(brightness + 0.3, 0.9)
            // Reduce saturation slightly for very bright colors to avoid harshness
            if brightness > 0.7 {
                saturation = saturation * 0.85
            }
        }
        
        // For very saturated colors, reduce saturation on dark backgrounds
        if saturation > 0.8 {
            saturation = saturation * 0.75
        }
        
        return Color(hue: Double(hue), saturation: Double(saturation), brightness: Double(brightness))
    }
    
    /// Ensures sufficient contrast between two colors
    static func ensureContrast(foreground: Color, background: Color, minRatio: Double = 4.5) -> Color {
        let currentRatio = contrastRatio(between: foreground, and: background)
        
        if currentRatio >= minRatio {
            return foreground
        }
        
        // Adjust the foreground color to meet contrast requirements
        let bgLuminance = relativeLuminance(of: background)
        let isLightBackground = bgLuminance > 0.5
        
        return adjustColorForContrast(
            foreground,
            against: background,
            targetRatio: minRatio,
            lighten: !isLightBackground
        )
    }
    
    /// Calculates contrast ratio between two colors (WCAG formula)
    static func contrastRatio(between color1: Color, and color2: Color) -> Double {
        let l1 = relativeLuminance(of: color1)
        let l2 = relativeLuminance(of: color2)
        
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// Calculates relative luminance (WCAG formula)
    private static func relativeLuminance(of color: Color) -> Double {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Apply gamma correction
        func adjust(_ component: CGFloat) -> Double {
            let c = Double(component)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        
        let r = adjust(red)
        let g = adjust(green)
        let b = adjust(blue)
        
        // Calculate luminance
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    
    /// Adjusts a color to meet target contrast ratio
    private static func adjustColorForContrast(
        _ color: Color,
        against background: Color,
        targetRatio: Double,
        lighten: Bool
    ) -> Color {
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // Iteratively adjust brightness until contrast requirement is met
        let step: CGFloat = 0.05
        let maxIterations = 20
        
        for _ in 0..<maxIterations {
            let testColor = Color(hue: Double(hue), saturation: Double(saturation), brightness: Double(brightness))
            let ratio = contrastRatio(between: testColor, and: background)
            
            if ratio >= targetRatio {
                return testColor
            }
            
            if lighten {
                brightness = min(brightness + step, 1.0)
                // Reduce saturation as we approach white
                if brightness > 0.8 {
                    saturation = max(saturation * 0.9, 0.1)
                }
            } else {
                brightness = max(brightness - step, 0.1)
                // Increase saturation slightly for very dark colors
                if brightness < 0.3 {
                    saturation = min(saturation * 1.1, 0.9)
                }
            }
        }
        
        return Color(hue: Double(hue), saturation: Double(saturation), brightness: Double(brightness))
    }
    
    // MARK: - Team Color Specific Adjustments
    
    /// Creates a balanced color palette from team colors
    static func createAdaptiveTheme(
        primary: Color,
        secondary: Color,
        accent: Color? = nil,
        useDarkBackground: Bool = true
    ) -> AdaptedColorSet {
        
        let background = useDarkBackground ? 
            Color(hex: "#0D1117") :  // Soft black (better than pure black)
            Color(hex: "#FFFFFF")
        
        let surface = useDarkBackground ?
            Color(hex: "#1A1F2E") :  // Slightly lighter than background
            Color(hex: "#F8F9FA")
        
        // Adapt primary color for the background
        let adaptedPrimary = useDarkBackground ?
            adaptForDarkMode(primary) :
            ensureContrast(foreground: primary, background: background)
        
        // Ensure secondary has good contrast
        let adaptedSecondary = ensureContrast(
            foreground: secondary,
            background: background,
            minRatio: 3.0  // Lower ratio for secondary elements
        )
        
        // Create accent if not provided
        let adaptedAccent = accent.map { color in
            ensureContrast(foreground: color, background: background, minRatio: 3.0)
        } ?? adaptedPrimary.opacity(0.8)
        
        // Generate text colors with guaranteed contrast
        let textPrimary = useDarkBackground ?
            Color(hex: "#FFFFFF") :
            Color(hex: "#1A1A1A")
        
        let textSecondary = useDarkBackground ?
            Color(hex: "#A8B2C7") :
            Color(hex: "#6B7280")
        
        // Ensure text on team colors is readable
        let textOnPrimary = ensureContrast(
            foreground: Color.white,
            background: adaptedPrimary,
            minRatio: 4.5
        )
        
        let textOnSecondary = ensureContrast(
            foreground: Color.white,
            background: adaptedSecondary,
            minRatio: 4.5
        )
        
        return AdaptedColorSet(
            primary: adaptedPrimary,
            secondary: adaptedSecondary,
            accent: adaptedAccent,
            background: background,
            surface: surface,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textOnPrimary: textOnPrimary,
            textOnSecondary: textOnSecondary
        )
    }
}

// MARK: - Adapted Color Set
struct AdaptedColorSet {
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: Color
    let surface: Color
    let textPrimary: Color
    let textSecondary: Color
    let textOnPrimary: Color
    let textOnSecondary: Color
    
    /// Creates gradients from adapted colors
    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [
                primary,
                primary.opacity(0.8),
                primary.opacity(0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                background,
                surface
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Creates a subtle team-colored glow effect
    var teamGlow: RadialGradient {
        RadialGradient(
            colors: [
                primary.opacity(0.3),
                primary.opacity(0.1),
                Color.clear
            ],
            center: .center,
            startRadius: 50,
            endRadius: 200
        )
    }
}

// Color+Hex extension is already defined in Color+Hex.swift
// No need to redefine it here