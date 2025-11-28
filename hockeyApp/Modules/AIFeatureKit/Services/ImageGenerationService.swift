import Foundation
import UIKit

// MARK: - Image Generation Provider
/// Enum to select which backend to use for image generation
enum ImageGenerationProvider: String, CaseIterable {
    case geminiDirect = "gemini_direct"  // Google's Gemini API directly (FREE during preview)
    case falAI = "fal_ai"                // fal.ai (same Gemini model, $0.15/image, no daily limits)

    var displayName: String {
        switch self {
        case .geminiDirect: return "Gemini Direct"
        case .falAI: return "fal.ai"
        }
    }
}

// MARK: - Gemini Rate Limit Tracker
/// Tracks when Gemini API returns 429 (rate limit exceeded) for the SHARED API key
/// The 250 RPD limit is per API key (shared across ALL users), not per device
/// Strategy: Always try Gemini first, fall back to fal.ai on 429, remember until midnight PT
/// Thread-safe for concurrent access from multiple requests
final class GeminiRateLimitTracker {
    static let shared = GeminiRateLimitTracker()

    private let userDefaults = UserDefaults.standard
    private let rateLimitHitKey = "gemini_rate_limit_hit_date"

    /// Serial queue for thread-safe access
    private let queue = DispatchQueue(label: "com.hockeyapp.gemini.ratelimit", qos: .userInitiated)

    private init() {}

    /// Whether we've received a 429 today (API key is at limit for all users)
    /// Thread-safe read
    var isAtLimit: Bool {
        return queue.sync {
            guard let hitDate = userDefaults.object(forKey: rateLimitHitKey) as? Date else {
                return false
            }

            // Check if the hit was today (Pacific Time - when Gemini quotas reset)
            guard let pacificTimeZone = TimeZone(identifier: "America/Los_Angeles") else {
                // Fallback: if timezone fails, assume not at limit to avoid blocking users
                print("⚠️ [GeminiRateLimitTracker] Failed to get Pacific timezone, defaulting to not at limit")
                return false
            }

            var calendar = Calendar.current
            calendar.timeZone = pacificTimeZone

            let today = calendar.startOfDay(for: Date())
            let hitDay = calendar.startOfDay(for: hitDate)

            // If hit was today or in the future (clock skew protection), we're still at limit
            if hitDay >= today {
                return true
            } else {
                // New day - clear the flag
                userDefaults.removeObject(forKey: rateLimitHitKey)
                print("🔄 [GeminiRateLimitTracker] New day (Pacific Time) - Gemini limit reset, trying Gemini again")
                return false
            }
        }
    }

    /// For backwards compatibility
    var shouldPreferFallback: Bool {
        return isAtLimit
    }

    /// Record a rate limit error (429) - remember that API key is exhausted for today
    /// Thread-safe write
    func recordRateLimitHit() {
        queue.sync {
            // Only record if not already recorded today (avoid redundant writes)
            if let existingDate = userDefaults.object(forKey: rateLimitHitKey) as? Date,
               let pacificTimeZone = TimeZone(identifier: "America/Los_Angeles") {
                var calendar = Calendar.current
                calendar.timeZone = pacificTimeZone
                let today = calendar.startOfDay(for: Date())
                let existingDay = calendar.startOfDay(for: existingDate)

                if existingDay >= today {
                    // Already recorded today, skip
                    return
                }
            }

            userDefaults.set(Date(), forKey: rateLimitHitKey)
            print("⚠️ [GeminiRateLimitTracker] 429 received! API key at daily limit (250 RPD). Using fal.ai until midnight PT.")
        }
    }

    /// No longer tracking individual requests - limit is shared across all users
    func recordRequest() {
        // No-op: We can't track shared API key usage across all users
        // Just rely on 429 detection
    }

    /// Clear the rate limit flag (for testing or manual reset)
    func reset() {
        queue.sync {
            userDefaults.removeObject(forKey: rateLimitHitKey)
            print("🔄 [GeminiRateLimitTracker] Rate limit flag cleared manually")
        }
    }
}

// MARK: - Image Generation Service
/// Service for generating images using either Google's Gemini API directly or via fal.ai
/// Both use the same gemini-3-pro-image-preview model (aka "Nano Banana Pro")
/// fal.ai advantage: No daily rate limits (250/day on Gemini direct), just concurrency limits
final class ImageGenerationService {

    // MARK: - Configuration
    struct Configuration {
        let provider: ImageGenerationProvider
        let geminiBaseURL: String
        let geminiAPIKey: String?
        let falAPIKey: String?
        let modelName: String

        init(provider: ImageGenerationProvider = .falAI,
             geminiBaseURL: String = "https://generativelanguage.googleapis.com/v1beta",
             geminiAPIKey: String? = nil,
             falAPIKey: String? = nil,
             modelName: String = "gemini-3-pro-image-preview") {
            self.provider = provider
            self.geminiBaseURL = geminiBaseURL
            self.geminiAPIKey = geminiAPIKey
            self.falAPIKey = falAPIKey
            self.modelName = modelName
        }
    }

    // MARK: - Generation Parameters
    struct GenerationParameters {
        let aspectRatio: AspectRatio
        let imageSize: ImageSize

        init(aspectRatio: AspectRatio = .threeByFour,
             imageSize: ImageSize = .twoK) {
            self.aspectRatio = aspectRatio
            self.imageSize = imageSize
        }
    }

    enum AspectRatio: String {
        case oneByOne = "1:1"
        case threeByFour = "3:4"
        case fourByThree = "4:3"
        case nineBy16 = "9:16"
        case sixteenByNine = "16:9"
    }

    enum ImageSize: String {
        case oneK = "1K"
        case twoK = "2K"
        case fourK = "4K"
    }

    // MARK: - Error Types
    enum ServiceError: LocalizedError {
        case invalidURL
        case invalidResponse
        case noData
        case decodingError(Error)
        case apiError(String)
        case missingAPIKey
        case imageDecodingFailed
        case noImagesGenerated
        case imageUploadFailed
        case rateLimitExceeded  // HTTP 429 - triggers fallback to fal.ai

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid API URL"
            case .invalidResponse:
                return "Invalid response from server"
            case .noData:
                return "No data received"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .apiError(let message):
                if message.lowercased().contains("rate limit") || message.lowercased().contains("quota") {
                    return "Too many requests. Please wait a moment before trying again."
                } else {
                    return "Image generation failed: \(message)"
                }
            case .missingAPIKey:
                return "API key is missing"
            case .imageDecodingFailed:
                return "Failed to decode generated image"
            case .noImagesGenerated:
                return "No images were generated"
            case .imageUploadFailed:
                return "Failed to upload reference image"
            case .rateLimitExceeded:
                return "Rate limit exceeded. Trying alternate provider..."
            }
        }

        /// Whether this error indicates a rate limit that should trigger fallback
        var isRateLimitError: Bool {
            switch self {
            case .rateLimitExceeded:
                return true
            case .apiError(let message):
                let lowercased = message.lowercased()
                return lowercased.contains("rate limit") ||
                       lowercased.contains("quota") ||
                       lowercased.contains("429") ||
                       lowercased.contains("resource_exhausted")
            default:
                return false
            }
        }
    }

    // MARK: - Constants
    private enum Constants {
        static let defaultRequestTimeout: TimeInterval = 180.0  // 3 minutes for image generation (fal.ai can be slow)
        static let maxRetries = 1
        static let retryDelay: TimeInterval = 2.0

        // fal.ai endpoints
        static let falBaseURL = "https://fal.run"
        static let falGeminiModel = "fal-ai/gemini-3-pro-image-preview/edit"

        // fal.ai file upload endpoint
        static let falUploadURL = "https://fal.run/fal-ai/any/upload"
    }

    // MARK: - Properties
    private let configuration: Configuration
    private let session: URLSession
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    /// Current provider being used
    var currentProvider: ImageGenerationProvider {
        configuration.provider
    }

    // MARK: - Initialization
    init(configuration: Configuration) {
        self.configuration = configuration

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = Constants.defaultRequestTimeout
        sessionConfig.timeoutIntervalForResource = Constants.defaultRequestTimeout
        sessionConfig.networkServiceType = .responsiveData
        sessionConfig.waitsForConnectivity = true
        sessionConfig.allowsCellularAccess = true
        sessionConfig.allowsConstrainedNetworkAccess = true
        sessionConfig.allowsExpensiveNetworkAccess = true

        self.session = URLSession(configuration: sessionConfig)
    }

    /// Convenience initializer that loads API keys from AppSecrets
    /// Uses smart provider selection: Gemini first (FREE), fal.ai as fallback ($0.15/image)
    convenience init?() {
        let falKey = AppSecrets.shared.falAPIKey
        let geminiKey = AppSecrets.shared.geminiAPIKey

        // Must have at least one provider available
        guard falKey != nil || geminiKey != nil else {
            print("❌ [ImageGenerationService] No API keys found")
            return nil
        }

        // Smart provider selection:
        // - Use Gemini if available AND not at rate limit
        // - Fall back to fal.ai if Gemini unavailable OR at rate limit
        let provider: ImageGenerationProvider
        let tracker = GeminiRateLimitTracker.shared

        if geminiKey != nil && !tracker.isAtLimit {
            provider = .geminiDirect
            print("✅ [ImageGenerationService] Using Gemini direct (~$0.13/image)")
        } else if falKey != nil {
            if tracker.isAtLimit {
                print("⚠️ [ImageGenerationService] Gemini hit 429 today, using fal.ai ($0.15/image)")
            } else {
                print("✅ [ImageGenerationService] Using fal.ai ($0.15/image)")
            }
            provider = .falAI
        } else {
            // Only Gemini available but at limit - still try Gemini (might work after midnight PT)
            provider = .geminiDirect
            print("⚠️ [ImageGenerationService] Only Gemini available, attempting despite previous 429")
        }

        self.init(configuration: Configuration(
            provider: provider,
            geminiAPIKey: geminiKey,
            falAPIKey: falKey
        ))
    }

    /// Initialize with a specific provider
    convenience init?(provider: ImageGenerationProvider) {
        let falKey = AppSecrets.shared.falAPIKey
        let geminiKey = AppSecrets.shared.geminiAPIKey

        switch provider {
        case .falAI:
            guard falKey != nil else {
                print("❌ [ImageGenerationService] fal.ai API key not found")
                return nil
            }
        case .geminiDirect:
            guard geminiKey != nil else {
                print("❌ [ImageGenerationService] Gemini API key not found")
                return nil
            }
        }

        self.init(configuration: Configuration(
            provider: provider,
            geminiAPIKey: geminiKey,
            falAPIKey: falKey
        ))
        print("✅ [ImageGenerationService] Initialized with \(provider.displayName)")
    }

    // MARK: - Image Generation

    /// Generate an image from a text prompt
    /// Uses smart provider selection with automatic fallback:
    /// 1. Try Gemini (FREE) first if available and not at rate limit
    /// 2. Fall back to fal.ai ($0.15/image) on rate limit or if Gemini unavailable
    /// - Parameters:
    ///   - prompt: The text description of the image to generate
    ///   - parameters: Generation parameters (size, aspect ratio, etc.)
    ///   - referenceImages: Optional array of reference images to guide generation (max 14)
    ///   - completion: Completion handler with generated image or error
    func generateImage(
        prompt: String,
        parameters: GenerationParameters = GenerationParameters(),
        referenceImages: [UIImage] = [],
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        switch configuration.provider {
        case .geminiDirect:
            generateImageWithGeminiDirectAndFallback(
                prompt: prompt,
                parameters: parameters,
                referenceImages: referenceImages,
                completion: completion
            )
        case .falAI:
            generateImageWithFalAI(
                prompt: prompt,
                parameters: parameters,
                referenceImages: referenceImages,
                completion: completion
            )
        }
    }

    /// Generate with Gemini, automatically falling back to fal.ai on rate limit
    private func generateImageWithGeminiDirectAndFallback(
        prompt: String,
        parameters: GenerationParameters,
        referenceImages: [UIImage],
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        generateImageWithGeminiDirect(
            prompt: prompt,
            parameters: parameters,
            referenceImages: referenceImages
        ) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let image):
                // Success! Record the request and return
                GeminiRateLimitTracker.shared.recordRequest()
                completion(.success(image))

            case .failure(let error):
                // Check if this is a rate limit error
                let isRateLimit: Bool
                if let serviceError = error as? ServiceError {
                    isRateLimit = serviceError.isRateLimitError
                } else {
                    // Check error message for rate limit indicators
                    let errorMessage = error.localizedDescription.lowercased()
                    isRateLimit = errorMessage.contains("429") ||
                                  errorMessage.contains("rate limit") ||
                                  errorMessage.contains("quota") ||
                                  errorMessage.contains("resource_exhausted")
                }

                if isRateLimit {
                    // Rate limit hit - record it and try fal.ai fallback
                    GeminiRateLimitTracker.shared.recordRateLimitHit()

                    // Check if fal.ai is available for fallback
                    if self.configuration.falAPIKey != nil {
                        print("🔄 [ImageGenerationService] Gemini rate limited, falling back to fal.ai...")
                        self.generateImageWithFalAI(
                            prompt: prompt,
                            parameters: parameters,
                            referenceImages: referenceImages,
                            completion: completion
                        )
                    } else {
                        // No fallback available
                        print("❌ [ImageGenerationService] Rate limited and no fal.ai fallback available")
                        completion(.failure(ServiceError.rateLimitExceeded))
                    }
                } else {
                    // Not a rate limit error, pass through
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - fal.ai Implementation

    private func generateImageWithFalAI(
        prompt: String,
        parameters: GenerationParameters,
        referenceImages: [UIImage],
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        print("🎨 [ImageGenerationService] Starting fal.ai image generation...")
        print("📝 [ImageGenerationService] Prompt length: \(prompt.count) chars")
        print("🔧 [ImageGenerationService] Parameters: Aspect Ratio \(parameters.aspectRatio.rawValue), Size: \(parameters.imageSize.rawValue)")
        if !referenceImages.isEmpty {
            print("🖼️ [ImageGenerationService] Reference images: \(referenceImages.count)")
        }

        // fal.ai requires images as URLs or base64 data URIs
        // We'll use base64 data URIs for simplicity
        var imageDataURIs: [String] = []

        for (index, image) in referenceImages.enumerated() {
            // Resize to max 1024px to reduce payload size
            let resizedImage = resizeImage(image, maxDimension: 1024)

            if let imageData = resizedImage.jpegData(compressionQuality: 0.8) {
                let base64String = imageData.base64EncodedString()
                let dataURI = "data:image/jpeg;base64,\(base64String)"
                imageDataURIs.append(dataURI)
                print("🖼️ [ImageGenerationService] Encoded image \(index + 1): \(imageData.count / 1024) KB")
            }
        }

        // Build fal.ai request
        guard let falAPIKey = configuration.falAPIKey else {
            completion(.failure(ServiceError.missingAPIKey))
            return
        }

        guard let url = URL(string: "\(Constants.falBaseURL)/\(Constants.falGeminiModel)") else {
            completion(.failure(ServiceError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Key \(falAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.defaultRequestTimeout

        // Build request body for fal.ai
        var requestBody: [String: Any] = [
            "prompt": prompt,
            "num_images": 1,
            "aspect_ratio": parameters.aspectRatio.rawValue,
            "resolution": parameters.imageSize.rawValue,
            "output_format": "png",
            "sync_mode": true  // Return image data directly
        ]

        if !imageDataURIs.isEmpty {
            requestBody["image_urls"] = imageDataURIs
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(ServiceError.decodingError(error)))
            return
        }

        let requestStartTime = Date()

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            let requestDuration = Date().timeIntervalSince(requestStartTime)
            print("📊 [ImageGenerationService] fal.ai request completed in \(String(format: "%.2f", requestDuration))s")

            if let error = error {
                print("❌ [ImageGenerationService] Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(ServiceError.invalidResponse))
                return
            }

            guard let data = data else {
                completion(.failure(ServiceError.noData))
                return
            }

            // Log response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 [ImageGenerationService] Response preview: \(String(responseString.prefix(500)))")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                // Handle specific HTTP errors
                switch httpResponse.statusCode {
                case 429:
                    // fal.ai rate limit (20 concurrent requests max)
                    print("⚠️ [ImageGenerationService] fal.ai 429 - Too many concurrent requests, try again shortly")
                    completion(.failure(ServiceError.apiError("fal.ai is busy, please try again in a few seconds")))
                case 401, 403:
                    print("❌ [ImageGenerationService] fal.ai authentication error")
                    completion(.failure(ServiceError.apiError("fal.ai API key invalid or expired")))
                case 500...599:
                    print("❌ [ImageGenerationService] fal.ai server error (HTTP \(httpResponse.statusCode))")
                    completion(.failure(ServiceError.apiError("fal.ai server error, please try again")))
                default:
                    if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let detail = errorJson["detail"] as? String {
                        print("❌ [ImageGenerationService] fal.ai API error: \(detail)")
                        completion(.failure(ServiceError.apiError(detail)))
                    } else {
                        completion(.failure(ServiceError.apiError("HTTP \(httpResponse.statusCode)")))
                    }
                }
                return
            }

            // Parse fal.ai response
            do {
                let image = try self.parseFalAIResponse(data: data)
                print("✅ [ImageGenerationService] fal.ai image generation complete")
                completion(.success(image))
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }

    private func parseFalAIResponse(data: Data) throws -> UIImage {
        // fal.ai response format:
        // { "images": [{ "url": "...", "content_type": "image/png", ... }] }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let images = json["images"] as? [[String: Any]],
              let firstImage = images.first else {
            print("❌ [ImageGenerationService] Failed to parse fal.ai response")
            throw ServiceError.noImagesGenerated
        }

        // Check if we have a URL or base64 data
        if let imageURL = firstImage["url"] as? String {
            // Download the image from URL
            print("📥 [ImageGenerationService] Downloading image from URL...")
            guard let url = URL(string: imageURL),
                  let imageData = try? Data(contentsOf: url),
                  let image = UIImage(data: imageData) else {
                throw ServiceError.imageDecodingFailed
            }
            print("✅ [ImageGenerationService] Downloaded image (\(imageData.count / 1024) KB)")
            return image
        }

        throw ServiceError.noImagesGenerated
    }

    // MARK: - Gemini Direct Implementation

    private func generateImageWithGeminiDirect(
        prompt: String,
        parameters: GenerationParameters,
        referenceImages: [UIImage] = [],
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        generateImageWithRetry(
            prompt: prompt,
            parameters: parameters,
            referenceImages: referenceImages,
            retryCount: 0,
            maxRetries: Constants.maxRetries,
            completion: completion
        )
    }

    private func generateImageWithRetry(
        prompt: String,
        parameters: GenerationParameters,
        referenceImages: [UIImage] = [],
        retryCount: Int,
        maxRetries: Int,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        print("🎨 [ImageGenerationService] Starting Gemini direct image generation...")
        print("📝 [ImageGenerationService] Prompt: \(prompt)")
        print("🔧 [ImageGenerationService] Parameters: Aspect Ratio \(parameters.aspectRatio.rawValue), Size: \(parameters.imageSize.rawValue)")
        if !referenceImages.isEmpty {
            print("🖼️ [ImageGenerationService] Reference images: \(referenceImages.count)")
        }

        let requestStartTime = Date()

        // Build request
        do {
            let request = try buildGeminiRequest(
                prompt: prompt,
                parameters: parameters,
                referenceImages: referenceImages
            )

            // Execute request
            let task = session.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }

                let requestDuration = Date().timeIntervalSince(requestStartTime)
                print("📊 [ImageGenerationService] Request completed in \(String(format: "%.2f", requestDuration))s")

                // Handle network errors
                if let error = error {
                    if self.shouldRetryError(error) && retryCount < maxRetries {
                        let delay = Constants.retryDelay
                        print("🔄 [ImageGenerationService] Retrying in \(delay)s... (attempt \(retryCount + 1)/\(maxRetries))")

                        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                            self.generateImageWithRetry(
                                prompt: prompt,
                                parameters: parameters,
                                referenceImages: referenceImages,
                                retryCount: retryCount + 1,
                                maxRetries: maxRetries,
                                completion: completion
                            )
                        }
                    } else {
                        completion(.failure(error))
                    }
                    return
                }

                // Validate response
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(ServiceError.invalidResponse))
                    return
                }

                guard let data = data else {
                    completion(.failure(ServiceError.noData))
                    return
                }

                // Handle HTTP errors
                guard (200...299).contains(httpResponse.statusCode) else {
                    // Check specifically for 429 (rate limit)
                    if httpResponse.statusCode == 429 {
                        print("⚠️ [ImageGenerationService] HTTP 429 - Rate limit exceeded")
                        completion(.failure(ServiceError.rateLimitExceeded))
                        return
                    }

                    if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorResponse["error"] as? [String: Any],
                       let message = error["message"] as? String {

                        print("❌ [ImageGenerationService] API error (HTTP \(httpResponse.statusCode)): \(message)")

                        // Check for quota/rate limit errors in the message
                        let lowercased = message.lowercased()
                        if lowercased.contains("quota") || lowercased.contains("rate limit") || lowercased.contains("resource_exhausted") {
                            completion(.failure(ServiceError.rateLimitExceeded))
                        } else {
                            completion(.failure(ServiceError.apiError(message)))
                        }
                    } else {
                        completion(.failure(ServiceError.apiError("HTTP \(httpResponse.statusCode)")))
                    }
                    return
                }

                // Parse response and extract image
                do {
                    let image = try self.parseGeminiResponse(data: data)
                    print("✅ [ImageGenerationService] Image generation complete")
                    completion(.success(image))
                } catch {
                    completion(.failure(error))
                }
            }

            task.resume()

        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - Request Building (Gemini Direct)

    private func buildGeminiRequest(
        prompt: String,
        parameters: GenerationParameters,
        referenceImages: [UIImage] = []
    ) throws -> URLRequest {
        guard let apiKey = configuration.geminiAPIKey else {
            throw ServiceError.missingAPIKey
        }

        // Build URL for Gemini 3 Pro Image
        guard let url = URL(string: "\(configuration.geminiBaseURL)/models/\(configuration.modelName):generateContent") else {
            throw ServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // CRITICAL FIX: Disable HTTP/3 to prevent QUIC protocol failures on cellular networks
        // This solves the "quic_conn_process_inbound unable to parse packet" errors
        if #available(iOS 15.0, *) {
            request.assumesHTTP3Capable = false
        }

        // Fix for iOS keep-alive bug that causes -1005 errors on cellular
        request.setValue("close", forHTTPHeaderField: "Connection")

        // Increase timeout for image generation (can take 30-60 seconds)
        request.timeoutInterval = 120.0

        // Build parts array with text and optional images
        var parts: [[String: Any]] = [
            ["text": prompt]
        ]

        // Add reference images as inline_data with optimized compression for cellular
        for image in referenceImages {
            // Resize to max 1024px to reduce payload size (critical for cellular)
            let resizedImage = resizeImage(image, maxDimension: 1024)

            // Use 0.8 compression to balance quality and size
            if let imageData = resizedImage.jpegData(compressionQuality: 0.8) {
                let base64String = imageData.base64EncodedString()
                parts.append([
                    "inline_data": [
                        "mime_type": "image/jpeg",
                        "data": base64String
                    ]
                ])
            }
        }

        // Build request body (Gemini format)
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": parts
                ]
            ],
            "generationConfig": [
                "responseModalities": ["IMAGE"],
                "imageConfig": [
                    "aspectRatio": parameters.aspectRatio.rawValue,
                    "imageSize": parameters.imageSize.rawValue
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        return request
    }

    // MARK: - Response Parsing (Gemini Direct)

    private func parseGeminiResponse(data: Data) throws -> UIImage {
        // Parse Gemini response format
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ServiceError.decodingError(NSError(domain: "ImageGenerationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"]))
        }

        // Extract candidates array from Gemini response
        // Format: { "candidates": [{ "content": { "parts": [{ "inlineData": { "mimeType": "image/png", "data": "..." } }] } }] }
        guard let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let inlineData = firstPart["inlineData"] as? [String: Any],
              let base64String = inlineData["data"] as? String else {

            print("❌ [ImageGenerationService] Failed to extract image data from response")
            print("📄 [ImageGenerationService] Response: \(String(data: data, encoding: .utf8) ?? "unable to decode")")
            throw ServiceError.noImagesGenerated
        }

        // Decode base64 to image data
        guard let imageData = Data(base64Encoded: base64String),
              let image = UIImage(data: imageData) else {
            print("❌ [ImageGenerationService] Failed to decode base64 image")
            throw ServiceError.imageDecodingFailed
        }

        print("✅ [ImageGenerationService] Successfully decoded image (\(imageData.count / 1024) KB)")
        return image
    }

    // MARK: - Error Handling

    private func shouldRetryError(_ error: Error) -> Bool {
        // Check for URLError network errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .cannotFindHost, .dnsLookupFailed:
                return false  // Don't retry for obvious no-network conditions
            case .timedOut, .networkConnectionLost, .cannotConnectToHost:
                return true  // These might be temporary
            default:
                break
            }
        }

        // Retry on specific service errors
        if let serviceError = error as? ServiceError {
            switch serviceError {
            case .invalidResponse, .noData:
                return true
            case .apiError(let message):
                let lowercased = message.lowercased()
                return lowercased.contains("timeout") ||
                       lowercased.contains("rate limit") ||
                       lowercased.contains("internal error") ||
                       lowercased.contains("500") ||
                       lowercased.contains("503")
            default:
                return false
            }
        }

        return false
    }

    // MARK: - Cancellation
    func cancelActiveRequests() {
        session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
    }

    // MARK: - Helper Methods

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        // If image is already smaller, return as-is
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        let newSize: CGSize

        if size.width > size.height {
            // Landscape or square
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            // Portrait
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        // Resize using high-quality graphics context
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }
}

// MARK: - Hockey Card Generation Extension
extension ImageGenerationService {
    /// Generate a hockey card from player info and jersey selection
    /// - Parameters:
    ///   - playerInfo: Player details (name, number, position, photo)
    ///   - jerseySelection: Selected jersey type
    ///   - completion: Completion handler with generated card image
    func generateHockeyCard(
        playerInfo: PlayerCardInfo,
        jerseySelection: JerseySelection,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        // Build prompt based on jersey selection
        let prompt = buildHockeyCardPrompt(playerInfo: playerInfo, jerseySelection: jerseySelection)

        // Configure parameters for hockey card (portrait aspect ratio, high quality)
        let parameters = GenerationParameters(
            aspectRatio: .threeByFour,
            imageSize: .twoK  // Changed from 4K to 2K for better face accuracy
        )

        // Collect reference images based on jersey selection
        var referenceImages: [UIImage] = []

        // FIRST: Add ALL player photos as primary references (up to 3 for best face accuracy)
        for (index, playerPhoto) in playerInfo.playerPhotos.enumerated() {
            referenceImages.append(playerPhoto)
            print("🖼️ [ImageGenerationService] Using player photo \(index + 1) as reference")
        }
        print("🖼️ [ImageGenerationService] Total player reference photos: \(playerInfo.playerPhotos.count)")

        // SECOND: Add jersey reference based on selection
        switch jerseySelection {
        case .usePhoto:
            // Use jersey from player photo - no additional reference needed
            print("🖼️ [ImageGenerationService] Using jersey from player photo")

        case .sty:
            // Load STY jersey from resources
            // Try loading from asset catalog first, then from bundle
            if let styJerseyImage = UIImage(named: "STYJersey") {
                referenceImages.append(styJerseyImage)
                print("🖼️ [ImageGenerationService] Using STY jersey as reference from asset catalog (image 2)")
            } else if let bundlePath = Bundle.main.path(forResource: "STYJersey", ofType: "png"),
                      let styJerseyImage = UIImage(contentsOfFile: bundlePath) {
                referenceImages.append(styJerseyImage)
                print("🖼️ [ImageGenerationService] Using STY jersey as reference from bundle (image 2)")
            } else {
                print("⚠️ [ImageGenerationService] STYJersey.png not found, using player photo only")
            }

        case .nhl:
            // NHL teams - use text description only (no jersey reference image)
            print("🖼️ [ImageGenerationService] NHL jersey - using player photo only")
            break
        }

        generateImage(
            prompt: prompt,
            parameters: parameters,
            referenceImages: referenceImages,
            completion: completion
        )
    }

    private func buildHockeyCardPrompt(
        playerInfo: PlayerCardInfo,
        jerseySelection: JerseySelection
    ) -> String {
        // Base prompt for hockey card
        let photoCount = playerInfo.playerPhotos.count
        let photoReferenceText = photoCount > 1 ? "first \(photoCount) reference images show" : "first reference image shows"

        var prompt = """
        Create a professional hockey trading card featuring the SAME person shown in the reference images.

        IDENTITY PRESERVATION - CRITICAL:
        - The \(photoReferenceText) the EXACT SAME individual from multiple angles
        - Keep the original person's face UNCHANGED and REALISTIC
        - Same character - maintain facial features across all edits
        - Preserve proportions and face geometry from reference
        - Match identity while preserving pose and action

        FACIAL FEATURES - MATCH PRECISELY:
        - Eye color, shape, and spacing: exactly as shown in reference
        - Nose shape and size: preserve exact proportions
        - Jaw line and face shape: maintain original structure
        - Eyebrows: match thickness, arch, and position
        - Hair style, color, and texture: identical to reference
        - Skin tone and texture: keep natural, avoid plastic smoothing
        - Age and ethnicity: preserve accurately
        - Facial hair (if present): match style and coverage

        REALISM REQUIREMENTS:
        - Preserve skin texture and pores - natural appearance
        - Maintain natural proportions and face geometry
        - Realistic lighting on facial features
        - No artificial smoothing or unrealistic enhancements
        - Keep facial expressions authentic and believable

        Player Details:
        - Name: \(playerInfo.playerName)
        - Number: #\(playerInfo.jerseyNumber)
        - Position: \(playerInfo.position.rawValue)

        """

        // Enhanced positive keywords for realism
        prompt += """

        QUALITY & STYLE:
        - 8k resolution, photorealistic, hyper-detailed
        - Sharp focus, professional sports photography
        - Dramatic arena lighting, volumetric fog, cinematic composition
        - Highly detailed textures (jersey fabric, ice surface, skin pores)
        - Color graded, vibrant, high contrast
        - Masterpiece, award-winning photography

        """

        // Add jersey-specific details (jersey image comes AFTER all player photos)
        let jerseyImageIndex = photoCount + 1
        let jerseyReferenceText = photoCount > 1 ? "images (photos \(photoCount + 1) onward)" : "image (photo \(photoCount + 1))"

        switch jerseySelection {
        case .usePhoto:
            prompt += """
            Jersey: Keep the exact jersey shown in the player's photo
            - Use the jersey already worn by the player in the reference photo(s)
            - Maintain the original jersey design, colors, and style from the player photo
            - Keep all original branding and design elements
            - Ensure clear visibility of jersey number #\(playerInfo.jerseyNumber)
            - Enhance and make the jersey look professional and game-ready

            """

        case .nhl(let team):
            prompt += """
            Jersey: \(team.city) \(team.name) official NHL jersey
            Colors: Official \(team.name) team colors
            - Put the player from the first \(photoCount) reference image(s) into an authentic NHL team jersey
            - Authentic NHL team jersey design
            - Include team logo and colors accurately
            - Jersey number #\(playerInfo.jerseyNumber)

            """

        case .sty:
            prompt += """
            Jersey: Use the STY Athletic jersey shown in reference \(jerseyReferenceText)
            - Put the player from the first \(photoCount) reference image(s) into the STY jersey
            - Recreate the exact jersey design from the jersey reference image
            - Black body with white/red accents as shown in the reference
            - "STY ATHLETIC CO." branding on chest exactly as in the jersey reference
            - Red stars on bottom hem and sleeves as shown in the reference
            - White V-neck collar with red trim
            - Jersey number #\(playerInfo.jerseyNumber) clearly visible
            - Match all colors, patterns, and design elements from the jersey reference image
            - Professional performance hockey jersey style

            """
        }

        // Card design requirements
        prompt += """

        CRITICAL OUTPUT FORMAT:
        - Generate the ACTUAL CARD DESIGN itself, NOT a photograph of a card
        - The output should be the flat, digital trading card artwork
        - NO white borders, NO card frame, NO background surface
        - NO photo-of-a-card effect, NO physical card appearance
        - Direct top-down view of the card design (0 degrees, perfectly flat)
        - Fill the entire frame edge-to-edge with the card design

        Card Design Style:
        - Vintage hockey card style (similar to 1990s Upper Deck or Score cards)
        - Professional action shot of player on ice
        - Player name prominently displayed at bottom in card design
        - Jersey number visible on card
        - Team colors incorporated in border/design elements
        - High quality, print-ready digital artwork
        - Glossy trading card aesthetic (design style, not photo of card)
        - No blurry or pixelated elements
        - Clean, sharp edges on all design elements
        - Full bleed design (no margins, fills entire frame)

        NEGATIVE CONSTRAINTS (ABSOLUTELY DO NOT INCLUDE):
        - Photo of a card, picture of a card, card on a surface
        - White border around the card, card frame, card mat
        - Background surface, table, wooden surface, countertop
        - Shadows around/under the card, 3D depth, tilted angle
        - Curved corners on outer edge (card design may have rounded corners internally)
        - Physical card appearance, scanned card look
        - Blurry, pixelated, low quality, low resolution
        - Distorted face, bad anatomy, extra limbs, missing limbs
        - Watermark, signature, copyright text
        - Out of frame, cropped player, cut off elements
        - Grain, noise, artifacts, jpeg compression
        - Cartoon, illustration, painting (player must be photorealistic)

        """

        prompt += """

        CRITICAL REQUIREMENTS:
        - The card should fill the ENTIRE image frame with NO background
        - NO wooden table, NO surface, NO shadows around the card
        - NO 3D perspective or depth - completely flat, straight-on view
        - The card border should go edge-to-edge in the image
        - Think of this as a digital scan of the card, not a photo of a physical card
        - Pure white or transparent background if any space exists outside the card
        - The card itself should be the only thing visible in the image

        FINAL IDENTITY LOCK:
        - Face 100% same as reference images - this is the CRITICAL requirement
        - The player on the card is the SAME person from the first \(photoCount) reference image(s)
        - Match identity while preserving pose and hockey action
        - Same character across all elements - facial features MUST be identical
        - This is a REAL person, not a generic athlete - preserve their unique appearance
        - Keep the original person's face unchanged and realistic throughout the entire card
        - Use all \(photoCount) reference image(s) as visual anchors for complete accuracy
        - Repeat defining traits: maintain eye color, hairstyle, face shape, skin tone exactly as shown

        CRITICAL SUCCESS CRITERIA:
        - Someone viewing the card should immediately recognize it as the SAME person from the reference photos
        - Facial features are preserved with photographic accuracy
        - No generic or artificial-looking face - must look like the real individual
        - Natural skin texture and realistic proportions maintained

        Important: Create a realistic, professional hockey trading card featuring the specific person from the reference images, photographed flat from directly above with no background visible.
        """

        return prompt
    }
}

// MARK: - Provider Configuration Helper
extension ImageGenerationService {
    /// Check which providers are available based on configured API keys
    static var availableProviders: [ImageGenerationProvider] {
        var providers: [ImageGenerationProvider] = []

        if AppSecrets.shared.falAPIKey != nil {
            providers.append(.falAI)
        }
        if AppSecrets.shared.geminiAPIKey != nil {
            providers.append(.geminiDirect)
        }

        return providers
    }

    /// Get the recommended provider (prefers fal.ai for no daily limits)
    static var recommendedProvider: ImageGenerationProvider? {
        if AppSecrets.shared.falAPIKey != nil {
            return .falAI
        } else if AppSecrets.shared.geminiAPIKey != nil {
            return .geminiDirect
        }
        return nil
    }
}
