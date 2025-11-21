import SwiftUI

// MARK: - Card Selector View
struct DualFeatureCardSelector: View {
    @Environment(\.theme) var theme
    @State private var selectedIndex = 0
    @State private var showingStyCheck = false
    @State private var showingShotRater = false

    let cardOptions = [
        "Split with Divider",
        "Hero + Secondary",
        "Dual Stacked Buttons",
        "Image Background",
        "Compact Minimal"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Choose Your Card Style")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(theme.text)

                Text("Scroll to preview • Tap to select")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.top, 60)
            .padding(.bottom, 20)

            // Card carousel
            TabView(selection: $selectedIndex) {
                DualFeatureCard_Option1(
                    onStyCheckTap: { showingStyCheck = true },
                    onShotRaterTap: { showingShotRater = true }
                )
                .tag(0)

                DualFeatureCard_Option2(
                    onStyCheckTap: { showingStyCheck = true },
                    onShotRaterTap: { showingShotRater = true }
                )
                .tag(1)

                DualFeatureCard_Option3(
                    onStyCheckTap: { showingStyCheck = true },
                    onShotRaterTap: { showingShotRater = true }
                )
                .tag(2)

                DualFeatureCard_Option4(
                    onStyCheckTap: { showingStyCheck = true },
                    onShotRaterTap: { showingShotRater = true }
                )
                .tag(3)

                DualFeatureCard_Option5(
                    onStyCheckTap: { showingStyCheck = true },
                    onShotRaterTap: { showingShotRater = true }
                )
                .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 280)

            // Current option label
            Text(cardOptions[selectedIndex])
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.primary)
                .padding(.top, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
        .fullScreenCover(isPresented: $showingStyCheck) {
            PlayerRaterFlowView(context: .homeScreen) { _ in
                showingStyCheck = false
            }
        }
        .fullScreenCover(isPresented: $showingShotRater) {
            SkillCheckView()
        }
    }
}

// MARK: - Option 1: Split Card with Glowing Divider
struct DualFeatureCard_Option1: View {
    @Environment(\.theme) var theme
    @StateObject private var monetization = MonetizationManager.shared
    @State private var isPressedTop = false
    @State private var isPressedBottom = false
    @State private var dividerGlow: CGFloat = 0.6

    let onStyCheckTap: () -> Void
    let onShotRaterTap: () -> Void

    

    var body: some View {
        VStack(spacing: 0) {
            // TOP: STY CHECK (FREE)
            Button(action: onStyCheckTap) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("STY CHECK")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            // FREE badge
                            Text("FREE")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(theme.primary))
                                .shadow(color: theme.primary.opacity(0.4), radius: 4, y: 2)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                                .foregroundColor(theme.primary)
                            Text("Rate Your Gear")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                    Spacer()
                    // Compact CTA
                    Text("Start →")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(isPressedTop ? theme.primary.opacity(0.08) : Color.clear)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isPressedTop ? 0.98 : 1.0)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                isPressedTop = pressing
            }, perform: {})

            // DIVIDER: Glowing neon line
            Rectangle()
                .fill(theme.primary)
                .frame(height: 2)
                .shadow(color: theme.primary.opacity(dividerGlow), radius: 8, y: 0)
                .shadow(color: theme.primary.opacity(dividerGlow * 0.5), radius: 16, y: 0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        dividerGlow = 0.8
                    }
                }

            // BOTTOM: SHOT RATER (PRO)
            Button(action: onShotRaterTap) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("SHOT RATER")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            if !monetization.isPremium {
                                ProChip()
                            }
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "target")
                                .font(.system(size: 16))
                                .foregroundColor(theme.primary)
                            Text("Analyze Any Hockey Skill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                    Spacer()
                    // Compact CTA
                    Text(monetization.isPremium ? "Analyze →" : "Unlock →")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(isPressedBottom ? theme.primary.opacity(0.06) : Color.clear)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isPressedBottom ? 0.98 : 1.0)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                isPressedBottom = pressing
            }, perform: {})
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [
                            theme.surface.opacity(0.9),
                            theme.surface.opacity(0.75)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.6),
                            theme.accent.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: theme.primary.opacity(0.2), radius: 12, x: 0, y: 4)
        .frame(height: 195)
        .padding(.horizontal, 20)
    }
}

// MARK: - Option 2: Hero + Secondary Layout
struct DualFeatureCard_Option2: View {
    @Environment(\.theme) var theme
    @StateObject private var monetization = MonetizationManager.shared
    @State private var isPressed = false

    let onStyCheckTap: () -> Void
    let onShotRaterTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // HERO: STY CHECK (135pt)
            Button(action: onStyCheckTap) {
                VStack(spacing: 12) {
                    // Player image placeholder
                    ZStack {
                        LinearGradient(
                            colors: [
                                theme.primary.opacity(0.2),
                                theme.accent.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Image(systemName: "figure.hockey")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .frame(height: 70)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    HStack {
                        Text("STY CHECK")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("FREE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(theme.primary))
                    }
                    .padding(.horizontal, 16)

                    Text("Rate your gear & style")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)

                    Text("TRY IT NOW →")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(theme.primary)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Divider
            Rectangle()
                .fill(theme.divider.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 16)

            // SECONDARY: SHOT RATER (65pt)
            Button(action: onShotRaterTap) {
                HStack(spacing: 10) {
                    Image(systemName: "target")
                        .font(.system(size: 20))
                        .foregroundColor(theme.primary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Skill Check")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Analyze any hockey skill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }

                    Spacer()

                    if !monetization.isPremium {
                        ProChip()
                    }

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [
                            theme.surface.opacity(0.9),
                            theme.surface.opacity(0.75)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.primary.opacity(0.5), lineWidth: 2)
        )
        .shadow(color: theme.primary.opacity(0.2), radius: 12, x: 0, y: 4)
        .frame(height: 220)
        .padding(.horizontal, 20)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
}

// MARK: - Option 3: Unified Gradient with Dual Stacked Buttons
struct DualFeatureCard_Option3: View {
    @Environment(\.theme) var theme
    @StateObject private var monetization = MonetizationManager.shared
    @State private var isPressedSty = false
    @State private var isPressedShot = false

    let onStyCheckTap: () -> Void
    let onShotRaterTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // HEADER: "GET RATED" with exact glow effect from screenshot
            VStack(alignment: .leading, spacing: 4) {
                Text("GET RATED")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.3), radius: 0, x: 0, y: 0)
                    .shadow(color: .white.opacity(0.25), radius: 2, x: 0, y: 0)
                    .shadow(color: .white.opacity(0.2), radius: 4, x: 0, y: 0)
                    .shadow(color: .white.opacity(0.15), radius: 8, x: 0, y: 0)
                    .shadow(color: theme.primary.opacity(0.2), radius: 12, x: 0, y: 2)

                Text("AI-powered analysis for your game")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // STY CHECK Button - White prominent style matching "Start This Workout"
            Button(action: onStyCheckTap) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Start STY Check")
                        .font(.system(size: 17, weight: .bold))

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white)
                )
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
                .overlay(alignment: .topTrailing) {
                    // FREE badge floating on top-right
                    Text("FREE")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(theme.primary)
                        )
                        .shadow(color: theme.primary.opacity(0.4), radius: 4, x: 0, y: 2)
                        .offset(x: -12, y: -8)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isPressedSty ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressedSty)
            .padding(.horizontal, 20)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                isPressedSty = pressing
            }, perform: {})

            // SHOT RATER Button - Green outlined style matching "Get My Ranking"
            Button(action: onShotRaterTap) {
                HStack(spacing: 10) {
                    if !monetization.isPremium {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 13, weight: .bold))
                    }

                    Text("Get Skill Rating")
                        .font(.system(size: 17, weight: .bold))

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(theme.primary)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.black.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(theme.primary, lineWidth: 1.2)
                )
                .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isPressedShot ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressedShot)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                isPressedShot = pressing
            }, perform: {})
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.surface.opacity(0.85),
                                    theme.surface.opacity(0.75)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.7),
                            theme.primary.opacity(0.5),
                            theme.accent.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
        )
        .shadow(color: theme.primary.opacity(0.15), radius: 12, x: 0, y: 4)
        .shadow(color: theme.primary.opacity(0.25), radius: 20, x: 0, y: 8)
        .frame(height: 230)
        .padding(.horizontal, 20)
    }
}

// MARK: - Option 4: Image Background with Overlaid CTAs (Featured Green Machine Style)
struct DualFeatureCard_Option4: View {
    @Environment(\.theme) var theme
    @StateObject private var monetization = MonetizationManager.shared
    @State private var isPressedLeft = false
    @State private var isPressedRight = false

    let onStyCheckTap: () -> Void
    let onShotRaterTap: () -> Void

    // Background layer extracted for type-check performance
    @ViewBuilder
    private var backgroundLayer: some View {
        ZStack {
            GeometryReader { proxy in
                Image("shotting")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .offset(y: 30) // Move image down to show player's head
                    .clipped()
            }
            LinearGradient(
                colors: [
                    Color.black.opacity(0.1),
                    Color.black.opacity(0.5),
                    Color.black.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            theme.primary.opacity(0.12)
                .blendMode(.overlay)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            backgroundLayer

            VStack(spacing: 0) {
                titleHeader

                Spacer()

                // DUAL GLASSMORPHIC CTAs at bottom (split 50/50)
                cardsRow
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.8),
                            theme.accent.opacity(0.5),
                            theme.primary.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .shadow(color: theme.primary.opacity(0.3), radius: 4, x: 0, y: 0)
        )
        .shadow(color: theme.primary.opacity(0.3), radius: 20, x: 0, y: 8)
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 20)
    }

    // MARK: - Helper Views
    private var titleHeader: some View {
        VStack(spacing: 6) {
            Text("GET RATED")
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .white.opacity(0.5), radius: 0)
                .shadow(color: .white.opacity(0.3), radius: 4)
                .shadow(color: .white.opacity(0.2), radius: 8)
                .shadow(color: theme.primary.opacity(0.4), radius: 12, x: 0, y: 2)

            Text("AI-powered hockey analysis")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
        }
        .padding(.top, 16)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private var cardsRow: some View {
        HStack(spacing: 8) {
            leftCard
            rightCard
        }
        .frame(height: 122)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private var leftCard: some View {
        Button(action: onStyCheckTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("STY CHECK")
                        .font(.system(size: 20, weight: .black))
                        .glowingHeaderText()
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .layoutPriority(1)
                    Spacer(minLength: 4)
                }
                .padding(.trailing, 28)

                Text("Get your hockey style rating")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(glassCardBackground(cornerRadius: 14))
            .overlay(glassCardStroke(cornerRadius: 14))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: theme.primary.opacity(0.22), radius: 7, x: 0, y: 0)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressedLeft ? 0.96 : 1.0)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressedLeft = pressing
        }, perform: {})
    }

    private var rightCard: some View {
        Button(action: onShotRaterTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("SKILL CHECK")
                        .font(.system(size: 20, weight: .black))
                        .glowingHeaderText()
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .layoutPriority(1)
                    Spacer(minLength: 4)
                }
                .padding(.trailing, 28)

                Text("Get AI feedback on any hockey skill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(glassCardBackground(cornerRadius: 14))
            .overlay(glassCardStroke(cornerRadius: 14))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: theme.primary.opacity(0.22), radius: 7, x: 0, y: 0)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressedRight ? 0.96 : 1.0)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressedRight = pressing
        }, perform: {})
    }

    private func glassCardBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }

    private func glassCardStroke(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        theme.primary.opacity(0.7),
                        theme.primary.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
    }
}

// MARK: - Option 5: Minimal Compact Design
struct DualFeatureCard_Option5: View {
    @Environment(\.theme) var theme
    @StateObject private var monetization = MonetizationManager.shared
    @State private var isPressedLeft = false
    @State private var isPressedRight = false

    let onStyCheckTap: () -> Void
    let onShotRaterTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Compact header with glow
            Text("GET RATED")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .white.opacity(0.4), radius: 0)
                .shadow(color: .white.opacity(0.2), radius: 3)
                .shadow(color: theme.primary.opacity(0.3), radius: 6, y: 1)
                .padding(.top, 12)
                .padding(.bottom, 14)

            HStack(spacing: 0) {
                // LEFT: STY CHECK
                Button(action: onStyCheckTap) {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(theme.primary)
                            .shadow(color: theme.primary.opacity(0.3), radius: 4)

                        VStack(spacing: 2) {
                            Text("STY CHECK")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.white)
                                .tracking(0.5)
                            Text("Gear Rating")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }

                        Spacer()

                        // FREE badge - hide when premium
                        if !monetization.isPremium {
                            Text("FREE")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(theme.primary))
                                .shadow(color: theme.primary.opacity(0.4), radius: 3, y: 1)
                        }

                        // Text-only CTA
                        HStack(spacing: 4) {
                            Text("Start Scan")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(theme.primary)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(theme.primary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(isPressedLeft ? theme.primary.opacity(0.05) : Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isPressedLeft ? 0.98 : 1.0)
                .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                    isPressedLeft = pressing
                }, perform: {})

                // Thin vertical divider
                Rectangle()
                    .fill(theme.divider.opacity(0.4))
                    .frame(width: 1)
                    .padding(.vertical, 12)

                // RIGHT: SHOT RATER
                Button(action: onShotRaterTap) {
                    VStack(spacing: 8) {
                        Image(systemName: "target")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(theme.primary)
                            .shadow(color: theme.primary.opacity(0.3), radius: 4)

                        VStack(spacing: 2) {
                            Text("SKILL CHECK")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.white)
                                .tracking(0.5)
                            Text("AI Skill Rating")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }

                        Spacer()

                        // Removed duplicate CTA (moved into bottom group above)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(isPressedRight ? theme.primary.opacity(0.05) : Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isPressedRight ? 0.98 : 1.0)
                .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                    isPressedRight = pressing
                }, perform: {})
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [
                            theme.surface.opacity(0.85),
                            theme.surface.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.6),
                            theme.accent.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: theme.primary.opacity(0.15), radius: 10, x: 0, y: 4)
        .frame(height: 165)
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview
#Preview {
    DualFeatureCardSelector()
        .preferredColorScheme(.dark)
}
