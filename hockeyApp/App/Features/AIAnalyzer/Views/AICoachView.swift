import SwiftUI

// MARK: - AI Coach View
/// Main AI Coach page that contains both the AI Shot Coach card and Shot Rating
struct AICoachView: View {
    @Environment(\.theme) var theme
    @Environment(\.entranceAnimationTrigger) var entranceAnimationTrigger
    @State private var selectedShotType: ShotType?
    @State private var resumeResult: ShotAnalysisResult?
    @State private var showAICoachFlow = false
    @ObservedObject private var background = ShotRaterBackgroundManager.shared
    
    // MARK: - Body
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                // Add small spacing after header
                Spacer()
                    .frame(height: 4)

                // AI Shot Coach Card - Shot Rater Style
                AICoachFeaturedCard_ShotRaterStyle(onTap: {
                    showAICoachFlow = true
                })

                // Shot Rating Section
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text("Shot Rating")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(theme.text)
                    
                    // Shot type cards
                    VStack(spacing: 12) {
                        ForEach(Array(ShotType.allCases.enumerated()), id: \.element) { idx, type in
                            ShotStatCard(
                                type: type,
                                analysisResult: background.latestResult(for: type),
                                isAnalyzing: background.isAnalyzing(type),
                                onStart: { selectedShotType = type },
                                onOpenResults: { if let res = background.latestResult(for: type) { resumeResult = res } },
                                onAnalyzeAgain: {
                                    background.clearResult(for: type)
                                    selectedShotType = type
                                },
                                onCancel: { background.cancelAnalysis(for: type) }
                            )
                            .cascadingListItem(index: idx, trigger: entranceAnimationTrigger)
                        }
                    }
                }
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.bottom, 90)
        }
        .fullScreenCover(item: $selectedShotType) { shotType in
            ShotRaterView(preSelectedShotType: shotType)
        }
        .fullScreenCover(item: $resumeResult) { result in
            ShotRaterView(
                preSelectedShotType: result.type,
                resumeResult: result
            )
        }
        .fullScreenCover(isPresented: $showAICoachFlow) {
            AICoachFlowView(
                preSelectedShotType: nil,
                onAnalysisComplete: { result in
                    // Analysis complete
                }
            )
        }
        .trackScreen("ai_coach")
    }
}
