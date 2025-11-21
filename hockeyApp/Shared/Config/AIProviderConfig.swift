import Foundation

// MARK: - AI Provider Configuration
/// Centralized configuration for AI provider selection
/// Makes it easy to switch between OpenAI, Gemini, or other providers
class AIProviderConfig {

    // MARK: - Provider Types
    enum ProviderType {
        case openAI
        case gemini
        case auto  // Automatically choose best provider for content type
    }

    // MARK: - Content Types
    enum ContentType {
        case image
        case video
    }

    // MARK: - Configuration

    /// Primary provider for image analysis (default: OpenAI for speed)
    static var imageProvider: ProviderType = .openAI

    /// Primary provider for video analysis (default: Gemini for native video support)
    static var videoProvider: ProviderType = .gemini

    // MARK: - Provider Factory

    /// Get the appropriate provider for a specific content type
    /// - Parameter contentType: The type of content to analyze
    /// - Returns: An AIProvider instance configured for that content type
    static func selectProvider(for contentType: ContentType) -> AIProvider {
        let providerType: ProviderType

        switch contentType {
        case .image:
            providerType = imageProvider
        case .video:
            providerType = videoProvider
        }

        return createProvider(type: providerType, contentType: contentType)
    }

    /// Create a provider instance of the specified type
    /// - Parameters:
    ///   - type: The provider type to create
    ///   - contentType: The content type (for auto selection)
    /// - Returns: An AIProvider instance
    private static func createProvider(type: ProviderType, contentType: ContentType) -> AIProvider {
        switch type {
        case .openAI:
            return OpenAIProvider()

        case .gemini:
            return GeminiProvider()

        case .auto:
            // Automatically choose based on content type
            switch contentType {
            case .image:
                // OpenAI is 6-10x faster for images on cellular
                return OpenAIProvider()
            case .video:
                // Gemini has native video support
                return GeminiProvider()
            }
        }
    }

    /// Get a specific provider by type (for advanced use)
    /// - Parameter type: The provider type
    /// - Returns: An AIProvider instance
    static func getProvider(_ type: ProviderType) -> AIProvider {
        switch type {
        case .openAI:
            return OpenAIProvider()
        case .gemini:
            return GeminiProvider()
        case .auto:
            // Default to OpenAI for general use
            return OpenAIProvider()
        }
    }

    // MARK: - Provider Info

    /// Get information about the current provider configuration
    static func getCurrentConfig() -> String {
        return """
        AI Provider Configuration:
        - Image Provider: \(providerName(imageProvider))
        - Video Provider: \(providerName(videoProvider))
        """
    }

    private static func providerName(_ type: ProviderType) -> String {
        switch type {
        case .openAI: return "OpenAI (GPT-4o-mini)"
        case .gemini: return "Gemini (2.5 Flash)"
        case .auto: return "Automatic"
        }
    }

    // MARK: - Testing & Debugging

    /// Temporarily override provider for testing
    /// - Parameters:
    ///   - provider: The provider type to use
    ///   - contentType: The content type to override
    static func setProvider(_ provider: ProviderType, for contentType: ContentType) {
        switch contentType {
        case .image:
            imageProvider = provider
            print("✅ [AIProviderConfig] Image provider set to: \(providerName(provider))")
        case .video:
            videoProvider = provider
            print("✅ [AIProviderConfig] Video provider set to: \(providerName(provider))")
        }
    }

    /// Reset to default configuration
    static func resetToDefaults() {
        imageProvider = .openAI  // Fast for images
        videoProvider = .gemini  // Native video support
        print("✅ [AIProviderConfig] Reset to defaults (OpenAI for images, Gemini for videos)")
    }
}
