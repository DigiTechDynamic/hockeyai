import Foundation

// MARK: - Timeout Helper
func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }

        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }

        guard let result = try await group.next() else {
            throw TimeoutError()
        }

        group.cancelAll()
        return result
    }
}

struct TimeoutError: Error {
    let localizedDescription = "Operation timed out"
}

// MARK: - Shared AI Validation Service
/// Common validation logic shared across AICoach, ShotRater, and StickAnalyzer
class AIValidationService {

    // MARK: - Common Validation Response Schema

    /// Standard validation result used across all AI features
    struct ValidationResponse: Codable, Equatable {
        let is_valid: Bool
        let confidence: Double
        let reason: String?

        // Optional fields for multi-angle validation
        let has_front_angle: Bool?
        let has_side_angle: Bool?

        init(is_valid: Bool, confidence: Double, reason: String? = nil,
             has_front_angle: Bool? = nil, has_side_angle: Bool? = nil) {
            self.is_valid = is_valid
            self.confidence = confidence
            self.reason = reason
            self.has_front_angle = has_front_angle
            self.has_side_angle = has_side_angle
        }
    }

    /// Schema definition for basic shot validation
    private static var shotValidationSchema: [String: Any] {
        return [
            "type": "object",
            "properties": [
                "is_valid": ["type": "boolean"],
                "confidence": ["type": "number", "minimum": 0, "maximum": 1],
                "reason": ["type": "string", "nullable": true],
                "has_front_angle": ["type": "boolean", "nullable": true],
                "has_side_angle": ["type": "boolean", "nullable": true]
            ],
            "required": ["is_valid", "confidence"]
        ]
    }


    // MARK: - Public Validation Methods

    /// Validate if a video contains a valid hockey shot
    static func validateHockeyShot(videoURL: URL) async throws -> ValidationResponse {
        guard AIAnalysisFacade.isAvailable else {
            throw AIAnalyzerError.networkIssue
        }

        // Preflight (non-blocking): show cellular notice before network work
        AINetworkPreflight.showCellularNoticeIfNeeded()

        let prompt = """
        Is this a hockey-related video with a player and stick?

        Requirements:
        - Player visible with hockey stick
        - Hockey-related activity (shooting, passing, stick handling - any is OK)

        Return JSON with:
        - is_valid: true if requirements met, false otherwise
        - confidence: 0.0 to 1.0
        - reason: brief explanation only if invalid (null if valid)
        """

        return try await performValidation(
            videoURL: videoURL,
            prompt: prompt,
            schema: shotValidationSchema,
            frameRate: 1 // Ultra-fast 1 FPS for basic presence validation (66% faster than 3 FPS)
        )
    }

    /// Validate if a video contains a valid hockey shot for multi-angle analysis
    static func validateHockeyShotWithAngles(videoURL: URL) async throws -> ValidationResponse {
        guard AIAnalysisFacade.isAvailable else {
            throw AIAnalyzerError.networkIssue
        }

        // Preflight (non-blocking): show cellular notice before network work
        AINetworkPreflight.showCellularNoticeIfNeeded()

        let prompt = """
        Is this a hockey-related video with a player and stick?

        Requirements:
        - Player visible with hockey stick
        - Hockey-related activity (shooting, passing, stick handling - any is OK)

        Return JSON with:
        - is_valid: true if requirements met, false otherwise
        - confidence: 0.0 to 1.0
        - reason: brief explanation only if invalid (null if valid)
        - has_front_angle: true if this appears to be from front/net view
        - has_side_angle: true if this appears to be from side view
        """

        return try await performValidation(
            videoURL: videoURL,
            prompt: prompt,
            schema: shotValidationSchema,
            frameRate: 1 // Ultra-fast 1 FPS for basic presence validation (66% faster than 3 FPS)
        )
    }

    /// Validate if a video shows hockey shooting motion (uses same validation as shot rater)
    static func validateHockeyStick(videoURL: URL) async throws -> ValidationResponse {
        // For stick analyzer, we use the same validation as shot rater
        // This ensures consistency across all features
        return try await validateHockeyShot(videoURL: videoURL)
    }

    /// Validate multiple videos sequentially (for AI Coach with two angles)
    /// Smart validation that adapts to network conditions
    static func validateMultipleShots(videoURLs: [URL]) async throws -> ValidationResponse {
        guard !videoURLs.isEmpty else {
            throw AIAnalyzerError.aiProcessingFailed("No videos provided for validation")
        }

        // Preflight (non-blocking) once for multi-video validation
        AINetworkPreflight.showCellularNoticeIfNeeded()

        // For now, always use full validation since network quality check is not available
        // This ensures the app works properly
        print("🔍 [AIValidationService] Using full validation for \(videoURLs.count) videos")
        return try await validateMultipleShotsFull(videoURLs: videoURLs)
    }

    /// Full validation for good network conditions
    private static func validateMultipleShotsFull(videoURLs: [URL]) async throws -> ValidationResponse {
        print("🔍 [AIValidationService] Validating \(videoURLs.count) videos sequentially for better reliability")

        var allValid = true
        var minConfidence: Double = 1.0
        var hasFrontAngle = false
        var hasSideAngle = false
        var reasons: [String] = []

        // Validate videos one by one (sequential) instead of parallel
        for (index, videoURL) in videoURLs.enumerated() {
            print("🔍 [AIValidationService] Validating video \(index + 1) of \(videoURLs.count): \(videoURL.lastPathComponent)")

            do {
                // Add timeout for individual validation (2 minutes max per video)
                let result = try await withTimeout(seconds: 120) {
                    try await validateHockeyShotWithAngles(videoURL: videoURL)
                }
                print("✅ [AIValidationService] Video \(index + 1) validation: valid=\(result.is_valid), confidence=\(result.confidence)")

                if !result.is_valid {
                    allValid = false
                    if let reason = result.reason {
                        reasons.append("Video \(index + 1): \(reason)")
                    }
                }

                minConfidence = min(minConfidence, result.confidence)
                hasFrontAngle = hasFrontAngle || (result.has_front_angle ?? false)
                hasSideAngle = hasSideAngle || (result.has_side_angle ?? false)

            } catch is TimeoutError {
                print("⏰ [AIValidationService] Video \(index + 1) validation timed out after 2 minutes, assuming valid")
                // Treat all networks the same; use general timeout handling
                minConfidence = min(minConfidence, 0.7)
                hasFrontAngle = true
                hasSideAngle = true
            } catch {
                print("⚠️ [AIValidationService] Video \(index + 1) validation failed: \(error), assuming valid to not block users")
                // If individual validation fails, assume valid to not block users
                minConfidence = min(minConfidence, 0.5)
                hasFrontAngle = true // Assume both angles present if validation fails
                hasSideAngle = true
            }
        }

        // Return combined result
        let finalReason = reasons.isEmpty ? nil : reasons.joined(separator: "; ")

        print("🔍 [AIValidationService] Sequential validation complete: valid=\(allValid), confidence=\(minConfidence)")

        return ValidationResponse(
            is_valid: allValid,
            confidence: minConfidence,
            reason: finalReason,
            has_front_angle: hasFrontAngle,
            has_side_angle: hasSideAngle
        )
    }


    // MARK: - Private Helper Methods

    /// Core validation logic shared across all validation types
    private static func performValidation(
        videoURL: URL,
        prompt: String,
        schema: [String: Any],
        frameRate: Int,
        transform: ((ValidationResponse) -> ValidationResponse)? = nil
    ) async throws -> ValidationResponse {

        return try await withCheckedThrowingContinuation { continuation in
            let request = AIAnalysisFacade.AIRequest.singleVideo(
                videoURL: videoURL,
                prompt: prompt,
                frameRate: frameRate,
                generationConfig: [
                    // Enforce machine-readable JSON in validation
                    "response_mime_type": "application/json",
                    "response_schema": schema,
                    // Keep camelCase for compatibility
                    "responseSchema": schema,
                    // Sampling + limits
                    "temperature": 0.1,
                    "topK": 10,
                    "topP": 0.8,
                    "maxOutputTokens": 1024
                ]
            )

            AIAnalysisFacade.sendToAI(request: request) { result in
                switch result {
                case .success(let rawResponse):
                    do {
                        // Clean and parse response
                        let cleanedResponse = AIAnalysisFacade.sanitizeJSON(from: rawResponse)
                        let data = cleanedResponse.data(using: .utf8) ?? Data()

                        // Try to decode validation response
                        let validation = try JSONDecoder().decode(ValidationResponse.self, from: data)
                        let finalValidation = transform?(validation) ?? validation
                        continuation.resume(returning: finalValidation)

                    } catch let parseError {
                        #if DEBUG
                        print("❌ [AIValidationService] Validation parsing failed")
                        print("📄 Response: \(String(rawResponse.prefix(500)))")
                        print("💥 Error: \(parseError.localizedDescription)")
                        #endif

                        continuation.resume(throwing: AIAnalyzerError.validationParsingFailed(
                            "Could not validate video. Please try again."
                        ))
                    }

                case .failure(let error):
                    continuation.resume(throwing: AIAnalyzerError.from(error))
                }
            }
        }
    }
}
