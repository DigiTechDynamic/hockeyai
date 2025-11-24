import SwiftUI
import UIKit

struct HockeyPopularPaywall: PaywallDesign {
    let id = "paywall_50yr_trial_5wk"

    func build(products: LoadedProducts, actions: PaywallActions) -> AnyView {
        AnyView(
            HockeyPopularPaywallContent(products: products, actions: actions)
        )
    }
}

private struct HockeyPopularPaywallContent: View {
    @Environment(\.theme) var theme
    let products: LoadedProducts
    let actions: PaywallActions
    @State private var selectedPlan: PricingPlan = .annual  // Pre-select highest price option (yearly with trial)
    private let contentPadding: CGFloat = 16
    private let maxContentWidth: CGFloat = UIScreen.main.bounds.width - 32

    // Dynamic fade configuration properties
    private let fadeStartRatio: CGFloat = 0.65
    private let fadeIntensity: CGFloat = 0.95

    // Pricing options enum (WEEKLY + YEARLY ONLY - removed monthly for 2-option test)
    enum PricingPlan {
        case weekly, annual
    }

    // SIMPLIFIED: No trial toggle - Weekly has no trial, Yearly has 3-day trial (always)
    // 3-DAY TRIAL on yearly (face rater psychology - users decide within 24-48 hours)
    private let pricingData: [(plan: PricingPlan, price: String, period: String, productID: String, trialDays: Int?, badge: String?)] = [
        (.weekly, "$4.99", "week", MonetizationConfig.ProductIDs.weeklyStandard, nil, nil),
        (.annual, "$49.99", "year", MonetizationConfig.ProductIDs.yearlyStandardTrial, 3, "BEST VALUE")
    ]

    private var selectedProductID: String {
        pricingData.first(where: { $0.plan == selectedPlan })?.productID ?? MonetizationConfig.ProductIDs.yearlyStandardTrial
    }

    private var selectedPrice: String {
        pricingData.first(where: { $0.plan == selectedPlan })?.price ?? "$49.99"
    }

    private var selectedPeriod: String {
        pricingData.first(where: { $0.plan == selectedPlan })?.period ?? "year"
    }

    private var selectedTrialDays: Int? {
        pricingData.first(where: { $0.plan == selectedPlan })?.trialDays
    }

    private var hasTrial: Bool {
        selectedTrialDays != nil
    }

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

                        Text("SnapHockey")
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

                            // Social proof section
                            socialProofSection

                            benefits
                                .padding(.bottom, 260) // Space for trial toggle + 2 payment cards (not 3)
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
                pricingOptionsStack
                bigCTA

                footerLinks
                    .padding(.top, 8)
            }
            .padding(.horizontal, contentPadding)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(Color.black.opacity(0.001))
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

    private var socialProofSection: some View {
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
            // STY RATING HEADLINE - Clean and direct
            VStack(alignment: .leading, spacing: 4) {
                Text("Unlock")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .glowingHeaderText()

                Text("Premium Access")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: "#39FF14"))
            }
            .padding(.bottom, 4)

            // CLEAN BENEFITS - What they get
            VStack(alignment: .leading, spacing: 10) {
                benefitRow(icon: "lock.open.fill", text: "Unlock all premium AI features", color: Color(hex: "#39FF14"))
                benefitRow(icon: "chart.bar.fill", text: "Get full analysis and recommendations", color: Color(hex: "#39FF14"))
                benefitRow(icon: "arrow.up.right", text: "Unlimited access to all tools", color: Color(hex: "#39FF14"))
                benefitRow(icon: "xmark.circle.fill", text: "Cancel anytime • No commitment", color: Color.white.opacity(0.7))
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

    // "Free Trial Enabled!" banner
    private var trialEnabledBanner: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Free Trial Enabled!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Text("$0.00 due today")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    Text("Free")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "#39FF14"))
                }
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "#39FF14"))
        }
        .padding(16)
        .frame(maxWidth: maxContentWidth)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "#39FF14"), Color(hex: "#39FF14").opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#39FF14").opacity(0.15), Color(hex: "#39FF14").opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .cornerRadius(16)
    }

    private var pricingOptionsStack: some View {
        VStack(spacing: 8) {
            ForEach(pricingData, id: \.plan) { option in
                pricingCard(
                    plan: option.plan,
                    price: option.price,
                    period: option.period,
                    trialDays: option.trialDays,
                    badge: option.badge,
                    isSelected: selectedPlan == option.plan
                )
            }
        }
    }

    private func pricingCard(plan: PricingPlan, price: String, period: String, trialDays: Int?, badge: String?, isSelected: Bool) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPlan = plan
            }
        }) {
            ZStack(alignment: .topTrailing) {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(period.uppercased() + " ACCESS")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(.white)

                        if let trialDays = trialDays {
                            // Show trial info prominently
                            HStack(spacing: 4) {
                                Text("\(trialDays)-DAYS FREE TRIAL")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color(hex: "#39FF14"))
                            }
                            Text("Then \(price) / \(period)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        } else {
                            Text("Just \(price) per \(period)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                    .frame(minHeight: 36, alignment: .leading)

                    Spacer()

                    // Selection indicator - fixed width to prevent shift
                    ZStack {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "#39FF14"))
                                .font(.system(size: 18))
                                .transition(.scale)
                        }
                    }
                    .frame(width: 24) // ✅ Smaller checkmark area

                    VStack(alignment: .trailing, spacing: 1) {
                        if let trialDays = trialDays {
                            Text("$0.00")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(hex: "#39FF14"))
                            Text("today")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            Text(price)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Text("per \(period)")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .frame(minWidth: 70, alignment: .trailing)
                }
                .padding(10)
                .frame(maxWidth: maxContentWidth, minHeight: 58)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? Color(hex: "#39FF14") : Color.white.opacity(0.3),
                            lineWidth: isSelected ? 2.5 : 1.5
                        )
                        .background(Color(hex: "#2D2D2D").opacity(isSelected ? 0.8 : 0.5))
                )
                .cornerRadius(12)
                .shadow(color: isSelected ? Color(hex: "#39FF14").opacity(0.3) : Color.clear, radius: 12, x: 0, y: 4)

                // Badge (for monthly/annual)
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(badge.contains("POPULAR") ? Color(hex: "#39FF14") : Color.yellow))
                        .offset(x: -10, y: -8)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var bigCTA: some View {
        Button(action: {
            Task {
                await actions.purchase(selectedProductID)
            }
        }) {
            VStack(spacing: 0) {
                if hasTrial {
                    // Trial CTA - "Try for $0.00"
                    Text("Try for $0.00")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: maxContentWidth)
                        .padding(.vertical, 18)
                } else {
                    // No trial CTA - "Secure Your Spot Now"
                    HStack(spacing: 10) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "#39FF14"))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Secure Your Spot Now")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)

                            Text("\(selectedPrice)/\(selectedPeriod) • Don't get cut")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.7))
                        }

                        Spacer()
                    }
                    .frame(maxWidth: maxContentWidth)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .background(
                ZStack {
                    // ✅ Always use dark background (consistent with brand)
                    LinearGradient(
                        colors: [
                            Color(hex: "#1A1A1A"),
                            Color(hex: "#0D0D0D")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // ✅ Green border matches brand color
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
            .shadow(color: Color(hex: "#39FF14").opacity(0.3), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var footerLinks: some View {
        PaywallLegalLinks()
            .frame(maxWidth: .infinity)
    }
}
