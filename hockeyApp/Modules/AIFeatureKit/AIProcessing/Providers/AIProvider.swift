import Foundation

// MARK: - AI Provider Protocol
/// Protocol for AI providers that can analyze content
/// This enables switching between different AI services (Gemini, OpenAI, Claude, etc.)
protocol AIProvider {

    /// Analyze a video with a text prompt
    /// - Parameters:
    ///   - videoURL: URL to the video file
    ///   - prompt: Analysis prompt text
    ///   - frameRate: Optional target frame rate for analysis (nil uses video's native rate)
    ///   - generationConfig: Optional configuration for the AI generation
    ///   - completion: Completion handler with raw AI response or error
    func analyzeVideo(
        videoURL: URL,
        prompt: String,
        frameRate: Int?,
        generationConfig: [String: Any]?,
        completion: @escaping (Result<String, Error>) -> Void
    )

    /// Analyze an image with a text prompt
    /// - Parameters:
    ///   - imageData: JPEG image data
    ///   - prompt: Analysis prompt text
    ///   - generationConfig: Optional configuration for the AI generation
    ///   - completion: Completion handler with raw AI response or error
    func analyzeImage(
        imageData: Data,
        prompt: String,
        generationConfig: [String: Any]?,
        completion: @escaping (Result<String, Error>) -> Void
    )

    /// Get the provider name for logging/debugging
    var providerName: String { get }

    /// Check if the provider is available (has API key, etc.)
    var isAvailable: Bool { get }
}

// MARK: - AI Provider Error
enum AIProviderError: LocalizedError {
    case providerUnavailable(String)
    case videoProcessingFailed(String)
    case analysisTimeout
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .providerUnavailable(let message):
            return "AI Provider unavailable: \(message)"
        case .videoProcessingFailed(let message):
            return "Video processing failed: \(message)"
        case .analysisTimeout:
            return "AI analysis timed out"
        case .invalidResponse:
            return "Invalid response from AI provider"
        }
    }
}