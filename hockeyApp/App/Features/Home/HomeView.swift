import SwiftUI
import UIKit

// MARK: - Tech Card Frame Components


// Slot shapes overlay


// MARK: - Home View
struct HomeView: View {
    @Environment(\.theme) var theme
    @Environment(\.entranceAnimationTrigger) var entranceAnimationTrigger
    @State private var isPressed = false
    @State private var activeModal: HomeModal? = nil
    @State private var currentStickData: StickAnalysisData?

    enum HomeModal: Identifiable {
        case styCheck
        case shotRater
        case stickAnalyzer(completion: (StickAnalysisResult) -> Void)

        var id: String {
            switch self {
            case .styCheck: return "styCheck"
            case .shotRater: return "shotRater"
            case .stickAnalyzer: return "stickAnalyzer"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            /*
            // Style Check Button - large island style (temporarily commented out)
            Button(action: {
                showingStyCheck = true
            }) {
                HStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .semibold))

                    Text("STY CHECK")
                        .font(.system(size: 20, weight: .bold))
                        .tracking(1.0)

                    Spacer()
                }
                .foregroundColor(theme.text)
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                .frame(width: UIScreen.main.bounds.width * 0.85, height: 80)
                .background(
                    ZStack {
                        // Base layer with blur effect
                        RoundedRectangle(cornerRadius: 20)
                            .fill(theme.primary.opacity(0.15))
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                            )

                        // Gradient overlay
                        LinearGradient(
                            colors: [
                                theme.primary.opacity(0.3),
                                theme.primary.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .cornerRadius(20)

                        // Inner border effect
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        theme.primary.opacity(0.8),
                                        theme.primary.opacity(0.4)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2
                            )
                            .padding(1)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: theme.primary.opacity(0.2), radius: 12, x: 0, y: 6)
                .shadow(color: theme.primary.opacity(0.1), radius: 24, x: 0, y: 12)
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            }
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
            .padding(.horizontal, 30)
            .padding(.top, 60)
            */

            // Home Screen Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // GET RATED card first
                    DualFeatureCard_Option4(
                        onStyCheckTap: { activeModal = .styCheck },
                        onShotRaterTap: { activeModal = .shotRater }
                    )
                    .padding(.top, 20)

                    // STICK ANALYSIS Card
                    StickAnalysisCard(
                        currentData: currentStickData,
                        onTap: {
                            activeModal = .stickAnalyzer { result in
                                let newData = StickAnalysisData(
                                    stickName: "Recommended Stick",
                                    currentFlex: "N/A",
                                    currentLength: "N/A",
                                    currentCurve: "N/A",
                                    currentLie: "N/A",
                                    optimizedFlex: result.recommendations.idealFlex.displayString,
                                    optimizedLength: result.recommendations.idealLength.displayString,
                                    optimizedCurve: result.recommendations.idealCurve.first ?? "",
                                    optimizedLie: String(result.recommendations.idealLie),
                                    analysisDate: Date()
                                )
                                currentStickData = newData
                                saveStickAnalysis(newData)
                            }
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadSavedStickAnalysis()
        }
        .fullScreenCover(item: $activeModal) { modal in
            modalView(for: modal)
        }
        .trackScreen("home")
    }

    // MARK: - Modal Views
    @ViewBuilder
    private func modalView(for modal: HomeModal) -> some View {
        switch modal {
        case .styCheck:
            PlayerRaterFlowView(context: .homeScreen) { _ in
                activeModal = nil
            }

        case .shotRater:
            SkillCheckView()

        case .stickAnalyzer(let completion):
            StickAnalyzerView { result in
                completion(result)
                activeModal = nil
            }
        }
    }

    // MARK: - Private Methods
    private func loadSavedStickAnalysis() {
        if let data = UserDefaults.standard.data(forKey: "lastStickAnalysis"),
           let decoded = try? JSONDecoder().decode(StickAnalysisData.self, from: data) {
            currentStickData = decoded
        }
    }

    private func saveStickAnalysis(_ data: StickAnalysisData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: "lastStickAnalysis")
        }
    }
}

// MARK: - Home Screen Card Components

// MARK: - Shot Rater Hero Card (THE MONEY MAKER)
struct ShotRaterHeroCard: View {
    @Environment(\.theme) var theme
    @State private var showDemo = false
    @State private var showShotRater = false
    @State private var isPressedExample = false
    @State private var isPressedMain = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Subtle radial gradient background (non-distracting)
            RadialGradient(
                colors: [
                    theme.primary.opacity(0.08),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 10,
                endRadius: 300
            )

            VStack(spacing: 0) {
                // Compact header with badge
                HStack {
                    Text("SHOT RATER")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(theme.textSecondary)
                        .tracking(1)

                    Spacer()

                    HStack(spacing: 3) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 9))
                        Text("10K+")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(theme.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(theme.primary.opacity(0.12)))
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)

                // Main headline - compact
                VStack(spacing: 6) {
                    Text("How Good Is Your Shot?")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(theme.text)
                        .multilineTextAlignment(.center)

                    Text("Compare to players your age")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Cleaner stats preview
                HStack(spacing: 0) {
                    VStack(spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("8.2")
                                .font(.system(size: 34, weight: .black))
                                .foregroundColor(theme.primary)
                            Text("/10")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.textSecondary)
                        }
                        Text("Rating")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(theme.divider)
                        .frame(width: 1, height: 44)

                    VStack(spacing: 2) {
                        Text("Top 15%")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(theme.primary)
                        Text("for 16yr olds")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.02))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.primary.opacity(0.15), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // CTAs - cleaner, more compact
                VStack(spacing: 8) {
                    Button(action: { showShotRater = true }) {
                        HStack {
                            Text("Get My Ranking")
                                .font(.system(size: 17, weight: .bold))
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.vertical, 15)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(theme.primary)
                        )
                        .shadow(color: theme.primary.opacity(0.3), radius: 8, y: 4)
                    }
                    .scaleEffect(isPressedMain ? 0.98 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressedMain)
                    .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                        isPressedMain = pressing
                    }, perform: {})

                    Button(action: { showDemo = true }) {
                        Text("See Example")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.primary)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
            }
        }
        .frame(height: 300)  // Much more compact
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.surface)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.6),
                            theme.accent.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: theme.primary.opacity(0.2), radius: 12, x: 0, y: 4)
        .fullScreenCover(isPresented: $showDemo) {
            // TODO: Show demo Shot Rater result
            Text("Demo Mode - Coming Soon")
                .foregroundColor(.white)
        }
        .fullScreenCover(isPresented: $showShotRater) {
            // TODO: Connect to actual Shot Rater flow
            SkillCheckView()
        }
    }
}

struct PlayerRaterHeroCard: View {
    @Environment(\.theme) var theme
    @State private var isPressed = false
    @State private var showingPlayerRater = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero image area - full bleed header
            ZStack {
                // Player image
                Image("player")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 240)
                    .clipped()

                // Dark vignette overlay (like Umax)
                LinearGradient(
                    colors: [
                        Color.black.opacity(0),
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Soft fade into card surface to avoid hard seam
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0),
                            theme.surface.opacity(0.95)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 32)
                }
                .allowsHitTesting(false)

                // Text overlay (like Umax "Get your ratings...")
                VStack {
                    Spacer()

                    Text("Get your ratings and\nrecommendations")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.6), radius: 10, x: 0, y: 3)
                        .padding(.bottom, 20)
                }
            }
            .frame(height: 240)
            .cornerRadius(20, corners: [.topLeft, .topRight])

            

            // Big green CTA button (like Start This Workout)
            Button(action: { showingPlayerRater = true }) {
                HStack {
                    Text("Begin Scan")
                        .font(.system(size: 18, weight: .semibold))

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(theme.textOnPrimary)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [theme.primary, theme.primary.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: theme.primary.opacity(0.35), radius: 12, x: 0, y: 6)
                .shadow(color: theme.primary.opacity(0.2), radius: 20, x: 0, y: 10)
            }
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
            .padding(.horizontal, 20)
            .padding(.top, -12) // slight overlap into image like reference
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.surface)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.6),
                            theme.accent.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: theme.primary.opacity(0.2), radius: 12, x: 0, y: 4)
        .fullScreenCover(isPresented: $showingPlayerRater) {
            PlayerRaterFlowView(context: .homeScreen) { rating in
                if let rating = rating {
                    print("Player rated: \(rating.overallScore)/100")
                }
                showingPlayerRater = false
            }
        }
    }
}

// MARK: - Shot Rater Featured Card (Styled like Green Machine card)
private struct ShotRaterFeaturedCard: View {
    @Environment(\.theme) var theme
    @State private var showShotRater = false
    @State private var isPressed = false
    @StateObject private var monetization = MonetizationManager.shared

    var body: some View {
        Button(action: {
            showShotRater = true
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Header Badge with live indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .shadow(color: .green, radius: 4, x: 0, y: 0)

                    Text("SHOT RATER")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.textSecondary.opacity(0.95))
                        .tracking(1.2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 14)

                // Split Layout: Text left, Image right
                HStack(spacing: 0) {
                    // Left side: Text content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How Good Is Your Shot?")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.95)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.white.opacity(0.3), radius: 0)
                            .shadow(color: Color.white.opacity(0.2), radius: 4)
                            .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 2)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)

                        // Social proof + value prop
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 9, weight: .bold))
                                Text("10K+ rated")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(theme.primary)

                            Text("Get your ratings vs players your age")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(theme.textSecondary)
                                .lineSpacing(1)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Right side: Action shot image with border
                    ZStack {
                        GeometryReader { proxy in
                            Image("shotting")
                                .resizable()
                                .scaledToFill()
                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .clipped()
                        }

                        // Gradient fade on left edge to blend with text area
                        LinearGradient(
                            colors: [
                                theme.surface.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                    .frame(width: 170)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        theme.primary.opacity(0.6),
                                        theme.primary.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .frame(height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Prominent CTA Button
                HStack {
                    Text("Get My Ranking")
                        .font(.system(size: 19, weight: .bold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(theme.primary)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(theme.primary.opacity(0.10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(theme.primary, lineWidth: 1.2)
                )
                .shadow(color: theme.primary.opacity(0.25), radius: 6, x: 0, y: 4)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.surface.opacity(0.95),
                                theme.surface.opacity(0.85)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.7),
                                theme.accent.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
            )
            // PRO pill (top-right) when user is not premium
            .overlay(alignment: .topTrailing) {
                if !monetization.isPremium {
                    ProChip()
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                        .allowsHitTesting(false)
                }
            }
            .shadow(color: Color.green.opacity(0.25), radius: 16, x: 0, y: 6)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .fullScreenCover(isPresented: $showShotRater) {
            SkillCheckView()
        }
    }
}

// MARK: - Fit Check Card (styled like Face Shape Analysis)
struct PlayerRaterImageCard: View {
    @Environment(\.theme) var theme
    @State private var isPressed = false
    @State private var showingPlayerRater = false

    var body: some View {
        Button(action: { showingPlayerRater = true }) {
            HStack(spacing: 0) {
                // Left side: Text + Button
                VStack(alignment: .leading, spacing: 10) {
                    // Title styled like HOCKEYAPP header (glow text)
                    Text("STY Check")
                        .font(.system(size: 24, weight: .bold))
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
                        .shadow(color: Color.white.opacity(0.3), radius: 0)
                        .shadow(color: Color.white.opacity(0.2), radius: 4)
                        .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("Rate your hockey gear and get personalized recommendations.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(3)
                        .minimumScaleFactor(0.9)

                    Spacer(minLength: 4)

                    // Start Analysis button (no play icon)
                    Text("Start Analysis")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.vertical, 11)
                        .padding(.horizontal, 20)
                        .background(
                            Capsule()
                                .fill(.white)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right side: Player image with detection frame
                ZStack {
                    // Use header-style backdrop instead of flat black
                    LinearGradient(
                        colors: [
                            theme.background.opacity(0.9),
                            theme.surface.opacity(0.75)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Player image
                    GeometryReader { proxy in
                        Image("player")
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                    }

                    // Detection frame overlay (corners)
                    VStack {
                        HStack {
                            DetectionCorner(theme: theme)
                            Spacer()
                            DetectionCorner(theme: theme)
                                .rotationEffect(.degrees(90))
                        }
                        Spacer()
                        HStack {
                            DetectionCorner(theme: theme)
                                .rotationEffect(.degrees(-90))
                            Spacer()
                            DetectionCorner(theme: theme)
                                .rotationEffect(.degrees(180))
                        }
                    }
                    .padding(10)
                }
                .frame(width: 170)
            }
            .frame(height: 190)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            ZStack {
                // Header-style glass + gradient background
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.surface.opacity(0.9),
                                theme.background.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [theme.primary.opacity(0.6), theme.accent.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: theme.primary.opacity(0.2), radius: 12, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) { pressing in
            isPressed = pressing
        } perform: {}
        .fullScreenCover(isPresented: $showingPlayerRater) {
            PlayerRaterFlowView(context: .homeScreen) { _ in
                showingPlayerRater = false
            }
        }
    }
}

// MARK: - Detection Corner Component
private struct DetectionCorner: View {
    let theme: AppTheme

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 18, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 18))
        }
        .stroke(theme.primary, lineWidth: 2.5)
        .frame(width: 18, height: 18)
    }
}

struct ChirpBotCard: View {
    @Environment(\.theme) var theme
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // TODO: Show paywall
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with crown PRO badge
                HStack {
                    Text("CHIRPBOT")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(theme.text)
                        .tracking(0.5)

                    Spacer()

                    // Crown PRO badge
                    HStack(spacing: 3) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("PRO")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.8))
                    )
                }

                // Example chirp teaser (the hook!)
                VStack(alignment: .leading, spacing: 6) {
                    Text("\"Your flow's dryer than burnt toast, bud\" 🔥")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.text.opacity(0.9))
                        .italic()
                        .lineLimit(2)

                    Text("Generate AI-powered trash talk")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                // CTA button
                HStack {
                    Text("Unlock ChirpBot")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(theme.primary)
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.primary.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.primary.opacity(0.5), lineWidth: 1.5)
                )
            }
            .padding(20)
            .frame(height: 200)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.surface)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.4),
                            theme.accent.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: theme.primary.opacity(0.1), radius: 12, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct ShotRaterCard: View {
    @Environment(\.theme) var theme
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // TODO: Show paywall
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with crown PRO badge
                HStack {
                    Text("SHOT RATER")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(theme.text)
                        .tracking(0.5)

                    Spacer()

                    // Crown PRO badge
                    HStack(spacing: 3) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("PRO")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.8))
                    )
                }

                // Description
                VStack(alignment: .leading, spacing: 6) {
                    Text("Analyze your wrist shot release & technique")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.text.opacity(0.9))
                        .lineLimit(2)

                    Text("Get instant AI feedback on form")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                // CTA button
                HStack {
                    Text("Unlock Shot Rater")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(theme.primary)
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.primary.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.primary.opacity(0.5), lineWidth: 1.5)
                )
            }
            .padding(20)
            .frame(height: 200)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.surface)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.4),
                            theme.accent.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: theme.primary.opacity(0.1), radius: 12, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}
