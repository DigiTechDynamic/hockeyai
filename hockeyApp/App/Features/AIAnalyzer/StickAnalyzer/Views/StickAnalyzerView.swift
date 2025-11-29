import SwiftUI

// MARK: - Stick Analyzer Flow View
/// Main container view for the Stick Analyzer flow
/// Uses body scan instead of video for lower friction
struct StickAnalyzerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    @StateObject private var flowHolder: StickAnalyzerFlowHolder
    @StateObject private var viewModel = StickAnalyzerViewModel()
    @State private var showCards = false
    @State private var selectedCardId: String? = nil
    // Monetization gate state
    @State private var shouldActivateGate = false
    @State private var gateTriggerId = UUID().uuidString
    @State private var monetizationGranted = false
    @State private var pendingMonetizedAction: (() -> Void)?
    // Body scan state
    @State private var showBodyScan = false

    let onAnalysisComplete: ((StickAnalysisResult) -> Void)?

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

                    case "body-scan":
                        bodyScanStageView(flowState: flowState)
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

                    case "stick-analysis-processing":
                        processingView(flowState: flowState)
                            .transition(.opacity)
                            .onAppear {
                                print("🔄 [StickAnalyzerView] Processing stage appeared, starting analysis in 0.5s...")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    print("🚀 [StickAnalyzerView] Calling performAnalysis()")
                                    viewModel.performAnalysis()
                                }
                            }
                            .onReceive(viewModel.$analysisResult) { result in
                                print("📡 [StickAnalyzerView] analysisResult changed: \(result != nil ? "has value" : "nil")")
                                if result != nil {
                                    print("✅ [StickAnalyzerView] Result received, proceeding to next stage...")
                                    flowState.proceed()
                                }
                            }
                            .onReceive(viewModel.$error) { error in
                                print("📡 [StickAnalyzerView] error changed: \(error != nil ? "has error" : "nil")")
                                if error != nil {
                                    print("⚠️ [StickAnalyzerView] Error received, proceeding to error view...")
                                    flowState.proceed()
                                }
                            }

                    case "stick-analysis-results":
                        Group {
                            if let error = viewModel.error {
                                AIServiceErrorView(
                                    errorType: AIServiceErrorType.from(analyzerError: error),
                                    onRetry: {
                                        viewModel.error = nil
                                        flowState.goBack()
                                        viewModel.performAnalysis()
                                    },
                                    onDismiss: {
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
            // Attach monetization gate
            .monetizationGate(
                featureIdentifier: "ai_analysis",
                source: "equipment",
                activatedProgrammatically: $shouldActivateGate,
                triggerId: gateTriggerId,
                consumeAccess: true,
                onAccessGranted: {
                    monetizationGranted = true
                    let action = pendingMonetizedAction
                    pendingMonetizedAction = nil
                    action?()
                },
                onDismissOrCancel: { _ in
                    pendingMonetizedAction = nil
                    monetizationGranted = false
                }
            )
            .onChange(of: flowState.currentStage?.id) { newStage in
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
                    totalSteps: 6
                )

                // Track initial stage
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let stageId = flowState.currentStage?.id {
                        trackFunnelProgress(for: stageId)
                    }
                }
            }
        }
        .overlay(
            GlobalPresentationLayer()
                .environmentObject(NoticeCenter.shared)
                .zIndex(10000)
        )
        .fullScreenCover(isPresented: $showBodyScan) {
            bodyScanFullScreenView()
        }
        .onAppear {
            print("🏒 [StickAnalyzerView] Flow started")
        }
        .onDisappear {
            viewModel.cleanup()
        }
        // Respond to global cancel from header Cancel
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AIFlowCancel"))) { _ in
            AIAnalysisFacade.cancelActiveRequests()
            dismiss()
        }
    }

    // MARK: - Body Scan Full Screen View
    @ViewBuilder
    private func bodyScanFullScreenView() -> some View {
        BodyScanView(
            onComplete: { result in
                // Save the body scan for future use
                BodyScanStorage.shared.save(result)
                viewModel.setBodyScan(result)
                showBodyScan = false
                // Proceed will be called from the stage view
            },
            onCancel: {
                showBodyScan = false
            }
        )
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
    // MARK: - Body Scan Stage View
    private func bodyScanStageView(flowState: AIFlowState) -> some View {
        BodyScanStageView(
            flowState: flowState,
            viewModel: viewModel,
            showBodyScan: $showBodyScan
        )
    }

    // MARK: - Monetization Helpers
    private func triggerMonetizationGate(action: @escaping () -> Void) {
        pendingMonetizedAction = action
        gateTriggerId = UUID().uuidString
        shouldActivateGate = true
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
            totalSteps: 6
        )

        // Track completion
        if stageId == "stick-analysis-results" {
            AnalyticsManager.shared.trackFunnelCompleted(
                funnel: "stick_analyzer",
                totalSteps: 6
            )
        }
    }

    private func mapStageToFunnel(_ stageId: String) -> (String, Int) {
        switch stageId {
        case "player-profile":
            return ("player_profile", 1)
        case "body-scan":
            return ("body_scan", 2)
        case "shooting-priority":
            return ("shooting_priority", 3)
        case "primary-shot":
            return ("primary_shot", 4)
        case "shooting-zone":
            return ("shooting_zone", 5)
        case "stick-analysis-processing":
            return ("analysis_processing", 6)
        case "stick-analysis-results":
            return ("results", 6)
        default:
            return ("unknown", 0)
        }
    }
}

// MARK: - Body Scan Stage View
struct BodyScanStageView: View {
    @ObservedObject var flowState: AIFlowState
    @ObservedObject var viewModel: StickAnalyzerViewModel
    @Binding var showBodyScan: Bool
    @Environment(\.theme) var theme
    @State private var showContent = false

    private var hasScan: Bool {
        viewModel.bodyScanResult != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    if let bodyScan = viewModel.bodyScanResult {
                        // Completed state - show compact card
                        completedCard(bodyScan: bodyScan)
                    } else {
                        // Empty state - show instructions card with button inside
                        emptyStateCard
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 120)
            }

            // Bottom action area - Continue button (enabled when scan exists) + Skip option
            VStack(spacing: 12) {
                Button(action: {
                    if hasScan {
                        flowState.proceed()
                    }
                }) {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(hasScan ? .black : .white.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(hasScan ? theme.primary : Color.white.opacity(0.1))
                    .cornerRadius(theme.cornerRadius)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!hasScan)

                // Skip option (only show when no scan)
                if !hasScan {
                    Button(action: {
                        flowState.proceed()
                    }) {
                        Text("Skip for now")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                theme.background
                    .opacity(0.95)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .onAppear {
            // Load saved body scan if available and not already set
            if viewModel.bodyScanResult == nil {
                if let savedScan = BodyScanStorage.shared.load() {
                    viewModel.setBodyScan(savedScan)
                    print("📸 [BodyScanStageView] Loaded saved body scan from \(savedScan.scanDate)")
                }
            }

            showContent = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    showContent = true
                }
            }
        }
    }

    // MARK: - Empty State Card (with Start button inside)
    private var emptyStateCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.stand")
                .font(.system(size: 60))
                .foregroundColor(theme.primary)

            Text("Body Scan")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(theme.text)

            Text("We'll capture a full-body photo to analyze your proportions for optimal stick fitting.")
                .font(.system(size: 15))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                instructionRow(icon: "person.fill", text: "Stand naturally with arms at your sides")
                instructionRow(icon: "camera.fill", text: "Have someone take your photo, or use a timer")
                instructionRow(icon: "lightbulb.fill", text: "Good lighting helps accuracy")
                instructionRow(icon: "arrow.up.and.down", text: "Full body should be visible")
            }
            .padding(.top, 8)

            // Start button inside card
            Button(action: {
                HapticManager.shared.playSelection()
                showBodyScan = true
            }) {
                HStack {
                    Image(systemName: "figure.stand")
                    Text("Start Body Scan")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(theme.primary)
                .cornerRadius(theme.cornerRadius)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 12)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.surface)
        )
        .padding(.horizontal, 20)
        .scaleEffect(showContent ? 1 : 0.9)
        .opacity(showContent ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: showContent)
    }

    // MARK: - Completed Card
    private func completedCard(bodyScan: BodyScanResult) -> some View {
        VStack(spacing: theme.spacing.lg) {
            // Header
            HStack {
                Image(systemName: "figure.stand")
                    .font(theme.fonts.body)
                    .foregroundColor(theme.primary)
                Text("Body Scan")
                    .font(theme.fonts.headline)
                    .foregroundColor(.white)
                Spacer()
            }

            Divider().background(Color.white.opacity(0.1))

            HStack(spacing: 16) {
                // Thumbnail
                if let image = bodyScan.loadImage() {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.surface)
                        .frame(width: 60, height: 80)
                        .overlay(
                            Image(systemName: "figure.stand")
                                .foregroundColor(theme.textSecondary)
                        )
                }

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                        Text("Body scan captured")
                            .font(theme.fonts.body)
                            .foregroundColor(.white)
                    }

                    Text("Captured \(formattedDate(bodyScan.scanDate))")
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()
            }

            // Rescan button
            Button(action: {
                HapticManager.shared.playSelection()
                showBodyScan = true
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Rescan")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(theme.primary.opacity(0.12))
                .cornerRadius(theme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.surface)
        )
        .padding(.horizontal, 20)
        .scaleEffect(showContent ? 1 : 0.9)
        .opacity(showContent ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: showContent)
    }

    // MARK: - Helper Views
    private func instructionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(theme.primary)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(theme.textSecondary)
            Spacer()
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
