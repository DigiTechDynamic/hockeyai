import Foundation
import UIKit

// MARK: - Image Generation Service
/// Service for generating images using Google's Gemini 3 Pro Image API
/// Uses gemini-3-pro-image-preview model (aka "Nano Banana Pro") for professional-quality image generation
/// Features: 4K resolution, advanced text rendering, Google Search grounding
final class ImageGenerationService {

    // MARK: - Configuration
    struct Configuration {
        let baseURL: String
        let apiKey: String
        let modelName: String

        init(baseURL: String = "https://generativelanguage.googleapis.com/v1beta",
             apiKey: String,
             modelName: String = "gemini-3-pro-image-preview") {
            self.baseURL = baseURL
            self.apiKey = apiKey
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
                    return "Image generation failed: \(message)"
                }
            case .missingAPIKey:
                return "Gemini API key is missing"
            case .imageDecodingFailed:
                return "Failed to decode generated image"
            case .noImagesGenerated:
                return "No images were generated"
            }
        }
    }

    // MARK: - Constants
    private enum Constants {
        static let defaultRequestTimeout: TimeInterval = 120.0  // 2 minutes for image generation
        static let maxRetries = 1
        static let retryDelay: TimeInterval = 2.0
    }

    // MARK: - Properties
    private let configuration: Configuration
    private let session: URLSession
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

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

    /// Convenience initializer that loads API key from AppSecrets
    convenience init?() {
        guard let apiKey = AppSecrets.shared.geminiAPIKey else {
            print("❌ [ImageGenerationService] No Gemini API key found")
            return nil
        }

        self.init(configuration: Configuration(apiKey: apiKey))
        print("✅ [ImageGenerationService] Initialized with API key")
    }

    // MARK: - Image Generation

    /// Generate an image from a text prompt
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
        print("🎨 [ImageGenerationService] Starting image generation...")
        print("📝 [ImageGenerationService] Prompt: \(prompt)")
        print("🔧 [ImageGenerationService] Parameters: Aspect Ratio \(parameters.aspectRatio.rawValue), Size: \(parameters.imageSize.rawValue)")
        if !referenceImages.isEmpty {
            print("🖼️ [ImageGenerationService] Reference images: \(referenceImages.count)")
        }

        let requestStartTime = Date()

        // Build request
        do {
            let request = try buildGenerationRequest(
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
                    if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorResponse["error"] as? [String: Any],
                       let message = error["message"] as? String {

                        print("❌ [ImageGenerationService] API error: \(message)")
                        completion(.failure(ServiceError.apiError(message)))
                    } else {
                        completion(.failure(ServiceError.apiError("HTTP \(httpResponse.statusCode)")))
                    }
                    return
                }

                // Parse response and extract image
                do {
                    let image = try self.parseGenerationResponse(data: data)
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

    // MARK: - Request Building

    private func buildGenerationRequest(
        prompt: String,
        parameters: GenerationParameters,
        referenceImages: [UIImage] = []
    ) throws -> URLRequest {
        // Build URL for Gemini 3 Pro Image
        guard let url = URL(string: "\(configuration.baseURL)/models/\(configuration.modelName):generateContent") else {
            throw ServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(configuration.apiKey, forHTTPHeaderField: "x-goog-api-key")
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

        // Add reference images as inline_data with highest quality compression
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

    // MARK: - Response Parsing

    private func parseGenerationResponse(data: Data) throws -> UIImage {
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
