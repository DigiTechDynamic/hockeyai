import SwiftUI
import SceneKit

// MARK: - Equipment View (AI Stick Analyzer Hub)
struct EquipmentView: View {
    @Environment(\.theme) var theme
    @Environment(\.entranceAnimationTrigger) var entranceAnimationTrigger
    @State private var showingStickAnalyzer = false
    @State private var showingStickGuide = false
    @State private var currentStickData: StickAnalysisData?
    @StateObject private var monetization = MonetizationManager.shared
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.md) {
                // Add small spacing after header
                Spacer()
                    .frame(height: 4)
                
                // Main Stick Analysis Card
                StickAnalysisCard(
                    currentData: currentStickData,
                    onTap: { showingStickAnalyzer = true }
                )

                // Stick Selection Guide Card
                StickGuideCard(onTap: { showingStickGuide = true })
            }
            .padding(.horizontal, theme.spacing.md)
            // Keep a small cushion above the tab bar, not a large fixed gap
            .padding(.bottom, theme.spacing.lg)
        }
        .onAppear {
            loadSavedAnalysis()
        }
        .fullScreenCover(isPresented: $showingStickAnalyzer) {
            StickAnalyzerView { result in
                // Update stick data with analysis results (no current stick comparison)
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
                saveAnalysis(newData)
            }
        }
        .fullScreenCover(isPresented: $showingStickGuide) {
            StickSelectionGuideView(onLaunchAnalyzer: {
                showingStickGuide = false
                // Small delay to allow sheet to dismiss before showing next one
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingStickAnalyzer = true
                }
            })
        }

    }
    
    // MARK: - Private Methods
    private func loadSavedAnalysis() {
        if let data = UserDefaults.standard.data(forKey: "lastStickAnalysis"),
           let decoded = try? JSONDecoder().decode(StickAnalysisData.self, from: data) {
            currentStickData = decoded
        }
    }
    
    private func saveAnalysis(_ data: StickAnalysisData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: "lastStickAnalysis")
        }
    }

    
}

// MARK: - Stick Analysis Card
struct StickAnalysisCard: View {
    @Environment(\.theme) var theme
    @StateObject private var monetization = MonetizationManager.shared
    let currentData: StickAnalysisData?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with PRO badge
                HStack {
                    Text("Stick Analysis")
                        .font(.system(size: 24, weight: .black))
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
                VStack(alignment: .leading, spacing: 6) {
                    if let data = currentData {
                        Text("\"AI found your perfect stick\" ✨")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(theme.text.opacity(0.9))
                            .italic()
                            .lineLimit(2)

                        // Quick specs preview
                        Text("Flex: \(data.optimizedFlex) • Length: \(data.optimizedLength)")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(theme.textSecondary)
                    } else {
                        Text("\"Find the perfect stick for your game\" 🏒")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(theme.text.opacity(0.9))
                            .italic()
                            .lineLimit(2)

                        Text("AI-powered recommendations tailored to your shot")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(theme.textSecondary)
                    }
                }

                Spacer()

                // CTA button
                HStack {
                    Text(currentData != nil ? "View Analysis" : "Start Analysis")
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
            .frame(height: 230)
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

// MARK: - Recommended Spec Row
struct RecommendedSpecRow: View {
    @Environment(\.theme) var theme
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.textSecondary.opacity(0.7))
                .frame(width: 50, alignment: .leading)

            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(theme.text)

            Spacer()
        }
    }
}

// MARK: - Spec Row
struct SpecRow: View {
    @Environment(\.theme) var theme
    let label: String
    let value: String
    let isOptimized: Bool
    
    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            Text(label)
                .font(theme.fonts.callout)
                .foregroundColor(theme.textSecondary.opacity(0.6))
                .frame(width: 55, alignment: .leading)
            
            Text(value)
                .font(theme.fonts.bodyBold)
                .foregroundColor(value == "--" ? theme.textSecondary.opacity(0.4) : (isOptimized ? theme.primary : theme.text))
        }
    }
}



// MARK: - Stick Guide Card
struct StickGuideCard: View {
    @Environment(\.theme) var theme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: theme.spacing.lg) {
                // Header with consistent sizing as Stick Analysis Card (no icon)
                HStack(alignment: .top) {
                    Text("Stick Selection Guide")
                        .font(.system(size: 24, weight: .black))
                        .glowingHeaderText()
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)

                    Spacer()

                    // Arrow button
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.15))
                            .frame(width: 56, height: 56)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(theme.primary)
                    }
                }

                // Content text with improved typography
                Text("Learn everything about flex, curves, lie angles, and kick points. Discover what the pros use and avoid common mistakes that hurt your game.")
                    .font(theme.fonts.body)
                    .foregroundColor(theme.textSecondary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Quick preview chips
                HStack(spacing: 8) {
                    guideChip(icon: "chart.line.uptrend.xyaxis", text: "Flex")
                    guideChip(icon: "waveform.path", text: "Curves")
                    guideChip(icon: "angle", text: "Lie")
                    guideChip(icon: "star.fill", text: "Pro Tips")
                    Spacer()
                }
            }
            .padding(theme.spacing.lg)
        }
        .background(
            // Match Stick Analysis card background
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

    private func guideChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(theme.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(theme.primary.opacity(0.15))
        )
    }
}

// MARK: - Data Models
struct StickAnalysisData: Codable {
    let stickName: String
    let currentFlex: String
    let currentLength: String
    let currentCurve: String
    let currentLie: String
    let optimizedFlex: String
    let optimizedLength: String
    let optimizedCurve: String
    let optimizedLie: String
    let analysisDate: Date
}

// Stick Optimizer Flow removed - replaced with StickAnalyzerView

// MARK: - Preview
struct EquipmentView_Previews: PreviewProvider {
    static var previews: some View {
        EquipmentView()
            .preferredColorScheme(.dark)
    }
}
