import SwiftUI
import UIKit
import Combine

// MARK: - Skill Check View Model
/// Manages all UI logic and state for the Skill Check feature
@MainActor
class SkillCheckViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var capturedVideoURL: URL?
    @Published var trimmedVideoURL: URL?
    @Published var processingState: ProcessingState = .idle
    @Published var analysisResult: SkillAnalysisResult?
    @Published var validationResult: AIValidationService.ValidationResponse?
    @Published var currentError: AIAnalyzerError?
    @Published var showError = false

    // MARK: - Private Properties
    private let videoManager = VideoStorageManager.shared

    // MARK: - Computed Properties
    var isProcessing: Bool {
        processingState.isProcessing
    }

    var isValidating: Bool {
        processingState == .validating
    }

    var isAnalyzing: Bool {
        processingState == .analyzing
    }

    // MARK: - Public Methods

    func setCapturedVideo(_ url: URL) {
        videoManager.updateManagedVideo(current: &capturedVideoURL, new: url)
    }

    func setTrimmedVideo(_ url: URL) {
        videoManager.updateManagedVideo(current: &trimmedVideoURL, new: url)
    }

    func startAnalysis() {
        guard let videoURL = trimmedVideoURL ?? capturedVideoURL else {
            handleError(AIAnalyzerError.aiProcessingFailed("No video available for analysis"))
            return
        }

        // Reset state
        analysisResult = nil
        currentError = nil
        showError = false

        Task {
            await analyzeSkill(videoURL: videoURL)
        }
    }

    /// Analyze a skill after validation - called from flow
    func analyzeSkill(videoURL: URL) async {
        processingState = .analyzing

        // Haptic feedback when AI analysis starts
        await MainActor.run {
            HapticManager.shared.playImpact(style: .light)
        }

        do {
            let result = try await SkillCheckService.analyzeSkill(videoURL: videoURL)
            analysisResult = result
            processingState = .idle

        } catch {
            // If user cancelled, swallow the error and exit quietly
            if Task.isCancelled {
                return
            }
            if let urlErr = error as? URLError, urlErr.code == .cancelled {
                return
            }
            handleError(AIAnalyzerError.from(error))
        }
    }

    func reset() {
        // Clean up video URLs
        cleanup()

        // Reset state
        capturedVideoURL = nil
        trimmedVideoURL = nil
        processingState = .idle
        analysisResult = nil
        validationResult = nil
        currentError = nil
        showError = false
    }

    // MARK: - Private Methods

    private func handleError(_ error: AIAnalyzerError) {
        processingState = .idle
        currentError = error
        showError = true
    }

    func cleanup() {
        // Clean up all managed videos
        if let captured = capturedVideoURL {
            videoManager.cleanupVideo(captured)
        }
        if let trimmed = trimmedVideoURL {
            videoManager.cleanupVideo(trimmed)
        }
        capturedVideoURL = nil
        trimmedVideoURL = nil
    }
}
