import SwiftUI

// MARK: - Hockey App Shell View
struct HockeyAppShellView<Header: View, Tabs: View, Content: View, Bottom: View>: View {
    let header: Header
    let tabs: Tabs
    let content: Content
    let bottom: Bottom
    
    @Environment(\.theme) var theme
    @EnvironmentObject var themeManager: ThemeManager
    @State private var glowOffset1: CGFloat = -200
    @State private var glowOffset2: CGFloat = 200
    
    var body: some View {
        ZStack {
            // Background with animated glow effects
            backgroundWithGlowEffects
            
            VStack(spacing: 0) {
                header
                    .background(Color.clear)
                
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                bottom
                    .background(Color.clear)
            }
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.dark)
    }
    
    private var backgroundWithGlowEffects: some View {
        ZStack {
            // Theme-aware background
            theme.background
                .ignoresSafeArea()
            
            // Theme-aware texture overlay for depth
            theme.backgroundGradient
                .ignoresSafeArea()
                .opacity(0.8)
            
            // Theme-specific glow effects based on current theme ID
            if themeManager.getCurrentThemeId() == "sty" {
                // STY theme glow effects - subtle neon green glows
                Circle()
                    .fill(theme.primary.opacity(0.3))
                    .frame(width: theme.spacing.xxl * 8, height: theme.spacing.xxl * 8) // 400
                    .blur(radius: theme.spacing.xxl * 2.5) // 120
                    .offset(x: glowOffset1, y: -(theme.spacing.xxl * 2)) // -100
                    .animation(
                        Animation.easeInOut(duration: 12)
                            .repeatForever(autoreverses: true),
                        value: glowOffset1
                    )
                
                Circle()
                    .fill(theme.accent.opacity(0.2))
                    .frame(width: theme.spacing.xxl * 6, height: theme.spacing.xxl * 6) // 300
                    .blur(radius: theme.spacing.xxl * 2) // 100
                    .offset(x: glowOffset2, y: theme.spacing.xxl * 4) // 200
                    .animation(
                        Animation.easeInOut(duration: 15)
                            .repeatForever(autoreverses: true),
                        value: glowOffset2
                    )
            } else if themeManager.getCurrentThemeId() == "quantum" {
                // Quantum theme glow effects - glass morphism effects
                Circle()
                    .fill(theme.primary.opacity(0.2))
                    .frame(width: theme.spacing.xxl * 10, height: theme.spacing.xxl * 10) // 500
                    .blur(radius: theme.spacing.xxl * 3) // 150
                    .offset(x: glowOffset1, y: 0)
                    .animation(
                        Animation.easeInOut(duration: 20)
                            .repeatForever(autoreverses: true),
                        value: glowOffset1
                    )
                
                Circle()
                    .fill(theme.accent.opacity(0.15))
                    .frame(width: theme.spacing.xxl * 8, height: theme.spacing.xxl * 8) // 400
                    .blur(radius: theme.spacing.xxl * 2.5) // 120
                    .offset(x: glowOffset2, y: theme.spacing.xxl * 2) // 100
                    .animation(
                        Animation.easeInOut(duration: 18)
                            .repeatForever(autoreverses: true),
                        value: glowOffset2
                    )
            }
        }
        .onAppear {
            glowOffset1 = theme.spacing.xxl * 4 // 200
            glowOffset2 = -(theme.spacing.xxl * 4) // -200
        }
    }
}