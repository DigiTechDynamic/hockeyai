import Foundation

// MARK: - Notification Names
extension Notification.Name {
    static let aiUploadsComplete = Notification.Name("aiUploadsComplete")
    static let aiRequestSent = Notification.Name("aiRequestSent")
    static let aiResponseReceived = Notification.Name("aiResponseReceived")
}

// MARK: - Network Quality Detection (fully removed)

// MARK: - Circuit Breaker Pattern
class RequestCircuitBreaker {
    private var failureCount = 0
    private var lastFailureTime: Date?
    private let failureThreshold = 3
    private let recoveryTimeout: TimeInterval = 60 // 1 minute
    private var state: CircuitState = .closed

    enum CircuitState {
        case closed, open, halfOpen
    }

    func canMakeRequest() -> Bool {
        switch state {
        case .closed:
            return true
        case .open:
            if canAttemptReset() {
                state = .halfOpen
                print("🔄 [CircuitBreaker] Attempting recovery (half-open)")
                return true
            }
            return false
        case .halfOpen:
            return true
        }
    }

    func recordSuccess() {
        failureCount = 0
        lastFailureTime = nil
        if state == .halfOpen {
            state = .closed
            print("✅ [CircuitBreaker] Circuit restored (closed)")
        }
    }

    func recordFailure() {
        failureCount += 1
        lastFailureTime = Date()

        if failureCount >= failureThreshold {
            state = .open
            print("🚫 [CircuitBreaker] Circuit opened - too many failures (\(failureCount))")
        }

        if state == .halfOpen {
            state = .open
            print("🚫 [CircuitBreaker] Recovery failed - circuit re-opened")
        }
    }

    private func canAttemptReset() -> Bool {
        guard let lastFailure = lastFailureTime else { return true }
        return Date().timeIntervalSince(lastFailure) >= recoveryTimeout
    }

    var status: String {
        switch state {
        case .closed: return "Normal"
        case .open: return "Blocked (too many failures)"
        case .halfOpen: return "Testing recovery"
        }
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let timeStampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Video Metadata
/// Video metadata supported by Gemini API
struct VideoMetadata {
    let fps: Int?              // Frame rate for AI analysis
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]

        // Only include fps as it's the only supported field
        if let fps = fps {
            // We downsample videos to 10 FPS before upload to save bandwidth
            // Cap at 24 FPS as a safety measure (though we always use 10 FPS)
            dict["fps"] = min(fps, 24)
        } else {
            dict["fps"] = 10 // Default to 10 FPS (our standard analysis rate)
        }

        return dict
    }
}

// MARK: - AIService
/// Service for interacting with Gemini-like multi-modal AI APIs
final class AIService {
    
    // MARK: - Configuration
    struct Configuration {
        let baseURL: String
        let apiKey: String
        let modelName: String
        
        init(baseURL: String = "https://generativelanguage.googleapis.com/v1beta",
             apiKey: String,
             modelName: String = "gemini-2.5-flash") {  // Using 2.5 Flash for optimal cost-performance and speed
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
                // Provide more helpful error messages for common server issues
                if message.lowercased().contains("internal error encountered") {
                    return "The AI service is temporarily unavailable. Please try again in a few moments. (Server error: \(message))"
                } else if message.lowercased().contains("rate limit") {
                    return "Too many requests. Please wait a moment before trying again."
                } else {
                    return "AI analysis failed: \(message)"
                }
            case .missingAPIKey:
                return "API key is missing"
            }
        }
    }
    
    // MARK: - Constants
    private enum Constants {
        static let defaultRequestTimeout: TimeInterval = 90.0  // Increased to 90s for video analysis
        static let defaultResourceTimeout: TimeInterval = 300.0
        static let videoRequestTimeout: TimeInterval = 120.0  // 2 minutes for video requests

        static let maxInlineDataSize = 20 * 1024 * 1024  // 20MB limit for inline data
        static let maxFileUploadSize = 2 * 1024 * 1024 * 1024  // 2GB for file upload API
        static let maxRetries = 1  // Max 1 retry for failed requests
        static let retryDelay: TimeInterval = 1.5  // 1.5 second delay before retry

        // FPS Settings:
        // - Videos are downsampled to 10 FPS before upload to minimize bandwidth and costs
        // - 10 FPS provides optimal balance between analysis quality and file size
        // - Recording at high FPS (up to 240) maintains smooth preview, then downsampled
        // - For 3-second video: ~30 frames analyzed at 10 FPS vs 720 frames at 240 FPS (96% reduction)
        static let analysisTargetFPS = 10  // Standard FPS for AI analysis
    }
    
    // MARK: - Properties
    private let configuration: Configuration
    private let session: URLSession
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    // Circuit breaker only (network quality monitoring removed)
    private let circuitBreaker = RequestCircuitBreaker()
    
    // MARK: - Initialization
    init(configuration: Configuration) {
        self.configuration = configuration

        // Create optimized session inline to avoid 'self' usage before init
        let sessionConfig = URLSessionConfiguration.default

        // Treat all networks the same
        sessionConfig.timeoutIntervalForRequest = Constants.defaultRequestTimeout
        sessionConfig.timeoutIntervalForResource = Constants.defaultResourceTimeout
        sessionConfig.networkServiceType = .default

        self.session = URLSession(configuration: sessionConfig)
    }

    // MARK: - Cancellation
    /// Cancels any active URLSession tasks issued by this service.
    /// Safe to call at any time; silently ignores if there are no tasks.
    func cancelActiveRequests() {
        session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
    }

    // MARK: - Network Quality Methods (removed)
    
    /// Convenience initializer that loads API key from AppSecrets
    convenience init?() {
        guard let apiKey = AppSecrets.shared.geminiAPIKey else {
            return nil
        }
        
        self.init(configuration: Configuration(apiKey: apiKey))
    }
    
    // MARK: - API Key Management
    
    private static func loadAPIKeyFromSecrets() -> String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let secrets = NSDictionary(contentsOfFile: path) else {
            return nil
        }
        
        // Try different key names
        if let apiKey = secrets["GeminiAPIKey"] as? String, !apiKey.isEmpty {
            return apiKey
        } else if let apiKey = secrets["GEMINI_API_KEY"] as? String, !apiKey.isEmpty {
            return apiKey
        }
        
        return nil
    }
    
    // MARK: - File Upload Method
    
    /// Uploads a file to the API and returns its URI for use in generateContent
    /// - Parameters:
    ///   - data: The file data to upload
    ///   - mimeType: MIME type of the file
    ///   - displayName: Optional display name for the file
    ///   - completion: Completion handler with the file URI or error
    func uploadFile(
        data: Data,
        mimeType: String,
        displayName: String? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let urlString = "\(configuration.baseURL)/upload/v1beta/files?key=\(configuration.apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(ServiceError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Metadata part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        let metadata: [String: Any] = [
            "file": [
                "displayName": displayName ?? "uploaded_media"
            ]
        ]
        body.append(try! JSONSerialization.data(withJSONObject: metadata))
        body.append("\r\n".data(using: .utf8)!)
        
        // File data part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(ServiceError.noData))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let file = json["file"] as? [String: Any],
                   let uri = file["uri"] as? String {
                    completion(.success(uri))
                } else {
                    completion(.failure(ServiceError.invalidResponse))
                }
            } catch {
                completion(.failure(ServiceError.decodingError(error)))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Public Methods
    
    /// Generates content using multi-modal inputs
    /// - Parameters:
    ///   - parts: Array of content parts supporting both inline data and file references
    ///          Examples: {"text": "prompt"}, {"inlineData": {"mimeType": "...", "data": "base64..."}},
    ///                   {"fileData": {"mimeType": "...", "fileUri": "gs://..."}} 
    ///   - generationConfig: Optional generation configuration
    ///   - completion: Completion handler with result
    func generateContent(
        parts: [[String: Any]],
        generationConfig: [String: Any]? = nil,
        skipDebugLogging: Bool = false,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        print("🌐 [AIService] generateContent called with \(parts.count) parts")
        
        // Build request body
        var requestBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": parts
                ]
            ]
        ]
        
        if let config = generationConfig {
            requestBody["generationConfig"] = config
        }
        
        // Log full request body to debug logs if enabled (skip if already logged from generateFromMultiModal)
        if AIDebugLogger.shared.isEnabled && !skipDebugLogging {
            // Extract text prompt from parts
            var promptText = ""
            var mediaItems: [AIDebugMedia] = []
            
            for part in parts {
                if let text = part["text"] as? String {
                    promptText = text
                } else if let inlineData = part["inlineData"] as? [String: Any],
                          let mimeType = inlineData["mimeType"] as? String,
                          let dataString = inlineData["data"] as? String {
                    // Estimate size from base64 string
                    let sizeBytes = dataString.count * 3 / 4
                    let mediaType = mimeType.hasPrefix("image") ? "image" : 
                                   (mimeType.hasPrefix("video") ? "video" : "audio")
                    mediaItems.append(AIDebugMedia(
                        type: mediaType,
                        sizeBytes: sizeBytes,
                        encoding: "base64",
                        mimeType: mimeType,
                        base64Data: dataString  // Store the actual base64 data
                    ))
                } else if let fileData = part["fileData"] as? [String: Any],
                          let mimeType = fileData["mimeType"] as? String,
                          let fileUri = fileData["fileUri"] as? String {
                    let mediaType = mimeType.hasPrefix("image") ? "image" : 
                                   (mimeType.hasPrefix("video") ? "video" : "audio")
                    mediaItems.append(AIDebugMedia(
                        type: mediaType,
                        sizeBytes: 0, // Size unknown for uploaded files
                        encoding: "file_upload: \(fileUri)",
                        mimeType: mimeType,
                        base64Data: nil  // No base64 data for uploaded files
                    ))
                }
            }
            
            // Convert full request body to JSON string
            var fullRequestBodyString: String?
            if let jsonData = try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                // Truncate base64 data for readability in logs
                var truncatedString = jsonString
                // Match base64 strings longer than 100 chars in "data" fields
                if let regex = try? NSRegularExpression(pattern: "\"data\"\\s*:\\s*\"[A-Za-z0-9+/=]{100,}\"", options: []) {
                    let nsString = truncatedString as NSString
                    truncatedString = regex.stringByReplacingMatches(
                        in: truncatedString,
                        options: [],
                        range: NSRange(location: 0, length: nsString.length),
                        withTemplate: "\"data\": \"[BASE64_DATA_TRUNCATED...]\""
                    )
                }
                fullRequestBodyString = truncatedString
            }
            
            // Convert generation config to JSON string
            var fullGenerationConfigString: String?
            if let config = generationConfig {
                if let jsonData = try? JSONSerialization.data(withJSONObject: config, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    fullGenerationConfigString = jsonString
                }
            }
            
            // Extract response schema if present
            var responseSchemaString: String?
            if let responseMimeType = generationConfig?["response_mime_type"] as? String,
               responseMimeType == "application/json",
               let responseSchema = generationConfig?["response_schema"] {
                if let jsonData = try? JSONSerialization.data(withJSONObject: responseSchema, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    responseSchemaString = jsonString
                }
            }
            
            let debugRequest = AIDebugRequest(
                prompt: promptText,
                model: configuration.modelName,
                media: mediaItems.isEmpty ? nil : mediaItems,
                temperature: generationConfig?["temperature"] as? Double,
                maxTokens: generationConfig?["maxOutputTokens"] as? Int,
                topP: generationConfig?["topP"] as? Double,
                topK: generationConfig?["topK"] as? Int,
                responseSchema: responseSchemaString,
                fullGenerationConfig: fullGenerationConfigString,
                fullRequestBody: fullRequestBodyString
            )
            
            AIDebugLogger.shared.logRequest(debugRequest)
        }
        
        // Create request
        guard let url = buildURL() else {
            print("❌ [AIService] Invalid URL")
            completion(.failure(ServiceError.invalidURL))
            return
        }
        
        // Sanitize URL for logging (hide API key)
        let sanitizedURL = url.absoluteString.replacingOccurrences(
            of: "key=\(configuration.apiKey)",
            with: "key=[REDACTED]"
        )
        print("🔗 [AIService] API URL: \(sanitizedURL)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            // Request configured
        } catch {
            completion(.failure(error))
            return
        }
        
        // Execute request with retry logic
        let requestStartTime = Date()
        print("🚀 [AIService] Sending request to Gemini API...")
        NotificationCenter.default.post(name: .aiRequestSent, object: nil)
        print("⏰ [AIService] Request started at: \(DateFormatter.timeStampFormatter.string(from: requestStartTime))")
        performRequestWithRetry(request: request, retryCount: 0, requestStartTime: requestStartTime, completion: completion)
    }
    
    /// Convenience method for text-only generation
    /// - Parameters:
    ///   - prompt: Text prompt
    ///   - completion: Completion handler with result
    func generateText(
        prompt: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let parts: [[String: Any]] = [["text": prompt]]
        generateContent(parts: parts, generationConfig: nil, skipDebugLogging: false, completion: completion)
    }
    
    /// Convenience method for text + image generation
    /// - Parameters:
    ///   - prompt: Text prompt
    ///   - imageData: Image data
    ///   - imageMimeType: MIME type of the image
    ///   - completion: Completion handler with result
    func generateFromTextAndImage(
        prompt: String,
        imageData: Data,
        imageMimeType: String = "image/jpeg",
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let parts: [[String: Any]] = [
            ["text": prompt],
            [
                "inlineData": [
                    "mimeType": imageMimeType,
                    "data": autoreleasepool { imageData.base64EncodedString() }
                ]
            ]
        ]
        generateContent(parts: parts, generationConfig: nil, skipDebugLogging: false, completion: completion)
    }
    
    /// Enhanced multi-modal generation that automatically uploads large files
    /// - Parameters:
    ///   - prompt: Text prompt
    ///   - imageData: Optional image data with MIME type
    ///   - audioData: Optional audio data with MIME type
    ///   - videoData: Optional video data with MIME type
    ///   - videoMetadata: Optional video metadata for enhanced analysis
    ///   - generationConfig: Optional generation configuration (including response schema)
    ///   - completion: Completion handler with result
    func generateFromMultiModal(
        prompt: String,
        imageData: (data: Data, mimeType: String)? = nil,
        audioData: (data: Data, mimeType: String)? = nil,
        videoData: (data: Data, mimeType: String)? = nil,
        videoMetadata: VideoMetadata? = nil,
        generationConfig: [String: Any]? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        print("🤖 [AIService] generateFromMultiModal called")
        
        // Create debug request for logging
        let requestStartTime = Date()
        var debugMedia: [AIDebugMedia] = []
        var debugRequest: AIDebugRequest?
        
        // Log request if debug logging is enabled
        if AIDebugLogger.shared.isEnabled {
            // Collect media information
            if let image = imageData {
                debugMedia.append(AIDebugMedia(
                    type: "image",
                    sizeBytes: image.data.count,
                    encoding: "base64",
                    mimeType: image.mimeType,
                    base64Data: nil  // Don't store base64 in memory for debug logs
                ))
            }
            if let video = videoData {
                let fps = videoMetadata?.fps
                debugMedia.append(AIDebugMedia(
                    type: "video",
                    sizeBytes: video.data.count,
                    encoding: video.data.count > Constants.maxInlineDataSize ? "file_upload" : "base64",
                    mimeType: video.mimeType,
                    fps: fps,
                    base64Data: nil  // Don't store base64 in memory for debug logs
                ))
            }
            if let audio = audioData {
                debugMedia.append(AIDebugMedia(
                    type: "audio",
                    sizeBytes: audio.data.count,
                    encoding: "base64",
                    mimeType: audio.mimeType,
                    base64Data: nil  // Don't store base64 in memory for debug logs
                ))
            }
            
            // Extract generation config parameters
            let temp = generationConfig?["temperature"] as? Double
            let maxTokens = generationConfig?["maxOutputTokens"] as? Int
            let topP = generationConfig?["topP"] as? Double
            let topK = generationConfig?["topK"] as? Int
            
            // Convert generation config to JSON string for full capture
            var fullGenerationConfigString: String?
            if let config = generationConfig {
                if let jsonData = try? JSONSerialization.data(withJSONObject: config, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    fullGenerationConfigString = jsonString
                }
            }
            
            // Extract response schema if present
            var responseSchemaString: String?
            if let responseMimeType = generationConfig?["response_mime_type"] as? String,
               responseMimeType == "application/json",
               let responseSchema = generationConfig?["response_schema"] {
                if let jsonData = try? JSONSerialization.data(withJSONObject: responseSchema, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    responseSchemaString = jsonString
                }
            }
            
            // Store initial request info but don't log yet
            debugRequest = AIDebugRequest(
                prompt: prompt,
                model: configuration.modelName,
                media: debugMedia.isEmpty ? nil : debugMedia,
                temperature: temp,
                maxTokens: maxTokens,
                topP: topP,
                topK: topK,
                responseSchema: responseSchemaString,
                fullGenerationConfig: fullGenerationConfigString,
                fullRequestBody: nil // Will be set later with complete body
            )
        }
        
        var parts: [[String: Any]] = []
        let group = DispatchGroup()
        var uploadError: Error?
        
        // Helper to add media (inline if small, upload if large)
        func addMedia(data: Data, mimeType: String, mediaType: String) {
            let sizeMB = data.count / 1024 / 1024
            print("📎 [AIService] Processing \(mediaType): \(sizeMB) MB")

            // Use single size limit for all connections
            let maxInlineSize = Constants.maxInlineDataSize

            // Single behavior for all networks

            if data.count <= maxInlineSize {
                print("✅ [AIService] Using inline data for \(mediaType)")
                // Use inline data for small files
                // Use autoreleasepool to manage memory for base64 encoding
                let base64String = autoreleasepool { () -> String in
                    return data.base64EncodedString()
                }
                var part: [String: Any] = [
                    "inlineData": [
                        "mimeType": mimeType,
                        "data": base64String
                    ]
                ]
                
                // Add video metadata (analysis FPS)
                if mediaType == "video" {
                    // Use provided metadata or default
                    if let metadata = videoMetadata {
                        part["videoMetadata"] = metadata.toDictionary()
                    } else {
                        part["videoMetadata"] = [
                            "fps": Constants.analysisTargetFPS
                        ]
                    }
                }
                
                parts.append(part)
            } else {
                print("📤 [AIService] Uploading large \(mediaType) file...")
                // Upload large files
                group.enter()
                uploadFile(data: data, mimeType: mimeType, displayName: "\(mediaType)_upload") { result in
                    switch result {
                    case .success(let uri):
                        print("✅ [AIService] Upload successful: \(uri)")
                        var part: [String: Any] = [
                            "fileData": [
                                "mimeType": mimeType,
                                "fileUri": uri
                            ]
                        ]
                        
                        // Add video metadata for higher FPS if it's a video
                        if mediaType == "video" {
                            // Use provided metadata or default
                            if let metadata = videoMetadata {
                                part["videoMetadata"] = metadata.toDictionary()
                            } else {
                                part["videoMetadata"] = [
                                    "fps": 30  // Maximum FPS for sports motion analysis
                                ]
                            }
                        }
                        
                        parts.append(part)
                    case .failure(let error):
                        print("❌ [AIService] Upload failed: \(error)")
                        uploadError = error
                    }
                    group.leave()
                }
            }
        }
        
        // Process each media type
        if let image = imageData {
            addMedia(data: image.data, mimeType: image.mimeType, mediaType: "image")
        }
        
        if let audio = audioData {
            addMedia(data: audio.data, mimeType: audio.mimeType, mediaType: "audio")
        }
        
        if let video = videoData {
            addMedia(data: video.data, mimeType: video.mimeType, mediaType: "video")
        }
        
        // Wait for all uploads to complete
        group.notify(queue: .main) {
            print("🔄 [AIService] All uploads complete, generating content...")
            NotificationCenter.default.post(name: .aiUploadsComplete, object: nil)
            if let error = uploadError {
                print("❌ [AIService] Upload error: \(error)")
                completion(.failure(error))
            } else {
                // Add text prompt AFTER video parts (as recommended by Gemini docs)
                parts.append(["text": prompt])
                
                print("📨 [AIService] Calling generateContent with \(parts.count) parts")
                // Use provided generation config or default to JSON
                let config = generationConfig ?? [
                    "response_mime_type": "application/json"
                ]
                
                // Now build the full request body for debug logging
                if AIDebugLogger.shared.isEnabled, var request = debugRequest {
                    // Build the complete request body structure
                    var requestBody: [String: Any] = [
                        "contents": [
                            [
                                "role": "user",
                                "parts": parts
                            ]
                        ]
                    ]
                    
                    requestBody["generationConfig"] = config
                    
                    // Convert to JSON string
                    var fullRequestBodyString: String?
                    if let jsonData = try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        // Truncate base64 data for readability in logs
                        var truncatedString = jsonString
                        if let regex = try? NSRegularExpression(pattern: "\"data\"\\s*:\\s*\"[A-Za-z0-9+/=]{100,}\"", options: []) {
                            truncatedString = regex.stringByReplacingMatches(
                                in: truncatedString,
                                options: [],
                                range: NSRange(location: 0, length: truncatedString.count),
                                withTemplate: "\"data\": \"[BASE64_DATA_TRUNCATED...]\""
                            )
                        }
                        fullRequestBodyString = truncatedString
                        print("📋 [AIService] Full request body captured, length: \(truncatedString.count)")
                    } else {
                        print("❌ [AIService] Failed to serialize request body to JSON")
                    }
                    
                    // Update request with full body
                    request = AIDebugRequest(
                        prompt: request.prompt,
                        systemPrompt: nil,  // Could extract from system instructions if using them
                        model: request.model,
                        parameters: ["endpoint": self.buildURL()?.absoluteString ?? "unknown"],
                        media: request.media,
                        tokenEstimate: nil,
                        temperature: request.temperature,
                        maxTokens: request.maxTokens,
                        topP: request.topP,
                        topK: request.topK,
                        responseSchema: request.responseSchema,
                        fullGenerationConfig: request.fullGenerationConfig,
                        playerProfile: nil,  // Could be added if context includes player data
                        fullRequestBody: fullRequestBodyString
                    )
                    
                    print("📝 [AIService] Logging request with full body: \(fullRequestBodyString?.prefix(100) ?? "nil")")
                    AIDebugLogger.shared.logRequest(request)
                    debugRequest = request
                }
                
                self.generateContent(parts: parts, generationConfig: config, skipDebugLogging: true) { result in
                    // Log response if debug logging is enabled
                    if AIDebugLogger.shared.isEnabled, let request = debugRequest {
                        let duration = Date().timeIntervalSince(requestStartTime)
                        
                        switch result {
                        case .success(let response):
                            print("✅ [AIService] generateContent succeeded")
                            let debugResponse = AIDebugResponse(
                                text: response,
                                tokenUsage: TokenUsage(promptTokens: 0, completionTokens: 0), // Would need actual token counts from API
                                modelVersion: self.configuration.modelName
                            )
                            AIDebugLogger.shared.updateLogWithResponse(request.id, response: debugResponse, duration: duration)
                        case .failure(let error):
                            print("❌ [AIService] generateContent failed: \(error)")
                            AIDebugLogger.shared.updateLogWithError(request.id, error: error, duration: duration)
                        }
                    } else {
                        switch result {
                        case .success(_):
                            print("✅ [AIService] generateContent succeeded")
                        case .failure(let error):
                            print("❌ [AIService] generateContent failed: \(error)")
                        }
                    }
                    completion(result)
                }
            }
        }
    }
    
    /// Enhanced multi-video generation for multiple video analysis
    /// - Parameters:
    ///   - prompt: Generation prompt
    ///   - videoDataArray: Array of video data with MIME types
    ///   - videoMetadataArray: Array of video metadata for enhanced analysis
    ///   - generationConfig: Optional generation configuration (including response schema)
    ///   - completion: Completion handler with result
    func generateFromMultipleVideos(
        prompt: String,
        videoDataArray: [(data: Data, mimeType: String)],
        videoMetadataArray: [VideoMetadata],
        generationConfig: [String: Any]? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        print("🤖 [AIService] generateFromMultipleVideos called with \(videoDataArray.count) videos")
        
        // Create debug request for logging
        let requestStartTime = Date()
        var debugMedia: [AIDebugMedia] = []
        var debugRequest: AIDebugRequest?
        
        // Log request if debug logging is enabled
        if AIDebugLogger.shared.isEnabled {
            // Collect media information for all videos
            for (index, video) in videoDataArray.enumerated() {
                let metadata = index < videoMetadataArray.count ? videoMetadataArray[index] : nil
                let fps = metadata?.fps
                debugMedia.append(AIDebugMedia(
                    type: "video",
                    sizeBytes: video.data.count,
                    encoding: video.data.count > Constants.maxInlineDataSize ? "file_upload" : "base64",
                    mimeType: video.mimeType,
                    fps: fps,
                    base64Data: nil  // Don't store base64 in memory for debug logs
                ))
            }
            
            // Extract generation config parameters
            let temp = generationConfig?["temperature"] as? Double
            let maxTokens = generationConfig?["maxOutputTokens"] as? Int
            let topP = generationConfig?["topP"] as? Double
            let topK = generationConfig?["topK"] as? Int
            
            // Convert generation config to JSON string for full capture
            var fullGenerationConfigString: String?
            if let config = generationConfig {
                if let jsonData = try? JSONSerialization.data(withJSONObject: config, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    fullGenerationConfigString = jsonString
                }
            }
            
            // Extract response schema if present
            var responseSchemaString: String?
            if let responseMimeType = generationConfig?["response_mime_type"] as? String,
               responseMimeType == "application/json",
               let responseSchema = generationConfig?["response_schema"] {
                if let jsonData = try? JSONSerialization.data(withJSONObject: responseSchema, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    responseSchemaString = jsonString
                }
            }
            
            // Store initial request info but don't log yet
            debugRequest = AIDebugRequest(
                prompt: prompt,
                model: configuration.modelName,
                media: debugMedia.isEmpty ? nil : debugMedia,
                temperature: temp,
                maxTokens: maxTokens,
                topP: topP,
                topK: topK,
                responseSchema: responseSchemaString,
                fullGenerationConfig: fullGenerationConfigString,
                fullRequestBody: nil // Will be set later with complete body
            )
        }
        
        var parts: [[String: Any]] = []
        let group = DispatchGroup()
        var uploadError: Error?
        
        // Add the prompt text part first
        parts.append(["text": prompt])
        
        // Helper to add multiple videos (inline if small, upload if large)
        func addVideos(_ videoDataArray: [(data: Data, mimeType: String)], _ metadataArray: [VideoMetadata]) {
            for (index, video) in videoDataArray.enumerated() {
                let metadata = index < metadataArray.count ? metadataArray[index] : nil
                let sizeMB = video.data.count / 1024 / 1024
                print("📎 [AIService] Processing video \(index + 1): \(sizeMB) MB")

            // Use single size limit for all connections
            let maxInlineSize = Constants.maxInlineDataSize

                if video.data.count <= maxInlineSize {
                    print("✅ [AIService] Using inline data for video \(index + 1)")
                    // Use inline data for small files
                    // Use autoreleasepool to manage memory for base64 encoding
                    let base64String = autoreleasepool { () -> String in
                        return video.data.base64EncodedString()
                    }
                    var part: [String: Any] = [
                        "inlineData": [
                            "mimeType": video.mimeType,
                            "data": base64String
                        ]
                    ]
                    
                    // Add video metadata for higher FPS
                    if let metadata = metadata {
                        part["videoMetadata"] = metadata.toDictionary()
                    } else {
                        part["videoMetadata"] = [
                            "fps": Constants.analysisTargetFPS
                        ]
                    }
                    
                    parts.append(part)
                } else {
                    print("📤 [AIService] Uploading large video \(index + 1) file...")
                    // Upload large files
                    group.enter()
                    uploadFile(data: video.data, mimeType: video.mimeType, displayName: "video_\(index + 1)_upload") { result in
                        switch result {
                        case .success(let uri):
                            print("✅ [AIService] Upload successful for video \(index + 1): \(uri)")
                            var part: [String: Any] = [
                                "fileData": [
                                    "mimeType": video.mimeType,
                                    "fileUri": uri
                                ]
                            ]
                            
                            // Add video metadata (analysis FPS)
                            if let metadata = metadata {
                                part["videoMetadata"] = metadata.toDictionary()
                            } else {
                                part["videoMetadata"] = [
                                    "fps": Constants.analysisTargetFPS
                                ]
                            }
                            
                            parts.append(part)
                            group.leave()
                        case .failure(let error):
                            uploadError = error
                            group.leave()
                        }
                    }
                }
            }
        }
        
        // Process all videos
        addVideos(videoDataArray, videoMetadataArray)
        
        // Wait for all uploads to complete
        group.notify(queue: .main) {
            if let error = uploadError {
                completion(.failure(error))
                return
            }
            
            // Now generate content with all parts
            self.generateContent(parts: parts, generationConfig: generationConfig, skipDebugLogging: true) { result in
                // Handle debug logging with full request body if enabled and we have the debug request
                if AIDebugLogger.shared.isEnabled, let debugReq = debugRequest {
                    // Create the full request body structure for debugging
                    let requestBody: [String: Any] = [
                        "contents": [
                            [
                                "parts": parts
                            ]
                        ],
                        "generationConfig": generationConfig ?? [:]
                    ]
                    
                    // Convert to JSON string and create new debug request with full body
                    var fullRequestBodyString: String?
                    if let jsonData = try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        fullRequestBodyString = jsonString
                        print("📋 [AIService] Captured full multi-video request body: \(jsonString.count) chars")
                    }
                    
                    // Create updated debug request with full body
                    let updatedDebugReq = AIDebugRequest(
                        prompt: debugReq.prompt,
                        systemPrompt: debugReq.systemPrompt,
                        model: debugReq.model,
                        parameters: debugReq.parameters,
                        media: debugReq.media,
                        tokenEstimate: debugReq.tokenEstimate,
                        temperature: debugReq.temperature,
                        maxTokens: debugReq.maxTokens,
                        topP: debugReq.topP,
                        topK: debugReq.topK,
                        responseSchema: debugReq.responseSchema,
                        fullGenerationConfig: debugReq.fullGenerationConfig,
                        playerProfile: debugReq.playerProfile,
                        fullRequestBody: fullRequestBodyString
                    )
                    
                    // Log the request with full body
                    AIDebugLogger.shared.logRequest(updatedDebugReq)
                    
                    // Handle response logging
                    let processingTime = Date().timeIntervalSince(requestStartTime)
                    switch result {
                    case .success(let response):
                        // For now, create a basic token usage estimate
                        let promptLength = prompt.count
                        let responseLength = response.count
                        let estimatedPromptTokens = promptLength / 4  // Rough estimate
                        let estimatedResponseTokens = responseLength / 4  // Rough estimate
                        
                        let tokenUsage = TokenUsage(
                            promptTokens: estimatedPromptTokens,
                            completionTokens: estimatedResponseTokens
                        )
                        
                        let debugResponse = AIDebugResponse(
                            text: response,
                            tokenUsage: tokenUsage,
                            processingTime: processingTime
                        )
                        
                        AIDebugLogger.shared.updateLogWithResponse(updatedDebugReq.id, response: debugResponse, duration: processingTime)
                        
                    case .failure(let error):
                        AIDebugLogger.shared.updateLogWithError(updatedDebugReq.id, error: error, duration: processingTime)
                    }
                }
                
                // Log result
                switch result {
                case .success(_):
                    print("✅ [AIService] generateFromMultipleVideos succeeded")
                case .failure(let error):
                    print("❌ [AIService] generateFromMultipleVideos failed: \(error)")
                }
                completion(result)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func performRequestWithRetry(request: URLRequest, retryCount: Int, requestStartTime: Date, completion: @escaping (Result<String, Error>) -> Void) {
        // Check circuit breaker before making request
        guard circuitBreaker.canMakeRequest() else {
            print("🚫 [AIService] Circuit breaker is open - request blocked (\(circuitBreaker.status))")
            completion(.failure(ServiceError.apiError("Service temporarily unavailable due to repeated failures. Please try again in a minute.")))
            return
        }

        // Create custom session for video requests with longer timeout
        var requestWithTimeout = request
        requestWithTimeout.timeoutInterval = Constants.videoRequestTimeout

        let networkStartTime = Date()
        if retryCount > 0 {
            print("🔄 [AIService] Retry #\(retryCount) starting network request at: \(DateFormatter.timeStampFormatter.string(from: networkStartTime))")
        } else {
            print("📡 [AIService] Initial network request starting at: \(DateFormatter.timeStampFormatter.string(from: networkStartTime))")
            print("🌐 [AIService] Circuit: \(circuitBreaker.status)")
        }

        var isCompleted = false
        let task = session.dataTask(with: requestWithTimeout) { [weak self] data, response, error in
            guard !isCompleted else { return } // Prevent double completion
            isCompleted = true
            let networkEndTime = Date()
            let networkDuration = networkEndTime.timeIntervalSince(networkStartTime)
            let totalDuration = networkEndTime.timeIntervalSince(requestStartTime)

            print("📊 [AIService] Network request completed:")
            print("   📡 Network time: \(String(format: "%.2f", networkDuration))s")
            print("   ⏱️ Total time: \(String(format: "%.2f", totalDuration))s")
            print("   🔢 Retry attempt: \(retryCount)")
            guard let self = self else { return }
            
            if let error = error {
                print("❌ [AIService] Network error: \(error)")
                
                // Check if we should retry (especially for timeouts)
                let shouldRetry = (error as NSError).code == NSURLErrorTimedOut || 
                                  (error as NSError).code == NSURLErrorNetworkConnectionLost
                
                if shouldRetry && retryCount < Constants.maxRetries {
                    let delay = Constants.retryDelay * Double(retryCount + 1) // Exponential backoff
                    print("🔄 [AIService] Request failed after \(String(format: "%.2f", networkDuration))s, retrying...")
                    print("🔄 [AIService] Retrying request (attempt \(retryCount + 1) of \(Constants.maxRetries))...")
                    print("⏳ [AIService] Waiting \(delay) seconds before retry")
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        self.performRequestWithRetry(request: request, retryCount: retryCount + 1, requestStartTime: requestStartTime, completion: completion)
                    }
                } else {
                    print("❌ [AIService] Max retries reached, failing request")
                    self.circuitBreaker.recordFailure()
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [AIService] HTTP Status: \(httpResponse.statusCode)")
                
                // Retry on server errors (5xx)
                if httpResponse.statusCode >= 500 && retryCount < Constants.maxRetries {
                    print("🔄 [AIService] Server error (\(httpResponse.statusCode)) after \(String(format: "%.2f", networkDuration))s, retrying...")
                    DispatchQueue.global().asyncAfter(deadline: .now() + Constants.retryDelay) {
                        self.performRequestWithRetry(request: request, retryCount: retryCount + 1, requestStartTime: requestStartTime, completion: completion)
                    }
                    return
                } else if httpResponse.statusCode >= 400 {
                    // Record failure for client/server errors
                    self.circuitBreaker.recordFailure()
                }
            }
            
            guard let data = data else {
                print("❌ [AIService] No data received")
                completion(.failure(ServiceError.noData))
                return
            }
            
            print("📦 [AIService] Received \(data.count) bytes after \(String(format: "%.2f", networkDuration))s network time")

            // Log request timing for debugging (circuit breaker only tracks failures, not slow requests)
            if totalDuration > 30.0 {
                print("🐌 [AIService] SLOW REQUEST WARNING: Total time \(String(format: "%.2f", totalDuration))s (>30s)")
            } else if totalDuration > 10.0 {
                print("⚠️ [AIService] Slow request: Total time \(String(format: "%.2f", totalDuration))s (>10s)")
            } else {
                print("✅ [AIService] Good response time: \(String(format: "%.2f", totalDuration))s")
            }
            
            // Print raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 [AIService] Raw response: \(responseString.prefix(500))...")
            }
            
            // Parse response
            self.parseResponse(data: data, completion: completion)
        }

        task.resume()

        // Add a timeout watchdog for slow connections
        // Check if this is a large request (multiple videos or large data)
        let requestBodySize = requestWithTimeout.httpBody?.count ?? 0
        let isLargeRequest = requestBodySize > 10_000_000 // Over 10MB

        // Single timeout policy for all networks
        let timeoutDuration: TimeInterval = isLargeRequest ? 120.0 : 120.0

        DispatchQueue.global().asyncAfter(deadline: .now() + timeoutDuration) { [weak self] in
            if !isCompleted {
                print("⏱️ [AIService] Request timeout after \(timeoutDuration)s - cancelling task")
                isCompleted = true
                task.cancel()
                self?.circuitBreaker.recordFailure()
                completion(.failure(ServiceError.apiError("Request timed out after \(Int(timeoutDuration)) seconds. Please check your connection and try again.")))
            }
        }
    }
    
    private func buildURL() -> URL? {
        let urlString = "\(configuration.baseURL)/models/\(configuration.modelName):generateContent?key=\(configuration.apiKey)"
        return URL(string: urlString)
    }
    
    private func parseResponse(data: Data, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            // Parse JSON response
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(.failure(ServiceError.invalidResponse))
                return
            }
            
            // Response received
            
            // Check for error response
            if let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                // API error occurred
                completion(.failure(ServiceError.apiError(message)))
                return
            }
            
            // Extract generated text
            guard let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart["text"] as? String else {
                completion(.failure(ServiceError.invalidResponse))
                return
            }
            
            // Record successful response for circuit breaker
            self.circuitBreaker.recordSuccess()
            NotificationCenter.default.post(name: .aiResponseReceived, object: nil)
            completion(.success(text))
            
        } catch {
            completion(.failure(ServiceError.decodingError(error)))
        }
    }
    
    // MARK: - Generation Configuration Helpers
    
    // (Removed unused createGenerationConfig helper)
}
