import Foundation
import AVFoundation

// MARK: - AI Analysis Facade
/// Generic AI analysis facade for video content
/// This facade provides a clean interface for AI analysis without business logic
class AIAnalysisFacade {
    
    // MARK: - Properties
    private static let provider: AIProvider = GeminiProvider()

    // MARK: - Unified AI Request

    /// Unified request structure for all AI analysis operations
    struct AIRequest {
        let prompt: String
        let videos: [URL]
        let frameRate: Int?
        let generationConfig: [String: Any]?

        /// Create request for single video analysis
        static func singleVideo(
            videoURL: URL,
            prompt: String,
            frameRate: Int? = nil,
            generationConfig: [String: Any]? = nil
        ) -> AIRequest {
            return AIRequest(
                prompt: prompt,
                videos: [videoURL],
                frameRate: frameRate,
                generationConfig: generationConfig
            )
        }

        /// Create request for multiple video analysis
        static func multipleVideos(
            videoURLs: [URL],
            prompt: String,
            frameRate: Int? = nil,
            generationConfig: [String: Any]? = nil
        ) -> AIRequest {
            return AIRequest(
                prompt: prompt,
                videos: videoURLs,
                frameRate: frameRate,
                generationConfig: generationConfig
            )
        }
    }

    /// Unified method to send requests to AI
    /// - Parameters:
    ///   - request: The AI request containing prompt and videos
    ///   - completion: Completion handler with raw AI response or error
    static func sendToAI(
        request: AIRequest,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard !request.videos.isEmpty else {
            print("❌ [AIAnalysisFacade] sendToAI: No videos provided")
            DispatchQueue.main.async {
                completion(.failure(AIProviderError.providerUnavailable("No videos provided")))
            }
            return
        }

        // Check if provider is available
        guard provider.isAvailable else {
            print("❌ [AIAnalysisFacade] AI Provider \(provider.providerName) is not available")
            DispatchQueue.main.async {
                completion(.failure(AIProviderError.providerUnavailable("AI service is not available")))
            }
            return
        }

        if request.videos.count == 1 {
            // Single video analysis
            print("🎯 [AIAnalysisFacade] Analyzing single video...")
            print("✅ [AIAnalysisFacade] Using \(provider.providerName) provider")

            provider.analyzeVideo(
                videoURL: request.videos[0],
                prompt: request.prompt,
                frameRate: request.frameRate,
                generationConfig: request.generationConfig
            ) { result in
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        } else {
            // Multiple videos analysis
            print("🎯 [AIAnalysisFacade] Analyzing multiple videos (\(request.videos.count))...")
            print("✅ [AIAnalysisFacade] Using \(provider.providerName) provider")

            // Get the underlying AI service if it's Gemini
            guard let geminiProvider = provider as? GeminiProvider,
                  let aiService = geminiProvider.aiService else {
                completion(.failure(AIProviderError.providerUnavailable("Multi-video analysis not supported")))
                return
            }

            Task {
                var downsampledURLs: [URL] = []  // Track temp files for cleanup (outside do block for error handler)

                do {
                    var videoDataArray: [(data: Data, mimeType: String)] = []
                    var videoMetadataArray: [VideoMetadata] = []

                    // Process all videos
                    for (index, videoURL) in request.videos.enumerated() {
                        // Downsample video to target FPS before upload
                        let targetFPS = request.frameRate ?? 10  // Use provided FPS or default to 10
                        print("🎬 [AIAnalysisFacade] Downsampling video \(index + 1) to \(targetFPS) FPS...")

                        let downsampledURL = try await geminiProvider.downsampleVideo(url: videoURL, targetFPS: targetFPS)
                        downsampledURLs.append(downsampledURL)

                        // Extract downsampled video data
                        guard let videoData = try? Data(contentsOf: downsampledURL) else {
                            // Cleanup on error
                            for tempURL in downsampledURLs {
                                try? FileManager.default.removeItem(at: tempURL)
                            }
                            completion(.failure(AIProviderError.videoProcessingFailed("Failed to read downsampled video file: \(videoURL.lastPathComponent)")))
                            return
                        }

                        videoDataArray.append((data: videoData, mimeType: "video/mp4"))
                        videoMetadataArray.append(VideoMetadata(fps: targetFPS))

                        print("📊 [AIAnalysisFacade] Video \(index + 1) (\(videoURL.lastPathComponent)): \(videoData.count / 1024) KB, \(targetFPS) FPS")
                    }

                    // Call AI service with multiple videos
                    aiService.generateFromMultipleVideos(
                        prompt: request.prompt,
                        videoDataArray: videoDataArray,
                        videoMetadataArray: videoMetadataArray,
                        generationConfig: request.generationConfig
                    ) { result in
                        // Best-effort cleanup of temp downsampled files
                        for tempURL in downsampledURLs {
                            try? FileManager.default.removeItem(at: tempURL)
                        }

                        DispatchQueue.main.async {
                            completion(result)
                        }
                    }

                } catch {
                    // Cleanup on error
                    for tempURL in downsampledURLs {
                        try? FileManager.default.removeItem(at: tempURL)
                    }
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Utility Methods

    /// Cancel any active AI requests (best-effort)
    static func cancelActiveRequests() {
        if let geminiProvider = provider as? GeminiProvider,
           let service = geminiProvider.aiService {
            service.cancelActiveRequests()
        }
    }

    /// Check if AI service is available
    static var isAvailable: Bool {
        return provider.isAvailable
    }

    /// Get provider name for debugging
    static var providerName: String {
        return provider.providerName
    }
    
    // MARK: - Video Metadata Extraction
    
    /// Extract basic metadata from video
    /// - Parameter videoURL: URL to the video file
    /// - Returns: Dictionary with video metadata
    static func extractVideoMetadata(from videoURL: URL) async throws -> [String: Any] {
        let videoAsset = AVURLAsset(url: videoURL)
        let videoDuration = try await videoAsset.load(.duration).seconds
        let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first
        let videoSize = try await videoTrack?.load(.naturalSize) ?? .zero
        let frameRate = try await videoTrack?.load(.nominalFrameRate) ?? 30.0
        let videoFileSize = try? FileManager.default.attributesOfItem(atPath: videoURL.path)[.size] as? Int64 ?? 0
        
        return [
            "duration": videoDuration,
            "width": Int(videoSize.width),
            "height": Int(videoSize.height),
            "frameRate": Int(frameRate),
            "fileSize": videoFileSize ?? 0,
            "isLandscape": videoSize.width > videoSize.height
        ]
    }
    
    /// Extract frame rate from video
    /// - Parameter videoURL: URL to the video file
    /// - Returns: Frame rate as Float
    private static func extractVideoFrameRate(from videoURL: URL) async throws -> Float {
        let videoAsset = AVURLAsset(url: videoURL)
        let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first
        let frameRate = try await videoTrack?.load(.nominalFrameRate) ?? 30.0
        return frameRate
    }
    
    // MARK: - JSON Extraction Helper
    
    /// Extract JSON from a response string that may contain markdown or other formatting
    /// - Parameter response: The raw response string
    /// - Returns: Clean JSON string
    static func extractJSON(from response: String) -> String {
        var cleanedResponse = response
        
        // Remove thinking tags if present
        if let thinkingStart = response.range(of: "<thinking>"),
           let thinkingEnd = response.range(of: "</thinking>", range: thinkingStart.upperBound..<response.endIndex) {
            let jsonStartIndex = thinkingEnd.upperBound
            cleanedResponse = String(response[jsonStartIndex...])
        }
        
        // Handle markdown code blocks
        if cleanedResponse.contains("```json") {
            let start = cleanedResponse.range(of: "```json\n")?.upperBound ?? cleanedResponse.startIndex
            let end = cleanedResponse.range(of: "\n```", range: start..<cleanedResponse.endIndex)?.lowerBound ?? cleanedResponse.endIndex
            cleanedResponse = String(cleanedResponse[start..<end])
        } else if cleanedResponse.contains("```") {
            // Handle plain ``` blocks
            let start = cleanedResponse.range(of: "```\n")?.upperBound ?? cleanedResponse.startIndex
            let end = cleanedResponse.range(of: "\n```", range: start..<cleanedResponse.endIndex)?.lowerBound ?? cleanedResponse.endIndex
            cleanedResponse = String(cleanedResponse[start..<end])
        }
        
        return cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - JSON Sanitization

    /// Sanitize malformed JSON from AI responses
    ///
    /// This method handles common AI-generated JSON malformations including:
    /// - Markdown code blocks and thinking tags (via extractJSON)
    /// - Priority fields with excessive digits (10+) → normalized to 1
    /// - Numeric fields with excessive digits (20+) → normalized to 1
    /// - Floats with excessive precision (10+ decimals) → rounded to 2 decimals
    /// - Duplicate JSON keys → keeps first occurrence
    ///
    /// - Parameter response: Raw AI response that may contain malformed JSON
    /// - Returns: Sanitized JSON string ready for parsing
    ///
    /// Example:
    /// ```swift
    /// let raw = """
    /// ```json
    /// {"priority": 12345678901234, "score": 2.9170000000000003, "is_valid": true, "is_valid": false}
    /// ```
    /// """
    /// let clean = AIAnalysisFacade.sanitizeJSON(from: raw)
    /// // Result: {"priority": 1, "score": 2.92, "is_valid": true}
    /// ```
    static func sanitizeJSON(from response: String) -> String {
        // Step 1: Extract JSON from markdown/thinking tags
        var cleaned = extractJSON(from: response)

        // Step 2: Fix priority fields with excessive digits (10+)
        // Example: "priority": 1234567890123 -> "priority": 1
        let priorityPattern = #""priority"\s*:\s*\d{10,}"#
        cleaned = cleaned.replacingOccurrences(
            of: priorityPattern,
            with: "\"priority\": 1",
            options: .regularExpression
        )

        // Step 3: Fix any numeric fields with excessive digits (20+)
        // Example: "value": 12345678901234567890 -> "value": 1
        let hugeNumberPattern = #":\s*\d{20,}"#
        cleaned = cleaned.replacingOccurrences(
            of: hugeNumberPattern,
            with: ": 1",
            options: .regularExpression
        )

        // Step 4: Fix floats with excessive precision (10+ decimal places)
        // Example: 2.9170000000000003 -> 2.92
        let floatPattern = #":\s*(\d+\.\d{10,})"#
        if let regex = try? NSRegularExpression(pattern: floatPattern, options: []) {
            let range = NSRange(cleaned.startIndex..., in: cleaned)
            let matches = regex.matches(in: cleaned, options: [], range: range)

            // Process in reverse to maintain string indices
            var result = cleaned
            for match in matches.reversed() {
                guard let matchRange = Range(match.range, in: result) else { continue }
                let matchedText = String(result[matchRange])

                // Extract just the number part
                if let numberMatch = matchedText.range(of: #"\d+\.\d+"#, options: .regularExpression) {
                    let numberStr = String(matchedText[numberMatch])
                    if let number = Double(numberStr) {
                        let replacement = ": \(String(format: "%.2f", number))"
                        result.replaceSubrange(matchRange, with: replacement)
                    }
                }
            }
            cleaned = result
        }

        // Step 5: Remove duplicate keys (common AI error)
        // This handles fields that appear multiple times like "is_valid": true, "is_valid": false
        cleaned = removeDuplicateJSONKeys(from: cleaned)

        return cleaned
    }

    /// Helper to remove duplicate JSON keys
    /// - Parameter json: JSON string that may contain duplicate keys
    /// - Returns: JSON string with duplicates removed (keeps first occurrence)
    private static func removeDuplicateJSONKeys(from json: String) -> String {
        // Pattern matches duplicate keys: "key": value, "key"
        // We need to handle this iteratively since there could be multiple duplicate keys
        var result = json
        var foundDuplicate = true

        // Keep processing until no more duplicates are found
        while foundDuplicate {
            foundDuplicate = false

            // Find any duplicate key pattern
            let duplicatePattern = #"("(\w+)"\s*:\s*[^,}]+),\s*("\2"\s*:\s*[^,}]+)"#

            if let regex = try? NSRegularExpression(pattern: duplicatePattern, options: []),
               let match = regex.firstMatch(in: result, options: [], range: NSRange(result.startIndex..., in: result)),
               match.numberOfRanges > 3,
               let fullRange = Range(match.range, in: result),
               let firstOccurrenceRange = Range(match.range(at: 1), in: result) {

                // Keep first occurrence, remove second
                let beforeMatch = String(result[..<fullRange.lowerBound])
                let firstOccurrence = String(result[firstOccurrenceRange])
                let afterMatch = String(result[fullRange.upperBound...])

                result = beforeMatch + firstOccurrence + afterMatch
                foundDuplicate = true
            }
        }

        return result
    }
}
