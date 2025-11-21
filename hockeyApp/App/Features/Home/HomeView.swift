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
