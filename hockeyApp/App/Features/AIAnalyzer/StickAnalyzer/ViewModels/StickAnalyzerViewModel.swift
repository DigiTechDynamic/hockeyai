import SwiftUI
import Combine

// MARK: - Stick Analyzer View Model
@MainActor
class StickAnalyzerViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var analysisResult: StickAnalysisResult?
    @Published var isProcessing = false
    @Published var error: AIAnalyzerError?
    @Published var processingMessage = "Analyzing your body proportions..."

    // MARK: - Data Storage
    var playerProfile: PlayerProfile?
    var stickDetails: StickDetails?
    @Published var bodyScanResult: BodyScanResult?  // @Published so UI updates after scan completes
    var questionnaire: ShootingQuestionnaire?


    // MARK: - Flow Management
    private let flowHolder: StickAnalyzerFlowHolder
    private var cancellables = Set<AnyCancellable>()

    init(flowHolder: StickAnalyzerFlowHolder = StickAnalyzerFlowHolder()) {
        self.flowHolder = flowHolder
    }

    // MARK: - Public Methods

    /// Store player profile data
    func setPlayerProfile(_ profile: PlayerProfile) {
        self.playerProfile = profile
    }

    /// Store stick details
    func setStickDetails(_ details: StickDetails) {
        self.stickDetails = details
    }

    /// Store body scan result (replaces setShotVideo)
    func setBodyScan(_ result: BodyScanResult) {
        self.bodyScanResult = result
    }

    /// Store questionnaire responses
    func setQuestionnaire(_ questionnaire: ShootingQuestionnaire) {
        self.questionnaire = questionnaire
    }

    /// Perform the stick analysis using body scan image (optional)
    func performAnalysis() {
        guard let profile = playerProfile,
              let questions = questionnaire else {
            self.error = AIAnalyzerError.aiProcessingFailed("Missing required data for analysis")
            return
        }

        // Start processing
        isProcessing = true
        error = nil

        // Haptic feedback when AI analysis starts
        HapticManager.shared.playImpact(style: .light)

        // Update processing messages
        startProcessingMessages()

        Task {
            do {
                let hasBodyScan = bodyScanResult != nil
                print("🔄 [StickAnalyzerViewModel] Starting AI analysis... (body scan: \(hasBodyScan ? "yes" : "no"))")

                // Perform analysis with optional body scan image
                let result = try await StickAnalyzerService.analyzeStick(
                    bodyScanResult: bodyScanResult,
                    playerProfile: profile,
                    questionnaire: questions
                )

                print("✅ [StickAnalyzerViewModel] Analysis complete, setting result...")
                self.analysisResult = result
                self.error = nil
                self.isProcessing = false
                print("📊 [StickAnalyzerViewModel] Result set - analysisResult is now: \(self.analysisResult != nil ? "non-nil" : "nil")")
            } catch {
                print("❌ [StickAnalyzerViewModel] Analysis failed: \(error.localizedDescription)")
                // Convert to unified error type
                if let aiError = error as? AIAnalyzerError {
                    self.error = aiError
                } else {
                    self.error = AIAnalyzerError.from(error)
                }
                self.analysisResult = nil
                self.isProcessing = false
                print("⚠️ [StickAnalyzerViewModel] Error set - error is now: \(self.error != nil ? "non-nil" : "nil")")
            }
        }
    }

    /// Reset all data for a new analysis
    func reset() {
        playerProfile = nil
        stickDetails = nil
        bodyScanResult = nil
        questionnaire = nil
        analysisResult = nil
        error = nil
        isProcessing = false
    }

    func cleanup() {
        // No video cleanup needed anymore - body scan images are managed by BodyScanStorage
        print("🗑️ [StickAnalyzerViewModel] Cleanup complete")
    }

    deinit {
        // Cancel any ongoing timers/subscriptions
        cancellables.removeAll()
    }

    // MARK: - Private Methods

    private func startProcessingMessages() {
        let messages = [
            "Analyzing your body proportions...",
            "Evaluating stick flex requirements...",
            "Calculating optimal length...",
            "Determining ideal curve pattern...",
            "Finding perfect kick point...",
            "Matching stick models to your style...",
            "Generating personalized recommendations..."
        ]

        var messageIndex = 0

        Timer.publish(every: 2.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isProcessing else { return }

                if messageIndex < messages.count {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.processingMessage = messages[messageIndex]
                    }
                    messageIndex += 1
                } else {
                    messageIndex = 0 // Loop back to start
                }
            }
            .store(in: &cancellables)
    }

}