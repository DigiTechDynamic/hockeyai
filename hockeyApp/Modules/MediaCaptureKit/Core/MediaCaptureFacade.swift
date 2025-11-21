import SwiftUI
import AVKit
import Photos

// MARK: - Media Capture Facade
/// Clean interface for all media capture operations
/// Separates media logic from UI components
public class MediaCaptureFacade {
    
    // MARK: - Media Source Types
    public enum MediaSource {
        case camera
        case library
    }
    
    // MARK: - Configuration
    public struct VideoConfiguration {
        let trimDuration: (min: Double, max: Double)
        let title: String
        let subtitle: String
        
        public init(
            trimDuration: (min: Double, max: Double),
            title: String = "Trim to Perfect Duration",
            subtitle: String = "Select the best moment for analysis"
        ) {
            self.trimDuration = trimDuration
            self.title = title
            self.subtitle = subtitle
        }
    }
    
    // MARK: - Camera Methods
    
    /// Present camera for video capture
    /// Returns a SwiftUI view that handles camera capture
    public static func createCameraView(
        mode: MediaType = .video,
        onVideoCaptured: @escaping (URL) -> Void,
        onPhotoCaptured: ((UIImage) -> Void)? = nil
    ) -> some View {
        CustomCameraView(
            capturedImage: .constant(nil),
            onVideoCaptured: onVideoCaptured,
            mode: mode
        )
    }
    
    /// Check camera permissions
    public static func checkCameraPermissions(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            completion(false)
        }
    }
    
    /// Request camera permissions if needed
    public static func requestCameraPermissions(completion: @escaping (Bool) -> Void) {
        checkCameraPermissions(completion: completion)
    }
    
    // MARK: - Library Methods
    
    /// Check photo library permissions
    public static func checkLibraryPermissions(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        default:
            completion(false)
        }
    }
    
    /// Create library picker view for media selection
    /// Returns a SwiftUI view that handles library selection
    public static func createLibraryPickerView(
        mediaType: MediaType,
        onMediaSelected: @escaping (URL?) -> Void
    ) -> some View {
        LibraryPickerWrapper(
            mediaType: mediaType,
            onMediaSelected: onMediaSelected
        )
    }
    
    
    // MARK: - Video Trimming
    
    /// Create video trimmer view
    /// Returns a SwiftUI view for video trimming
    public static func createVideoTrimmerView(
        videoURL: URL,
        minDuration: Double,
        maxDuration: Double,
        onTrimComplete: @escaping (URL?) -> Void
    ) -> some View {
        VideoTrimmerView(
            sourceVideoURL: videoURL,
            configuration: VideoTrimmerConfig(
                minDuration: minDuration,
                maxDuration: maxDuration
            ),
            onTrimComplete: onTrimComplete
        )
    }
    
    /// Trim video to specified duration programmatically
    /// Uses AVFoundation to trim without UI
    public static func trimVideo(
        url: URL,
        startTime: Double,
        endTime: Double,
        completion: @escaping (URL?) -> Void
    ) {
        Task {
            do {
                let trimmedURL = try await performVideoTrim(
                    url: url,
                    startTime: startTime,
                    endTime: endTime
                )
                await MainActor.run {
                    completion(trimmedURL)
                }
            } catch {
                print("❌ [MediaCaptureFacade] Video trim failed: \(error)")
                await MainActor.run {
                    completion(nil)
                }
            }
        }
    }
    
    /// Perform the actual video trimming
    private static func performVideoTrim(
        url: URL,
        startTime: Double,
        endTime: Double
    ) async throws -> URL {
        let asset = AVAsset(url: url)
        
        // Create composition
        let composition = AVMutableComposition()
        
        let startCMTime = CMTime(seconds: startTime, preferredTimescale: 600)
        let endCMTime = CMTime(seconds: endTime, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startCMTime, end: endCMTime)
        
        // Add video track
        if let videoTrack = try await asset.loadTracks(withMediaType: .video).first,
           let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
           ) {
            try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
        }
        
        // Add audio track
        if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first,
           let compositionAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
           ) {
            try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
        }
        
        // Create output URL
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("trimmed_\(UUID().uuidString).mp4")
        
        // Export
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw VideoTrimError.exportFailed
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        
        await exportSession.export()
        
        if exportSession.status == .completed {
            return outputURL
        } else {
            throw VideoTrimError.exportFailed
        }
    }
    
    // MARK: - Error Types
    enum VideoTrimError: LocalizedError {
        case exportFailed
        
        var errorDescription: String? {
            switch self {
            case .exportFailed:
                return "Failed to export trimmed video"
            }
        }
    }
    
    // MARK: - Video Preview
    /// Create a video preview view with thumbnail and play button
    public static func createVideoPreviewView(url: URL) -> some View {
        VideoPreviewView(url: url)
    }
}

// MARK: - Video Preview View
/// Clean video preview component
private struct VideoPreviewView: View {
    let url: URL
    @State private var thumbnail: UIImage?
    @State private var showPlayer = false
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                // Video thumbnail
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .overlay(
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipped()
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                // Play button
                Button(action: {
                    showPlayer = true
                    let newPlayer = AVPlayer(url: url)
                    newPlayer.isMuted = true
                    newPlayer.volume = 0.0
                    player = newPlayer
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }
            } else {
                // Loading state
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.blue))
                    )
            }
        }
        .onAppear {
            generateThumbnail()
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let player = player {
                OrientationAwareVideoPlayerView(url: url, player: player)
                    .ignoresSafeArea()
                    .overlay(alignment: .topTrailing) {
                        Button(action: {
                            player.pause()
                            showPlayer = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                                .padding()
                        }
                    }
            }
        }
    }
    
    private func generateThumbnail() {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 1920, height: 1080)
        
        Task {
            do {
                let duration = try await asset.load(.duration)
                let midpointTime = CMTime(seconds: duration.seconds / 2, preferredTimescale: 600)
                let cgImage = try await generator.image(at: midpointTime).image
                let thumbnailImage = UIImage(cgImage: cgImage)
                
                await MainActor.run {
                    self.thumbnail = thumbnailImage
                }
            } catch {
                print("❌ [MediaCaptureFacade] Failed to generate thumbnail: \(error)")
            }
        }
    }
}

// MARK: - Orientation Aware Player
private struct OrientationAwareVideoPlayerView: UIViewControllerRepresentable {
    let url: URL
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        // Ensure player is muted
        player.isMuted = true
        player.volume = 0.0
        controller.player = player
        controller.videoGravity = .resizeAspect
        
        Task {
            await MainActor.run {
                player.play()
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}