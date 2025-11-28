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
        case hockeyCardGenerator

        var id: String {
            switch self {
            case .styCheck: return "styCheck"
            case .shotRater: return "shotRater"
            case .stickAnalyzer: return "stickAnalyzer"
            case .hockeyCardGenerator: return "hockeyCardGenerator"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Home Screen Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // AI ANALYZER card first
                    DualFeatureCard_Option4(
                        onStyCheckTap: { activeModal = .styCheck },
                        onShotRaterTap: { activeModal = .shotRater }
                    )
                    .padding(.top, 20)

                    // HOCKEY CARD GENERATOR Card
                    HockeyCardGeneratorCard(
                        onTap: {
                            activeModal = .hockeyCardGenerator
                        }
                    )
                    .padding(.horizontal, 20)

                    // STICK ANALYSIS Card (Compact version for Home)
                    CompactStickAnalysisCard(
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

        case .hockeyCardGenerator:
            NavigationView {
                HockeyCardCreationView(onDismiss: {
                    activeModal = nil
                })
            }
            .navigationViewStyle(.stack)
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

// MARK: - Hockey Card Generator Card
struct HockeyCardGeneratorCard: View {
    @Environment(\.theme) var theme
    @StateObject private var monetization = MonetizationManager.shared
    @State private var latestCardImage: UIImage?

    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .center) {
            // 1. Background
            ZStack {
                GeometryReader { proxy in
                    Image("hockey_card_bg")
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                }

                // Dark Gradient Overlay for readability
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.6),
                        Color.black.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Theme Tint
                theme.primary.opacity(0.12)
                    .blendMode(.overlay)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
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

            // 2. Content Layer
            HStack(spacing: 0) {
                // Left Content
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hockey Card")
                        .font(.system(size: 24, weight: .black))
                        .glowingHeaderText()
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .layoutPriority(1)
                        .padding(.top, 4)

                    Text("Create your custom hockey card")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(2)
                }
                .padding(.leading, 24)
                .padding(.vertical, 24)

                Spacer()

                // Right Visual - Tilted Card (Popping out)
                ZStack {
                    // Glow
                    Circle()
                        .fill(theme.primary.opacity(0.4))
                        .frame(width: 140, height: 140)
                        .blur(radius: 30)

                    // Card Shape
                    if let cardImage = latestCardImage {
                        Image(uiImage: cardImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 110)
                            .cornerRadius(6)
                            .rotationEffect(.degrees(12))
                            .shadow(color: .black.opacity(0.5), radius: 15, x: 8, y: 8)
                    } else {
                        // Placeholder Hockey Card
                        Image("PlaceholderHockeyCard")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 110)
                            .cornerRadius(6)
                            .rotationEffect(.degrees(12))
                            .shadow(color: .black.opacity(0.5), radius: 15, x: 8, y: 8)
                    }
                }
                .frame(width: 140)
                .offset(x: 10, y: -25) // Pop up and right
                .padding(.trailing, 10)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture { onTap() }

        .onAppear {
            if let path = UserDefaults.standard.string(forKey: "latestGeneratedCardPath"),
               let image = UIImage(contentsOfFile: path) {
                latestCardImage = image
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LatestCardUpdated"))) { _ in
            if let path = UserDefaults.standard.string(forKey: "latestGeneratedCardPath"),
               let image = UIImage(contentsOfFile: path) {
                latestCardImage = image
            }
        }
    }
}

// MARK: - Compact Stick Analysis Card (for Home screen only)
struct CompactStickAnalysisCard: View {
    @Environment(\.theme) var theme
    @StateObject private var monetization = MonetizationManager.shared
    let currentData: StickAnalysisData?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Header with PRO badge
                HStack {
                    Text("Stick Analysis")
                        .font(.system(size: 22, weight: .black))
                        .glowingHeaderText()
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)

                    Spacer()

                    // Crown PRO badge
                    if !monetization.isPremium {
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
                }

                // Hook/teaser text
                VStack(alignment: .leading, spacing: 4) {
                    if let data = currentData {
                        Text("\"AI found your perfect stick\" ✨")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(theme.text.opacity(0.9))
                            .italic()
                            .lineLimit(1)

                        // Quick specs preview
                        Text("Flex: \(data.optimizedFlex) • Length: \(data.optimizedLength)")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(1)
                    } else {
                        Text("\"Find the perfect stick for your game\" 🏒")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(theme.text.opacity(0.9))
                            .italic()
                            .lineLimit(1)

                        Text("AI-powered recommendations tailored to your shot")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                // CTA button
                HStack {
                    Text(currentData != nil ? "View Analysis" : "Start Analysis")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(theme.primary)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.primary.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.primary.opacity(0.5), lineWidth: 1.5)
                )
            }
            .padding(16)
            .frame(height: 170)
        }
        .background(
            // Match STY Check card background
            ZStack {
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
        .buttonStyle(PlainButtonStyle())
    }
}
