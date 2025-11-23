import SwiftUI

// MARK: - Minimal Floating Header
// Modern floating profile button that appears/disappears on scroll
struct MinimalFloatingHeader: View {
    @Environment(\.theme) var theme
    @StateObject private var monetization = MonetizationManager.shared
    let profileImage: UIImage?
    let userInitials: String
    let onProfileTap: () -> Void
    let isVisible: Bool
    let pageTitle: String
    // Pro CTA
    let showProCTA: Bool
    let proCTALabel: String?
    let proCTAMode: HeaderProCTAMode
    let onProCTATap: (() -> Void)?

    @State private var glowIntensity: CGFloat = 0.6
    @State private var shimmerTimer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            // Header with integrated background that extends into safe area
            HStack {
                // App name
                Text("Snap Hockey")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0.9)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.white.opacity(0.3), radius: 0, x: 0, y: 0)
                    .shadow(color: Color.white.opacity(0.2), radius: 4, x: 0, y: 0)
                    .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 2)
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.9)
                .animation(.easeInOut(duration: 0.2), value: isVisible)
                
                Spacer()

                // Optional Go Pro CTA (non-premium only), placed before avatar
                if showProCTA && !monetization.isPremium {
                    HeaderProCTA(
                        label: proCTALabel ?? "Go Pro",
                        mode: proCTAMode,
                        isLoading: false,
                        onTap: { onProCTATap?() }
                    )
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.9)
                    .animation(.easeInOut(duration: 0.2), value: isVisible)
                }

                Button(action: onProfileTap) {
                    ZStack {
                        // Glass effect background
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        theme.primary.opacity(0.15),
                                        theme.primary.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 42, height: 42)
                            .overlay(
                                Circle()
                                    .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: theme.primary.opacity(0.2), radius: 8, x: 0, y: 2)
                        
                        // Profile image or icon placeholder
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 38, height: 38)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(theme.primary)
                        }

                        // Crown badge (top-right) for Pro users
                        if monetization.isPremium {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                    )
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Color.yellow)
                            }
                            .offset(x: 16, y: -16)
                        }
                    }
                }
                .scaleEffect(isVisible ? 1 : 0.7)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: isVisible)
            }
            .padding(.horizontal, 20)
            // Remove extra spacing so header aligns flush with safe area
            .padding(.top, 0)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Glass morphism background
                    Rectangle()
                        .fill(.ultraThinMaterial)
                    
                    // Gradient overlay
                    LinearGradient(
                        colors: [
                            theme.surface.opacity(0.9),
                            theme.background.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea(edges: .top) // Extend background into safe area
            )
            
            // Subtle separator line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0),
                            theme.primary.opacity(0.3),
                            theme.primary.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .allowsHitTesting(isVisible)
    }

    // MARK: - Shimmer Effect
    private func startShimmerEffect() {
        // Shimmer every 4-6 seconds randomly
        shimmerTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 4...6), repeats: true) { _ in
            // Quick shimmer animation
            withAnimation(.easeInOut(duration: 0.4)) {
                glowIntensity = 1.0
            }

            // Return to normal after shimmer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    glowIntensity = 0.6
                }
            }
        }
    }
}

// MARK: - Legacy Header (kept for compatibility)
// This is the old header, keeping it for backward compatibility
struct GamifiedHeader: View {
    @Environment(\.theme) var theme
    let userName: String
    let profileImage: UIImage?
    let userInitials: String
    let onProfileTap: () -> Void
    let xp: Int  // Not used
    let level: Int  // Not used
    let progress: CGFloat  // Not used
    
    var body: some View {
        EmptyView()  // Return empty view - we're using floating header now
    }
}

// MARK: - Helper Components
// ProfileButton with proper visual sizing
struct ProfileButton: View {
    @Environment(\.theme) var theme
    let profileImage: UIImage?
    let userInitials: String
    let size: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Invisible expanded tap area (44x44 minimum)
                Color.clear
                    .frame(width: max(44, size), height: max(44, size))
                
                // Visual profile circle
                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(theme.divider.opacity(0.15), lineWidth: 0.5)
                        )
                } else {
                    Circle()
                        .fill(theme.surface)
                        .frame(width: size, height: size)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: size * 0.5, weight: .medium))
                                .foregroundColor(theme.primary)
                        )
                        .overlay(
                            Circle()
                                .stroke(theme.divider.opacity(0.15), lineWidth: 0.5)
                        )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())  // Expanded tap area
    }
}
