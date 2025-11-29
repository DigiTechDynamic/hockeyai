import Foundation
import UIKit

// MARK: - Stick Analyzer Service
/// Service for analyzing hockey sticks using AI
/// Uses body scan images for analysis (no video required)
class StickAnalyzerService {

    // MARK: - Public Methods

    /// Analyze stick specifications based on player data (with optional body scan image)
    static func analyzeStick(
        bodyScanResult: BodyScanResult?,
        playerProfile: PlayerProfile,
        questionnaire: ShootingQuestionnaire
    ) async throws -> StickAnalysisResult {

        let startTime = Date()

        // Check if AI service is available
        guard AIAnalysisFacade.isAvailable else {
            throw AIAnalyzerError.aiProcessingFailed("AI service is not available")
        }

        // Show a brief cellular notice overlay before analysis (non-blocking)
        await MainActor.run {
            AINetworkPreflight.showCellularNoticeIfNeeded()
        }

        // Check if we have a body scan image
        if let bodyScan = bodyScanResult,
           let bodyImage = bodyScan.loadImage(),
           let imageData = bodyImage.jpegData(compressionQuality: 0.8) {
            // Use image-based analysis
            return try await analyzeWithImage(
                imageData: imageData,
                bodyImagePath: bodyScan.imagePath,
                playerProfile: playerProfile,
                questionnaire: questionnaire,
                startTime: startTime
            )
        } else {
            // Use text-only analysis (no body scan)
            return try await analyzeTextOnly(
                playerProfile: playerProfile,
                questionnaire: questionnaire,
                startTime: startTime
            )
        }
    }

    // MARK: - Image-Based Analysis

    private static func analyzeWithImage(
        imageData: Data,
        bodyImagePath: String?,
        playerProfile: PlayerProfile,
        questionnaire: ShootingQuestionnaire,
        startTime: Date
    ) async throws -> StickAnalysisResult {

        // Create analysis prompt with body scan context
        let prompt = createAnalysisPrompt(
            playerProfile: playerProfile,
            questionnaire: questionnaire,
            hasBodyScan: true
        )

        // Use typed response parsing with image
        return try await withCheckedThrowingContinuation { continuation in
            // Use GeminiProvider for image analysis
            let provider = GeminiProvider()

            // Call AI with image data
            provider.analyzeImage(
                imageData: imageData,
                prompt: prompt,
                generationConfig: [
                    "temperature": 0.3,  // Slightly higher for varied stick recommendations
                    "topK": 40,
                    "topP": 0.9,
                    "maxOutputTokens": 8192,
                    "response_mime_type": "application/json",
                    "response_schema": StickAnalysisResponse.schemaDefinition.toDictionary(),
                    "responseSchema": StickAnalysisResponse.schemaDefinition.toDictionary()
                ]
            ) { [provider] result in
                // Capture provider to keep it alive during the async request
                _ = provider
                handleAIResponse(
                    result: result,
                    playerProfile: playerProfile,
                    bodyImagePath: bodyImagePath,
                    startTime: startTime,
                    continuation: continuation
                )
            }
        }
    }

    // MARK: - Text-Only Analysis

    private static func analyzeTextOnly(
        playerProfile: PlayerProfile,
        questionnaire: ShootingQuestionnaire,
        startTime: Date
    ) async throws -> StickAnalysisResult {

        print("📝 [StickAnalyzerService] Using text-only analysis (no body scan)")

        // Create text-only analysis prompt
        let prompt = createAnalysisPrompt(
            playerProfile: playerProfile,
            questionnaire: questionnaire,
            hasBodyScan: false
        )

        // Use typed response parsing without image
        return try await withCheckedThrowingContinuation { continuation in
            let provider = GeminiProvider()

            // Call AI with text-only (no image)
            provider.generateContent(
                prompt: prompt,
                generationConfig: [
                    "temperature": 0.3,  // Slightly higher for varied stick recommendations
                    "topK": 40,
                    "topP": 0.9,
                    "maxOutputTokens": 8192,
                    "response_mime_type": "application/json",
                    "response_schema": StickAnalysisResponse.schemaDefinition.toDictionary(),
                    "responseSchema": StickAnalysisResponse.schemaDefinition.toDictionary()
                ]
            ) { [provider] result in
                // Capture provider to keep it alive during the async request
                _ = provider
                handleAIResponse(
                    result: result,
                    playerProfile: playerProfile,
                    bodyImagePath: nil,
                    startTime: startTime,
                    continuation: continuation
                )
            }
        }
    }

    // MARK: - Shared Response Handler

    private static func handleAIResponse(
        result: Result<String, Error>,
        playerProfile: PlayerProfile,
        bodyImagePath: String?,
        startTime: Date,
        continuation: CheckedContinuation<StickAnalysisResult, Error>
    ) {
        switch result {
        case .success(let rawResponse):
            print("✅ [StickAnalyzerService] AI response received, length: \(rawResponse.count)")

            // Clean and parse the response
            let cleanedResponse = AIAnalysisFacade.sanitizeJSON(from: rawResponse)
            print("🧹 [StickAnalyzerService] Cleaned response length: \(cleanedResponse.count)")

            let data = cleanedResponse.data(using: .utf8) ?? Data()

            do {
                // Decode the typed response format
                let decoder = JSONDecoder()
                let stickResponse = try decoder.decode(StickAnalysisResponse.self, from: data)
                print("📊 [StickAnalyzerService] Parsed successfully - confidence: \(stickResponse.confidence)")

                // Convert to StickAnalysisResult
                let analysisResult = self.createAnalysisResult(
                    from: stickResponse,
                    playerProfile: playerProfile,
                    bodyImagePath: bodyImagePath,
                    processingTime: Date().timeIntervalSince(startTime)
                )

                print("🎯 [StickAnalyzerService] Analysis result created, resuming continuation")
                continuation.resume(returning: analysisResult)

            } catch let parseError {
                print("❌ [StickAnalyzerService] Analysis parsing failed")
                print("📄 Response preview: \(String(cleanedResponse.prefix(500)))")
                print("💥 Error: \(parseError.localizedDescription)")

                // Print more detailed error info
                if let decodingError = parseError as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("🔑 Missing key: \(key.stringValue) at \(context.codingPath)")
                    case .typeMismatch(let type, let context):
                        print("🔄 Type mismatch: expected \(type) at \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("❓ Value not found: \(type) at \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("💔 Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("❓ Unknown decoding error")
                    }
                }

                continuation.resume(throwing: AIAnalyzerError.analysisParsingFailed(
                    "Analysis completed but results couldn't be processed. Please try again."
                ))
            }

        case .failure(let error):
            continuation.resume(throwing: AIAnalyzerError.from(error))
        }
    }

    // MARK: - Private Helper Methods

    /// Create analysis prompt for stick evaluation (with or without body scan)
    private static func createAnalysisPrompt(
        playerProfile: PlayerProfile,
        questionnaire: ShootingQuestionnaire,
        hasBodyScan: Bool
    ) -> String {
        let heightStr = playerProfile.heightInFeetAndInches
        let weightStr = Int(playerProfile.weight ?? 0)
        let ageStr = playerProfile.age != nil ? String(playerProfile.age!) : "Not specified"
        let genderStr = playerProfile.gender?.rawValue ?? "Not specified"
        let positionStr = playerProfile.position?.rawValue ?? "Not specified"
        let priorityStr = questionnaire.priorityFocus.rawValue
        let primaryShotStr = questionnaire.primaryShot.rawValue
        let zoneStr = questionnaire.shootingZone.rawValue

        let intro = hasBodyScan
            ? "Analyze this player's full body photo and provide personalized hockey stick recommendations."
            : "Provide personalized hockey stick recommendations based on the player profile below."

        let bodyAnalysisSection = hasBodyScan
            ? """

        BODY ANALYSIS:
        Look at the full body photo and assess:
        1. Arm span relative to height (affects stick length)
        2. Build type (lean, athletic, stocky) for flex recommendations
        3. Torso-to-leg ratio for stance and lie angle
        4. Overall proportions for optimal stick fit
        """
            : """

        NOTE: No body scan was provided. Base all recommendations on the player's height, weight, and profile data. Use standard proportions for arm span (approximately equal to height) when calculating stick length.
        """

        let reasoningInstructions = hasBodyScan
            ? "Each reasoning must be 35-40 words and reference the player's profile and body proportions observed."
            : "Each reasoning must be 35-40 words and reference the player's profile data (height, weight, position, preferences)."

        return """
        \(intro)

        PLAYER PROFILE:
        - Height: \(heightStr) (use as reference for body proportions)
        - Weight: \(weightStr) lbs
        - Age: \(ageStr)
        - Gender: \(genderStr)
        - Position: \(positionStr)
        - Priority: \(priorityStr)
        - Primary Shot: \(primaryShotStr)
        - Shooting Zone: \(zoneStr)
        \(bodyAnalysisSection)

        HOCKEY STICK GUIDELINES:

        Flex Guidelines (weight-based):
        - Under 120 lbs: 50-60 flex (intermediate/youth)
        - 120-140 lbs: 55-65 flex (intermediate)
        - 140-160 lbs: 65-75 flex (intermediate/senior transition)
        - 160-180 lbs: 75-85 flex (senior)
        - Over 180 lbs: 85+ flex (senior)
        - Female players: Subtract additional 5-10 from ranges above
        - Style: Lower for wrist shots, higher for slap shots (±5)

        Length Guidelines (height-based + arm span adjustment):
        - Under 5'4": 52-54" (youth/junior)
        - 5'4" to 5'7": 54-57" (intermediate)
        - 5'7" to 5'10": 57-59" (intermediate/senior)
        - Over 5'10": 59-62" (senior)
        - Longer arm span = consider +1-2" to length
        - Shorter arm span = consider -1-2" from length

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

        Lie Angle: 4-6 range (ensure flat blade contact based on stance)

        STICK DATABASE - Select from these options based on player profile:

        BAUER (Premium $250-330):
        - Vapor HyperLite 2: Low kick, lightweight, quick release (wrist/snap)
        - Vapor X5 Pro: Low kick, excellent puck feel ($200)
        - Supreme M5 Pro: Mid kick, powerful slap shots
        - Supreme Mach: Mid kick, max power transfer
        - Nexus Sync: Low-mid hybrid, versatile all-around
        - AG5NT: Mid kick, balanced power/release

        CCM (Premium $250-330):
        - Jetspeed FT6 Pro: Low kick, fastest release
        - Jetspeed FT7 Pro: Low kick, optimized loading
        - Ribcor Trigger 8 Pro: Low-mid kick, flex profile
        - Ribcor Trigger 9 Pro: Variable kick, whip effect
        - Tacks AS-V Pro: Mid kick, one-piece feel
        - Tacks XF Pro: Mid-high kick, max power

        WARRIOR (Premium $250-300):
        - Alpha LX2 Pro: Mid kick, balance of power/release
        - Alpha DX Pro: Low kick, quick shots
        - Covert QR5 Pro: Low kick, lightweight snappy
        - Novium Pro: Mid kick, versatile

        TRUE (Premium $280-330):
        - Catalyst 9X: Low kick, quick release
        - Catalyst PX: Mid kick, pro-level
        - HZRDUS PX: Mid-high kick, power focused
        - Project X: Low kick, excellent feel

        SHERWOOD (Mid-tier $150-220):
        - Rekker M90: Low kick, good value
        - Code TMP Pro: Mid kick, solid performance
        - Playrite PP77: Mid kick, durable

        SHER-WOOD (Budget $80-150):
        - Rekker M70: Entry-level, forgiving flex
        - Code TMP 1: Budget friendly, decent performance

        STX (Mid-tier $180-250):
        - Surgeon RX3: Low kick, responsive
        - Stallion HPR 2: Mid kick, durable

        RECOMMENDATION RULES:
        1. VARY your recommendations - don't always pick the same sticks
        2. Consider the player's age/experience level for price tier
        3. Match kick point to primary shot type (low=wrist/snap, mid=versatile, high=slap)
        4. For youth/beginners: recommend mid-tier options ($150-220)
        5. For experienced players: recommend premium options ($250-330)
        6. Include at least ONE stick from a different brand than the top pick
        7. Each recommendation should have DIFFERENT characteristics (vary curves, kick points)

        IMPORTANT: Return your analysis as valid JSON matching the schema. Provide RANGES for flex and length (min/max values). \(reasoningInstructions) Recommend 3-5 specific stick models with match scores (0-100). DIVERSIFY your recommendations across brands and price points.
        """
    }

    private static func createAnalysisResult(
        from aiResponse: StickAnalysisResponse,
        playerProfile: PlayerProfile,
        bodyImagePath: String?,
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
            bodyImagePath: bodyImagePath,
            recommendations: recommendations,
            processingTime: processingTime
        )
    }
}
