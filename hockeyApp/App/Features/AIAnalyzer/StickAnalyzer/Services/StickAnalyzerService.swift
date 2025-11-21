import Foundation
import AVFoundation

// MARK: - Stick Analyzer Service
/// Service for analyzing hockey sticks using AI
/// Uses typed response model (StickAnalysisResponse) with flat schema
class StickAnalyzerService {

    // MARK: - Validation (Using Shared Service)

    /// Type alias for shared validation response
    typealias ValidationResponse = AIValidationService.ValidationResponse

    // MARK: - Public Methods

    /// Validate if a video contains a visible hockey stick
    static func validateStick(videoURL: URL) async throws -> ValidationResponse {
        return try await AIValidationService.validateHockeyStick(videoURL: videoURL)
    }

    /// Analyze stick specifications without validation (validation done separately)
    static func analyzeStickWithoutValidation(
        shotVideoURL: URL,
        playerProfile: PlayerProfile,
        questionnaire: ShootingQuestionnaire
    ) async throws -> StickAnalysisResult {

        let startTime = Date()

        // Check if AI service is available
        guard AIAnalysisFacade.isAvailable else {
            throw AIAnalyzerError.aiProcessingFailed("AI service is not available")
        }

        // Skip validation and proceed directly to analysis
        return try await performStickAnalysis(
            shotVideoURL: shotVideoURL,
            playerProfile: playerProfile,
            questionnaire: questionnaire,
            startTime: startTime
        )
    }

    /// Analyze stick specifications based on player data and shooting video
    static func analyzeStick(
        shotVideoURL: URL,
        playerProfile: PlayerProfile,
        questionnaire: ShootingQuestionnaire
    ) async throws -> StickAnalysisResult {

        let startTime = Date()

        // Check if AI service is available
        guard AIAnalysisFacade.isAvailable else {
            throw AIAnalyzerError.aiProcessingFailed("AI service is not available")
        }

        // STEP 1: Validate hockey shot first
        let validation = try await validateStick(videoURL: shotVideoURL)

        if !validation.is_valid {
            let reason = validation.reason ?? "Not a valid hockey shot"
            throw AIAnalyzerError.invalidContent(.aiDetectedInvalidContent(reason))
        }

        // STEP 2: Now proceed with stick analysis
        return try await performStickAnalysis(
            shotVideoURL: shotVideoURL,
            playerProfile: playerProfile,
            questionnaire: questionnaire,
            startTime: startTime
        )
    }

    // MARK: - Private Methods

    private static func performStickAnalysis(
        shotVideoURL: URL,
        playerProfile: PlayerProfile,
        questionnaire: ShootingQuestionnaire,
        startTime: Date
    ) async throws -> StickAnalysisResult {
        // Show a brief cellular notice overlay before heavy analysis (non-blocking)
        AINetworkPreflight.showCellularNoticeIfNeeded()

        // Extract metadata from video
        let videoMetadata = try await extractVideoMetadata(from: shotVideoURL)

        // Calculate video size in KB
        let fileSize = try? FileManager.default.attributesOfItem(atPath: shotVideoURL.path)[.size] as? Int64 ?? 0
        let videoSizeKB = Int((fileSize ?? 0) / 1024)

        // Track analysis started
        let provider = "gemini"
        AIPerformanceAnalytics.trackAnalysisStarted(
            feature: .stickAnalyzer,
            provider: provider,
            imageSizeKB: videoSizeKB,
            context: "stick_recommendation"
        )

        // Create analysis prompt
        let prompt = createAnalysisPrompt(
            playerProfile: playerProfile,
            questionnaire: questionnaire
        )

        // Use typed response parsing
        return try await withCheckedThrowingContinuation { continuation in
            let request = AIAnalysisFacade.AIRequest.singleVideo(
                videoURL: shotVideoURL,
                prompt: prompt,
                frameRate: 10,  // Optimized 10 FPS for detailed stick analysis (67% faster than 30 FPS)
                generationConfig: [
                    "temperature": 0.1,
                    "topK": 10,
                    "topP": 0.8,
                    "maxOutputTokens": 8192,
                    // Enforce raw JSON output with strict schema
                    "response_mime_type": "application/json",
                    "response_schema": StickAnalysisResponse.schemaDefinition.toDictionary(),
                    // Keep camelCase for compatibility
                    "responseSchema": StickAnalysisResponse.schemaDefinition.toDictionary()
                ]
            )

            AIAnalysisFacade.sendToAI(request: request) { result in
                switch result {
                case .success(let rawResponse):
                    // Clean and parse the response
                    let cleanedResponse = AIAnalysisFacade.sanitizeJSON(from: rawResponse)
                    let data = cleanedResponse.data(using: .utf8) ?? Data()

                    do {
                        // Decode the typed response format
                        let decoder = JSONDecoder()
                        let stickResponse = try decoder.decode(StickAnalysisResponse.self, from: data)

                        // Convert to StickAnalysisResult
                        let analysisResult = self.createAnalysisResult(
                            from: stickResponse,
                            playerProfile: playerProfile,
                            shotVideoURL: shotVideoURL,
                            processingTime: Date().timeIntervalSince(startTime)
                        )

                        // Track successful analysis
                        let duration = Date().timeIntervalSince(startTime)
                        AIPerformanceAnalytics.trackAnalysisCompleted(
                            feature: .stickAnalyzer,
                            provider: provider,
                            durationSeconds: duration,
                            tokensUsed: nil,
                            responseValid: true,
                            containsPerson: nil,
                            scoreGenerated: nil,  // Stick analyzer doesn't generate scores
                            hasPremiumData: !stickResponse.recommended_sticks.isEmpty,
                            imageSizeKB: videoSizeKB
                        )

                        continuation.resume(returning: analysisResult)

                    } catch let parseError {
                        #if DEBUG
                        print("❌ [StickAnalyzerService] Analysis parsing failed")
                        print("📄 Response preview: \(String(cleanedResponse.prefix(500)))")
                        print("💥 Error: \(parseError.localizedDescription)")
                        #endif

                        // Track parsing failure
                        let duration = Date().timeIntervalSince(startTime)
                        AIPerformanceAnalytics.trackAnalysisFailed(
                            feature: .stickAnalyzer,
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
                        feature: .stickAnalyzer,
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

    // MARK: - Private Helper Methods

    /// Create analysis prompt for stick evaluation
    private static func createAnalysisPrompt(
        playerProfile: PlayerProfile,
        questionnaire: ShootingQuestionnaire
    ) -> String {
        let heightStr = playerProfile.heightInFeetAndInches
        let weightStr = Int(playerProfile.weight ?? 0)
        let ageStr = playerProfile.age != nil ? String(playerProfile.age!) : "Not specified"
        let genderStr = playerProfile.gender?.rawValue ?? "Not specified"
        let positionStr = playerProfile.position?.rawValue ?? "Not specified"
        let priorityStr = questionnaire.priorityFocus.rawValue
        let primaryShotStr = questionnaire.primaryShot.rawValue
        let zoneStr = questionnaire.shootingZone.rawValue

        return """
        Analyze this player's shooting technique from the provided video and provide personalized stick recommendations.

        PLAYER PROFILE:
        - Height: \(heightStr)
        - Weight: \(weightStr) lbs
        - Age: \(ageStr)
        - Gender: \(genderStr)
        - Position: \(positionStr)
        - Priority: \(priorityStr)
        - Primary Shot: \(primaryShotStr)
        - Shooting Zone: \(zoneStr)

        HOCKEY STICK GUIDELINES:

        Flex Guidelines (weight-based):
        - Under 120 lbs: 50-60 flex (intermediate/youth)
        - 120-140 lbs: 55-65 flex (intermediate)
        - 140-160 lbs: 65-75 flex (intermediate/senior transition)
        - 160-180 lbs: 75-85 flex (senior)
        - Over 180 lbs: 85+ flex (senior)
        - Female players: Subtract additional 5-10 from ranges above
        - Style: Lower for wrist shots, higher for slap shots (±5)

        Length Guidelines (height-based):
        - Under 5'4": 52-54" (youth/junior)
        - 5'4" to 5'7": 54-57" (intermediate)
        - 5'7" to 5'10": 57-59" (intermediate/senior)
        - Over 5'10": 59-62" (senior)
        - Small players (under 5'7" OR under 140 lbs): Use intermediate sticks

        Curve Options:
        - P92 (Mid-Toe, Open): Quick elevation, wrist shots
        - P88 (Mid, slightly closed): Control, accurate passing
        - P28 (Toe, Open): Fast elevation, deceptive release
        - P29 (Mid-Open): Balanced versatility
        - P90/P90TM (Modern Mid): Balance of elevation + control

        Kick Point:
        - Low: Fastest release (wrist/snap shots)
        - Mid: Balanced (all shot types)
        - High: Maximum power (slap shots)

        Lie Angle: 4-6 range (ensure flat blade contact)

        IMPORTANT: Return your analysis as valid JSON matching the schema. Provide RANGES for flex and length (min/max values). Each reasoning must be 35-40 words and specifically reference the player's profile. Recommend 3-5 specific stick models with match scores (0-100).

        Base all recommendations on actual observations from the video and the player's profile.
        """
    }

    private static func extractVideoMetadata(from url: URL) async throws -> [String: Any] {
        return try await AIAnalysisFacade.extractVideoMetadata(from: url)
    }

    private static func createAnalysisResult(
        from aiResponse: StickAnalysisResponse,
        playerProfile: PlayerProfile,
        shotVideoURL: URL,
        processingTime: TimeInterval
    ) -> StickAnalysisResult {
        // Build recommendations from AI response
        let recommendations = StickRecommendations(
            idealFlex: FlexRange(
                min: aiResponse.ideal_flex_min,
                max: aiResponse.ideal_flex_max,
                reasoning: aiResponse.flex_reasoning
            ),
            idealLength: LengthRange(
                minInches: aiResponse.ideal_length_min,
                maxInches: aiResponse.ideal_length_max,
                reasoning: aiResponse.length_reasoning
            ),
            idealCurve: aiResponse.ideal_curves,
            idealKickPoint: KickPointType(rawValue: aiResponse.ideal_kick_point) ?? .mid,
            idealLie: aiResponse.ideal_lie,
            topStickModels: aiResponse.recommended_sticks.map { stick in
                RecommendedStick(
                    brand: stick.brand,
                    model: stick.model,
                    flex: stick.flex,
                    curve: stick.curve,
                    kickPoint: KickPointType(rawValue: stick.kick_point) ?? .mid,
                    price: stick.price,
                    reasoning: stick.reasoning,
                    matchScore: stick.match_score
                )
            },
            curveReasoning: aiResponse.curve_reasoning,
            kickPointReasoning: aiResponse.kick_point_reasoning,
            lieReasoning: aiResponse.lie_reasoning,
            recommendedProfiles: nil
        )

        return StickAnalysisResult(
            confidence: aiResponse.confidence,
            playerProfile: playerProfile,
            shotVideoURL: shotVideoURL,
            recommendations: recommendations,
            processingTime: processingTime
        )
    }
}
