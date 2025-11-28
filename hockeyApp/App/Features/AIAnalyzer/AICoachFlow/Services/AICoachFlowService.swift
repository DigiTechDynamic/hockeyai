import Foundation
import AVFoundation

// MARK: - AI Coach Flow Service
class AICoachFlowService {

    // MARK: - Validation (Using Shared Service)

    /// Type alias for shared validation response
    typealias ValidationResponse = AIValidationService.ValidationResponse

    // MARK: - Public Methods

    /// Validate if a video contains a valid hockey shot (single video)
    static func validateShot(videoURL: URL) async throws -> ValidationResponse {
        return try await AIValidationService.validateHockeyShotWithAngles(videoURL: videoURL)
    }

    /// Validate multiple videos in parallel (for AI Coach with two angles)
    static func validateShots(videoURLs: [URL]) async throws -> ValidationResponse {
        return try await AIValidationService.validateMultipleShots(videoURLs: videoURLs)
    }

    /// Analyze hockey shot from multiple angles with player profile context
    static func analyzeShot(
        frontNetVideoURL: URL,
        sideAngleVideoURL: URL,
        shotType: ShotType,
        playerProfile: PlayerProfile
    ) async throws -> AICoachAnalysisResult {

        let startTime = Date()

        // Show a brief cellular notice overlay before multi-video analysis (non-blocking)
        AINetworkPreflight.showCellularNoticeIfNeeded()

        // Check if AI service is available
        guard AIAnalysisFacade.isAvailable else {
            throw AIAnalyzerError.networkIssue
        }

        // Create comprehensive analysis prompt
        let prompt = AICoachFlowConfig.createAnalysisPrompt(
            shotType: shotType,
            playerProfile: playerProfile
        )
        
        // Use contract-based parsing with simplified response handling
        return try await withCheckedThrowingContinuation { continuation in
            // First try to get the raw response
            let request = AIAnalysisFacade.AIRequest.multipleVideos(
                videoURLs: [frontNetVideoURL, sideAngleVideoURL],
                prompt: prompt,
                frameRate: 10,  // Optimized 10 FPS for detailed technique analysis (67% faster than 30 FPS)
                generationConfig: [
                    "temperature": 0.1,
                    "topK": 10,
                    "maxOutputTokens": 8192,
                    // Enforce raw JSON output with strict schema
                    "response_mime_type": "application/json",
                    "response_schema": AICoachSimpleSchema.schemaDefinition.toDictionary(),
                    // Keep camelCase for compatibility
                    "responseSchema": AICoachSimpleSchema.schemaDefinition.toDictionary()
                ]
            )

            AIAnalysisFacade.sendToAI(request: request) { result in
                switch result {
                case .success(let rawResponse):
                    // Clean and parse the response
                    let cleanedResponse = AIAnalysisFacade.sanitizeJSON(from: rawResponse)
                    let data = cleanedResponse.data(using: .utf8) ?? Data()

                    // DEBUG: Log cleaned response length
                    print("🔍 [AICoachFlowService] Cleaned response length: \(cleanedResponse.count) chars")

                    do {
                        // Try to decode the simple response format
                        let decoder = JSONDecoder()
                        let simpleResponse = try decoder.decode(AICoachSimpleResponse.self, from: data)

                        // DEBUG: Log what we got
                        print("🔍 [AICoachFlowService] Successfully parsed typed response")
                        print("   - Overall rating: \(simpleResponse.overall_rating)")
                        print("   - Key observation length: \(simpleResponse.key_observation.count) chars")
                        print("   - how_to_improve length: \(simpleResponse.primary_focus.how_to_improve.count) chars")
                        print("   - Coaching cues: \(simpleResponse.primary_focus.coaching_cues.count) items")

                        // Create analysis result using the typed response directly
                        let analysisResult = AICoachAnalysisResult(
                            shotType: shotType,
                            playerProfile: playerProfile,
                            frontNetVideoURL: frontNetVideoURL,
                            sideAngleVideoURL: sideAngleVideoURL,
                            processingTime: Date().timeIntervalSince(startTime),
                            response: simpleResponse
                        )

                        continuation.resume(returning: analysisResult)

                    } catch let parseError {
                        #if DEBUG
                        print("❌ [AICoachFlowService] Analysis parsing failed")
                        print("📄 Response preview: \(String(cleanedResponse.prefix(500)))")
                        print("💥 Error: \(parseError.localizedDescription)")
                        print("🔍 Expected schema: AICoachSimpleResponse")
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
    
    // MARK: - Private Methods
    
    private static func extractVideoMetadata(from url: URL) async throws -> [String: Any] {
        return try await AIAnalysisFacade.extractVideoMetadata(from: url)
    }
}
