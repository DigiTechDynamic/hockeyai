import Foundation
import UIKit

// MARK: - OpenAI Service
/// Service for interacting with OpenAI Vision API
/// Optimized for fast image analysis (2-3s vs Gemini's 13-20s on cellular)
final class OpenAIService {

    // MARK: - Configuration
    struct Configuration {
        let baseURL: String
        let apiKey: String
        let modelName: String

        init(baseURL: String = "https://api.openai.com/v1",
             apiKey: String,
             modelName: String = "gpt-4o-mini") {
            self.baseURL = baseURL
            self.apiKey = apiKey
            self.modelName = modelName
        }
    }

    // MARK: - Error Types
    enum ServiceError: LocalizedError {
        case invalidURL
        case invalidResponse
        case noData
        case decodingError(Error)
        case apiError(String)
        case missingAPIKey
        case imageEncodingFailed

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
                if message.lowercased().contains("rate limit") {
                    return "Too many requests. Please wait a moment before trying again."
                } else {
                    return "AI analysis failed: \(message)"
                }
            case .missingAPIKey:
                return "OpenAI API key is missing"
            case .imageEncodingFailed:
                return "Failed to encode image data"
            }
        }
    }

    // MARK: - Constants
    private enum Constants {
        static let defaultRequestTimeout: TimeInterval = 60.0  // 60s for image requests
        static let maxRetries = 1
        static let retryDelay: TimeInterval = 1.5
    }

    // MARK: - Properties
    private let configuration: Configuration
    private let session: URLSession
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    private let circuitBreaker = RequestCircuitBreaker()

    // MARK: - Initialization
    init(configuration: Configuration) {
        self.configuration = configuration

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = Constants.defaultRequestTimeout
        sessionConfig.timeoutIntervalForResource = Constants.defaultRequestTimeout
        sessionConfig.networkServiceType = .default

        self.session = URLSession(configuration: sessionConfig)
    }

    /// Convenience initializer that loads API key from AppSecrets
    convenience init?() {
        guard let apiKey = AppSecrets.shared.openAIAPIKey else {
            print("❌ [OpenAIService] No OpenAI API key found")
            return nil
        }

        self.init(configuration: Configuration(apiKey: apiKey))
        print("✅ [OpenAIService] Initialized with API key")
    }

    // MARK: - Cancellation
    func cancelActiveRequests() {
        session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
    }

    // MARK: - Image Analysis

    /// Analyze an image with OpenAI Vision API
    /// - Parameters:
    ///   - imageData: JPEG image data
    ///   - prompt: Analysis prompt
    ///   - generationConfig: Configuration options (temperature, max_tokens, response_format)
    ///   - completion: Completion handler with raw response or error
    func analyzeImage(
        imageData: Data,
        prompt: String,
        generationConfig: [String: Any]?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        analyzeImageWithRetry(
            imageData: imageData,
            prompt: prompt,
            generationConfig: generationConfig,
            retryCount: 0,
            maxRetries: Constants.maxRetries,
            completion: completion
        )
    }

    private func analyzeImageWithRetry(
        imageData: Data,
        prompt: String,
        generationConfig: [String: Any]?,
        retryCount: Int,
        maxRetries: Int,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Check circuit breaker
        guard circuitBreaker.canMakeRequest() else {
            print("🚫 [OpenAIService] Circuit breaker open - too many failures")
            completion(.failure(ServiceError.apiError("Service temporarily unavailable due to repeated failures. Please try again later.")))
            return
        }

        print("🤖 [OpenAIService] Starting image analysis with OpenAI...")
        print("📊 [OpenAIService] Image size: \(imageData.count / 1024) KB")

        let requestStartTime = Date()

        // Convert image data to base64
        let base64Image = imageData.base64EncodedString()

        // Build request
        do {
            let request = try buildImageAnalysisRequest(
                base64Image: base64Image,
                prompt: prompt,
                generationConfig: generationConfig
            )

            // Execute request
            let task = session.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }

                let requestDuration = Date().timeIntervalSince(requestStartTime)
                print("📊 [OpenAIService] Request completed in \(String(format: "%.2f", requestDuration))s")

                // Handle network errors
                if let error = error {
                    self.circuitBreaker.recordFailure()

                    if self.shouldRetryError(error) && retryCount < maxRetries {
                        let delay = Constants.retryDelay
                        print("🔄 [OpenAIService] Retrying in \(delay)s... (attempt \(retryCount + 1)/\(maxRetries))")

                        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                            self.analyzeImageWithRetry(
                                imageData: imageData,
                                prompt: prompt,
                                generationConfig: generationConfig,
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
                    self.circuitBreaker.recordFailure()
                    completion(.failure(ServiceError.invalidResponse))
                    return
                }

                guard let data = data else {
                    self.circuitBreaker.recordFailure()
                    completion(.failure(ServiceError.noData))
                    return
                }

                // Handle HTTP errors
                guard (200...299).contains(httpResponse.statusCode) else {
                    self.circuitBreaker.recordFailure()

                    if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorResponse["error"] as? [String: Any],
                       let message = error["message"] as? String {

                        print("❌ [OpenAIService] API error: \(message)")
                        completion(.failure(ServiceError.apiError(message)))
                    } else {
                        completion(.failure(ServiceError.apiError("HTTP \(httpResponse.statusCode)")))
                    }
                    return
                }

                // Parse response
                do {
                    let responseText = try self.parseImageAnalysisResponse(data: data)
                    self.circuitBreaker.recordSuccess()
                    print("✅ [OpenAIService] Analysis complete")
                    // Mirror AIService notifications for UI progress updates
                    NotificationCenter.default.post(name: .aiResponseReceived, object: nil)
                    completion(.success(responseText))
                } catch {
                    self.circuitBreaker.recordFailure()
                    completion(.failure(error))
                }
            }

            // Notify request started for UI progress updates
            NotificationCenter.default.post(name: .aiRequestSent, object: nil)
            task.resume()

        } catch {
            self.circuitBreaker.recordFailure()
            completion(.failure(error))
        }
    }

    // MARK: - Request Building

    private func buildImageAnalysisRequest(
        base64Image: String,
        prompt: String,
        generationConfig: [String: Any]?
    ) throws -> URLRequest {
        // Build URL
        guard let url = URL(string: "\(configuration.baseURL)/chat/completions") else {
            throw ServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Extract config parameters
        let temperature = generationConfig?["temperature"] as? Double ?? 0.3
        let maxTokens = generationConfig?["maxOutputTokens"] as? Int ?? 16384  // Use GPT-4o-mini max capacity

        print("🔧 [OpenAIService] Config - maxTokens: \(maxTokens), temperature: \(temperature)")

        // Check for JSON mode (OpenAI uses response_format instead of response_mime_type)
        let responseFormat: [String: Any]?
        if let responseMimeType = generationConfig?["response_mime_type"] as? String,
           responseMimeType == "application/json",
           let responseSchema = generationConfig?["response_schema"] as? [String: Any] {
            // Use OpenAI Structured Outputs for guaranteed valid JSON
            // This ensures the response matches the schema exactly
            responseFormat = [
                "type": "json_schema",
                "json_schema": [
                    "name": "player_rating_response",
                    "strict": true,
                    "schema": responseSchema
                ]
            ]
            print("🔧 [OpenAIService] Using Structured Outputs with strict schema enforcement")
        } else if let responseMimeType = generationConfig?["response_mime_type"] as? String,
                  responseMimeType == "application/json" {
            // Fallback to json_object mode if no schema provided
            responseFormat = ["type": "json_object"]
        } else {
            responseFormat = nil
        }

        // Don't enhance prompt if using Structured Outputs (schema is already enforced)
        var enhancedPrompt = prompt
        if responseFormat?["type"] as? String != "json_schema",
           let responseSchema = generationConfig?["response_schema"] as? [String: Any] {
            // Only add schema to prompt if NOT using Structured Outputs
            enhancedPrompt = enhancePromptWithSchema(prompt: prompt, schema: responseSchema)
        }

        // Build request body (OpenAI Vision API format)
        var requestBody: [String: Any] = [
            "model": configuration.modelName,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": enhancedPrompt  // Use enhanced prompt with schema
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "temperature": temperature,
            "max_tokens": maxTokens
        ]

        // Add response format if JSON mode requested
        if let responseFormat = responseFormat {
            requestBody["response_format"] = responseFormat
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        return request
    }

    // MARK: - Response Parsing

    private func parseImageAnalysisResponse(data: Data) throws -> String {
        // Parse OpenAI response format
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ServiceError.decodingError(NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"]))
        }

        // Extract content from response
        // Format: { "choices": [{ "message": { "content": "..." } }] }
        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {

            print("❌ [OpenAIService] Failed to extract content from response")
            print("📄 [OpenAIService] Response: \(String(data: data, encoding: .utf8) ?? "unable to decode")")
            throw ServiceError.invalidResponse
        }

        // Check for truncation
        if let finishReason = firstChoice["finish_reason"] as? String {
            print("📊 [OpenAIService] Finish reason: \(finishReason)")

            if finishReason == "length" {
                print("⚠️ [OpenAIService] Response was TRUNCATED - hit max_tokens limit!")
                print("💡 [OpenAIService] Increase maxOutputTokens in generationConfig")
            }
        }

        // Log token usage if available
        if let usage = json["usage"] as? [String: Any] {
            let promptTokens = usage["prompt_tokens"] as? Int ?? 0
            let completionTokens = usage["completion_tokens"] as? Int ?? 0
            let totalTokens = usage["total_tokens"] as? Int ?? 0

            print("📊 [OpenAIService] Token usage - Prompt: \(promptTokens), Completion: \(completionTokens), Total: \(totalTokens)")
        }

        return content
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

    /// Enhance prompt with JSON schema requirements
    /// OpenAI doesn't support strict schema enforcement like Gemini, so we add it to the prompt
    private func enhancePromptWithSchema(prompt: String, schema: [String: Any]) -> String {
        // Extract properties from schema
        guard let properties = schema["properties"] as? [String: Any] else {
            return prompt
        }

        var schemaDescription = "\n\nIMPORTANT: You must respond with valid JSON in this exact format:\n{\n"

        for (key, value) in properties {
            if let propertyDetails = value as? [String: Any],
               let description = propertyDetails["description"] as? String {
                // Add field to schema description
                if let type = propertyDetails["type"] as? String {
                    schemaDescription += "  \"\(key)\": \(type) // \(description)\n"
                }
            }
        }

        schemaDescription += "}\n\nDo not include any markdown formatting or code blocks. Return only the raw JSON object."

        return prompt + schemaDescription
    }
}
