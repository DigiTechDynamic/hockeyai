import Foundation
import AVFoundation

// MARK: - Skill Check Service
/// Service for analyzing any hockey skill using AI
class SkillCheckService {

    // MARK: - Validation (Using Shared Service)

    /// Type alias for shared validation response
    typealias ValidationResponse = AIValidationService.ValidationResponse

    // MARK: - Public Methods

    /// Validate if a video contains valid hockey content
    /// - Parameter videoURL: URL to the video file
    /// - Returns: Validation result with confidence and reason
    static func validateSkill(videoURL: URL) async throws -> ValidationResponse {
        return try await AIValidationService.validateHockeyShot(videoURL: videoURL)
    }

    /// Analyze any hockey skill from video
    /// - Parameters:
    ///   - videoURL: URL to the video file
    static func analyzeSkill(videoURL: URL) async throws -> SkillAnalysisResult {

        let startTime = Date()

        // Show a brief cellular notice (non-blocking overlay)
        AINetworkPreflight.showCellularNoticeIfNeeded()

        // Check if AI service is available
        guard AIAnalysisFacade.isAvailable else {
            throw AIAnalyzerError.networkIssue
        }

        // Get video metadata
        let metadata = try await extractVideoMetadata(from: videoURL)

        // Calculate video size in KB
        let fileSize = try? FileManager.default.attributesOfItem(atPath: videoURL.path)[.size] as? Int64 ?? 0
        let videoSizeKB = Int((fileSize ?? 0) / 1024)

        // Track analysis started
        let provider = "gemini"  // Using Gemini for video analysis
        AIPerformanceAnalytics.trackAnalysisStarted(
            feature: .skillCheck,
            provider: provider,
            imageSizeKB: videoSizeKB,
            context: "skill_check"
        )

        // Create analysis prompt
        let prompt = createAnalysisPrompt()

        // Use typed response parsing
        return try await withCheckedThrowingContinuation { continuation in
            let request = AIAnalysisFacade.AIRequest.singleVideo(
                videoURL: videoURL,
                prompt: prompt,
                frameRate: 10,  // Optimized 10 FPS for detailed analysis
                generationConfig: [
                    "temperature": 0.1,
                    "topK": 10,
                    "maxOutputTokens": 4096,
                    // Enforce raw JSON output with strict schema
                    "response_mime_type": "application/json",
                    "response_schema": SkillCheckSchema.schemaDefinition.toDictionary(),
                    // Keep camelCase for compatibility
                    "responseSchema": SkillCheckSchema.schemaDefinition.toDictionary()
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
                        let skillResponse = try decoder.decode(SkillCheckResponse.self, from: data)

                        // Update metadata with processing info
                        var updatedMetadata = metadata
                        updatedMetadata.processingTime = Date().timeIntervalSince(startTime)

                        // Convert to SkillAnalysisResult
                        let analysisResult = SkillAnalysisResult(
                            confidence: skillResponse.confidence,
                            overallScore: skillResponse.overall_rating,
                            category: skillResponse.category,
                            aiComment: skillResponse.aiComment,
                            premiumBreakdown: skillResponse.premiumBreakdown,
                            videoURL: videoURL,
                            analysisMetadata: updatedMetadata
                        )

                        // Track successful analysis
                        let duration = Date().timeIntervalSince(startTime)
                        AIPerformanceAnalytics.trackAnalysisCompleted(
                            feature: .skillCheck,
                            provider: provider,
                            durationSeconds: duration,
                            tokensUsed: nil,
                            responseValid: true,
                            containsPerson: nil,  // Not applicable for video
                            scoreGenerated: skillResponse.overall_rating,
                            hasPremiumData: skillResponse.premiumBreakdown != nil,
                            imageSizeKB: videoSizeKB
                        )

                        // Track quality issues if premium data is missing
                        if skillResponse.premiumBreakdown == nil {
                            AIPerformanceAnalytics.trackQualityIssue(
                                feature: .skillCheck,
                                issueType: .missingPremiumData,
                                score: skillResponse.overall_rating,
                                hasComment: skillResponse.aiComment != nil && !skillResponse.aiComment.isEmpty,
                                hasPremiumData: false
                            )
                        }

                        continuation.resume(returning: analysisResult)

                    } catch let parseError {
                        #if DEBUG
                        print("❌ [SkillCheckService] Analysis parsing failed")
                        print("📄 Response preview: \(String(cleanedResponse.prefix(500)))")
                        print("💥 Error: \(parseError.localizedDescription)")
                        #endif

                        // Track parsing failure
                        let duration = Date().timeIntervalSince(startTime)
                        AIPerformanceAnalytics.trackAnalysisFailed(
                            feature: .skillCheck,
                            provider: provider,
                            errorType: .parsingError,
                            errorMessage: parseError.localizedDescription,
                            durationBeforeFailure: duration,
                            retryCount: 0,
                            imageSizeKB: videoSizeKB
                        )

                        continuation.resume(throwing: AIAnalyzerError.analysisParsingFailed(
                            "Analysis completed but results couldn't be processed. Please try again."
                        ))
                    }

                case .failure(let error):
                    // Track analysis failure
                    let duration = Date().timeIntervalSince(startTime)
                    let errorType = AIPerformanceAnalytics.categorizeError(error)
                    AIPerformanceAnalytics.trackAnalysisFailed(
                        feature: .skillCheck,
                        provider: provider,
                        errorType: errorType,
                        errorMessage: error.localizedDescription,
                        durationBeforeFailure: duration,
                        retryCount: 0,
                        imageSizeKB: videoSizeKB
                    )

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

        return VideoAnalysisMetadata(
            videoDuration: videoDuration,
            videoResolution: videoSize,
            videoFileSize: fileSize,
            processingTime: 0,
            selectedShotType: ""
        )
    }

    // MARK: - Private Methods - Prompt Creation

    /// Create analysis prompt for generic skill evaluation
    private static func createAnalysisPrompt() -> String {
        return """
        Analyze this hockey video and provide a comprehensive evaluation of whatever skill is being demonstrated.

        The video could show any hockey skill including:
        - Shooting (wrist shot, slap shot, snapshot, backhand)
        - Stickhandling (dekes, puck control, hands)
        - Skating (speed, edges, transitions, stops)
        - Passing (tape-to-tape, saucer passes)
        - Defensive skills (stick checks, positioning)
        - Or any other hockey-related skill

        Evaluate the following:

        1. **Category**: Identify what skill is being demonstrated (e.g., "stickhandling", "shooting", "skating", "passing")
        2. **Overall Rating** (0-100): Holistic assessment of the skill execution quality
        3. **AI Comment**: Write a fun, personalized 1-2 sentence comment from Greeny (the AI mascot) about what you observed. Be encouraging, a bit playful, and reference specific things you saw (equipment, technique, style, etc.). Think of it as Greeny hyping them up or giving them a friendly roast.
        4. **Highlights** (3-5 items): Key strengths and positive observations from what you see in the video
        5. **Tips** (3-5 items): Specific, actionable suggestions for improvement based on what you observe

        IMPORTANT:
        - Base all feedback on actual observations from the video
        - Be specific about what you see (stick position, body mechanics, timing, etc.)
        - Make the AI comment personal and engaging - reference visible details like jersey, location, style
        - Provide actionable coaching advice that the player can implement
        - Keep highlights and tips concise (1-2 sentences each)
        - Return your analysis as valid JSON matching the schema

        Focus on being helpful and constructive while identifying both strengths and areas for development.
        """
    }
}
