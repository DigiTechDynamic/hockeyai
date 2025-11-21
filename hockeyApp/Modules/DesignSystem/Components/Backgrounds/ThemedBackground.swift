import SwiftUI

// MARK: - Themed Background (Reusable)
/// A shared, theme-aware background with subtle texture and animated glow effects.
/// Use this behind full-screen flows and standalone pages to match the app shell.
public struct ThemedBackground: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var glowOffset1: CGFloat = -200
    @State private var glowOffset2: CGFloat = 200

    public init() {}

    public var body: some View {
        ZStack {
            // Base background
            theme.background
                .ignoresSafeArea()

            // Texture / gradient layer for depth
            theme.backgroundGradient
                .ignoresSafeArea()
                .opacity(0.8)

            // Animated glow accents vary by theme
            if themeManager.getCurrentThemeId() == "sty" {
                // Subtle neon green glows
                Circle()
                    .fill(theme.primary.opacity(0.3))
                    .frame(width: theme.spacing.xxl * 8, height: theme.spacing.xxl * 8)
                    .blur(radius: theme.spacing.xxl * 2.5)
                    .offset(x: glowOffset1, y: -(theme.spacing.xxl * 2))
                    .animation(
                        Animation.easeInOut(duration: 12)
                            .repeatForever(autoreverses: true),
                        value: glowOffset1
                    )

                Circle()
                    .fill(theme.accent.opacity(0.2))
                    .frame(width: theme.spacing.xxl * 6, height: theme.spacing.xxl * 6)
                    .blur(radius: theme.spacing.xxl * 2)
                    .offset(x: glowOffset2, y: theme.spacing.xxl * 4)
                    .animation(
                        Animation.easeInOut(duration: 15)
                            .repeatForever(autoreverses: true),
                        value: glowOffset2
                    )
            } else if themeManager.getCurrentThemeId() == "quantum" {
                // Glass morphism glows
                Circle()
                    .fill(theme.primary.opacity(0.2))
                    .frame(width: theme.spacing.xxl * 10, height: theme.spacing.xxl * 10)
                    .blur(radius: theme.spacing.xxl * 3)
                    .offset(x: glowOffset1, y: 0)
                    .animation(
                        Animation.easeInOut(duration: 20)
                            .repeatForever(autoreverses: true),
                        value: glowOffset1
                    )

                Circle()
                    .fill(theme.accent.opacity(0.15))
                    .frame(width: theme.spacing.xxl * 8, height: theme.spacing.xxl * 8)
                    .blur(radius: theme.spacing.xxl * 2.5)
                    .offset(x: glowOffset2, y: theme.spacing.xxl * 2)
                    .animation(
                        Animation.easeInOut(duration: 18)
                            .repeatForever(autoreverses: true),
                        value: glowOffset2
                    )
            }
        }
        .onAppear {
            glowOffset1 = theme.spacing.xxl * 4
            glowOffset2 = -(theme.spacing.xxl * 4)
        }
    }
}

