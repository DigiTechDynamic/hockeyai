import SwiftUI

// MARK: - Shot Rater View
/// Main container view for Shot Rater flow
struct ShotRaterView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    @StateObject private var viewModel = ShotRaterViewModel()

    // Optional pre-selected shot type
    let preSelectedShotType: ShotType?

    // Completion handler for analysis result
    let onAnalysisComplete: ((ShotAnalysisResult) -> Void)?

    // Optional resume payload to jump into results stage
    let resumeResult: ShotAnalysisResult?

    // State
    @State private var isValidating = false
    @State private var validationTask: Task<Void, Never>? = nil
    @State private var analysisTask: Task<Void, Never>? = nil
    @State private var runInBackground = false
    @State private var shouldActivateGate = false
    @State private var gateTriggerId = UUID().uuidString
    @State private var pendingMonetizedAction: (() -> Void)?
    // Selection animation/state (match AI Coach selection UX)
    @State private var showCards = false
    @State private var selectedCardId: String? = nil

    init(preSelectedShotType: ShotType? = nil,
         onAnalysisComplete: ((ShotAnalysisResult) -> Void)? = nil,
         resumeResult: ShotAnalysisResult? = nil) {
        self.preSelectedShotType = preSelectedShotType
        self.onAnalysisComplete = onAnalysisComplete
        self.resumeResult = resumeResult
    }

    var body: some View {
        let flow = ShotRaterFlowDefinition(preSelectedShotType: preSelectedShotType)

        AIFlowContainer(flow: flow) { flowState in
            ZStack {
                if let stage = flowState.currentStage {
                    switch stage.id {
                    case "shot-selection":
                        shotSelectionView(flowState: flowState)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))

                    case "phone-setup-tutorial":
                        PhoneSetupTutorialView(flowContext: .shotRater) { context in
                            flowState.proceed()
                        }
                        .transition(.opacity)

                    case "video-capture":
                        shotCaptureView(flowState: flowState)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))

                    case "video-trim":
                        EmptyView()

                    case "validation":
                        shotValidationView(flowState: flowState)
                            .transition(.opacity)

                    case "analysis":
                        shotAnalysisView(flowState: flowState)
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
                            ShotRaterResultsView(
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
            .onAppear { setupInitialState(flowState: flowState) }
            .onDisappear {
                // If user chose to run in background, keep tasks and media alive
                guard !runInBackground else { return }
                // Clean up videos when view disappears (only if not backgrounding)
                viewModel.reset()
                validationTask?.cancel()
                validationTask = nil
                analysisTask?.cancel()
                analysisTask = nil
            }
            .onChange(of: flowState.currentStage?.id) { newStage in
                handleStageChange(newStage, flowState: flowState)
            }
            // Proactively cancel work if header Cancel is tapped
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AIFlowCancel"))) { _ in
                let type = viewModel.selectedShotType
                // Cancel via manager but avoid rebroadcast to prevent recursive events
                ShotRaterBackgroundManager.shared.cancelAnalysis(for: type, broadcast: false)

                // Cancel active network requests
                AIAnalysisFacade.cancelActiveRequests()

                // Cancel local tasks
                validationTask?.cancel()
                validationTask = nil
                analysisTask?.cancel()
                analysisTask = nil

                isValidating = false
                viewModel.reset()
                dismiss()
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
            source: "ShotRaterView_AnalyzeButton",
            activatedProgrammatically: $shouldActivateGate,
            triggerId: gateTriggerId,
            consumeAccess: true,
            onAccessGranted: handleMonetizationGranted,
            onDismissOrCancel: handleMonetizationDismissed
        )
    }

    // MARK: - Setup

    private func setupInitialState(flowState: AIFlowState) {
        if let shotType = preSelectedShotType {
            viewModel.selectShotType(shotType)
            flowState.setData(shotType, for: "selected-shot-type")
        }

        // If we were launched with an initial result (from deep link or card),
        // hydrate the results stage with header/progress via the flow container
        if let initialResult = resumeResult {
            viewModel.selectShotType(initialResult.type)
            flowState.setData(initialResult.type, for: "selected-shot-type")
            viewModel.analysisResult = initialResult
            if let resultsStage = flowState.flow.stages.first(where: { $0.id == "results" }) {
                flowState.currentStage = resultsStage
            }
        }
    }

    // MARK: - Stage Views

    private func shotSelectionView(flowState: AIFlowState) -> some View {
        // Use the same animated card layout as AI Coach selection
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Top spacer to match AI Coach look (no subtitle text)
                    Spacer()
                        .frame(height: theme.spacing.lg)

                    // If we have a SelectionStage, render its options as cards
                    if let stage = flowState.currentStage as? SelectionStage, stage.id == "shot-selection" {
                        VStack(spacing: theme.spacing.md) {
                            ForEach(Array(stage.options.enumerated()), id: \.element.id) { index, option in
                                shotTypeCard(option: option, flowState: flowState, stage: stage)
                                    .scaleEffect(showCards ? 1 : 0.85)
                                    .opacity(showCards ? 1 : 0)
                                    .offset(y: showCards ? 0 : 20)
                                    .animation(
                                        .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                                        .delay(Double(index) * 0.08),
                                        value: showCards
                                    )
                            }
                        }
                        .padding(.horizontal, theme.spacing.lg)
                    }
                }
                .padding(.bottom, 120)
            }

            // Bottom button to proceed to capture
            bottomSelectionButton(for: flowState)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showCards = true }
        }
        .onDisappear { showCards = false }
    }

    private func shotTypeCard(option: SelectionStage.SelectionOption, flowState: AIFlowState, stage: SelectionStage) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCardId = option.id
                flowState.setData(option.id, for: stage.id)

                // Map selection id to ShotType and store
                let shotType = mapSelectionIdToShotType(option.id)
                viewModel.selectShotType(shotType)
                flowState.setData(shotType, for: "selected-shot-type")
            }
        }) {
            HStack(spacing: 16) {
                if let icon = option.icon, !icon.isEmpty {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(theme.primary)
                        .frame(width: 32)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.text)
                    if let subtitle = option.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Radio indicator matching AI Coach
                Circle()
                    .stroke(flowState.getData(for: stage.id) as? String == option.id ? theme.primary : theme.divider, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 16, height: 16)
                            .opacity(flowState.getData(for: stage.id) as? String == option.id ? 1 : 0)
                    )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(flowState.getData(for: stage.id) as? String == option.id ? theme.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(flowState.getData(for: stage.id) as? String == option.id ? 1.02 : 1.0)
    }

    private func bottomSelectionButton(for flowState: AIFlowState) -> some View {
        let selectedId = (flowState.getData(for: "shot-selection") as? String) ?? selectedCardId
        let shotTypeName: String = {
            switch mapSelectionIdToShotType(selectedId ?? "") {
            case .wristShot: return "Wrist Shot"
            case .slapShot: return "Slap Shot"
            case .backhandShot: return "Backhand"
            case .snapShot: return "Snap Shot"
            }
        }()

        return AppButton(
            title: selectedId != nil ? "Record \(shotTypeName)" : "Select Shot",
            action: {
                if selectedId != nil {
                    flowState.proceed()
                }
            },
            style: .primary,
            size: .large,
            icon: "arrow.right",
            isDisabled: selectedId == nil
        )
        .padding()
        .background(
            theme.background
                .opacity(0.95)
                .ignoresSafeArea()
        )
    }

    private func mapSelectionIdToShotType(_ id: String) -> ShotType {
        let idLower = id.lowercased()
        if idLower.contains("wrist") { return .wristShot }
        if idLower.contains("slap") { return .slapShot }
        if idLower.contains("backhand") { return .backhandShot }
        if idLower.contains("snap") { return .snapShot }
        // Fallback to any selection we may already have, else default
        return viewModel.selectedShotType
    }

    private func shotCaptureView(flowState: AIFlowState) -> some View {
        ShotRaterCaptureView(
            shotType: preSelectedShotType ?? viewModel.selectedShotType,
            capturedVideoURL: .constant(nil),
            onVideoCaptured: { url in
                triggerMonetizationGate {
                    viewModel.setCapturedVideo(url)
                    flowState.setData(url, for: "captured-video")
                    flowState.proceed()
                }
            }
        )
    }

    private func shotValidationView(flowState: AIFlowState) -> some View {
        SharedValidationView(
            isValidating: $isValidating,
            validationResult: $viewModel.validationResult,
            validationError: .constant(nil),
            featureName: "Shot Rater",
            onSuccess: {
                isValidating = false
                flowState.proceed()

                // Start analysis
                if let videoURL = flowState.getData(for: "captured-video") as? URL {
                    analysisTask?.cancel()
                    let task = Task { @MainActor in
                        await viewModel.analyzeShot(
                            videoURL: videoURL,
                            shotType: viewModel.selectedShotType
                        )
                    }
                    analysisTask = task
                    ShotRaterBackgroundManager.shared.setAnalysisTask(for: viewModel.selectedShotType, task: task)
                }
            },
            onRetry: {
                // Not used - errors go to results stage
            },
            onCancel: {
                validationTask?.cancel()
                validationTask = nil
                isValidating = false
                viewModel.reset()
                flowState.goBack()
            },
            onBackground: {
                runInBackground = true
                dismiss()
            },
            showsEmbeddedHeader: false
        )
    }

    private func shotAnalysisView(flowState: AIFlowState) -> some View {
        ShotRaterProcessingView(
            shotType: viewModel.selectedShotType,
            onBackground: {
                runInBackground = true
                dismiss()
            }
        )
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

    // MARK: - Validation Execution

    @MainActor
    private func executeValidation(flowState: AIFlowState) async {
        guard let videoURL = flowState.getData(for: "captured-video") as? URL else {
            viewModel.currentError = AIAnalyzerError.aiProcessingFailed("Missing video data")
            isValidating = false
            if let resultsStage = flowState.flow.stages.first(where: { $0.id == "results" }) {
                flowState.currentStage = resultsStage
            }
            return
        }

        do {
            let validation = try await ShotRaterService.validateShot(videoURL: videoURL)
            viewModel.validationResult = validation
            isValidating = false

            if !validation.is_valid {
                let reason = validation.reason ?? "Please record a valid hockey shot"
                viewModel.currentError = AIAnalyzerError.invalidContent(.aiDetectedInvalidContent(reason))
                if !runInBackground, let resultsStage = flowState.flow.stages.first(where: { $0.id == "results" }) {
                    flowState.currentStage = resultsStage
                }
            } else if runInBackground {
                analysisTask?.cancel()
                let task = Task { @MainActor in
                    await viewModel.analyzeShot(
                        videoURL: videoURL,
                        shotType: viewModel.selectedShotType
                    )
                }
                analysisTask = task
                ShotRaterBackgroundManager.shared.setAnalysisTask(for: viewModel.selectedShotType, task: task)
            }
        } catch {
            viewModel.currentError = AIAnalyzerError.from(error)
            isValidating = false
            if !runInBackground, let resultsStage = flowState.flow.stages.first(where: { $0.id == "results" }) {
                flowState.currentStage = resultsStage
            }
        }

        validationTask = nil
    }

    private func handleStageChange(_ stageId: String?, flowState: AIFlowState) {
        guard let stageId else { return }

        if stageId == "validation" {
            beginValidation(flowState: flowState)
        } else if stageId != "analysis" {
            validationTask?.cancel()
            validationTask = nil
        }
    }

    private func beginValidation(flowState: AIFlowState) {
        viewModel.validationResult = nil
        viewModel.currentError = nil
        isValidating = true

        validationTask?.cancel()
        validationTask = Task { await executeValidation(flowState: flowState) }
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
}

// MARK: - Shot Rater Flow Definition
/// Flow definition for Shot Rater using AIFlowContainer
struct ShotRaterFlowDefinition: AIFlowDefinition {
    let id = "shot-rater"
    let name = "Shot Rater"
    let allowsBackNavigation = true
    let showsProgress = true
    let preSelectedShotType: ShotType?

    init(preSelectedShotType: ShotType? = nil) {
        self.preSelectedShotType = preSelectedShotType
    }

    var stages: [any AIFlowStage] {
        var stageList: [any AIFlowStage] = []

        // Phone setup tutorial is now shown just-in-time when user taps "Record Video"

        // Include selection stage if no shot type is pre-selected
        if preSelectedShotType == nil {
            stageList.append(
                SelectionStage(
                    id: "shot-selection",
                    title: "Select Shot Type",
                    subtitle: "",
                    options: ShotType.allCases.map { shotType in
                        SelectionStage.SelectionOption(
                            id: shotType.rawValue.lowercased().replacingOccurrences(of: " ", with: "-"),
                            title: shotType.displayName,
                            subtitle: nil,   // remove descriptive text under names
                            icon: nil        // remove icons from selection list
                        )
                    }
                )
            )
        }

        // Video Capture
        stageList.append(
            MediaCaptureStage(
                id: "video-capture",
                title: "Record Shot",
                subtitle: "",
                mediaTypes: [.video],
                maxItems: 1,
                minItems: 1,
                instructions: "Position camera 10-15ft to the side at waist height",
                maxVideos: 1
            )
        )

        // Validation Stage
        stageList.append(
            ProcessingStage(
                id: "validation",
                title: "Validating Shot",
                subtitle: "",
                processingMessage: "Checking for valid hockey shot...",
                showsHeader: true,
                showsCancelButton: true
            )
        )

        // Analysis Stage
        stageList.append(
            ProcessingStage(
                id: "analysis",
                title: "Analyzing Shot",
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
    ShotRaterView()
        .preferredColorScheme(.dark)
}
