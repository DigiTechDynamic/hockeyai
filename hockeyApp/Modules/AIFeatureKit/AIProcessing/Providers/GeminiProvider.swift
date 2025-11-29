import Foundation
import AVFoundation

// MARK: - Gemini Provider
/// Gemini-specific implementation of AIProvider
/// Wraps the existing AIService to provide clean abstraction
class GeminiProvider: AIProvider {
    
    // MARK: - Properties
    internal let aiService: AIService?
    
    var providerName: String {
        return "Gemini"
    }
    
    var isAvailable: Bool {
        return aiService != nil
    }
    
    // MARK: - Initialization
    init() {
        self.aiService = AIService()
    }
    
    // MARK: - AIProvider Implementation
    func analyzeVideo(
        videoURL: URL,
        prompt: String,
        frameRate: Int?,
        generationConfig: [String: Any]?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Add retry wrapper
        analyzeVideoWithRetry(
            videoURL: videoURL,
            prompt: prompt,
            frameRate: frameRate,
            generationConfig: generationConfig,
            retryCount: 0,
            maxRetries: 1,  // Reduced from 2 to 1 for faster failure
            completion: completion
        )
    }

    func analyzeImage(
        imageData: Data,
        prompt: String,
        generationConfig: [String: Any]?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let aiService = aiService else {
            completion(.failure(AIProviderError.providerUnavailable("Gemini API key not available")))
            return
        }

        print("🤖 [GeminiProvider] Starting image analysis with Gemini...")
        print("📊 [GeminiProvider] Image data size: \(imageData.count / 1024) KB")

        let config = generationConfig ?? createDefaultConfig()

        // Call AI service
        aiService.generateFromMultiModal(
            prompt: prompt,
            imageData: (data: imageData, mimeType: "image/jpeg"),
            generationConfig: config
        ) { result in
            switch result {
            case .success(let response):
                print("✅ [GeminiProvider] Image analysis complete")
                completion(.success(response))
            case .failure(let error):
                print("❌ [GeminiProvider] Image analysis failed: \(error)")
                completion(.failure(error))
            }
        }
    }

    /// Generate content from text-only prompt (no media)
    func generateContent(
        prompt: String,
        generationConfig: [String: Any]?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let aiService = aiService else {
            completion(.failure(AIProviderError.providerUnavailable("Gemini API key not available")))
            return
        }

        print("🤖 [GeminiProvider] Starting text-only generation with Gemini...")

        let config = generationConfig ?? createDefaultConfig()
        let parts: [[String: Any]] = [["text": prompt]]

        // Call AI service with text-only parts
        aiService.generateContent(
            parts: parts,
            generationConfig: config,
            skipDebugLogging: false
        ) { result in
            switch result {
            case .success(let response):
                print("✅ [GeminiProvider] Text generation complete")
                completion(.success(response))
            case .failure(let error):
                print("❌ [GeminiProvider] Text generation failed: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    private func analyzeVideoWithRetry(
        videoURL: URL,
        prompt: String,
        frameRate: Int?,
        generationConfig: [String: Any]?,
        retryCount: Int,
        maxRetries: Int,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let aiService = aiService else {
            completion(.failure(AIProviderError.providerUnavailable("Gemini API key not available")))
            return
        }

        print("🤖 [GeminiProvider] Starting video analysis with Gemini...")

        // Log analysis start if debug logging enabled
        let requestStartTime = Date()

        Task {
            do {
                // Downsample video to 10 FPS before upload to save bandwidth and reduce costs
                let targetFPS = 10  // Optimal FPS for analysis while minimizing file size
                print("🎬 [GeminiProvider] Downsampling video to \(targetFPS) FPS for optimal upload...")

                let downsampledURL = try await downsampleVideo(url: videoURL, targetFPS: targetFPS)

                // Read downsampled video data
                guard let videoData = try? Data(contentsOf: downsampledURL) else {
                    completion(.failure(AIProviderError.videoProcessingFailed("Failed to read downsampled video file")))
                    return
                }

                print("📊 [GeminiProvider] Downsampled video size: \(videoData.count / 1024) KB")

                // Always use 10 FPS since we downsampled the video to 10 FPS
                let analysisFrameRate = targetFPS
                print("🎯 [GeminiProvider] Analysis frame rate: \(analysisFrameRate) FPS")
                
                // Create video metadata for AI
                let videoMetadata = VideoMetadata(
                    fps: analysisFrameRate
                )
                
                // Use provided generation config or default
                let config = generationConfig ?? createDefaultConfig()
                
                // Call AI service
                aiService.generateFromMultiModal(
                    prompt: prompt,
                    videoData: (data: videoData, mimeType: "video/mp4"),
                    videoMetadata: videoMetadata,
                    generationConfig: config
                ) { [weak self] result in
                    // Best-effort cleanup of temp file
                    try? FileManager.default.removeItem(at: downsampledURL)
                    switch result {
                    case .success(let response):
                        print("✅ [GeminiProvider] Analysis complete")
                        completion(.success(response))
                    case .failure(let error):
                        print("❌ [GeminiProvider] Analysis failed: \(error)")
                        
                        // Check if we should retry
                        let shouldRetry = self?.shouldRetryError(error) ?? false
                        if shouldRetry && retryCount < maxRetries {
                            // Reduced retry delay for better UX
                            let baseDelay = retryCount == 0 ? 1.0 : 2.0
                            let jitter = Double.random(in: 0...0.5)
                            let delay = baseDelay + jitter
                            
                            print("🔄 [GeminiProvider] Network error detected: \(error.localizedDescription)")
                            print("🔄 [GeminiProvider] Retrying in \(String(format: "%.1f", delay)) seconds... (attempt \(retryCount + 1)/\(maxRetries))")
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                self?.analyzeVideoWithRetry(
                                    videoURL: videoURL,
                                    prompt: prompt,
                                    frameRate: frameRate,
                                    generationConfig: generationConfig,
                                    retryCount: retryCount + 1,
                                    maxRetries: maxRetries,
                                    completion: completion
                                )
                            }
                        } else {
                            // Provide better error message for timeouts
                            if error.localizedDescription.lowercased().contains("timeout") ||
                               error.localizedDescription.lowercased().contains("timed out") {
                                completion(.failure(AIProviderError.analysisTimeout))
                            } else {
                                completion(.failure(error))
                            }
                        }
                    }
                }
                
            } catch {
                completion(.failure(AIProviderError.videoProcessingFailed("Failed to process video: \(error.localizedDescription)")))
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func extractVideoFrameRate(from videoURL: URL) async throws -> Double {
        let videoAsset = AVURLAsset(url: videoURL)
        let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first
        let frameRate = try await videoTrack?.load(.nominalFrameRate) ?? 30.0
        return Double(frameRate)
    }
    
    /// Create a basic default configuration for general AI analysis
    private func createDefaultConfig() -> [String: Any] {
        return [
            "temperature": 0.1,  // Very low for consistent sports analysis
            "topK": 10,  // More focused token selection
            "topP": 0.8,  // Higher precision
            "maxOutputTokens": 8192  // Increased for detailed analysis
        ]
    }
    
    /// Determine if an error should trigger a retry
    private func shouldRetryError(_ error: Error) -> Bool {
        // Check for NSURLError network errors first
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .cannotFindHost, .dnsLookupFailed:
                // Don't retry for obvious no-network conditions
                return false
            case .timedOut, .networkConnectionLost, .cannotConnectToHost:
                // These might be temporary, allow one retry
                return true
            default:
                break
            }
        }
        
        // Retry on specific AIService errors
        if let serviceError = error as? AIService.ServiceError {
            switch serviceError {
            case .invalidResponse, .noData:
                return true
            case .apiError(let message):
                // Retry on specific API errors
                let lowercased = message.lowercased()
                return lowercased.contains("max_tokens") ||
                       lowercased.contains("timeout") ||
                       lowercased.contains("rate limit") ||
                       lowercased.contains("internal error") ||
                       lowercased.contains("500") ||
                       lowercased.contains("503")
            default:
                return false
            }
        }
        
        // Retry on provider errors
        if let providerError = error as? AIProviderError {
            switch providerError {
            case .analysisTimeout, .invalidResponse:
                return true
            default:
                return false
            }
        }
        
        // Check for specific error messages in general errors
        let errorMessage = error.localizedDescription.lowercased()
        if errorMessage.contains("max_tokens") ||
           errorMessage.contains("timeout") ||
           errorMessage.contains("timed out") ||
           errorMessage.contains("network") ||
           errorMessage.contains("rate limit") ||
           errorMessage.contains("connection") {
            return true
        }
        
        return false
    }

    /// Downsamples a video to the target FPS to reduce file size for upload
    /// - Parameters:
    ///   - url: Source video URL
    ///   - targetFPS: Target frame rate (e.g., 10 FPS)
    /// - Returns: URL of the downsampled video
    func downsampleVideo(url: URL, targetFPS: Int) async throws -> URL {
        let asset = AVURLAsset(url: url)

        // Get source video track
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw AIProviderError.videoProcessingFailed("No video track found")
        }

        // Get source properties
        let sourceFrameRate = try await videoTrack.load(.nominalFrameRate)
        let duration = try await asset.load(.duration)
        let naturalSize = try await videoTrack.load(.naturalSize)
        let transform = try await videoTrack.load(.preferredTransform)

        print("📹 [GeminiProvider] Source video: \(Int(sourceFrameRate)) FPS, \(Int(naturalSize.width))x\(Int(naturalSize.height)), \(String(format: "%.1f", duration.seconds))s")

        // If source FPS is already at or below target, return original
        if sourceFrameRate <= Float(targetFPS) {
            print("✅ [GeminiProvider] Source FPS (\(Int(sourceFrameRate))) already at or below target (\(targetFPS)), skipping downsample")
            return url
        }

        // Create composition
        let composition = AVMutableComposition()

        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw AIProviderError.videoProcessingFailed("Failed to create composition track")
        }

        // Insert entire video track
        try compositionVideoTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: duration),
            of: videoTrack,
            at: .zero
        )

        // Apply original transform to maintain orientation
        compositionVideoTrack.preferredTransform = transform

        // Copy audio track if exists
        if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
            if let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) {
                try compositionAudioTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: duration),
                    of: audioTrack,
                    at: .zero
                )
            }
        }

        // Create export session
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPreset1920x1080
        ) else {
            throw AIProviderError.videoProcessingFailed("Failed to create export session")
        }

        // Generate temporary output URL
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        // Configure video composition to control frame rate
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTime(value: 1, timescale: Int32(targetFPS))
        videoComposition.renderSize = naturalSize

        // Add instruction for the video track
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        layerInstruction.setTransform(transform, at: .zero)

        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        exportSession.videoComposition = videoComposition

        // Export the video
        print("🔄 [GeminiProvider] Exporting downsampled video...")
        await exportSession.export()

        // Check for errors
        if let error = exportSession.error {
            throw AIProviderError.videoProcessingFailed("Export failed: \(error.localizedDescription)")
        }

        guard exportSession.status == .completed else {
            throw AIProviderError.videoProcessingFailed("Export status: \(exportSession.status.rawValue)")
        }

        // Get file sizes for comparison
        if let originalSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int,
           let downsampledSize = try? FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? Int {
            let reductionPercent = Int((1.0 - Double(downsampledSize) / Double(originalSize)) * 100)
            print("✅ [GeminiProvider] Downsampling complete: \(originalSize / 1024) KB → \(downsampledSize / 1024) KB (\(reductionPercent)% reduction)")
        }

        return outputURL
    }
}
