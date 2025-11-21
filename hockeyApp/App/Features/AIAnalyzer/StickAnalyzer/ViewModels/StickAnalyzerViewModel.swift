import SwiftUI
import Combine

// MARK: - Stick Analyzer View Model
@MainActor
class StickAnalyzerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var analysisResult: StickAnalysisResult?
    @Published var isProcessing = false
    @Published var error: AIAnalyzerError?
    @Published var processingMessage = "Analyzing your stick specifications..."
    
    // MARK: - Data Storage
    var playerProfile: PlayerProfile?
    var stickDetails: StickDetails?
    var shotVideoURL: URL?
    var questionnaire: ShootingQuestionnaire?
    
    
    // MARK: - Flow Management
    private let flowHolder: StickAnalyzerFlowHolder
    private var cancellables = Set<AnyCancellable>()
    private let videoManager = VideoStorageManager.shared
    
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
    
    /// Store shot video URL
    func setShotVideo(_ url: URL) {
        videoManager.updateManagedVideo(current: &shotVideoURL, new: url)
    }
    
    /// Store questionnaire responses
    func setQuestionnaire(_ questionnaire: ShootingQuestionnaire) {
        self.questionnaire = questionnaire
    }
    
    /// Perform the stick analysis without validation (validation happens separately now)
    func performAnalysisWithoutValidation() {
        // Skip validation since it's handled by SharedValidationView
        guard let profile = playerProfile,
              let shotURL = shotVideoURL,
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
                // Perform analysis without validation (already validated)
                let result = try await StickAnalyzerService.analyzeStickWithoutValidation(
                    shotVideoURL: shotURL,
                    playerProfile: profile,
                    questionnaire: questions
                )

                self.analysisResult = result
                self.error = nil
                self.isProcessing = false
            } catch {
                // Convert to unified error type
                if let aiError = error as? AIAnalyzerError {
                    self.error = aiError
                } else {
                    self.error = AIAnalyzerError.from(error)
                }
                self.analysisResult = nil
                self.isProcessing = false
            }
        }
    }

    /// Perform the stick analysis (legacy method that includes validation)
    func performAnalysis() {
        // Validate all required data
        guard let profile = playerProfile else {
            self.error = AIAnalyzerError.aiProcessingFailed("Player profile is required")
            return
        }

        guard let shotURL = shotVideoURL else {
            self.error = AIAnalyzerError.aiProcessingFailed("Shot video is required")
            return
        }

        guard let questions = questionnaire else {
            self.error = AIAnalyzerError.aiProcessingFailed("Shooting questionnaire is required")
            return
        }

        // Start processing
        isProcessing = true
        error = nil

        // Update processing messages
        startProcessingMessages()

        Task {
            do {
                // Perform analysis with single video
                let result = try await StickAnalyzerService.analyzeStick(
                    shotVideoURL: shotURL,
                    playerProfile: profile,
                    questionnaire: questions
                )

                self.analysisResult = result
                self.error = nil
                self.isProcessing = false
            } catch {
                // Convert to unified error type
                if let aiError = error as? AIAnalyzerError {
                    self.error = aiError
                } else {
                    self.error = AIAnalyzerError.from(error)
                }
                self.analysisResult = nil
                self.isProcessing = false
            }
        }
    }
    
    /// Reset all data for a new analysis
    func reset() {
        
        // Clean up videos
        cleanup()
        
        playerProfile = nil
        stickDetails = nil
        shotVideoURL = nil
        questionnaire = nil
        analysisResult = nil
        error = nil
        isProcessing = false
    }
    
    func cleanup() {
        // Clean up managed video
        if let shot = shotVideoURL {
            videoManager.cleanupVideo(shot)
        }
        shotVideoURL = nil
        print("🗑️ [StickAnalyzerViewModel] Videos cleaned up")
    }
    
    deinit {
        // Cancel any ongoing timers/subscriptions
        cancellables.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func startProcessingMessages() {
        let messages = [
            "Analyzing your shooting technique...",
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