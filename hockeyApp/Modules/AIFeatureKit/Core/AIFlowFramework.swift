import Foundation
import SwiftUI

// MARK: - Unified AI Header
struct UnifiedAIHeader: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    
    let title: String
    let subtitle: String?
    let showBackButton: Bool
    let onBack: (() -> Void)?
    let onClose: (() -> Void)?
    let animationNamespace: Namespace.ID?
    let trailingButton: AnyView?
    
    init(
        title: String,
        subtitle: String? = nil,
        showBackButton: Bool = false,
        onBack: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        animationNamespace: Namespace.ID? = nil,
        trailingButton: AnyView? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showBackButton = showBackButton
        self.onBack = onBack
        self.onClose = onClose
        self.animationNamespace = animationNamespace
        self.trailingButton = trailingButton
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: theme.spacing.md) {
                // Left button
                if showBackButton {
                    Button(action: {
                        HapticManager.shared.playImpact(style: .light)
                        onBack?()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(theme.primary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                } else {
                    // Show X for close only if onClose is provided
                    if onClose != nil {
                        Button(action: {
                            HapticManager.shared.playImpact(style: .light)
                            if let onClose = onClose {
                                onClose()
                            } else {
                                dismiss()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(theme.surface)
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                    } else {
                        // Empty spacer when no close button
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                }
                
                Spacer()
                
                // Center title and subtitle
                VStack(spacing: theme.spacing.xs / 2) {
                    if let namespace = animationNamespace {
                        Text(title)
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color.white.opacity(0.95)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.white.opacity(0.55), radius: 0, x: 0, y: 0)
                            .shadow(color: Color.white.opacity(0.35), radius: 4, x: 0, y: 0)
                            .shadow(color: theme.primary.opacity(0.45), radius: 10, x: 0, y: 2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .matchedGeometryEffect(id: "headerTitle", in: namespace)
                    } else {
                        Text(title)
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color.white.opacity(0.95)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.white.opacity(0.55), radius: 0, x: 0, y: 0)
                            .shadow(color: Color.white.opacity(0.35), radius: 4, x: 0, y: 0)
                            .shadow(color: theme.primary.opacity(0.45), radius: 10, x: 0, y: 2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    
                    if let subtitle = subtitle {
                        if let namespace = animationNamespace {
                            Text(subtitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.textSecondary)
                                .matchedGeometryEffect(id: "headerSubtitle", in: namespace)
                        } else {
                            Text(subtitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Trailing button (natural width) or spacer for balance
                if let trailingButton = trailingButton {
                    trailingButton
                        .frame(height: 44)
                } else {
                    theme.background.opacity(0)
                        .frame(width: 44, height: 44)
                }
            }
            .frame(height: 56)
            // Keep normal left padding; tighten right padding when a trailing button is present
            .padding(.leading, theme.spacing.md)
            .padding(.trailing, trailingButton == nil ? theme.spacing.md : 8)
            
            // Divider
            Rectangle()
                .fill(theme.divider)
                .frame(height: 1)
        }
        .background(theme.background)
    }
}

// MARK: - Progress Bar Component
struct AIProgressBar: View {
    @Environment(\.theme) var theme
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.divider.opacity(0.3))
                    .frame(height: 4)
                
                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [theme.primary, theme.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: progressWidth(in: geometry.size.width), height: 4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
            }
        }
        .frame(height: 4)
    }
    
    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard totalSteps > 0 else { return 0 }
        let progress = CGFloat(currentStep) / CGFloat(totalSteps)
        return totalWidth * progress
    }
}

// MARK: - Flow Stage Protocol
protocol AIFlowStage: Identifiable {
    var id: String { get }
    var title: String { get }
    var subtitle: String { get }
    var isRequired: Bool { get }
    var canSkip: Bool { get }
    var canGoBack: Bool { get }
    var showsHeader: Bool { get }
    
    func validate(data: Any?) -> AIValidationResult
}

// Default implementation for showsHeader
extension AIFlowStage {
    var showsHeader: Bool { true }
}

// MARK: - Validation
public struct AIValidationResult {
    public let isValid: Bool
    public let errors: [String]
    
    public init(isValid: Bool, errors: [String] = []) {
        self.isValid = isValid
        self.errors = errors
    }
    
    public static var valid: AIValidationResult {
        AIValidationResult(isValid: true, errors: [])
    }
    
    public static func invalid(_ errors: String...) -> AIValidationResult {
        AIValidationResult(isValid: false, errors: errors)
    }
}

// (Removed unused MediaCaptureConfiguration)

// MARK: - Flow Definition
protocol AIFlowDefinition {
    var id: String { get }
    var name: String { get }
    var stages: [any AIFlowStage] { get }
    var allowsBackNavigation: Bool { get }
    var showsProgress: Bool { get }
    
    func nextStage(from currentStage: any AIFlowStage, with data: [String: Any]) -> (any AIFlowStage)?
    func previousStage(from currentStage: any AIFlowStage) -> (any AIFlowStage)?
}

// MARK: - Flow State
@MainActor
class AIFlowState: ObservableObject {
    @Published var currentStage: (any AIFlowStage)?
    @Published var stageData: [String: Any] = [:]
    @Published var isProcessing: Bool = false
    @Published var completedStages: Set<String> = []
    @Published var error: Error?
    @Published var validationError: AIAnalyzerError?
    
    let flow: any AIFlowDefinition
    private var stageHistory: [String] = []
    
    init(flow: any AIFlowDefinition) {
        self.flow = flow
        self.currentStage = flow.stages.first
        if let firstStage = flow.stages.first {
            stageHistory.append(firstStage.id)
        }
    }
    
    func setData(_ data: Any?, for stageId: String) {
        stageData[stageId] = data
    }
    
    func getData(for stageId: String) -> Any? {
        return stageData[stageId]
    }
    
    func canProceed() -> Bool {
        guard let stage = currentStage else { return false }
        let validation = stage.validate(data: getData(for: stage.id))
        return validation.isValid || (!stage.isRequired && stage.canSkip)
    }
    
    func proceed() {
        guard let current = currentStage else { 
            print("❌ [AIFlowState] proceed() called but no current stage!")
            return 
        }
        
        print("🔄 [AIFlowState] Proceeding from stage: \(current.id)")
        
        // Mark current stage as completed
        completedStages.insert(current.id)
        print("✅ [AIFlowState] Marked stage '\(current.id)' as completed")
        
        // Get next stage
        if let next = flow.nextStage(from: current, with: stageData) {
            print("➡️ [AIFlowState] Transitioning to next stage: \(next.id)")
            currentStage = next
            stageHistory.append(next.id)
            print("🎯 [AIFlowState] Successfully transitioned to stage: \(next.id)")
        } else {
            print("🏁 [AIFlowState] No next stage found - flow complete")
        }
    }
    
    func goBack() {
        guard flow.allowsBackNavigation,
              let current = currentStage,
              current.canGoBack,
              let previous = flow.previousStage(from: current) else { return }
        
        currentStage = previous
        stageHistory.append(previous.id)
    }
    
    func skip() {
        guard let current = currentStage,
              current.canSkip else { return }
        
        proceed()
    }
    
    func restart() {
        stageData.removeAll()
        completedStages.removeAll()
        stageHistory.removeAll()
        currentStage = flow.stages.first
        if let firstStage = flow.stages.first {
            stageHistory.append(firstStage.id)
        }
        error = nil
        validationError = nil
        isProcessing = false
    }
    
    func currentStageIndex() -> Int {
        guard let current = currentStage else { return 0 }
        return flow.stages.firstIndex(where: { $0.id == current.id }) ?? 0
    }
    
    func totalStages() -> Int {
        return flow.stages.count
    }
    
    func isComplete() -> Bool {
        guard let current = currentStage else { return false }
        return flow.stages.last?.id == current.id && completedStages.contains(current.id)
    }
}

// MARK: - Common Stage Types
struct SelectionStage: AIFlowStage {
    let id: String
    let title: String
    let subtitle: String
    let isRequired: Bool
    let canSkip: Bool
    let canGoBack: Bool
    let options: [SelectionOption]
    let multiSelect: Bool
    
    struct SelectionOption {
        let id: String
        let title: String
        let subtitle: String?
        let icon: String?
    }
    
    init(
        id: String,
        title: String,
        subtitle: String,
        isRequired: Bool = true,
        canSkip: Bool = false,
        canGoBack: Bool = true,
        options: [SelectionOption],
        multiSelect: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.isRequired = isRequired
        self.canSkip = canSkip
        self.canGoBack = canGoBack
        self.options = options
        self.multiSelect = multiSelect
    }
    
    func validate(data: Any?) -> AIValidationResult {
        if !isRequired && data == nil {
            return .valid
        }
        
        if multiSelect {
            guard let selections = data as? [String], !selections.isEmpty else {
                return .invalid("Please make at least one selection")
            }
        } else {
            guard let selection = data as? String, !selection.isEmpty else {
                return .invalid("Please make a selection")
            }
        }
        
        return .valid
    }
}

struct MediaCaptureStage: AIFlowStage {
    let id: String
    let title: String
    let subtitle: String
    let isRequired: Bool
    let canSkip: Bool
    let canGoBack: Bool
    let mediaTypes: Set<MediaType>
    let maxItems: Int
    let instructions: String?
    let minItems: Int
    let maxImages: Int
    let maxVideos: Int
    
    init(
        id: String,
        title: String,
        subtitle: String,
        isRequired: Bool = true,
        canSkip: Bool = false,
        canGoBack: Bool = true,
        mediaTypes: Set<MediaType> = [.image, .video],
        maxItems: Int = 5,
        minItems: Int = 1,
        instructions: String? = nil,
        maxImages: Int? = nil,
        maxVideos: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.isRequired = isRequired
        self.canSkip = canSkip
        self.canGoBack = canGoBack
        self.mediaTypes = mediaTypes
        self.maxItems = maxItems
        self.minItems = minItems
        self.instructions = instructions
        // If specific limits aren't provided, use maxItems as the limit for each type
        self.maxImages = maxImages ?? maxItems
        self.maxVideos = maxVideos ?? maxItems
    }
    
    func validate(data: Any?) -> AIValidationResult {
        guard let mediaData = data as? MediaStageData else {
            return .invalid("No media data provided")
        }
        
        let totalItems = mediaData.images.count + mediaData.videos.count
        
        if totalItems < minItems {
            return .invalid("Please add at least \(minItems) media item(s)")
        }
        
        if totalItems > maxItems {
            return .invalid("Maximum \(maxItems) media items allowed")
        }
        
        return .valid
    }
}

// (Removed unused TextInputStage)

struct ProcessingStage: AIFlowStage {
    let id: String
    let title: String
    let subtitle: String
    let isRequired: Bool = true
    let canSkip: Bool = false
    let canGoBack: Bool = false
    let processingMessage: String
    let showsHeader: Bool
    let showsCancelButton: Bool
    
    init(id: String, title: String, subtitle: String, processingMessage: String, showsHeader: Bool = true, showsCancelButton: Bool = false) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.processingMessage = processingMessage
        self.showsHeader = showsHeader
        self.showsCancelButton = showsCancelButton
    }
    
    func validate(data: Any?) -> AIValidationResult {
        // Processing stages are always valid
        return .valid
    }
}

struct ResultsStage: AIFlowStage {
    let id: String
    let title: String
    let subtitle: String
    let isRequired: Bool = true
    let canSkip: Bool = false
    let canGoBack: Bool = false
    let showsHeader: Bool

    init(id: String, title: String, subtitle: String, showsHeader: Bool = true) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.showsHeader = showsHeader
    }

    func validate(data: Any?) -> AIValidationResult {
        // Results stages are always valid
        return .valid
    }
}

struct CustomStage: AIFlowStage {
    let id: String
    let title: String
    let subtitle: String
    let isRequired: Bool
    let canSkip: Bool
    let canGoBack: Bool
    let showsHeader: Bool
    let showsProgress: Bool

    init(id: String, title: String, subtitle: String, isRequired: Bool = false, canSkip: Bool = false, canGoBack: Bool = false, showsHeader: Bool = false, showsProgress: Bool = false) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.isRequired = isRequired
        self.canSkip = canSkip
        self.canGoBack = canGoBack
        self.showsHeader = showsHeader
        self.showsProgress = showsProgress
    }

    func validate(data: Any?) -> AIValidationResult {
        // Custom stages are always valid
        return .valid
    }
}

// MARK: - Linear Flow Implementation
class LinearAIFlow: AIFlowDefinition {
    let id: String
    let name: String
    let stages: [any AIFlowStage]
    let allowsBackNavigation: Bool
    let showsProgress: Bool
    
    init(
        id: String,
        name: String,
        stages: [any AIFlowStage],
        allowsBackNavigation: Bool = true,
        showsProgress: Bool = true
    ) {
        self.id = id
        self.name = name
        self.stages = stages
        self.allowsBackNavigation = allowsBackNavigation
        self.showsProgress = showsProgress
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

// MARK: - Flow Container View
struct AIFlowContainer<Content: View>: View {
    @StateObject var flowState: AIFlowState
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    @Namespace private var animationNamespace
    let content: (AIFlowState) -> Content
    @State private var showCancelConfirm = false
    
    init(flow: any AIFlowDefinition, @ViewBuilder content: @escaping (AIFlowState) -> Content) {
        self._flowState = StateObject(wrappedValue: AIFlowState(flow: flow))
        self.content = content
    }
    
    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with dynamic content (only show if stage wants it)
                if let stage = flowState.currentStage, stage.showsHeader {
                    let isProcessingWithCancel = (stage as? ProcessingStage)?.showsCancelButton == true
                    let showBackButton = stage.canGoBack && flowState.currentStageIndex() > 0

                    // Determine trailing button:
                    // 1. Processing stage with cancel button -> show Cancel button
                    // 2. Mid-flow with back button showing -> show X close button on right
                    // 3. Otherwise -> no trailing button (X shows on left)
                    let trailing: AnyView? = {
                        if isProcessingWithCancel {
                            return AnyView(
                                Button(action: { showCancelConfirm = true }) {
                                    Text("Cancel")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                        .shadow(color: Color.white.opacity(0.85), radius: 1.5)
                                        .shadow(color: Color.white.opacity(0.35), radius: 3.5)
                                        .shadow(color: theme.destructive.opacity(0.35), radius: 6)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(theme.destructive)
                                        )
                                        .fixedSize()
                                }
                            )
                        } else if showBackButton {
                            // Show close X on the right when back button is on the left
                            return AnyView(
                                Button(action: { dismiss() }) {
                                    ZStack {
                                        Circle()
                                            .fill(theme.surface)
                                            .frame(width: 36, height: 36)

                                        Image(systemName: "xmark")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(theme.textSecondary)
                                    }
                                }
                            )
                        }
                        return nil
                    }()

                    UnifiedAIHeader(
                        title: stage.title,
                        subtitle: stage.subtitle,
                        showBackButton: showBackButton,
                        onBack: { flowState.goBack() },
                        // Show close (X) on left only when no back button and no trailing button
                        onClose: (!showBackButton && trailing == nil) ? { dismiss() } : nil,
                        animationNamespace: animationNamespace,
                        trailingButton: trailing
                    )
                }
                
                // Progress indicator (hide for CustomStage unless showsProgress is true)
                let showProgressBar: Bool = {
                    guard flowState.flow.showsProgress else { return false }
                    if let customStage = flowState.currentStage as? CustomStage {
                        return customStage.showsProgress
                    }
                    return !(flowState.currentStage is CustomStage)
                }()

                if showProgressBar {
                    AIProgressBar(
                        currentStep: flowState.currentStageIndex() + 1,
                        totalSteps: flowState.totalStages()
                    )
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.vertical, theme.spacing.sm)
                }
                
                // Stage content
                content(flowState)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: flowState.currentStage?.id)
            }
        }
        .confirmationDialog(
            "Cancel analysis?",
            isPresented: $showCancelConfirm,
            titleVisibility: .visible
        ) {
            Button("Stop Analysis", role: .destructive) {
                NotificationCenter.default.post(name: Notification.Name("AIFlowCancel"), object: flowState.flow.id)
            }
            Button("Keep Running", role: .cancel) {}
        }
    }
}
