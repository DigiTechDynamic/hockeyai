import SwiftUI
import UIKit
import Combine


// MARK: - Processing State
/// Unified processing state for the view model
enum ProcessingState {
    case idle
    case validating
    case analyzing
    
    var isProcessing: Bool {
        switch self {
        case .idle: return false
        default: return true
        }
    }
}

// MARK: - Shot Rater View Model
/// Manages all UI logic and state for the Shot Rater feature
@MainActor
class ShotRaterViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedShotType: ShotType = .wristShot
    @Published var capturedVideoURL: URL?
    @Published var trimmedVideoURL: URL?
    @Published var processingState: ProcessingState = .idle
    @Published var analysisResult: ShotAnalysisResult?
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
    
    func selectShotType(_ type: ShotType) {
        selectedShotType = type
    }
    
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
            await analyzeShot(videoURL: videoURL, shotType: selectedShotType)
        }
    }

    /// Analyze a shot after validation - called from flow
    func analyzeShot(videoURL: URL, shotType: ShotType) async {
        processingState = .analyzing
        // Mark the selected shot type as analyzing (for background indicator)
        ShotRaterBackgroundManager.shared.setAnalyzing(true, for: shotType)

        // Haptic feedback when AI analysis starts
        await MainActor.run {
            HapticManager.shared.playImpact(style: .light)
        }

        do {
            let result = try await ShotRaterService.analyzeShot(
                videoURL: videoURL,
                shotType: shotType
            )
            analysisResult = result
            processingState = .idle

            // Clear background indicator for this shot type (if any)
            ShotRaterBackgroundManager.shared.setAnalyzing(false, for: result.type)

            // If this analysis was cancelled from card/header, do not surface results or notify
            if ShotRaterBackgroundManager.shared.consumeCancellationFlag(for: result.type) {
                ShotRaterBackgroundManager.shared.setAnalyzing(false, for: result.type)
                return
            }

            // Update latest-result manager for UI
            ShotRaterBackgroundManager.shared.setLatestResult(result, for: result.type)

            // Save result and send notification - SUPER SIMPLE!
            let analysisId = UUID().uuidString
            ShotRaterResultStore.shared.save(result: result, id: analysisId)

            // Just one line to send notification! NotificationKit handles everything else
            NotificationKit.sendShotAnalysisNotification(
                shotType: result.type.displayName,
                score: result.overallScore,
                analysisId: analysisId
            )
        } catch {
            // If user cancelled, swallow the error and exit quietly
            if Task.isCancelled || ShotRaterBackgroundManager.shared.isCancelled(shotType) {
                ShotRaterBackgroundManager.shared.setAnalyzing(false, for: shotType)
                return
            }
            if let urlErr = error as? URLError, urlErr.code == .cancelled {
                ShotRaterBackgroundManager.shared.setAnalyzing(false, for: shotType)
                return
            }
            // Clear background indicator on error too
            ShotRaterBackgroundManager.shared.setAnalyzing(false, for: selectedShotType)
            handleError(AIAnalyzerError.from(error))
        }
    }
    
    // Remove performAnalysis - it's now integrated into startAnalysis
    
    func reset() {
        // Track previous type to clear background indicator correctly
        let previousType = selectedShotType

        // Clean up video URLs
        cleanup()

        // Reset state
        selectedShotType = .wristShot
        capturedVideoURL = nil
        trimmedVideoURL = nil
        processingState = .idle
        analysisResult = nil
        validationResult = nil
        currentError = nil
        showError = false

        // Ensure background indicator is cleared for the type that was in-flight
        ShotRaterBackgroundManager.shared.setAnalyzing(false, for: previousType)
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
