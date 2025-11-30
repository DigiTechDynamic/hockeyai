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
    ///   - context: Optional user-provided context about the skill
    static func analyzeSkill(videoURL: URL, context: SkillCheckContext? = nil) async throws -> SkillAnalysisResult {

        let startTime = Date()

        // Show a brief cellular notice (non-blocking overlay)
        AINetworkPreflight.showCellularNoticeIfNeeded()

        // Check if AI service is available
        guard AIAnalysisFacade.isAvailable else {
            throw AIAnalyzerError.networkIssue
        }

        // Get video metadata
        let metadata = try await extractVideoMetadata(from: videoURL)

        // Create analysis prompt with context
        let prompt = createAnalysisPrompt(context: context)

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

                        continuation.resume(returning: analysisResult)

                    } catch let parseError {
                        #if DEBUG
                        print("❌ [SkillCheckService] Analysis parsing failed")
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
    /// - Parameter context: Optional user-provided context for better analysis
    private static func createAnalysisPrompt(context: SkillCheckContext? = nil) -> String {
        var prompt = """
        Analyze this hockey video and provide a comprehensive evaluation of whatever skill is being demonstrated.

        The video could show any hockey skill including:
        - Shooting (wrist shot, slap shot, snapshot, backhand)
        - Stickhandling (dekes, puck control, hands)
        - Skating (speed, edges, transitions, stops)
        - Passing (tape-to-tape, saucer passes)
        - Goaltending (positioning, saves, movement)
        - Defensive skills (stick checks, positioning)
        - Or any other hockey-related skill

        Provide the following:

        1. **Category**: Identify what skill is being demonstrated (e.g., "wrist shot", "skating", "stickhandling")

        2. **Overall Rating** (0-100): Holistic assessment of skill execution quality. NEVER use multiples of 5 (not 70, 75, 80, etc). Use natural numbers like 73, 78, 82, 87, 91.

        3. **AI Comment**: A fun, personalized 1-2 sentence comment from Greeny (the AI mascot). Be encouraging and reference specific things you observed in the video.

        4. **What You Did Well** (exactly 3 items): Specific positive observations about their technique. Be precise about what you see (e.g., "Great weight transfer from back to front foot", "Smooth stick flex on release"). Each item = 1 short sentence.

        5. **What To Work On** (exactly 3 items): Specific areas for improvement. Be constructive and actionable (e.g., "Keep elbow higher during release", "Bend knees more for better power"). Each item = 1 short sentence.

        6. **How To Improve** (exactly 3 items): Practical drills or exercises they can do to get better. Include the drill name and brief description (e.g., "Wall shots - 50 reps daily focusing on quick release", "Balance board stickhandling for stability"). Each item = 1 short sentence.

        CRITICAL REQUIREMENTS:
        - Base ALL feedback on actual observations from the video - don't make generic statements
        - Be specific about technique (stick position, body mechanics, timing, weight transfer, etc.)
        - Each array must have EXACTLY 3 items - no more, no less
        - The feedback should work for ANY skill the user submits (shooting, skating, goalie, etc.)
        - Return valid JSON matching the schema
        """

        // Add user context if provided
        if let context = context {
            prompt += context.promptContext
        }

        return prompt
    }
}
