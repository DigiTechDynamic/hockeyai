import SwiftUI
import AVKit
import AVFoundation

// MARK: - AI Example Media View
/// A reusable component for displaying example media (image or video) with instructions
/// Used across AI features to show users how to capture content
public struct AIExampleMediaView: View {
    @Environment(\.theme) var theme
    
    // MARK: - Configuration
    public enum MediaSource {
        case image(String) // Asset name or URL string
        case video(String) // Video file name or URL string
    }
    
    public let mediaSource: MediaSource
    public let actionTitle: String
    public let instructions: String
    public let cornerRadius: CGFloat
    public let isMuted: Bool
    
    // MARK: - Private State
    @State private var isVideoPlaying = false
    @State private var player: AVPlayer?
    
    // MARK: - Initialization
    public init(
        mediaSource: MediaSource,
        actionTitle: String,
        instructions: String,
        cornerRadius: CGFloat = 24,
        isMuted: Bool = true
    ) {
        self.mediaSource = mediaSource
        self.actionTitle = actionTitle
        self.instructions = instructions
        self.cornerRadius = cornerRadius
        self.isMuted = true // Always mute videos
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(spacing: 0) {
            // Media container with overlay
            ZStack(alignment: .bottom) {
                // Media content
                mediaContent
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16/9, contentMode: .fill)
                    .clipped()
            }
            .clipShape(
                .rect(
                    topLeadingRadius: cornerRadius,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: cornerRadius
                )
            )
            
            // Instructions section
            instructionsSection
        }
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(theme.primary.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Media Content
    @ViewBuilder
    private var mediaContent: some View {
        switch mediaSource {
        case .image(let source):
            if source.hasPrefix("http") {
                // URL image
                AsyncImage(url: URL(string: source)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(theme.surface)
                }
            } else {
                // Local asset
                Image(source)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            
        case .video(let source):
            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true) // Prevent controls
                    .rotationEffect(source == "WristFromSide.MOV" ? .degrees(-90) : .degrees(0))
                    .scaleEffect(source == "WristFromSide.MOV" ? 2.0 : 1.0)
                    .onAppear {
                        // Configure audio session to not interrupt other audio
                        configureAudioSession()
                        
                        // Always mute the player
                        player.isMuted = true
                        player.volume = 0.0
                        player.play()
                        player.actionAtItemEnd = .none
                        
                        // Loop video
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: player.currentItem,
                            queue: .main
                        ) { _ in
                            player.seek(to: .zero)
                            player.play()
                        }
                    }
            } else {
                // Loading state
                ZStack {
                    Color.black
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                .onAppear {
                    loadVideo(source: source)
                }
            }
        }
    }
    
    
    // MARK: - Instructions Section
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(instructions)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.md)
        .background(Color.gray.opacity(0.5))
        .clipShape(
            .rect(
                topLeadingRadius: 0,
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius,
                topTrailingRadius: 0
            )
        )
    }
    
    // MARK: - Helper Methods
    private func loadVideo(source: String) {
        if source.hasPrefix("http"), let url = URL(string: source) {
            player = AVPlayer(url: url)
        } else if let url = Bundle.main.url(forResource: source, withExtension: nil) {
            player = AVPlayer(url: url)
        }
        // Always mute the player when loading
        player?.isMuted = true
        player?.volume = 0.0
    }
    
    private func configureAudioSession() {
        do {
            // Configure the audio session to allow mixing with other audio
            // This prevents the video from interrupting background music
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // If configuration fails, we still allow video to play
            // but it might interrupt background audio
            print("Failed to configure audio session for non-interrupting playback: \(error)")
        }
    }
}

// MARK: - Convenience Initializers
public extension AIExampleMediaView {
    /// Create an example view with an image
    static func image(
        _ imageName: String,
        actionTitle: String,
        instructions: String,
        cornerRadius: CGFloat = 24
    ) -> AIExampleMediaView {
        AIExampleMediaView(
            mediaSource: .image(imageName),
            actionTitle: actionTitle,
            instructions: instructions,
            cornerRadius: cornerRadius,
            isMuted: true
        )
    }
    
    /// Create an example view with a video
    static func video(
        _ videoName: String,
        actionTitle: String,
        instructions: String,
        cornerRadius: CGFloat = 24,
        isMuted: Bool = true
    ) -> AIExampleMediaView {
        AIExampleMediaView(
            mediaSource: .video(videoName),
            actionTitle: actionTitle,
            instructions: instructions,
            cornerRadius: cornerRadius,
            isMuted: true // Always mute videos
        )
    }
}

// MARK: - Preview
#if DEBUG
struct AIExampleMediaView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AIExampleMediaView.image(
                "example-shot",
                actionTitle: "Record Like This",
                instructions: "Shoot from 15ft back: camera 10-20ft sideways, chest height—full wrist roll, stick, net visible."
            )
            
            AIExampleMediaView.video(
                "example-video",
                actionTitle: "Pitch Like This",
                instructions: "Stand on the mound, full wind-up motion visible, camera positioned at 45° angle."
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
#endif
