import SwiftUI

struct SplashScreen: View {
    @Environment(\.theme) var theme
    @EnvironmentObject var themeManager: ThemeManager
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var glowScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var particleIntensity: Double = 0.0
    @State private var textOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var dotScale1: CGFloat = 1.0
    @State private var dotScale2: CGFloat = 1.0
    @State private var dotScale3: CGFloat = 1.0
    @State private var progressRing: CGFloat = 0

    // Dynamic company name based on active theme
    private var companyName: String {
        // Check if an NHL team is selected
        if let nhlTeam = themeManager.getCurrentNHLTeam() {
            return "\(nhlTeam.city) \(nhlTeam.name)".uppercased()
        }
        // Default to Snap Hockey for STY theme
        return "SNAP HOCKEY"
    }

    var body: some View {
        ZStack {
            // Dark background with subtle gradient
            LinearGradient(
                colors: [
                    theme.background,
                    theme.background.opacity(0.95),
                    Color.black.opacity(0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Particle effects layer
            BackgroundAnimationView(
                type: .particles,
                isActive: true,
                intensity: particleIntensity
            )
            .opacity(0.4)
            .blendMode(.plusLighter)
            
            // Main content
            VStack(spacing: 0) {
                Spacer()
                
                // Logo section with enhanced effects
                ZStack {
                    // Subtle glow layer
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 120, height: 120)
                        .blur(radius: 30)
                        .opacity(glowOpacity * 0.3)
                        .scaleEffect(glowScale)

                    // Progress ring - sized to wrap around logo without overlapping text
                    Circle()
                        .trim(from: 0, to: progressRing)
                        .stroke(
                            LinearGradient(
                                colors: [theme.primary, theme.primary.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: 240, height: 240)
                        .rotationEffect(.degrees(-90))
                        .opacity(0.5)

                    // Logo - white_cropped.png with S and flames
                    // Snap Hockey Logo
                    VStack(spacing: 6) {
                        Text("Snap Hockey")
                            .font(.system(size: 50, weight: .black))
                            .italic()
                            .foregroundColor(.white)
                            .shadow(color: Color.white.opacity(0.4), radius: 8, x: 0, y: 0)
                            .shadow(color: theme.primary.opacity(0.5), radius: 16, x: 0, y: 4)

                        Text("CAPTURE YOUR STYLE")
                            .font(.system(size: 12, weight: .heavy))
                            .tracking(6)
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: theme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                }
                .frame(height: 200)
                .padding(.bottom, theme.spacing.xl)
                
                // Company name removed (integrated into logo)

                // Tagline
                Text("SHOWCASE YOUR GAME")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textSecondary.opacity(0.8))
                    .tracking(3)
                    .opacity(subtitleOpacity)
                
                Spacer()
                
                // Animated loading dots
                HStack(spacing: theme.spacing.sm) {
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotScale1)
                        .opacity(dotScale1 > 1.0 ? 1.0 : 0.7)
                    
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotScale2)
                        .opacity(dotScale2 > 1.0 ? 1.0 : 0.7)
                    
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotScale3)
                        .opacity(dotScale3 > 1.0 ? 1.0 : 0.7)
                }
                .padding(.bottom, theme.spacing.xxl * 2)
                .opacity(textOpacity)
            }
            .padding(.horizontal, theme.spacing.xl)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading Snap Hockey")
        .accessibilityHint("Please wait while the app loads")
        .onAppear {
            animateIn()
            // Haptic feedback on appear
            let hapticManager = HapticManager.shared
            hapticManager.prepareHaptics()
            hapticManager.playNotification(type: .success)
        }
    }
    
    private func animateIn() {
        // Logo entrance animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Subtle glow pulsing
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowScale = 1.1
            glowOpacity = 0.5
        }
        
        // Progress ring animation
        withAnimation(.easeInOut(duration: 2.5).delay(0.3)) {
            progressRing = 1.0
        }
        
        // Particle intensity
        withAnimation(.easeIn(duration: 1.0).delay(0.5)) {
            particleIntensity = 0.6
        }
        
        // Text animations
        withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
            textOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
            subtitleOpacity = 1.0
        }
        
        // Animate dots sequentially
        animateDots()
    }
    
    private func animateDots() {
        // Dot 1
        withAnimation(.easeInOut(duration: 0.6).delay(1.0).repeatForever(autoreverses: true)) {
            dotScale1 = 1.3
        }
        
        // Dot 2
        withAnimation(.easeInOut(duration: 0.6).delay(1.2).repeatForever(autoreverses: true)) {
            dotScale2 = 1.3
        }
        
        // Dot 3
        withAnimation(.easeInOut(duration: 0.6).delay(1.4).repeatForever(autoreverses: true)) {
            dotScale3 = 1.3
        }
    }
}


// MARK: - Splash Container
struct SplashContainer: View {
    @State private var showSplash = true
    @State private var contentOpacity: Double = 0
    @State private var splashScale: CGFloat = 1.0

    // Build content lazily so child .onAppear runs after splash hides
    private let contentBuilder: () -> AnyView

    init<Content: View>(@ViewBuilder content: @escaping () -> Content) {
        self.contentBuilder = { AnyView(content()) }
    }
    
    var body: some View {
        ZStack {
            // Main content (instantiated only after splash is gone)
            if !showSplash {
                contentBuilder()
                    .opacity(contentOpacity)
                    .scaleEffect(contentOpacity > 0 ? 1.0 : 0.95)
                    .transition(.opacity.combined(with: .scale))
            }

            // Splash screen overlay
            if showSplash {
                SplashScreen()
                    .scaleEffect(splashScale)
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
            }
        }
        // Theme is now handled by AppTheme
        .onAppear {
            // Keep splash for 3 seconds or until auth completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                // Scale up splash slightly before transitioning
                withAnimation(.easeInOut(duration: 0.3)) {
                    splashScale = 1.05
                }
                
                // Remove splash with smooth transition
                withAnimation(.easeInOut(duration: 0.6).delay(0.1)) {
                    showSplash = false
                }
                
                // Fade in main content
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                    contentOpacity = 1.0
                }
                
                // Haptic feedback on transition
                HapticManager.shared.playImpact(style: .light)
            }
        }
    }
}

// MARK: - Preview
struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
