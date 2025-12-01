import SwiftUI

// MARK: - AI Coach Flow Wrapper
class AICoachFlowWrapper: ObservableObject {
    let flow: AICoachAnalysisFlow

    init(shotType: ShotType? = nil) {
        self.flow = AICoachFlowConfig.buildFlow(for: shotType)
    }
}

// MARK: - AI Coach Flow View
struct AICoachFlowView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    @StateObject private var flowWrapper: AICoachFlowWrapper
    @State private var showCards = false
    @State private var selectedCardId: String? = nil
    @State private var isValidating = false
    @State private var validationResult: AIValidationService.ValidationResponse?
    @State private var validationError: AIAnalyzerError?
    @State private var validationTask: Task<Void, Never>? = nil
    @State private var analysisTask: Task<Void, Never>? = nil
    // Monetization gate state (gate on the page before sending to AI)
    @State private var shouldActivateGate = false
    @State private var gateTriggerId = UUID().uuidString
    @State private var monetizationGranted = false
    @State private var pendingMonetizedAction: (() -> Void)?
    @State private var interceptedValidationNav = false
    // Resume state
    @State private var showResumePrompt = false
    @State private var savedStateToResume: AICoachSavedState? = nil

    // Progress estimation
    // Smart progress estimator removed; using simple time-based progress

    // Optional pre-selected shot type
    let preSelectedShotType: ShotType?

    // Completion handler for analysis result
    let onAnalysisComplete: ((AICoachAnalysisResult) -> Void)?

    init(preSelectedShotType: ShotType? = nil,
         onAnalysisComplete: ((AICoachAnalysisResult) -> Void)? = nil) {
        self.preSelectedShotType = preSelectedShotType
        self.onAnalysisComplete = onAnalysisComplete
        self._flowWrapper = StateObject(wrappedValue: AICoachFlowWrapper(shotType: preSelectedShotType))
    }
    
    var body: some View {
        AIFlowContainer(flow: flowWrapper.flow) { flowState in
            ZStack {
                // Custom stage handling for AI Coach analysis
                if let stage = flowState.currentStage {
                    switch stage.id {
                    case "shot-type-selection":
                        if let selectionStage = stage as? SelectionStage {
                            shotTypeSelectionView(selectionStage: selectionStage, flowState: flowState)
                        }

                    case "player-profile":
                        PlayerProfileStageView(flowState: flowState)

                    case "phone-setup-tutorial":
                        // Tutorial stage with custom full-screen UI (no container)
                        PhoneSetupTutorialView(flowContext: .aiCoach) { context in
                            // Proceed to next stage (tutorial handles dismiss logic)
                            flowState.proceed()
                        }

                    case "front-net-capture":
                        FrontNetVideoCaptureView(flowState: flowState)

                    case "side-angle-capture":
                        SideAngleVideoCaptureView(
                            flowState: flowState,
                            requestMonetizedAccess: { (action: @escaping () -> Void) in
                                triggerMonetizationGate {
                                    action()
                                }
                            }
                        )

                    case "shot-validation":
                        SharedValidationView(
                            isValidating: $isValidating,
                            validationResult: $validationResult,
                            validationError: $validationError,
                            featureName: "AI Coach",
                            onSuccess: {
                                flowState.proceed()
                            },
                            onRetry: {
                                restartValidation(flowState: flowState)
                            },
                            onCancel: {
                                // Cancel local task(s) and upstream AI requests
                                validationTask?.cancel()
                                validationTask = nil
                                AIAnalysisFacade.cancelActiveRequests()
                                flowState.goBack()
                            }
                        )

                    case "ai-coach-processing":
                        if let processingStage = stage as? ProcessingStage {
                            AICoachFlowProcessingView(
                                processingMessage: processingStage.processingMessage
                            )
                                .onAppear {
                                    analysisTask?.cancel()
                                    analysisTask = Task { @MainActor in
                                        await executeAnalysis(flowState: flowState)
                                    }
                                }
                        }

                    case "ai-coach-results":
                        if let validationError = flowState.validationError {
                            AIServiceErrorView(
                                errorType: AIServiceErrorType.from(analyzerError: validationError),
                                onRetry: {
                                    flowState.validationError = nil
                                    flowState.restart()
                                },
                                onDismiss: {
                                    flowState.restart()
                                }
                            )
                        } else if let networkError = flowState.error {
                            AIServiceErrorView(
                                errorType: AIServiceErrorType.from(networkError),
                                onRetry: {
                                    flowState.error = nil
                                    flowState.restart()
                                },
                                onDismiss: {
                                    flowState.restart()
                                }
                            )
                        } else if let result = flowState.getData(for: "ai-coach-analysis-result") as? AICoachAnalysisResult {
                            AICoachFlowResultsView(
                                analysisResult: result,
                                onAnalyzeNext: {
                                    flowState.restart()
                                },
                                onExit: {
                                    onAnalysisComplete?(result)
                                    dismiss()
                                }
                            )
                            .onAppear {
                                onAnalysisComplete?(result)
                            }
                        } else {
                            Text("No results available")
                                .foregroundColor(theme.error)
                        }

                    default:
                        EmptyView()
                    }
                }
            }
            // Attach paywall gating to this view so we can trigger it right before validation
            .monetizationGate(
                featureIdentifier: "ai_analysis",
                source: "ai_coach",
                activatedProgrammatically: $shouldActivateGate,
                triggerId: gateTriggerId,
                consumeAccess: true,
                onAccessGranted: {
                    monetizationGranted = true
                    if interceptedValidationNav {
                        // We intercepted navigation to validation; now proceed
                        interceptedValidationNav = false
                        flowState.proceed()
                    } else {
                        let action = pendingMonetizedAction
                        pendingMonetizedAction = nil
                        action?()
                    }
                },
                onDismissOrCancel: { _ in
                    // User closed paywall without purchasing
                    pendingMonetizedAction = nil
                    monetizationGranted = false
                    isValidating = false
                    validationTask?.cancel()
                    validationTask = nil
                    if flowState.currentStage?.id == "shot-validation" || interceptedValidationNav {
                        flowState.goBack()
                        interceptedValidationNav = false
                    }
                }
            )
            .onAppear {
                // Store the pre-selected shot type in flow state if provided
                if let shotType = preSelectedShotType {
                    flowState.setData(shotType, for: "selected-shot-type")
                }
            }
            .onChange(of: flowState.currentStage?.id) { newStage in
                handleStageChange(newStage, flowState: flowState)
                // Track funnel progress
                if let stageId = newStage {
                    trackFunnelProgress(for: stageId)
                    // Save state at key checkpoints
                    saveFlowStateIfNeeded(stageId: stageId, flowState: flowState)
                }
            }
            .onAppear {
                // Check for saved state to resume
                checkForSavedState(flowState: flowState)

                // Track funnel start
                AnalyticsManager.shared.trackFunnelStep(
                    funnel: "ai_coach",
                    step: "started",
                    stepNumber: 0,
                    totalSteps: 6
                )

                // Track initial stage (onChange doesn't fire for initial state)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let stageId = flowState.currentStage?.id {
                        trackFunnelProgress(for: stageId)
                    }
                }
            }
            .sheet(isPresented: $showResumePrompt) {
                resumePromptSheet(flowState: flowState)
            }
            .onDisappear {
                validationTask?.cancel()
                validationTask = nil
                analysisTask?.cancel()
                analysisTask = nil
            }
        }
        .overlay(
            GlobalPresentationLayer()
                .environmentObject(NoticeCenter.shared)
                .zIndex(10000)
        )
        // Respond to global cancel from header Cancel
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AIFlowCancel"))) { _ in
            // Best-effort cancellation: stop tasks and tell AI service to cancel
            validationTask?.cancel()
            validationTask = nil
            analysisTask?.cancel()
            analysisTask = nil
            AIAnalysisFacade.cancelActiveRequests()
            dismiss()
        }
    }

    // MARK: - Shot Type Selection View
    private func shotTypeSelectionView(selectionStage: SelectionStage, flowState: AIFlowState) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Removed the "Select Shot" text - just spacing at top
                    Spacer()
                        .frame(height: theme.spacing.lg)

                    // Shot type options with staggered animation
                    VStack(spacing: theme.spacing.md) {
                        ForEach(Array(selectionStage.options.enumerated()), id: \.element.id) { index, option in
                            shotTypeCard(option: option, flowState: flowState, stage: selectionStage)
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
                .padding(.bottom, 120)
            }

            // Bottom button
            bottomButton(for: flowState)
        }
        .onAppear {
            // Trigger animation after a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showCards = true
            }
        }
        .onDisappear {
            showCards = false
        }
    }
    
    private func shotTypeCard(option: SelectionStage.SelectionOption, flowState: AIFlowState, stage: SelectionStage) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCardId = option.id
                flowState.setData(option.id, for: stage.id)

                // Store the selected shot type for later use
                let shotType: ShotType = {
                    switch option.id {
                    case "wrist": return .wristShot
                    case "slap": return .slapShot
                    case "backhand": return .backhandShot
                    case "snapshot": return .snapShot
                    default: return .wristShot
                    }
                }()
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

                // Radio button indicator
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
    
    private func bottomButton(for flowState: AIFlowState) -> some View {
        let selectedId = flowState.getData(for: "shot-type-selection") as? String
        let shotTypeName: String = {
            switch selectedId {
            case "wrist": return "Wrist Shot"
            case "slap": return "Slap Shot"
            case "backhand": return "Backhand"
            case "snapshot": return "Snap Shot"
            default: return "Shot"
            }
        }()
        
        return AppButton(
            title: selectedId != nil ? "Analyze \(shotTypeName)" : "Select Shot",
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
    
    // MARK: - Execute Validation
    @MainActor
    private func executeValidation(flowState: AIFlowState) async {
        // Get both video URLs
        guard let frontNetData = flowState.getData(for: "front-net-capture") as? MediaStageData,
              let frontNetURL = frontNetData.videos.first,
              let sideAngleData = flowState.getData(for: "side-angle-capture") as? MediaStageData,
              let sideAngleURL = sideAngleData.videos.first else {
            print("❌ [AICoachProcessing] Missing video data")
            await MainActor.run {
                validationError = AIAnalyzerError.aiProcessingFailed("Both angle videos are required")
                isValidating = false
            }
            return
        }

        print("📹 [AICoachProcessing] Found both videos")
        print("📹 Front net: \(frontNetURL)")
        print("📹 Side angle: \(sideAngleURL)")

        // Run validation using AICoachFlowService
        do {
            print("🔍 [AICoachProcessing] Starting shot validation for both angles...")
            let validation = try await AICoachFlowService.validateShots(videoURLs: [sideAngleURL, frontNetURL])
            print("🔍 [AICoachProcessing] Validation complete - Valid: \(validation.is_valid)")

            // Validation completed - use timing for estimation
            // estimator removed

            await MainActor.run {
                // Store validation result in flow state first
                flowState.setData(validation, for: "shot-validation-result")

                if !validation.is_valid {
                    print("❌ [AICoachProcessing] Invalid hockey shot detected - stopping")
                    let errorReason = validation.reason ?? "Please record a valid hockey shot from both angles"
                    validationError = AIAnalyzerError.invalidContent(.aiDetectedInvalidContent(errorReason))
                    flowState.validationError = AIAnalyzerError.invalidContent(.aiDetectedInvalidContent(errorReason))
                    flowState.isProcessing = false
                    flowState.setData(nil, for: "ai-coach-analysis-result")
                    isValidating = false
                    // Skip to results stage to show error
                    if let resultsStage = flowState.flow.stages.first(where: { $0.id == "ai-coach-results" }) {
                        flowState.currentStage = resultsStage
                    }
                } else {
                    print("✅ [AICoachProcessing] Valid shot detected, proceeding to analysis...")
                    // Set validation result which will trigger SharedValidationView's onChange
                    validationResult = validation
                    // Set isValidating to false so the view properly updates
                    isValidating = false
                    print("🔄 [AICoachProcessing] Set validationResult and isValidating=false")
                    // The onSuccess callback in SharedValidationView will call flowState.proceed()
                }
            }
        } catch {
            print("❌ [AICoachProcessing] Validation failed: \(error)")
            await MainActor.run {
                validationError = AIAnalyzerError.from(error)
                isValidating = false
                // estimator removed
            }
        }

        // Reset gate flag so a future attempt re-gates
        monetizationGranted = false
        validationTask = nil
    }

    private func handleStageChange(_ stageId: String?, flowState: AIFlowState) {
        guard let stageId else { return }

        if stageId == "shot-validation" {
            // Ensure we do not show validation unless paywall is granted
            if !monetizationGranted {
                // Intercept: step back and show paywall, then re-proceed on grant
                interceptedValidationNav = true
                flowState.goBack()
                triggerMonetizationGate { /* on grant proceed handled in onAccessGranted */ }
                return
            }
            beginValidation(flowState: flowState)
        } else {
            validationTask?.cancel()
            validationTask = nil
        }
    }

    private func beginValidation(flowState: AIFlowState) {
        validationTask?.cancel()

        validationResult = nil
        validationError = nil
        isValidating = true
        validationTask = Task { await executeValidation(flowState: flowState) }
    }

    private func restartValidation(flowState: AIFlowState) {
        beginValidation(flowState: flowState)
    }

    // MARK: - Monetization Helpers
    private func triggerMonetizationGate(action: @escaping () -> Void) {
        pendingMonetizedAction = action
        gateTriggerId = UUID().uuidString
        shouldActivateGate = true
    }

    // MARK: - Execute Analysis
    @MainActor
    private func executeAnalysis(flowState: AIFlowState) async {
        // Get both video URLs
        guard let frontNetData = flowState.getData(for: "front-net-capture") as? MediaStageData,
              let frontNetURL = frontNetData.videos.first,
              let sideAngleData = flowState.getData(for: "side-angle-capture") as? MediaStageData,
              let sideAngleURL = sideAngleData.videos.first else {
            print("❌ [AICoachProcessing] Missing video data")
            await MainActor.run {
                flowState.error = AIAnalyzerError.aiProcessingFailed("Both angle videos are required")
                flowState.isProcessing = false
            }
            return
        }
        
        // Get player profile
        guard let playerProfile = flowState.getData(for: "player-profile") as? PlayerProfile else {
            print("❌ [AICoachProcessing] Missing player profile")
            await MainActor.run {
                flowState.error = AIAnalyzerError.aiProcessingFailed("Missing player profile")
                flowState.isProcessing = false
            }
            return
        }
        
        // Get selected shot type
        let shotType = flowState.getData(for: "selected-shot-type") as? ShotType ?? .wristShot
        
        print("📹 [AICoachProcessing] Found both videos and profile")
        print("📹 Front net: \(frontNetURL)")
        print("📹 Side angle: \(sideAngleURL)")
        
        // Validation already done in previous stage, proceed directly to analysis
        do {
            print("✅ [AICoachProcessing] Starting full analysis...")
            
            let result = try await AICoachFlowService.analyzeShot(
                frontNetVideoURL: frontNetURL,
                sideAngleVideoURL: sideAngleURL,
                shotType: shotType,
                playerProfile: playerProfile
            )
            
            print("✅ [AICoachProcessing] Analysis complete")
            await MainActor.run {
                // estimator removed
                flowState.setData(result, for: "ai-coach-analysis-result")
                flowState.isProcessing = false
                flowState.proceed()
            }
            
        } catch {
            print("❌ [AICoachProcessing] Error: \(error)")
            await MainActor.run {
                // Convert network errors to unified AIAnalyzerError and store in flowState.error
                flowState.error = AIAnalyzerError.from(error)
                flowState.isProcessing = false
                flowState.proceed() // Go to results which will show error
            }
        }
    }

    // MARK: - Funnel Tracking

    private func trackFunnelProgress(for stageId: String) {
        let (stepName, stepNumber) = mapStageToFunnel(stageId)

        // Skip tracking for optional/internal steps (step 0)
        guard stepNumber > 0 else { return }

        AnalyticsManager.shared.trackFunnelStep(
            funnel: "ai_coach",
            step: stepName,
            stepNumber: stepNumber,
            totalSteps: 6
        )

        // Track completion
        if stageId == "ai-coach-results" {
            AnalyticsManager.shared.trackFunnelCompleted(
                funnel: "ai_coach",
                totalSteps: 6
            )
        }
    }

    private func mapStageToFunnel(_ stageId: String) -> (String, Int) {
        switch stageId {
        case "shot-type-selection":
            return ("shot_type_selection", 1)
        case "player-profile":
            return ("player_profile", 2)
        case "phone-setup-tutorial":
            // Skip tutorial - it's optional and not always shown
            return ("phone_setup_tutorial", 0)
        case "front-net-capture":
            return ("front_net_capture", 3)
        case "side-angle-capture":
            return ("side_angle_capture", 4)
        case "shot-validation":
            // Skip validation - it's an internal processing step
            return ("shot_validation", 0)
        case "ai-coach-processing":
            return ("analysis_processing", 5)
        case "ai-coach-results":
            return ("results", 6)
        default:
            return ("unknown", 0)
        }
    }

    // MARK: - Flow State Persistence

    /// Check for saved state and show resume prompt if found
    private func checkForSavedState(flowState: AIFlowState) {
        if let savedState = FlowStateManager.shared.load(AICoachSavedState.self) {
            savedStateToResume = savedState
            showResumePrompt = true
            print("📂 [AICoachFlowView] Found saved state at stage: \(savedState.currentStageId)")
        }
    }

    /// Save flow state at key checkpoints
    private func saveFlowStateIfNeeded(stageId: String, flowState: AIFlowState) {
        // Save state after meaningful progress (not on processing/results/validation)
        let savableStages = ["shot-type-selection", "player-profile", "front-net-capture", "side-angle-capture"]

        guard savableStages.contains(stageId) else { return }

        let state = AICoachSavedState.from(
            currentStageId: stageId,
            flowState: flowState
        )

        FlowStateManager.shared.save(state)
    }

    /// Resume from saved state
    private func resumeFromSavedState(_ savedState: AICoachSavedState, flowState: AIFlowState) {
        print("▶️ [AICoachFlowView] Resuming from stage: \(savedState.currentStageId)")

        // Restore shot type selection
        if let shotType = savedState.selectedShotType {
            flowState.setData(shotType, for: "selected-shot-type")
            // Also set the string selection for the UI
            let shotId: String = {
                switch shotType {
                case .wristShot: return "wrist"
                case .slapShot: return "slap"
                case .backhandShot: return "backhand"
                case .snapShot: return "snapshot"
                }
            }()
            flowState.setData(shotId, for: "shot-type-selection")
        }

        // Restore player profile
        if let profile = savedState.playerProfile {
            flowState.setData(profile, for: "player-profile")
        }

        // Restore front net video
        if let frontPath = savedState.frontNetVideoPath,
           let videoURL = FlowStateManager.shared.getMediaURL(for: frontPath) {
            let mediaData = MediaStageData(videos: [videoURL])
            flowState.setData(mediaData, for: "front-net-capture")
        }

        // Restore side angle video
        if let sidePath = savedState.sideAngleVideoPath,
           let videoURL = FlowStateManager.shared.getMediaURL(for: sidePath) {
            let mediaData = MediaStageData(videos: [videoURL])
            flowState.setData(mediaData, for: "side-angle-capture")
        }

        // Navigate to the saved stage
        if let targetStage = flowState.flow.stages.first(where: { $0.id == savedState.currentStageId }) {
            flowState.currentStage = targetStage
        }

        // Clear the saved state since we're resuming
        FlowStateManager.shared.clear(.aiCoach)
    }

    /// Clear saved state on completion
    private func clearSavedStateOnCompletion() {
        FlowStateManager.shared.clear(.aiCoach)
    }

    /// Resume prompt sheet UI
    @ViewBuilder
    private func resumePromptSheet(flowState: AIFlowState) -> some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(theme.primary)

                Text("Continue Where You Left Off?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.text)

                if let savedState = savedStateToResume {
                    let stageName = FlowStateManager.shared.getReadableStageInfo(for: .aiCoach) ?? savedState.currentStageId
                    let timeAgo = FlowStateManager.shared.formattedSaveTime(for: .aiCoach) ?? "recently"

                    Text("You were at \"\(stageName)\" (\(timeAgo))")
                        .font(.system(size: 15))
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 32)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button(action: {
                    showResumePrompt = false
                    if let savedState = savedStateToResume {
                        resumeFromSavedState(savedState, flowState: flowState)
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Continue")
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.primary)
                    .cornerRadius(theme.cornerRadius)
                }

                Button(action: {
                    showResumePrompt = false
                    FlowStateManager.shared.clear(.aiCoach)
                    savedStateToResume = nil
                }) {
                    Text("Start Fresh")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(theme.background)
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
    }
}
