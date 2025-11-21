import SwiftUI

struct SoftOnboardingUpsellView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var showPaywall = false
    @State private var animateStats = false
    @State private var animateBenefits = false

    // Determine if we'll show a paywall with free trial
    private var hasFreeTrial: Bool {
        // Get the paywall that will be shown for this source
        let design = PaywallRegistry.getDesign(for: "onboarding_upsell")
        let config = MonetizationConfig.paywallConfigurations[design.id]
        return config?.showFreeTrial ?? true
    }

    // Dynamic CTA text based on paywall variant
    private var ctaText: String {
        hasFreeTrial ? "Start Free Trial" : "See Plans"
    }

    var body: some View {
        ZStack {
            // Use app's onboarding background gradient from theme (fill full screen including safe areas)
            theme.onboardingBackgroundGradient
                .ignoresSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Close button - subtle, top-right
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        HapticManager.shared.playImpact(style: .light)
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.textSecondary.opacity(0.6))
                            .frame(width: 32, height: 32)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                Spacer()
            }
            .zIndex(10)

            // Main content - ScrollView to prevent overflow
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero Section - TIGHTER spacing
                    VStack(spacing: 10) {
                        // Crown icon with glow
                        ZStack {
                            Circle()
                                .fill(theme.primary.opacity(0.15))
                                .frame(width: 60, height: 60)
                                .blur(radius: 20)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [theme.primary, theme.accent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: theme.primary.opacity(0.5), radius: 10)
                        }
                        .scaleEffect(animateStats ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateStats)

                        // Headline - Loss Aversion
                        Text("Don't Get Cut")
                            .font(theme.fonts.largeTitle)
                            .glowingHeaderText()
                            .multilineTextAlignment(.center)
                            .opacity(animateStats ? 1 : 0)
                            .offset(y: animateStats ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: animateStats)

                        // Subheadline - Social Proof
                        Text("Join 50,000+ players training smarter")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(theme.primary)
                            .multilineTextAlignment(.center)
                            .opacity(animateStats ? 1 : 0)
                            .offset(y: animateStats ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.3), value: animateStats)
                    }
                    .padding(.top, 35)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 24)

                    // Stats Cards - COMPACT
                    HStack(spacing: 12) {
                        statCard(number: "89%", label: "Make the team", icon: "trophy.fill")
                            .opacity(animateStats ? 1 : 0)
                            .offset(x: animateStats ? 0 : -30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateStats)

                        statCard(number: "23%", label: "Shot improvement", icon: "chart.line.uptrend.xyaxis")
                            .opacity(animateStats ? 1 : 0)
                            .offset(x: animateStats ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: animateStats)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 22)

                    // Benefits - REDUCED to 3 most impactful
                    VStack(alignment: .leading, spacing: 13) {
                        benefitRow(
                            icon: "exclamationmark.triangle.fill",
                            text: "Players without pro training get cut first",
                            color: Color(hex: "#FF4444"),
                            delay: 0.6
                        )

                        benefitRow(
                            icon: "clock.fill",
                            text: "Tryouts coming - you're running out of time",
                            color: Color(hex: "#FFA500"),
                            delay: 0.7
                        )

                        benefitRow(
                            icon: "checkmark.shield.fill",
                            text: "Pro tools = better form = making the team",
                            color: theme.primary,
                            delay: 0.8
                        )
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 20)

                    // What You Get - COMPACT
                    VStack(alignment: .leading, spacing: 10) {
                        Text("WHAT YOU GET:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(theme.textSecondary)
                            .tracking(1.2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)

                        VStack(spacing: 8) {
                            featureRow(icon: "sparkles", text: "2-angle AI Shot Coach")
                            featureRow(icon: "scope", text: "Shot Rater with detailed tips")
                            featureRow(icon: "hockey.puck", text: "Personalized stick recommendations")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 24)

                    // CTA Section - DYNAMIC BUTTON TEXT
                    VStack(spacing: 16) {
                        // Primary CTA - Changes based on paywall variant
                        Button(action: {
                            HapticManager.shared.playImpact(style: .medium)
                            showPaywall = true
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 18, weight: .bold))

                                Text(ctaText)
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [theme.primary, theme.primary.opacity(0.9)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )

                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        .padding(1)
                                }
                            )
                            .shadow(color: theme.primary.opacity(0.4), radius: 20, y: 10)
                        }
                        .buttonStyle(ScaleButtonStyle())

                        // Secondary option - More obvious it's tappable
                        Button(action: {
                            HapticManager.shared.playImpact(style: .light)
                            dismiss()
                        }) {
                            Text("I'll risk getting cut")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(theme.textSecondary)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 24)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.05))
                                        .overlay(
                                            Capsule()
                                                .stroke(theme.textSecondary.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                }
            }
        }
        .fullScreenCover(isPresented: $showPaywall, onDismiss: {
            // Only dismiss if user completes or genuinely cancels
            // Transaction abandonment will be handled by PaywallPresenter
            dismiss()
        }) {
            PaywallPresenter(source: "onboarding_upsell")
                .preferredColorScheme(.dark)
        }
        .onAppear {
            markSeen()
            withAnimation {
                animateStats = true
                animateBenefits = true
            }
        }
    }

    // MARK: - Stat Card (COMPACT)
    private func statCard(number: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.primary)

            Text(number)
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Benefit Row (COMPACT)
    private func benefitRow(icon: String, text: String, color: Color, delay: Double) -> some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
            }

            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .opacity(animateBenefits ? 1 : 0)
        .offset(x: animateBenefits ? 0 : -20)
        .animation(.easeOut(duration: 0.5).delay(delay), value: animateBenefits)
    }

    // MARK: - Feature Row (COMPACT)
    private func featureRow(icon: String, text: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.primary)
                .frame(width: 18)

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.text.opacity(0.9))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func markSeen() {
        UserDefaults.standard.set(false, forKey: "showSoftUpsellAfterOnboarding")
    }
}
