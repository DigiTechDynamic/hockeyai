import SwiftUI
import Combine

// MARK: - AI Coach Flow View Model
/// Manages all UI logic and state for the AI Coach Flow feature
@MainActor
class AICoachFlowViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedShotType: ShotType?
    @Published var playerProfile: PlayerProfile?
    @Published var frontNetVideoURL: URL?
    @Published var sideAngleVideoURL: URL?
    @Published var isAnalyzing = false
    @Published var analysisResult: AICoachAnalysisResult?
    @Published var analysisError: Error?
    
    // MARK: - Private Properties
    private let videoManager = VideoStorageManager.shared
    
    // MARK: - Public Methods
    
    func selectShotType(_ type: ShotType) {
        selectedShotType = type
    }
    
    func setPlayerProfile(_ profile: PlayerProfile) {
        playerProfile = profile
    }
    
    func setFrontNetVideo(_ url: URL) {
        videoManager.updateManagedVideo(current: &frontNetVideoURL, new: url)
    }
    
    func setSideAngleVideo(_ url: URL) {
        videoManager.updateManagedVideo(current: &sideAngleVideoURL, new: url)
    }
    
    func startAnalysis() {
        guard let frontNetURL = frontNetVideoURL,
              let sideAngleURL = sideAngleVideoURL,
              let shotType = selectedShotType,
              let profile = playerProfile else {
            return
        }
        
        // Reset previous results
        analysisResult = nil
        analysisError = nil
        
        Task {
            isAnalyzing = true

            // Haptic feedback when AI analysis starts
            HapticManager.shared.playImpact(style: .light)

            do {
                // Perform analysis directly (validation happens inside the service)
                let result = try await AICoachFlowService.analyzeShot(
                    frontNetVideoURL: frontNetURL,
                    sideAngleVideoURL: sideAngleURL,
                    shotType: shotType,
                    playerProfile: profile
                )
                analysisResult = result
                isAnalyzing = false
            } catch {
                isAnalyzing = false
                analysisError = error
            }
        }
    }
    
    func reset() {
        // Clean up videos
        cleanup()
        
        selectedShotType = nil
        playerProfile = nil
        frontNetVideoURL = nil
        sideAngleVideoURL = nil
        isAnalyzing = false
        analysisResult = nil
        analysisError = nil
    }
    
    func cleanup() {
        // Clean up all managed videos
        if let frontNet = frontNetVideoURL {
            videoManager.cleanupVideo(frontNet)
        }
        if let sideAngle = sideAngleVideoURL {
            videoManager.cleanupVideo(sideAngle)
        }
        frontNetVideoURL = nil
        sideAngleVideoURL = nil
    }
}