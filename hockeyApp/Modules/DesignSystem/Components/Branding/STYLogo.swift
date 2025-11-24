import SwiftUI

// MARK: - STY Logo Component
struct STYLogo: View {
    @Environment(\.theme) private var theme

    enum LogoStyle {
        case compact      // Just the logo
        case withText     // Logo with STY text
        case fullBrand    // Logo with full company name
        case loading      // Animated loading version
        case imageFlame   // New: Uses Swhite.png with colored flame animation
    }

    let style: LogoStyle
    let size: CGFloat
    @State private var glowIntensity: Double = 0.4
    @State private var flameAnimation: Double = 0
    @State private var isAnimating = false

    init(style: LogoStyle = .withText, size: CGFloat = 100) {
        self.style = style
        self.size = size
    }

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Logo with flame effect
            if style == .imageFlame {
                animatedFlameLogo
            } else {
                logoWithFlame
            }

            // Additional text based on style
            if style == .withText || style == .fullBrand {
                brandingText
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Animated Flame Logo (Using Swhite.png)
    private var animatedFlameLogo: some View {
        ZStack {
            // Layer 1: Outer orange/red flame glow (largest, slowest)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.orange.opacity(0.6),
                            Color.red.opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.9
                    )
                )
                .frame(width: size * 1.8, height: size * 1.8)
                .blur(radius: 25)
                .scaleEffect(1 + flameAnimation * 0.15)
                .opacity(glowIntensity * 0.7)

            // Layer 2: Middle orange glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.6, blue: 0.0).opacity(0.8),
                            Color(red: 1.0, green: 0.3, blue: 0.0).opacity(0.5),
                            Color.clear
                        ],
                        center: .leading,
                        startRadius: 0,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size * 1.3, height: size * 1.3)
                .blur(radius: 12)
                .opacity(glowIntensity * 0.6)
                .scaleEffect(1 + sin(flameAnimation) * 0.08)
                .blendMode(.plusLighter)

            // Layer 3: Green S glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.3, green: 1.0, blue: 0.3).opacity(0.7),
                            Color(red: 0.2, green: 0.9, blue: 0.2).opacity(0.4),
                            Color.clear
                        ],
                        center: .trailing,
                        startRadius: 0,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size * 1.1, height: size * 1.1)
                .blur(radius: 10)
                .opacity(glowIntensity * 0.5)
                .scaleEffect(1 + cos(flameAnimation * 1.2) * 0.05)
                .blendMode(.plusLighter)

            // Layer 4: Base white logo (HockeyAISymbol.png)
            Image("HockeyAISymbol")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundColor(.white)
                .shadow(color: Color.white.opacity(0.4), radius: 2, x: 0, y: 0)

            // Layer 5: Orange/red overlay for flame parts (left side)
            Image("HockeyAISymbol")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.5, blue: 0.0),
                            Color(red: 1.0, green: 0.3, blue: 0.0),
                            Color(red: 0.9, green: 0.1, blue: 0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .mask(
                    // Mask to show only the left flame streaks
                    LinearGradient(
                        colors: [
                            .black,
                            .black.opacity(0.8),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: UnitPoint(x: 0.45, y: 0.5)
                    )
                )
                .blur(radius: 0.5)
                .blendMode(.overlay)

            // Layer 6: Green overlay for S letter (right side)
            Image("HockeyAISymbol")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.4, green: 1.0, blue: 0.4),
                            Color(red: 0.3, green: 0.95, blue: 0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .mask(
                    // Mask to show only the S part
                    LinearGradient(
                        colors: [
                            .clear,
                            .black.opacity(0.3),
                            .black
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .blur(radius: 0.5)
                .blendMode(.overlay)

            // Layer 7: Sharp highlight glows for depth
            Image("HockeyAISymbol")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 1.05, height: size * 1.05)
                .foregroundColor(Color.orange)
                .blur(radius: 4)
                .opacity(0.3 + flameAnimation * 0.2)
                .blendMode(.screen)

            // Layer 8: Rotating flame particles around the logo
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(
                        index % 2 == 0 ?
                        Color.orange.opacity(0.7) :
                        Color(red: 1.0, green: 0.3, blue: 0.0).opacity(0.6)
                    )
                    .frame(width: 3, height: 3)
                    .offset(
                        x: cos(flameAnimation + Double(index) * .pi / 4) * (size * 0.55),
                        y: sin(flameAnimation + Double(index) * .pi / 4) * (size * 0.55)
                    )
                    .blur(radius: 1.5)
                    .opacity(0.8)
            }
        }
    }
    
    // MARK: - Logo with Flame Effect
    private var logoWithFlame: some View {
        ZStack {
            // Outer glow layers for flame effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.2, green: 1.0, blue: 0.2).opacity(0.8),
                            Color(red: 0.1, green: 0.9, blue: 0.1).opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.2,
                        endRadius: size * 0.8
                    )
                )
                .frame(width: size * 1.8, height: size * 1.8)
                .blur(radius: 20)
                .opacity(glowIntensity * 0.6)
                .scaleEffect(1 + flameAnimation * 0.1)
            
            // Middle flame layer
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.3, green: 1.0, blue: 0.3),
                            Color(red: 0.2, green: 0.95, blue: 0.2).opacity(0.8),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.1,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 10)
                .opacity(glowIntensity * 0.5)
                .offset(y: -flameAnimation * 5)
            
            // Inner flame glow
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.4, green: 1.0, blue: 0.4),
                            Color(red: 0.2, green: 0.9, blue: 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 1.1, height: size * 1.1)
                .blur(radius: 5)
                .opacity(glowIntensity * 0.4)
            
            // Main circle background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.35, green: 1.0, blue: 0.35),
                            Color(red: 0.25, green: 0.95, blue: 0.25),
                            Color(red: 0.15, green: 0.85, blue: 0.15)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: Color(red: 0.2, green: 0.9, blue: 0.2).opacity(0.5), radius: 10, x: 0, y: 0)
            
            // STY Text
            Text("AI")
                .font(.system(size: size * 0.38, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.95)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .tracking(size * 0.01)
            
            // Animated flame particles for loading style
            if style == .loading {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(Color(red: 0.4, green: 1.0, blue: 0.4).opacity(0.6))
                        .frame(width: size * 0.05, height: size * 0.05)
                        .offset(
                            x: cos(Double(index) * .pi / 2.5 + flameAnimation * 2) * size * 0.4,
                            y: sin(Double(index) * .pi / 2.5 + flameAnimation * 2) * size * 0.4
                        )
                        .blur(radius: 2)
                }
            }
        }
    }
    
    // MARK: - Branding Text
    @ViewBuilder
    private var brandingText: some View {
        if style == .fullBrand {
            VStack(spacing: theme.spacing.xs) {
                Text("SNAPHOCKEY")
                    .font(.system(size: size * 0.28, weight: .black))
                    .foregroundColor(theme.primary)
                    .tracking(3)

                Text("CAPTURE YOUR STYLE")
                    .font(.system(size: size * 0.12, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .tracking(2)
            }
        }
    }
    
    // MARK: - Animations
    private func startAnimations() {
        if style == .imageFlame {
            // More intense, faster animations for the flame logo
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowIntensity = 0.9
            }

            // Continuous rotation for particles
            withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                flameAnimation = .pi * 2
            }
        } else if style == .loading {
            // Glow pulsing animation
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowIntensity = 0.7
            }

            // Flame movement animation
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                flameAnimation = .pi * 2
            }
        } else {
            // Standard animations
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowIntensity = 0.7
            }

            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                flameAnimation = 0.3
            }
        }

        isAnimating = true
    }
}

// MARK: - Convenience Modifiers
extension STYLogo {
    func compact() -> STYLogo {
        STYLogo(style: .compact, size: size)
    }
    
    func withFullBranding() -> STYLogo {
        STYLogo(style: .fullBrand, size: size)
    }
    
    func loading() -> STYLogo {
        STYLogo(style: .loading, size: size)
    }
}

// MARK: - Preview
#if DEBUG
struct STYLogo_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Compact
                STYLogo(style: .compact, size: 80)
                
                // With text
                STYLogo(style: .withText, size: 100)
                
                // Full brand
                STYLogo(style: .fullBrand, size: 100)
                
                // Loading animation
                STYLogo(style: .loading, size: 100)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
#endif