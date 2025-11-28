import Foundation
import AVFoundation

// MARK: - Shot Rater Service
/// Service for analyzing hockey shots using AI
/// Uses typed response model (ShotRaterResponse) with simplified flat schema
class ShotRaterService {

    // MARK: - Validation (Using Shared Service)

    /// Type alias for shared validation response
    typealias ValidationResponse = AIValidationService.ValidationResponse

    // MARK: - Public Methods

    /// Validate if a video contains a valid hockey shot
    /// - Parameter videoURL: URL to the video file
    /// - Returns: Validation result with confidence and reason
    static func validateShot(videoURL: URL) async throws -> ValidationResponse {
        return try await AIValidationService.validateHockeyShot(videoURL: videoURL)
    }

    /// Analyze a hockey shot from video using typed response
    /// - Parameters:
    ///   - videoURL: URL to the video file
    ///   - shotType: Type of shot being analyzed
    static func analyzeShot(
        videoURL: URL,
        shotType: ShotType
    ) async throws -> ShotAnalysisResult {

        let startTime = Date()

        // Show a brief cellular notice (non-blocking overlay)
        AINetworkPreflight.showCellularNoticeIfNeeded()

        // Check if AI service is available
        guard AIAnalysisFacade.isAvailable else {
            throw AIAnalyzerError.networkIssue
        }

        // Get video metadata
        let metadata = try await extractVideoMetadata(from: videoURL)

        // Create analysis prompt
        let prompt = createAnalysisPrompt(for: shotType)

        // Use typed response parsing
        return try await withCheckedThrowingContinuation { continuation in
            let request = AIAnalysisFacade.AIRequest.singleVideo(
                videoURL: videoURL,
                prompt: prompt,
                frameRate: 10,  // Optimized 10 FPS for detailed shot analysis (67% faster than 30 FPS)
                generationConfig: [
                    "temperature": 0.1,
                    "topK": 10,
                    "maxOutputTokens": 4096,
                    // Enforce raw JSON output with strict schema
                    "response_mime_type": "application/json",
                    "response_schema": ShotRaterSchema.schemaDefinition.toDictionary(),
                    // Keep camelCase for compatibility
                    "responseSchema": ShotRaterSchema.schemaDefinition.toDictionary()
                ]
            )

            AIAnalysisFacade.sendToAI(request: request) { result in
                switch result {
                case .success(let rawResponse):
                    // Clean and parse the response
                    let cleanedResponse = AIAnalysisFacade.sanitizeJSON(from: rawResponse)
                    let data = cleanedResponse.data(using: .utf8) ?? Data()

                    do {
                        // Try to decode the typed response format
                        let decoder = JSONDecoder()
                        let shotResponse = try decoder.decode(ShotRaterResponse.self, from: data)

                        // Update metadata with processing info
                        var updatedMetadata = metadata
                        updatedMetadata.processingTime = Date().timeIntervalSince(startTime)
                        updatedMetadata.selectedShotType = shotType.rawValue

                        // Convert to ShotAnalysisResult
                        let analysisResult = ShotAnalysisResult(
                            type: shotType,
                            confidence: shotResponse.confidence,
                            overallScore: shotResponse.overall_rating,
                            metrics: ShotMetrics(
                                technique: ShotMetric(
                                    score: shotResponse.technique_score,
                                    reason: shotResponse.technique_reason
                                ),
                                power: ShotMetric(
                                    score: shotResponse.power_score,
                                    reason: shotResponse.power_reason
                                )
                            ),
                            tips: shotResponse.summary,
                            videoURL: videoURL,
                            analysisMetadata: updatedMetadata,
                            detectedType: nil,
                            hasTypeMismatch: false
                        )

                        continuation.resume(returning: analysisResult)

                    } catch let parseError {
                        #if DEBUG
                        print("❌ [ShotRaterService] Analysis parsing failed")
                        print("📄 Response preview: \(String(cleanedResponse.prefix(500)))")
                        print("💥 Error: \(parseError.localizedDescription)")
                        #endif

                        continuation.resume(throwing: AIAnalyzerError.analysisParsingFailed(
                            "Analysis completed but results couldn't be processed. Please try again."
                        ))
                    }

                case .failure(let error):
                    continuation.resume(throwing: AIAnalyzerError.from(error))
                }
            }
        }
    }
    
    // MARK: - Private Methods - Video Processing
    
    private static func extractVideoMetadata(from videoURL: URL) async throws -> VideoAnalysisMetadata {
        // Use the generic metadata extraction from AIAnalysisFacade
        let metadata = try await AIAnalysisFacade.extractVideoMetadata(from: videoURL)
        
        let videoDuration = metadata["duration"] as? Double ?? 0
        let width = metadata["width"] as? Int ?? 0
        let height = metadata["height"] as? Int ?? 0
        let frameRate = metadata["frameRate"] as? Int ?? 30
        let fileSize = metadata["fileSize"] as? Int64 ?? 0
        let isLandscape = metadata["isLandscape"] as? Bool ?? false
        
        let videoSize = CGSize(width: CGFloat(width), height: CGFloat(height))
        
        // Video properties extracted
        
        return VideoAnalysisMetadata(
            videoDuration: videoDuration,
            videoResolution: videoSize,
            videoFileSize: fileSize,
            processingTime: 0,
            selectedShotType: ""
        )
    }
    
    // MARK: - Private Methods - Prompt Creation

    /// Create analysis prompt for shot evaluation
    private static func createAnalysisPrompt(for shotType: ShotType) -> String {
        return """
        Analyze this \(shotType.displayName) hockey shot and provide a comprehensive evaluation.

        Evaluate the following aspects based on what you observe in the video:

        1. **Technique** (0-100): Rate the shot mechanics, form, weight transfer, stick handling, and overall execution quality
        2. **Power** (0-100): Rate the shot velocity potential, energy transfer, loading mechanics, and explosive force generation
        3. **Overall Rating** (0-100): Holistic assessment of the shot quality considering both technique and power

        For each score, provide specific reasoning based on observations from the video (what you actually see, not generic advice).

        Include a brief 2-3 sentence summary highlighting the key strengths and areas for improvement.

        IMPORTANT: Return your analysis as valid JSON matching the schema. Base all scores and feedback on actual observations from the video.
        """
    }
}
