import SwiftUI
import UIKit

struct HockeyUltraWeeklyPaywall: PaywallDesign {
    let id = "paywall_5wk_only"

    func build(products: LoadedProducts, actions: PaywallActions) -> AnyView {
        AnyView(
            HockeyUltraWeeklyPaywallContent(products: products, actions: actions)
        )
    }
}

private struct HockeyUltraWeeklyPaywallContent: View {
    let products: LoadedProducts
    let actions: PaywallActions
    @State private var pulseAnimation = false

    private let contentPadding: CGFloat = 16
    private let maxContentWidth: CGFloat = UIScreen.main.bounds.width - 32

    // Dynamic fade configuration properties
    private let fadeStartRatio: CGFloat = 0.65
    private let fadeIntensity: CGFloat = 0.95

    // ONLY weekly option - no trials, no other plans
    private let weeklyPrice = "$4.99"
    private let weeklyProductID = MonetizationConfig.ProductIDs.weeklyStandard

    // Safe area helpers
    private var safeTop: CGFloat { safeInsets.top }
    private var safeBottom: CGFloat { safeInsets.bottom }
    private var safeInsets: UIEdgeInsets {
        #if os(iOS)
        let scenes = UIApplication.shared.connectedScenes
        if let windowScene = scenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return window.safeAreaInsets
        }
        #endif
        return .zero
    }

    var body: some View {
        ZStack {
            // Background image with smooth edge blending - shifted right
            GeometryReader { geometry in
                Image("player")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width * 1.15, height: geometry.size.height)
                    .offset(x: geometry.size.width * 0.08, y: 0)
                    .clipped()
                    .mask(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .black, location: 0.0),
                                .init(color: .black, location: fadeStartRatio),
                                .init(color: .black.opacity(0.9), location: fadeStartRatio + (1 - fadeStartRatio) * 0.2),
                                .init(color: .black.opacity(0.6), location: fadeStartRatio + (1 - fadeStartRatio) * 0.5),
                                .init(color: .black.opacity(0.3), location: fadeStartRatio + (1 - fadeStartRatio) * 0.75),
                                .init(color: .clear.opacity(fadeIntensity), location: 0.98)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0),
                                Color.black.opacity(0.3)
                            ]),
                            center: .center,
                            startRadius: geometry.size.width * 0.3,
                            endRadius: geometry.size.width * 0.8
                        )
                    )

                // Dark overlay for text readability
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.8),
                        Color(hex: "#1A1A1A").opacity(0.7),
                        Color.black.opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            // Main content with proper safe area handling
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Top bar: X • STY Hockey • Restore
                    ZStack {
                        HStack {
                            closeButton
                            Spacer()
                            restoreButton
                        }

                        Text("STY Hockey")
                            .font(.system(size: 20, weight: .black))
                            .glowingHeaderText()
                    }
                    .padding(.horizontal, contentPadding)
                    .padding(.top, safeTop)
                    .padding(.bottom, 16)
                    .frame(maxWidth: geometry.size.width)

                    // Scrollable content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            Spacer(minLength: 10)

                            // Influencer social proof section
                            influencerSocialProof

                            // Main headline and benefits
                            benefits
                                .padding(.bottom, 260) // Space for 3 plan cards + CTA
                        }
                        .padding(.horizontal, contentPadding)
                        .frame(maxWidth: geometry.size.width)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 12) {
                // Single weekly option only
                weeklyPlanCard
                bigCTA

                footerLinks
                    .padding(.top, 8)
            }
            .padding(.horizontal, contentPadding)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(Color.black.opacity(0.001))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }

    private var closeButton: some View {
        Button(action: { actions.dismiss() }) {
            Image(systemName: "xmark")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white.opacity(0.85))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close paywall")
    }

    private var restoreButton: some View {
        Button(action: { Task { _ = await actions.restore() } }) {
            Text("Restore")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .frame(height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Restore purchases")
    }

    private var influencerSocialProof: some View {
        VStack(spacing: 8) {
            // Stars + rating - clean, centered
            HStack(spacing: 8) {
                HStack(spacing: 3) {
                    ForEach(0..<5) { _ in
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 20, weight: .medium))
                    }
                }

                Text("4.9")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.white)

                Text("•")
                    .foregroundColor(.white.opacity(0.4))
                    .font(.system(size: 22))
                    .fontWeight(.bold)

                Text("50,000+ players made the team")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Trophy
            HStack(spacing: 10) {
                Image(systemName: "trophy.fill")
                    .foregroundColor(Color(hex: "#FFD700"))
                    .font(.system(size: 22, weight: .medium))

                Text("#1 Hockey Training App")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Unlock-focused headline - matches Fear paywall
            VStack(alignment: .leading, spacing: 4) {
                Text("Unlock")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("Premium Access")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: "#39FF14"))
            }
            .padding(.bottom, 4)

            // Simplified benefits (works for ALL features)
            VStack(alignment: .leading, spacing: 10) {
                benefitRow(
                    icon: "lock.open.fill",
                    text: "Unlock all premium AI features",
                    color: Color(hex: "#39FF14")
                )
                benefitRow(
                    icon: "chart.bar.fill",
                    text: "Get full analysis and recommendations",
                    color: Color(hex: "#39FF14")
                )
                benefitRow(
                    icon: "arrow.up.right",
                    text: "Unlimited access to all tools",
                    color: Color(hex: "#39FF14")
                )
                benefitRow(
                    icon: "xmark.circle.fill",
                    text: "Cancel anytime • No commitment",
                    color: Color.white.opacity(0.7)
                )
            }
        }
    }

    private func benefitRow(icon: String, text: String, color: Color = Color(hex: "#39FF14")) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24, height: 24)

            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var weeklyPlanCard: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(Color(hex: "#39FF14"))
                        .font(.system(size: 14))
                    Text("INSTANT ACCESS")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(.white)
                }

                Text("WEEK")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            // Always selected (only one option)
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: "#39FF14"))
                .font(.system(size: 22))

            VStack(alignment: .trailing, spacing: 2) {
                Text(weeklyPrice)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text("per week")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(16)
        .frame(maxWidth: maxContentWidth)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    Color(hex: "#39FF14"),
                    lineWidth: 2.5
                )
                .background(Color(hex: "#2D2D2D").opacity(0.8))
        )
        .cornerRadius(12)
        .shadow(color: Color(hex: "#39FF14").opacity(0.3), radius: 12, x: 0, y: 4)
    }

    private var bigCTA: some View {
        Button(action: {
            Task {
                // Purchase weekly plan
                await actions.purchase(weeklyProductID)
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#39FF14"))
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Get Instant Access")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text("\(weeklyPrice)/week • Cancel anytime")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.7))
                }

                Spacer()
            }
            .frame(maxWidth: maxContentWidth)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: "#1A1A1A"),
                            Color(hex: "#0D0D0D")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#39FF14"),
                                    Color(hex: "#39FF14").opacity(0.6)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                }
            )
            .cornerRadius(14)
            .shadow(color: Color(hex: "#39FF14").opacity(0.3), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var footerLinks: some View {
        PaywallLegalLinks()
            .frame(maxWidth: .infinity)
    }
}
