import SwiftUI
import AuthenticationServices

// MARK: - Authentication View
struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var authContainer = AuthenticationContainer.shared
    @Environment(\.theme) private var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var glowOpacity: Double = 0.3
    @State private var particleIntensity: Double = 0.0
    
    // Computed property for responsive button width
    private func buttonWidth(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        
        // More aggressive constraints for large devices
        if horizontalSizeClass == .regular {
            // iPad or large iPhone in landscape
            return min(screenWidth * 0.45, 320)
        } else {
            // iPhone - use more conservative sizing for better proportions
            let idealWidth = screenWidth * 0.85 // 85% of screen
            return min(idealWidth, 350) // Increased cap for better appearance
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
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
                
                // Subtle particle effects
                BackgroundAnimationView(
                    type: .particles,
                    isActive: true,
                    intensity: particleIntensity
                )
                .opacity(0.2)
                .blendMode(.plusLighter)
                .ignoresSafeArea()
                
                VStack(spacing: theme.spacing.xxl) {
                Spacer()
                
                // Logo and branding
                VStack(spacing: theme.spacing.xl) {
                    // Logo with flame shape (matching SplashScreen)
                    ZStack {
                        // Subtle glow layer
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 120, height: 120)
                            .blur(radius: 30)
                            .opacity(glowOpacity * 0.3)
                        
                        // Flame background
                        Image(systemName: "flame.fill")
                            .font(.system(size: 100))
                            .foregroundColor(theme.primary)
                            .opacity(0.95)
                            .shadow(color: theme.primary.opacity(0.5), radius: 10)
                            .shadow(color: theme.primary.opacity(0.3), radius: 20)
                        
                        // STY Text
                        Text("SnapHockey")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                    VStack(spacing: theme.spacing.xs) {
                        Text("CAPTURE YOUR STYLE")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(theme.primary)
                            .tracking(3)
                            .opacity(contentOpacity)
                        
                        Text("Sign in to continue")
                            .font(theme.fonts.body)
                            .foregroundColor(theme.textSecondary)
                            .opacity(contentOpacity)
                    }
                }
                
                Spacer()
                
                // Authentication options
                VStack(spacing: theme.spacing.md) {
                    // Apple Sign In - Using custom button for consistent sizing
                    Button(action: appleSignIn) {
                        HStack {
                            Image(systemName: "applelogo")
                                .font(.system(size: 20))
                            
                            Text("Sign in with Apple")
                                .font(.system(size: 17, weight: .semibold))
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: min(theme.buttonHeight, 48))
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(AppSettings.Constants.Layout.cornerRadiusMedium)
                    .shadow(color: theme.primary.opacity(0.15), radius: 4, x: 0, y: 2)
                    .clipped()
                    .opacity(contentOpacity)
                    
                    // Google Sign In
                    Button(action: googleSignIn) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20))
                            
                            Text(authContainer.content.continueWithGoogle)
                                .font(.system(size: 17, weight: .semibold))
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: min(theme.buttonHeight, 48))
                    .background(theme.surface)
                    .foregroundColor(theme.text)
                    .cornerRadius(AppSettings.Constants.Layout.cornerRadiusMedium)
                    .shadow(color: theme.primary.opacity(0.15), radius: 4, x: 0, y: 2)
                    .clipped()
                    .opacity(contentOpacity)
                    
                    // Anonymous Sign In - For testing/debugging (improved proportions)
                    Button(action: anonymousSignIn) {
                        HStack(spacing: theme.spacing.xs) {
                            Image(systemName: "person.fill.questionmark")
                                .font(.system(size: 14))
                            
                            Text("Continue as Guest")
                                .font(.system(size: 14, weight: .regular))
                                .minimumScaleFactor(0.9)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 40) // Fixed smaller height
                    }
                    .background(theme.surface.opacity(0.3))
                    .foregroundColor(theme.textSecondary.opacity(0.8))
                    .cornerRadius(AppSettings.Constants.Layout.cornerRadiusMedium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSettings.Constants.Layout.cornerRadiusMedium)
                            .stroke(theme.textSecondary.opacity(0.15), lineWidth: 0.5)
                    )
                    .opacity(contentOpacity)
                }
                .frame(maxWidth: buttonWidth(for: geometry))
                .padding(.horizontal)
                .onAppear {
                    print("🔍 AuthView - Screen width: \(geometry.size.width)")
                    print("🔍 AuthView - Button width: \(buttonWidth(for: geometry))")
                    print("🔍 AuthView - Button height: \(min(theme.buttonHeight, 48))")
                    print("🔍 AuthView - Size class: \(horizontalSizeClass == .regular ? "regular" : "compact")")
                }
                
                // Terms and Privacy
                VStack(spacing: theme.spacing.xs) {
                    Text(authContainer.content.termsText)
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.textSecondary)
                    
                    HStack(spacing: theme.spacing.md) {
                        Button("Terms of Service") {
                            // Open terms
                        }
                        .foregroundColor(theme.primary)
                        .font(theme.fonts.caption)
                        
                        Text("•")
                            .foregroundColor(theme.textSecondary)
                        
                        Button("Privacy Policy") {
                            // Open privacy
                        }
                        .foregroundColor(theme.primary)
                        .font(theme.fonts.caption)
                    }
                }
                .opacity(contentOpacity)
                .padding(.bottom, theme.spacing.xxl)
            }
            
            // Loading overlay
            if isLoading {
                theme.background.opacity(0.85)
                    .ignoresSafeArea()
                
                VStack(spacing: theme.spacing.lg) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                        .scaleEffect(1.5)
                    
                    Text("Signing in...")
                        .font(theme.fonts.body)
                        .foregroundColor(theme.text)
                }
                .padding(theme.spacing.xxl)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.cardBackground)
                        .shadow(color: theme.background.opacity(0.2), radius: 10)
                )
            }
        }
        }
        .preferredColorScheme(.dark)
        .alert(authContainer.content.genericErrorMessage, isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            animateIn()
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
            glowOpacity = 0.6
        }
        
        // Particle intensity
        withAnimation(.easeIn(duration: 1.0).delay(0.3)) {
            particleIntensity = 0.3
        }
        
        // Content fade in
        withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
            contentOpacity = 1.0
        }
        
        // Haptic feedback
        HapticManager.shared.playImpact(style: .light)
    }
    
    // MARK: - Apple Sign In
    private func appleSignIn() {
        isLoading = true
        
        Task {
            do {
                _ = try await authManager.signInWithApple()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Google Sign In
    private func googleSignIn() {
        isLoading = true
        
        Task {
            do {
                _ = try await authManager.signInWithGoogle()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Anonymous Sign In
    private func anonymousSignIn() {
        isLoading = true
        
        Task {
            do {
                _ = try await authManager.signInAnonymously()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Preview
struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}