import SwiftUI

// MARK: - Skill Check View
/// Main container view for Skill Check flow - simplified, no skill type selection
struct SkillCheckView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    @StateObject private var viewModel = SkillCheckViewModel()

    // Completion handler for analysis result
    let onAnalysisComplete: ((SkillAnalysisResult) -> Void)?

    // State
    @State private var analysisTask: Task<Void, Never>? = nil
    @State private var shouldActivateGate = false
    @State private var gateTriggerId = UUID().uuidString
    @State private var pendingMonetizedAction: (() -> Void)?

    init(onAnalysisComplete: ((SkillAnalysisResult) -> Void)? = nil) {
        self.onAnalysisComplete = onAnalysisComplete
    }

    var body: some View {
        let flow = SkillCheckFlowDefinition()

        AIFlowContainer(flow: flow) { flowState in
            ZStack {
                if let stage = flowState.currentStage {
                    switch stage.id {
                    case "video-capture":
                        skillCaptureView(flowState: flowState)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))

                    case "analysis":
                        skillAnalysisView(flowState: flowState)
                            .transition(.opacity)

                    case "results":
                        if let error = viewModel.currentError {
                            AIServiceErrorView(
                                errorType: AIServiceErrorType.from(analyzerError: error),
                                onRetry: {
                                    viewModel.reset()
                                    flowState.restart()
                                },
                                onDismiss: {
                                    flowState.restart()
                                }
                            )
                        } else if let result = viewModel.analysisResult {
                            SkillCheckResultsView(
                                analysisResult: result,
                                onExit: {
                                    onAnalysisComplete?(result)
                                    viewModel.cleanup()
                                    dismiss()
                                }
                            )
                            .onAppear {
                                onAnalysisComplete?(result)
                            }
                        } else {
                            ProgressView("Loading results...")
                                .progressViewStyle(CircularProgressViewStyle())
                        }

                    default:
                        EmptyView()
                    }
                }
            }
            .onDisappear {
                // Clean up videos when view disappears
                viewModel.reset()
                analysisTask?.cancel()
                analysisTask = nil
            }
            // Proactively cancel work if header Cancel is tapped
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AIFlowCancel"))) { _ in
                // Cancel active network requests
                AIAnalysisFacade.cancelActiveRequests()

                // Cancel local tasks
                analysisTask?.cancel()
                analysisTask = nil

                viewModel.reset()
                dismiss()
            }
            // Note: Funnel tracking now handled in individual views
            // - Started: SkillCheckView.onAppear
            // - Video selected: skillCaptureView callback
            // - Analyzing: skillAnalysisView.onAppear
            // - Results viewed: SkillCheckResultsView.onAppear
            // - Elite breakdown clicked: SkillCheckResultsView.unlockPremium
            // - Elite breakdown unlocked: SkillCheckResultsView.checkPremiumStatus
            .onAppear {
                // Track funnel start (Step 1)
                SkillCheckAnalytics.trackStarted(source: "skill_check_home")
            }
        }
        // Ensure cellular banner renders above the flow container
        .overlay(
            GlobalPresentationLayer()
                .environmentObject(NoticeCenter.shared)
                .zIndex(10000)
        )
        .monetizationGate(
            featureIdentifier: "ai_analysis",
            source: "SkillCheckView_AnalyzeButton",
            activatedProgrammatically: $shouldActivateGate,
            triggerId: gateTriggerId,
            consumeAccess: true,
            onAccessGranted: handleMonetizationGranted,
            onDismissOrCancel: handleMonetizationDismissed
        )
    }

    // MARK: - Stage Views

    private func skillCaptureView(flowState: AIFlowState) -> some View {
        SkillCheckCaptureView(
            capturedVideoURL: .constant(nil),
            onVideoCaptured: { url in
                // Track video selected & trimmed (Steps 2-4 happen in MediaCaptureKit)
                // We track completion here as a single step
                SkillCheckAnalytics.trackVideoSelected(source: "library") // TODO: Track actual source

                // Free analysis - no paywall gate
                viewModel.setCapturedVideo(url)
                flowState.setData(url, for: "captured-video")

                // Skip validation, proceed directly to analysis
                flowState.proceed()

                // Start analysis immediately
                analysisTask?.cancel()
                let task = Task { @MainActor in
                    await viewModel.analyzeSkill(videoURL: url)
                }
                analysisTask = task
            }
        )
    }

    private func skillAnalysisView(flowState: AIFlowState) -> some View {
        SkillCheckProcessingView()
            .onAppear {
                // Track analyzing (Step 5)
                SkillCheckAnalytics.trackAnalyzing()
            }
            .onReceive(viewModel.$analysisResult) { result in
                if result != nil {
                    flowState.proceed()
                }
            }
            .onReceive(viewModel.$currentError) { error in
                if error != nil {
                    flowState.proceed()
                }
            }
    }

    // MARK: - Monetization

    private func triggerMonetizationGate(action: @escaping () -> Void) {
        pendingMonetizedAction = action
        gateTriggerId = UUID().uuidString
        shouldActivateGate = true
    }

    private func handleMonetizationGranted() {
        print("GRANTED - Proceed with AI analysis")
        shouldActivateGate = false
        let action = pendingMonetizedAction
        pendingMonetizedAction = nil
        guard let action else { return }
        DispatchQueue.main.async {
            action()
        }
    }

    private func handleMonetizationDismissed(_ error: String?) {
        shouldActivateGate = false
        gateTriggerId = UUID().uuidString
        pendingMonetizedAction = nil
        print("User cancelled or error: \(error ?? "none")")
    }

    // MARK: - Funnel Tracking
    // Tracking now handled in individual view components via SkillCheckAnalytics
}

// MARK: - Skill Check Flow Definition
/// Flow definition for Skill Check using AIFlowContainer
struct SkillCheckFlowDefinition: AIFlowDefinition {
    let id = "skill-check"
    let name = "Skill Check"
    let allowsBackNavigation = true
    let showsProgress = true

    var stages: [any AIFlowStage] {
        var stageList: [any AIFlowStage] = []

        // Video Capture (no selection needed)
        stageList.append(
            MediaCaptureStage(
                id: "video-capture",
                title: "Record Skill",
                subtitle: "",
                mediaTypes: [.video],
                maxItems: 1,
                minItems: 1,
                instructions: "Record any hockey skill you want analyzed",
                maxVideos: 1
            )
        )

        // Analysis Stage (validation removed for faster processing)
        stageList.append(
            ProcessingStage(
                id: "analysis",
                title: "Analyzing Skill",
                subtitle: "",
                processingMessage: "AI is evaluating your technique...",
                showsHeader: true,
                showsCancelButton: true
            )
        )

        // Results
        stageList.append(
            ResultsStage(
                id: "results",
                title: "Analysis Complete",
                subtitle: ""
            )
        )

        return stageList
    }

    func nextStage(from currentStage: any AIFlowStage, with data: [String: Any]) -> (any AIFlowStage)? {
        guard let currentIndex = stages.firstIndex(where: { $0.id == currentStage.id }) else {
            return nil
        }

        let nextIndex = currentIndex + 1
        return nextIndex < stages.count ? stages[nextIndex] : nil
    }

    func previousStage(from currentStage: any AIFlowStage) -> (any AIFlowStage)? {
        guard let currentIndex = stages.firstIndex(where: { $0.id == currentStage.id }),
              currentIndex > 0 else {
            return nil
        }

        return stages[currentIndex - 1]
    }
}

// MARK: - Preview
#Preview {
    SkillCheckView()
        .preferredColorScheme(.dark)
}
