import SwiftUI

// MARK: - Stick Analyzer Flow View
/// Main container view for the Stick Analyzer flow - EXACTLY like AICoachFlow
struct StickAnalyzerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    @StateObject private var flowHolder: StickAnalyzerFlowHolder
    @StateObject private var viewModel = StickAnalyzerViewModel()
    @State private var isValidating = false
    @State private var validationResult: AIValidationService.ValidationResponse?
    @State private var validationError: AIAnalyzerError?
    @State private var showCards = false
    @State private var selectedCardId: String? = nil
    @State private var validationTask: Task<Void, Never>? = nil
    // Monetization gate state (gate before validation just like Shot Rater)
    @State private var shouldActivateGate = false
    @State private var gateTriggerId = UUID().uuidString
    @State private var monetizationGranted = false
    @State private var pendingMonetizedAction: (() -> Void)?
    @State private var interceptedValidationNav = false
    
    let onAnalysisComplete: ((StickAnalysisResult) -> Void)?

    // Smart progress estimator removed; using simple time-based progress
    
    init(onAnalysisComplete: ((StickAnalysisResult) -> Void)? = nil) {
        self.onAnalysisComplete = onAnalysisComplete
        self._flowHolder = StateObject(wrappedValue: StickAnalyzerFlowHolder())
    }
    
    var body: some View {
        AIFlowContainer(flow: flowHolder.flow) { flowState in
            ZStack {
                if let stage = flowState.currentStage {
                    switch stage.id {
                    case "player-profile":
                        PlayerProfileStageView(flowState: flowState)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .onReceive(flowState.$stageData) { data in
                                if let profile = data["player-profile"] as? PlayerProfile {
                                    viewModel.setPlayerProfile(profile)
                                }
                            }

                    case "phone-setup-tutorial":
                        PhoneSetupTutorialView(flowContext: .stickAnalyzer) { context in
                            flowState.proceed()
                        }
                        .transition(.opacity)

                    case "stick-details":
                        StickDetailsInputView(flowState: flowState, viewModel: viewModel)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))

                    case "shot-video-capture":
                        shotVideoView(flowState: flowState)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))

                    case "shooting-priority", "primary-shot", "shooting-zone":
                        if let selectionStage = stage as? SelectionStage {
                            shootingPreferenceView(selectionStage: selectionStage, flowState: flowState)
                                .id(selectionStage.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }

                    case "stick-validation":
                        SharedValidationView(
                            isValidating: $isValidating,
                            validationResult: $validationResult,
                            validationError: .constant(nil),
                            featureName: "Stick Analyzer",
                            onSuccess: {
                                flowState.proceed()
                            },
                            onRetry: {
                                // Not used - errors go to results stage
                            },
                            onCancel: {
                                // Cancel upstream AI and reset local state
                                AIAnalysisFacade.cancelActiveRequests()
                                validationTask?.cancel()
                                validationTask = nil
                                viewModel.reset()
                                flowState.goBack()
                            }
                        )
                        .transition(.opacity)

                    case "stick-analysis-processing":
                        processingView(flowState: flowState)
                            .transition(.opacity)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    viewModel.performAnalysisWithoutValidation()
                                }
                            }
                            .onReceive(viewModel.$analysisResult) { result in
                                if result != nil {
                                    flowState.proceed()
                                }
                            }
                            .onReceive(viewModel.$error) { error in
                                if error != nil {
                                    flowState.proceed()
                                }
                            }

                    case "stick-analysis-results":
                        Group {
                            if let error = viewModel.error {
                                AIAnalysisErrorView(
                                    error: error,
                                    featureName: "Stick Analyzer",
                                    onRetry: {
                                        viewModel.error = nil
                                        flowState.goBack()
                                        viewModel.performAnalysis()
                                    },
                                    onCancel: {
                                        dismiss()
                                    }
                                )
                            } else if viewModel.analysisResult != nil {
                                StickAnalyzerResultsView(
                                    viewModel: viewModel,
                                    onComplete: { result in
                                        onAnalysisComplete?(result)
                                        dismiss()
                                    }
                                )
                            } else {
                                ProgressView("Loading results...")
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                        .transition(.opacity)

                    default:
                        EmptyView()
                    }
                }
            }
            // Attach monetization gate here so we can trigger right before validation
            .monetizationGate(
                featureIdentifier: "ai_analysis",
                source: "equipment",
                activatedProgrammatically: $shouldActivateGate,
                triggerId: gateTriggerId,
                consumeAccess: true,
                onAccessGranted: {
                    monetizationGranted = true
                    if interceptedValidationNav {
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
                    if flowState.currentStage?.id == "stick-validation" || interceptedValidationNav {
                        flowState.goBack()
                        interceptedValidationNav = false
                    }
                }
            )
            .onChange(of: flowState.currentStage?.id) { newStage in
                handleStageChange(newStage, flowState: flowState)
                // Track funnel progress
                if let stageId = newStage {
                    trackFunnelProgress(for: stageId)
                }
            }
            .onAppear {
                // Track funnel start
                AnalyticsManager.shared.trackFunnelStep(
                    funnel: "stick_analyzer",
                    step: "started",
                    stepNumber: 0,
                    totalSteps: 7
                )

                // Track initial stage (onChange doesn't fire for initial state)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let stageId = flowState.currentStage?.id {
                        trackFunnelProgress(for: stageId)
                    }
                }
            }
            .onDisappear {
                validationTask?.cancel()
                validationTask = nil
            }
        }
        .overlay(
            GlobalPresentationLayer()
                .environmentObject(NoticeCenter.shared)
                .zIndex(10000)
        )
        .onAppear {
            print("🏒 [StickAnalyzerView] Flow started")
        }
        .onDisappear {
            viewModel.cleanup()
            validationTask?.cancel()
            validationTask = nil
        }
        // Respond to global cancel from header Cancel
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AIFlowCancel"))) { _ in
            validationTask?.cancel()
            validationTask = nil
            AIAnalysisFacade.cancelActiveRequests()
            dismiss()
        }
        .trackScreen("stick_analyzer_flow")
    }

    // MARK: - Shooting Preference Selection View
private func shootingPreferenceView(selectionStage: SelectionStage, flowState: AIFlowState) -> some View {
        ShootingPreferenceSelectionView(
            selectionStage: selectionStage,
            flowState: flowState,
            viewModel: viewModel,
            requestMonetizedAccess: { (action: @escaping () -> Void) in
                // Use the flow-level gate function
                triggerMonetizationGate { action() }
            }
        )
    }

    // MARK: - Processing View
    private func processingView(flowState: AIFlowState) -> some View {
        // Simple processing view - consistent with Shot Coach / Shot Rater
        StickProcessingView(
            primaryMessage: viewModel.processingMessage,
            contextChips: makeContextChips()
        )
        // Removed long-wait hint to keep UI cleaner and consistent
    }

    private func makeContextChips() -> [String]? {
        guard let q = viewModel.questionnaire else { return nil }
        return [
            "Priority: \(q.priorityFocus.rawValue)",
            "Shot: \(q.primaryShot.rawValue)",
            "Zone: \(q.shootingZone.rawValue)"
        ]
    }
}

// MARK: - Shooting Preference Selection View
struct ShootingPreferenceSelectionView: View {
    let selectionStage: SelectionStage
    let flowState: AIFlowState
    @ObservedObject var viewModel: StickAnalyzerViewModel
    @Environment(\.theme) var theme
    @State private var selectedOption: String? = nil
    @State private var showCards = false
    // Gate trigger provided by parent flow
    var requestMonetizedAccess: ((@escaping () -> Void) -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Question content
            ScrollView {
                VStack(spacing: 16) {
                    // Question text
                    Text(selectionStage.subtitle)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(theme.text)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 20)
                    
                    // Options with staggered animation
                    VStack(spacing: 16) {
                        ForEach(Array(selectionStage.options.enumerated()), id: \.element.id) { index, option in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedOption = option.id
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
                                        .stroke(selectedOption == option.id ? theme.primary : theme.divider, lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Circle()
                                                .fill(theme.primary)
                                                .frame(width: 16, height: 16)
                                                .opacity(selectedOption == option.id ? 1 : 0)
                                        )
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                                        .fill(theme.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                                        .stroke(selectedOption == option.id ? theme.primary : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .scaleEffect(showCards ? 1 : 0.85)
                            .opacity(showCards ? 1 : 0)
                            .offset(y: showCards ? 0 : 20)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                                .delay(Double(index) * 0.08),
                                value: showCards
                            )
                            .scaleEffect(selectedOption == option.id ? 1.02 : 1.0)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 100) // Make room for bottom button
            }
            
            // Bottom action button - only enabled when selection is made
            VStack {
                Button(action: {
                    guard let selected = selectedOption else { return }
                    
                    // Store selection in flow state
                    flowState.setData(selected, for: selectionStage.id)
                    
                    // When last question is answered, compile questionnaire from flow data
                    if selectionStage.id == "shooting-zone" {
                        // Get all selections from flow data
                        let priorityId = flowState.getData(for: "shooting-priority") as? String ?? ""
                        let shotId = flowState.getData(for: "primary-shot") as? String ?? ""
                        
                        let questionnaire = ShootingQuestionnaire(
                            priorityFocus: mapPriorityFocus(priorityId),
                            primaryShot: mapPrimaryShot(shotId),
                            shootingZone: mapShootingZone(selected)
                        )
                        viewModel.setQuestionnaire(questionnaire)
                        // Gate exactly here (last page before analyzing)
                        let proceed = { flowState.proceed() }
                        if let gate = requestMonetizedAccess {
                            gate { proceed() }
                        } else {
                            proceed()
                        }
                    } else {
                        // Not the last question; just proceed
                        flowState.proceed()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                        Text(selectionStage.id == "shooting-zone" ? "Continue" : "Next")
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(selectedOption != nil ? .black : theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .fill(selectedOption != nil ? theme.primary : theme.surface)
                    )
                }
                .disabled(selectedOption == nil)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                Color.clear
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .onAppear {
            // Reset state to ensure animations trigger on each new question
            showCards = false

            // Trigger animation after a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    showCards = true
                }
            }
        }
        .onDisappear {
            showCards = false
        }
    }
    
    // MARK: - Helper Methods
    private func mapPriorityFocus(_ id: String) -> PriorityFocus {
        switch id {
        case "power": return .power
        case "accuracy": return .accuracy
        case "balance": return .balance
        default: return .balance
        }
    }
    
    private func mapPrimaryShot(_ id: String) -> PrimaryShotType {
        switch id {
        case "wrist": return .wrist
        case "slap": return .slap
        case "snap": return .snap
        case "backhand": return .backhand
        default: return .wrist
        }
    }
    
    private func mapShootingZone(_ id: String) -> ShootingZone {
        switch id {
        case "point": return .point
        case "slot": return .slot
        case "close": return .closeRange
        case "varies": return .varies
        default: return .varies
        }
    }
}

// MARK: - Main Flow View Extension
extension StickAnalyzerView {
    // MARK: - Single Shot Video View
    private func shotVideoView(flowState: AIFlowState) -> some View {
        ShotVideoView(
            flowState: flowState,
            viewModel: viewModel,
            requestMonetizedAccess: { (action: @escaping () -> Void) in
                triggerMonetizationGate { action() }
            }
        )
    }
}

// MARK: - Shot Video View
struct ShotVideoView: View {
    @ObservedObject var flowState: AIFlowState
    @ObservedObject var viewModel: StickAnalyzerViewModel
    @Environment(\.theme) var theme
    @State private var showVideoInstructions = false
    @State private var showVideoUpload = false
    // Optional paywall trigger provided by parent
    var requestMonetizedAccess: ((@escaping () -> Void) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Demo Image using AIExampleMediaView with Shoting_Side_Angle asset
                    AIExampleMediaView.image(
                        "Shoting_Side_Angle",
                        actionTitle: "Side View",
                        instructions: "Position camera 10-20ft to the side at chest height. Capture full body motion from setup to follow-through with clear view of stick and puck."
                    )
                    .padding(.horizontal, 20)
                    .scaleEffect(showVideoInstructions ? 1 : 0.9)
                    .opacity(showVideoInstructions ? 1 : 0)
                    .offset(y: showVideoInstructions ? 0 : 30)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                        .delay(0.1),
                        value: showVideoInstructions
                    )
                    
                    // Shot Upload
                    MediaUploadView(
                        configuration: MediaUploadView.Configuration(
                            title: "Shot Recording",
                            description: viewModel.shotVideoURL != nil ? "Tap to preview • Replace to re-record" : "Show us your shooting technique",
                            instructions: "• Any shot type (wrist, slap, snap, backhand)\n• Position camera to your side\n• Show full technique\n• Include puck release\n• Good lighting helps analysis",
                            mediaType: .video,
                            buttonTitle: "Start Recording",
                            showSourceSelector: true,
                            showTrimmerImmediately: true,
                            preCameraGuideBuilder: { onComplete in
                                AnyView(
                                    PhoneSetupTutorialView(flowContext: .stickAnalyzer) { _ in
                                        onComplete()
                                    }
                                )
                            },
                            primaryColor: Color.green,
                            backgroundColor: theme.background,
                            surfaceColor: theme.surface,
                            textColor: theme.text,
                            textSecondaryColor: theme.textSecondary,
                            successColor: theme.success,
                            cornerRadius: theme.cornerRadius
                        ),
                        selectedVideoURL: Binding(
                            get: { viewModel.shotVideoURL },
                            set: { url in
                                // Don't set here, let the completion handler do it
                            }
                        ),
                        featureType: .stickAnalyzer
                    ) { url in
                        viewModel.setShotVideo(url)
                        flowState.setData(url, for: "shotVideoURL")
                    }
                    .padding(.horizontal, 20)
                    .scaleEffect(showVideoUpload ? 1 : 0.9)
                    .opacity(showVideoUpload ? 1 : 0)
                    .offset(y: showVideoUpload ? 0 : 30)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                        .delay(0.25),
                        value: showVideoUpload
                    )
                }
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            
            // Bottom Continue Button
            VStack {
                AppButton(
                    title: "Continue",
                    action: {
                        guard viewModel.shotVideoURL != nil else { return }
                        // Store and proceed — gating now occurs on the last question page
                        flowState.setData(viewModel.shotVideoURL, for: "shot-video-capture")
                        flowState.proceed()
                    },
                    style: .primary,
                    size: .large,
                    icon: "arrow.right",
                    isDisabled: viewModel.shotVideoURL == nil
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                theme.background
                    .opacity(0.95)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .onAppear {
            // Reset states first to ensure animation triggers
            showVideoInstructions = false
            showVideoUpload = false

            // Trigger animations in sequence
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation {
                    showVideoInstructions = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    showVideoUpload = true
                }
            }
        }
        .onDisappear {
            showVideoInstructions = false
            showVideoUpload = false
        }
    }
}

extension StickAnalyzerView {
    // MARK: - Validation Execution
    @MainActor
    private func executeValidation(flowState: AIFlowState) async {
        guard let videoURL = flowState.getData(for: "shot-video-capture") as? URL else {
            viewModel.error = AIAnalyzerError.aiProcessingFailed("Missing video data")
            isValidating = false
            if let resultsStage = flowState.flow.stages.first(where: { $0.id == "stick-analysis-results" }) {
                flowState.currentStage = resultsStage
            }
            validationTask = nil
            return
        }

        do {
            let validation = try await StickAnalyzerService.validateStick(videoURL: videoURL)

            validationResult = validation
            isValidating = false
            // progress estimator removed

            if !validation.is_valid {
                let reason = validation.reason ?? "Please record a valid hockey shot"
                viewModel.error = AIAnalyzerError.invalidContent(.aiDetectedInvalidContent(reason))
                if let resultsStage = flowState.flow.stages.first(where: { $0.id == "stick-analysis-results" }) {
                    flowState.currentStage = resultsStage
                }
            }
            // onSuccess callback in SharedValidationView will handle the valid case
        } catch {
            viewModel.error = AIAnalyzerError.from(error)
            isValidating = false
            if let resultsStage = flowState.flow.stages.first(where: { $0.id == "stick-analysis-results" }) {
                flowState.currentStage = resultsStage
            }
        }

        // Reset gate flag so next attempt re-gates
        monetizationGranted = false
        validationTask = nil
    }

    private func handleStageChange(_ stageId: String?, flowState: AIFlowState) {
        guard let stageId else { return }

        if stageId == "stick-validation" {
            if !monetizationGranted {
                // Intercept navigation and show paywall; re-proceed on grant
                interceptedValidationNav = true
                flowState.goBack()
                triggerMonetizationGate { /* handled on grant */ }
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
        viewModel.error = nil
        
        isValidating = true
        validationTask = Task { await executeValidation(flowState: flowState) }
    }

    // MARK: - Monetization Helpers
    private func triggerMonetizationGate(action: @escaping () -> Void) {
        pendingMonetizedAction = action
        gateTriggerId = UUID().uuidString
        shouldActivateGate = true
    }

    // MARK: - Helper Methods
    private func mapPriorityFocus(_ id: String) -> PriorityFocus {
        switch id {
        case "power": return .power
        case "accuracy": return .accuracy
        case "balance": return .balance
        default: return .balance
        }
    }

    private func mapPrimaryShot(_ id: String) -> PrimaryShotType {
        switch id {
        case "wrist": return .wrist
        case "slap": return .slap
        case "snap": return .snap
        case "backhand": return .backhand
        default: return .wrist
        }
    }

    private func mapShootingZone(_ id: String) -> ShootingZone {
        switch id {
        case "point": return .point
        case "slot": return .slot
        case "close": return .closeRange
        case "varies": return .varies
        default: return .varies
        }
    }

    // MARK: - Funnel Tracking

    private func trackFunnelProgress(for stageId: String) {
        let (stepName, stepNumber) = mapStageToFunnel(stageId)

        // Skip tracking for optional/internal steps (step 0)
        guard stepNumber > 0 else { return }

        AnalyticsManager.shared.trackFunnelStep(
            funnel: "stick_analyzer",
            step: stepName,
            stepNumber: stepNumber,
            totalSteps: 7
        )

        // Track completion
        if stageId == "stick-analysis-results" {
            AnalyticsManager.shared.trackFunnelCompleted(
                funnel: "stick_analyzer",
                totalSteps: 7
            )
        }
    }

    private func mapStageToFunnel(_ stageId: String) -> (String, Int) {
        switch stageId {
        case "player-profile":
            return ("player_profile", 1)
        case "phone-setup-tutorial":
            // Skip tutorial - it's optional and not always shown
            return ("phone_setup_tutorial", 0)
        case "shot-video-capture":
            return ("shot_video_capture", 2)
        case "shooting-priority":
            return ("shooting_priority", 3)
        case "primary-shot":
            return ("primary_shot", 4)
        case "shooting-zone":
            return ("shooting_zone", 5)
        case "stick-validation":
            // Skip validation - it's an internal processing step
            return ("stick_validation", 0)
        case "stick-analysis-processing":
            return ("analysis_processing", 6)
        case "stick-analysis-results":
            return ("results", 7)
        default:
            return ("unknown", 0)
        }
    }
}
