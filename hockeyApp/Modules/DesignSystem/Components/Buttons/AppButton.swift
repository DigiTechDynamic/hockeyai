import SwiftUI
import UIKit

// MARK: - Button Style
enum AppButtonStyle {
    case primary      // Primary action with gradient
    case primaryNeon  // Primary with neon glow emphasis
    case secondary    // Secondary action with subtle styling
    case ghost        // Text only with border
    case danger       // Destructive actions
    case success      // Success/confirmation actions
    case elevated     // Glassmorphism effect
    case plain        // Minimal styling
}

// MARK: - Icon Position

// MARK: - Button Size
enum AppButtonSize {
    case small
    case medium
    case large
    
    // MARK: - Size Constants
    private enum Constants {
        static let smallHeight: CGFloat = 36
        static let mediumHeight: CGFloat = 44
        static let largeHeight: CGFloat = 56
        
        static let smallFontSize: CGFloat = 14
        static let mediumFontSize: CGFloat = 16
        static let largeFontSize: CGFloat = 18
        
        static let smallIconSize: CGFloat = 16
        static let mediumIconSize: CGFloat = 20
        static let largeIconSize: CGFloat = 24
        
        static let smallPadding: CGFloat = 16
        static let mediumPadding: CGFloat = 20
        static let largePadding: CGFloat = 24
    }
    
    var height: CGFloat {
        switch self {
        case .small: return Constants.smallHeight
        case .medium: return Constants.mediumHeight
        case .large: return Constants.largeHeight
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .small: return Constants.smallFontSize
        case .medium: return Constants.mediumFontSize
        case .large: return Constants.largeFontSize
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return Constants.smallIconSize
        case .medium: return Constants.mediumIconSize
        case .large: return Constants.largeIconSize
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return Constants.smallPadding
        case .medium: return Constants.mediumPadding
        case .large: return Constants.largePadding
        }
    }
}

// MARK: - Button Constants
private enum AppButtonConstants {
    static let gradientOpacity: Double = 0.8
    static let pressedScale: CGFloat = 0.96
    static let shadowRadius: CGFloat = 8
    static let shadowRadiusLarge: CGFloat = 12
    static let shadowRadiusXLarge: CGFloat = 15
    static let shadowOpacity: Double = 0.3
    static let borderOpacity: Double = 0.3
    static let elevatedOpacity: Double = 0.6
    static let animationDuration: Double = 0.2
}

// MARK: - AppButton
struct AppButton: View {
    @Environment(\.theme) var theme
    @State private var isPressed = false
    @State private var isPressedDown = false
    @State private var gestureLocation: CGPoint = .zero
    
    let title: String
    let action: () -> Void
    var style: AppButtonStyle = .primary
    var size: AppButtonSize = .medium
    var icon: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var fullWidth: Bool = true
    var enableSoundEffects: Bool = true
    var enableHaptics: Bool = true
    // Optional override for horizontal padding to allow compact pills in headers
    var customHorizontalPadding: CGFloat? = nil
    
    // Computed properties for styling
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            theme.primaryGradient
        case .primaryNeon:
            theme.primaryGradient
        case .secondary:
            theme.surface
        case .ghost:
            Color.clear
        case .danger:
            // Deeper neon red with pronounced depth
            LinearGradient(
                colors: [
                    AppButton.blend(theme.destructive, with: .white, by: 0.06),
                    AppButton.blend(theme.destructive, with: .black, by: 0.32)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .success:
            LinearGradient(
                colors: [theme.success, theme.success.opacity(AppButtonConstants.gradientOpacity)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .elevated:
            Color.clear
        case .plain:
            Color.clear
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .primaryNeon, .success:
            return theme.textOnPrimary
        case .danger:
            // Destructive buttons should always use high-contrast text
            return Color.white
        case .secondary:
            return theme.text
        case .ghost, .plain:
            return theme.primary
        case .elevated:
            return theme.text
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .ghost:
            return theme.primary
        case .secondary:
            return theme.divider
        case .elevated:
            return theme.divider.opacity(0.5)
        default:
            return Color.clear
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary:
            return theme.primary.opacity(0.3)
        case .primaryNeon:
            return theme.primary.opacity(0.45)
        case .elevated:
            return Color.black.opacity(0.1)
        case .danger:
            return theme.destructive.opacity(0.45)
        case .success:
            return theme.success.opacity(0.3)
        default:
            return Color.clear
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .primary, .primaryNeon, .danger, .success:
            return 8
        case .elevated:
            return 12
        default:
            return 0
        }
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled && !isLoading {
                // Play action - no sound on release, just haptic
                if enableHaptics {
                    SafeManagers.playHaptic(style: .light)
                }
                action()
            }
        }) {
            ZStack {
                // Dynamic shadow layer
                if style != .ghost && style != .plain {
                    RoundedRectangle(cornerRadius: AppSettings.Constants.Layout.cornerRadiusMedium)
                        .fill(shadowColor.opacity(0.3))
                        .blur(radius: isPressedDown ? 8 : 15)
                        .offset(y: isPressedDown ? 2 : 6)
                        .scaleEffect(isPressedDown ? 0.98 : 1.02)
                }
                
                // Background
                if style == .elevated {
                    RoundedRectangle(cornerRadius: AppSettings.Constants.Layout.cornerRadiusMedium)
                        .fill(.ultraThinMaterial)
                } else {
                    backgroundView
                        .cornerRadius(AppSettings.Constants.Layout.cornerRadiusMedium)
                }
                
                // Neon glow for destructive style
                if style == .danger {
                    RoundedRectangle(cornerRadius: AppSettings.Constants.Layout.cornerRadiusMedium)
                        .fill(theme.destructive)
                        .blur(radius: isPressedDown ? 8 : 16)
                        .opacity(isPressedDown ? 0.25 : 0.35)
                        .scaleEffect(isPressedDown ? 0.98 : 1.04)
                }

                // Neon glow for primary emphasis button (backgrounding)
                if style == .primaryNeon {
                    RoundedRectangle(cornerRadius: AppSettings.Constants.Layout.cornerRadiusMedium)
                        .fill(theme.primary)
                        .blur(radius: isPressedDown ? 8 : 18)
                        .opacity(isPressedDown ? 0.18 : 0.28)
                        .scaleEffect(isPressedDown ? 0.99 : 1.03)
                }
                
                // Content
                HStack(spacing: theme.spacing.sm) {
                    if let icon = icon, !isLoading {
                        Image(systemName: icon)
                            .font(.system(size: size.iconSize)) // Keep dynamic sizing for button icon
                            .foregroundColor(foregroundColor)
                            .rotationEffect(.degrees(isPressedDown ? -5 : 0))
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressedDown)
                    }

                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                            .scaleEffect(0.8)
                    } else {
                        let text = Text(title)
                            .font(.system(size: size.fontSize, weight: .semibold, design: .rounded))
                            .foregroundColor(foregroundColor)

                        if style == .danger {
                            text
                                // Clean glow for cancel text
                                .shadow(color: Color.white.opacity(0.85), radius: 1.5)
                                .shadow(color: Color.white.opacity(0.35), radius: 3.5)
                                .shadow(color: theme.destructive.opacity(0.35), radius: 6)
                        } else if style == .primaryNeon {
                            text
                                // Slight inner shadow/glow for neon button label
                                .shadow(color: Color.black.opacity(0.15), radius: 1)
                                .shadow(color: theme.primary.opacity(0.35), radius: 5)
                        } else {
                            text
                        }
                    }
                }
                .padding(.horizontal, customHorizontalPadding ?? size.horizontalPadding)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: size.height)
            .overlay(
                RoundedRectangle(cornerRadius: AppSettings.Constants.Layout.cornerRadiusMedium)
                    .stroke(borderColor, lineWidth: borderColor == Color.clear ? 0 : 1)
                    .opacity(isPressedDown ? 0.5 : 1.0)
            )
            // Extra polish specifically for destructive buttons
            .overlay(
                Group {
                    if style == .danger {
                        // Top highlight and subtle inner border
                        RoundedRectangle(cornerRadius: AppSettings.Constants.Layout.cornerRadiusMedium)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.white.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ), lineWidth: 0.75
                            )
                            .blendMode(.overlay)
                            .opacity(0.9)
                            .padding(0.25)
                    } else if style == .primaryNeon {
                        // Subtle top highlight for neon variant
                        RoundedRectangle(cornerRadius: AppSettings.Constants.Layout.cornerRadiusMedium)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.25), Color.white.opacity(0.06)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ), lineWidth: 0.75
                            )
                            .blendMode(.overlay)
                            .opacity(0.9)
                            .padding(0.25)
                    }
                }
            )
            .opacity(isDisabled || isLoading ? 0.6 : 1.0)
            .scaleEffect(isPressedDown ? 0.92 : (isPressed ? 0.96 : 1.0))
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressedDown)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .disabled(isDisabled || isLoading)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                // Handle press state changes with proper cleanup
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressedDown = pressing
                    isPressed = pressing
                }
                
                if pressing && !isDisabled && !isLoading {
                    // Subtle touch down feedback
                    if enableHaptics && enableSoundEffects {
                        SafeManagers.playFeedback(sound: "uiPress", haptic: .light)
                    } else if enableHaptics {
                        SafeManagers.playHaptic(style: .light)
                    } else if enableSoundEffects {
                        SafeManagers.playSound("uiPress", volume: 0.3)
                    }
                }
            },
            perform: {
                // Empty - action is handled by Button
            }
        )
        .onDisappear {
            // Clean up state when button disappears
            isPressedDown = false
            isPressed = false
        }
    }
}

// Convenience modifiers
extension AppButton {
    func buttonStyle(_ style: AppButtonStyle) -> AppButton {
        var button = self
        button.style = style
        return button
    }
    
    func buttonSize(_ size: AppButtonSize) -> AppButton {
        var button = self
        button.size = size
        return button
    }
    
    func withIcon(_ icon: String) -> AppButton {
        var button = self
        button.icon = icon
        return button
    }

    
    func loading(_ isLoading: Bool) -> AppButton {
        var button = self
        button.isLoading = isLoading
        return button
    }
    
    func disabled(_ isDisabled: Bool) -> AppButton {
        var button = self
        button.isDisabled = isDisabled
        return button
    }
    
    func fullWidth(_ fullWidth: Bool) -> AppButton {
        var button = self
        button.fullWidth = fullWidth
        return button
    }

    /// Override default horizontal padding (useful for compact header pills)
    func horizontalPadding(_ value: CGFloat) -> AppButton {
        var button = self
        button.customHorizontalPadding = value
        return button
    }
    
    func soundEffects(_ enabled: Bool) -> AppButton {
        var button = self
        button.enableSoundEffects = enabled
        return button
    }
    
    func haptics(_ enabled: Bool) -> AppButton {
        var button = self
        button.enableHaptics = enabled
        return button
    }
}

// MARK: - Local Color Utilities
extension AppButton {
    /// Blend two SwiftUI Colors using sRGB space
    static func blend(_ c1: Color, with c2: Color, by amount: Double) -> Color {
        let t = max(0.0, min(1.0, amount))

        let u1 = UIColor(c1)
        let u2 = UIColor(c2)

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        u1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        u2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let r = r1 * (1 - t) + r2 * t
        let g = g1 * (1 - t) + g2 * t
        let b = b1 * (1 - t) + b2 * t
        let a = a1 * (1 - t) + a2 * t

        return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Convenience Initializers
extension AppButton {
    // Primary button with icon
    static func primary(_ title: String, icon: String? = nil, action: @escaping () -> Void) -> AppButton {
        AppButton(title: title, action: action, style: .primary, icon: icon)
    }
    
    // Secondary button
    static func secondary(_ title: String, icon: String? = nil, action: @escaping () -> Void) -> AppButton {
        AppButton(title: title, action: action, style: .secondary, icon: icon)
    }
    
    // Ghost button
    static func ghost(_ title: String, icon: String? = nil, action: @escaping () -> Void) -> AppButton {
        AppButton(title: title, action: action, style: .ghost, icon: icon)
    }
    
    // Danger button
    static func danger(_ title: String, icon: String? = nil, action: @escaping () -> Void) -> AppButton {
        AppButton(title: title, action: action, style: .danger, icon: icon)
    }
}

// MARK: - Preview
struct AppButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Button Styles")
                .font(.headline)
            
            // Primary styles
            AppButton(title: "Primary Button", action: {})
                .buttonStyle(.primary)
            
            AppButton(title: "Primary with Icon", action: {})
                .buttonStyle(.primary)
                .withIcon("arrow.right")
            
            // Secondary
            AppButton(title: "Secondary Button", action: {})
                .buttonStyle(.secondary)
            
            // Ghost
            AppButton(title: "Ghost Button", action: {})
                .buttonStyle(.ghost)
            
            // Elevated
            AppButton(title: "Elevated Button", action: {})
                .buttonStyle(.elevated)
                .withIcon("sparkles")
            
            // Danger
            AppButton(title: "Delete", action: {})
                .buttonStyle(.danger)
                .withIcon("trash")
            
            // Success
            AppButton(title: "Confirm", action: {})
                .buttonStyle(.success)
                .withIcon("checkmark")
            
            // Loading state
            AppButton(title: "Loading...", action: {})
                .buttonStyle(.primary)
                .loading(true)
            
            // Disabled state
            AppButton(title: "Disabled", action: {})
                .buttonStyle(.primary)
                .disabled(true)
            
            // Sizes
            HStack(spacing: 10) {
                AppButton(title: "Small", action: {})
                    .buttonSize(.small)
                    .fullWidth(false)
                
                AppButton(title: "Medium", action: {})
                    .buttonSize(.medium)
                    .fullWidth(false)
                
                AppButton(title: "Large", action: {})
                    .buttonSize(.large)
                    .fullWidth(false)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
