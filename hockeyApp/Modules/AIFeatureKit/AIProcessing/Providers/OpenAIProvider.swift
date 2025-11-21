import Foundation
import AVFoundation
import UIKit

// MARK: - OpenAI Provider
/// OpenAI-specific implementation of AIProvider
/// Optimized for fast image analysis (2-3s vs Gemini's 13-20s on cellular)
class OpenAIProvider: AIProvider {

    // MARK: - Properties
    private let openAIService: OpenAIService?

    var providerName: String {
        return "OpenAI"
    }

    var isAvailable: Bool {
        return openAIService != nil
    }

    // MARK: - Initialization
    init() {
        self.openAIService = OpenAIService()
    }

    // MARK: - AIProvider Implementation

    /// Analyze an image with OpenAI Vision API
    func analyzeImage(
        imageData: Data,
        prompt: String,
        generationConfig: [String: Any]?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let service = openAIService else {
            completion(.failure(AIProviderError.providerUnavailable("OpenAI API key not available")))
            return
        }

        print("🤖 [OpenAIProvider] Starting image analysis with OpenAI...")
        print("📊 [OpenAIProvider] Image data size: \(imageData.count / 1024) KB")

        // Call OpenAI service
        service.analyzeImage(
            imageData: imageData,
            prompt: prompt,
            generationConfig: generationConfig
        ) { result in
            switch result {
            case .success(let response):
                print("✅ [OpenAIProvider] Image analysis complete")
                completion(.success(response))
            case .failure(let error):
                print("❌ [OpenAIProvider] Image analysis failed: \(error)")
                completion(.failure(error))
            }
        }
    }

    /// Analyze a video (OpenAI doesn't support native video, so extract key frame)
    /// Note: For video analysis, prefer using GeminiProvider which has native video support
    func analyzeVideo(
        videoURL: URL,
        prompt: String,
        frameRate: Int?,
        generationConfig: [String: Any]?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let service = openAIService else {
            completion(.failure(AIProviderError.providerUnavailable("OpenAI API key not available")))
            return
        }

        print("🤖 [OpenAIProvider] Starting video analysis with OpenAI...")
        print("⚠️ [OpenAIProvider] Note: OpenAI doesn't support native video analysis. Extracting key frame...")

        Task {
            do {
                // Extract middle frame from video as a representative image
                let keyFrame = try await extractKeyFrame(from: videoURL)

                // Convert to JPEG data (increased to 0.9 for better quality)
                guard let imageData = keyFrame.jpegData(compressionQuality: 0.9) else {
                    completion(.failure(AIProviderError.videoProcessingFailed("Failed to convert frame to JPEG")))
                    return
                }

                print("📊 [OpenAIProvider] Extracted key frame: \(imageData.count / 1024) KB")

                // Analyze the extracted frame
                service.analyzeImage(
                    imageData: imageData,
                    prompt: prompt,
                    generationConfig: generationConfig
                ) { result in
                    switch result {
                    case .success(let response):
                        print("✅ [OpenAIProvider] Video frame analysis complete")
                        completion(.success(response))
                    case .failure(let error):
                        print("❌ [OpenAIProvider] Video frame analysis failed: \(error)")
                        completion(.failure(error))
                    }
                }

            } catch {
                completion(.failure(AIProviderError.videoProcessingFailed("Failed to extract key frame: \(error.localizedDescription)")))
            }
        }
    }

    // MARK: - Private Methods

    /// Extract a key frame from the middle of the video
    private func extractKeyFrame(from videoURL: URL) async throws -> UIImage {
        let asset = AVURLAsset(url: videoURL)
        let duration = try await asset.load(.duration)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        // Extract frame from middle of video
        let midpoint = CMTime(seconds: duration.seconds / 2, preferredTimescale: duration.timescale)

        let cgImage = try generator.copyCGImage(at: midpoint, actualTime: nil)
        return UIImage(cgImage: cgImage)
    }
}
