import SwiftUI

// MARK: - Skill Check View
/// Main container view for Skill Check flow
/// SIMPLIFIED FLOW: Video + Context → Processing → Results
/// Key insight: Get video first, ask questions after (like Wrestle AI)
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

    // Saved results state
    @State private var showingSavedResults = false
    @State private var savedResult: StoredSkillCheckResult?

    init(onAnalysisComplete: ((SkillAnalysisResult) -> Void)? = nil) {
        self.onAnalysisComplete = onAnalysisComplete
    }

    /// Check if user has a recent saved result to show
    private var hasSavedResult: Bool {
        AnalysisResultsStore.shared.latestSkillResult != nil
    }

    var body: some View {
        Group {
            if showingSavedResults, let saved = savedResult {
                // Show saved results view
                SavedSkillCheckResultsView(
                    result: saved,
                    onNewCheck: {
                        // User wants to do a new check
                        showingSavedResults = false
                        savedResult = nil
                    },
                    onExit: {
                        dismiss()
                    }
                )
            } else {
                // Normal flow
                normalFlowView
            }
        }
        .onAppear {
            // Check for saved results when view appears
            if let latestResult = AnalysisResultsStore.shared.latestSkillResult {
                savedResult = latestResult
                showingSavedResults = true
            }
        }
    }

    // MARK: - Normal Flow View
    private var normalFlowView: some View {
        let flow = SkillCheckFlowDefinition()

        return AIFlowContainer(flow: flow) { flowState in
            ZStack {
                if let stage = flowState.currentStage {
                    switch stage.id {
                    case "video-capture":
                        // Use existing capture view with preview
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
                viewModel.reset()
                analysisTask?.cancel()
                analysisTask = nil
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AIFlowCancel"))) { _ in
                AIAnalysisFacade.cancelActiveRequests()
                analysisTask?.cancel()
                analysisTask = nil
                viewModel.reset()
                dismiss()
            }
        }
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

    // MARK: - Video Capture View (Simplified)
    private func skillCaptureView(flowState: AIFlowState) -> some View {
        SkillCheckVideoCaptureView(
            onVideoCaptured: { url, context in
                // Track video selected
                SkillCheckAnalytics.trackVideoSelected(source: "capture")

                // Store the video and context, proceed to analysis
                viewModel.setCapturedVideo(url)
                viewModel.setContext(context)
                flowState.setData(url, for: "captured-video")
                flowState.setData(context, for: "skill-context")
                flowState.proceed()

                // Start analysis with context
                analysisTask?.cancel()
                let task = Task { @MainActor in
                    await viewModel.analyzeSkill(videoURL: url, context: context)
                }
                analysisTask = task
            }
        )
    }

    private func skillAnalysisView(flowState: AIFlowState) -> some View {
        SkillCheckProcessingView()
            .onAppear {
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
    }
}

// MARK: - Skill Check Flow Definition
/// Simplified flow: Video + Context → Processing → Results
struct SkillCheckFlowDefinition: AIFlowDefinition {
    let id = "skill-check"
    let name = "Skill Check"
    let allowsBackNavigation = true
    let showsProgress = true // Show progress bar

    var stages: [any AIFlowStage] {
        var stageList: [any AIFlowStage] = []

        // Video Capture with Context Questions (single screen)
        stageList.append(
            MediaCaptureStage(
                id: "video-capture",
                title: "Skill Check",
                subtitle: "",
                mediaTypes: [.video],
                maxItems: 1,
                minItems: 1,
                instructions: "",
                maxVideos: 1
            )
        )

        // Analysis Stage
        stageList.append(
            ProcessingStage(
                id: "analysis",
                title: "Analyzing",
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
                title: "Results",
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

// MARK: - Generic Stage (for Hero)
struct GenericStage: AIFlowStage {
    let id: String
    let title: String
    let subtitle: String
    let showsHeader: Bool

    var isRequired: Bool { true }
    var canSkip: Bool { false }
    var canGoBack: Bool { true }

    func validate(data: Any?) -> AIValidationResult {
        AIValidationResult(isValid: true, errors: [])
    }
}

// MARK: - Preview
#Preview {
    SkillCheckView()
        .preferredColorScheme(.dark)
}
