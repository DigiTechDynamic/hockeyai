import SwiftUI
import AVKit

/// Background video player for drill demonstrations
/// Plays video in loop with optional dark overlay for readability
struct DrillVideoPlayer: View {
    let videoFileName: String?
    let showOverlay: Bool

    @StateObject private var playerViewModel = VideoPlayerViewModel()

    init(videoFileName: String?, showOverlay: Bool = true) {
        self.videoFileName = videoFileName
        self.showOverlay = showOverlay
    }

    var body: some View {
        ZStack {
            if let videoURL = getVideoURL() {
                PlayerViewControllerContainer(url: videoURL, player: playerViewModel.player)
                    .background(Color.black)

                // Dark overlay for text readability
                if showOverlay {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                }
            } else {
                // Fallback: Show obvious placeholder
                ZStack {
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()

                    VStack(spacing: 12) {
                        Image(systemName: "video.slash.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.5))

                        Text("Video Not Found")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))

                        if let fileName = videoFileName {
                            Text(fileName)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Text("Add DrillVideos folder to Xcode")
                            .font(.system(size: 11))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
            }
        }
        .onAppear {
            if let url = getVideoURL() {
                playerViewModel.setupPlayer(with: url)
            }
        }
        .onDisappear {
            playerViewModel.cleanup()
        }
    }

    private func getVideoURL() -> URL? {
        guard let fileName = videoFileName else {
            print("❌ No video file name provided")
            return nil
        }

        // Remove extension if present for Bundle lookup
        let fileNameWithoutExt = fileName.replacingOccurrences(of: ".mp4", with: "")
                                         .replacingOccurrences(of: ".mov", with: "")

        print("🎬 Looking for video: \(fileName)")

        // Try ROOT Resources folder first (simpler, more reliable)
        if let url = Bundle.main.url(forResource: fileNameWithoutExt, withExtension: "mp4") {
            print("✅ Found video in Resources root: \(url.path)")
            return url
        }

        if let url = Bundle.main.url(forResource: fileNameWithoutExt, withExtension: "mov") {
            print("✅ Found video in Resources root: \(url.path)")
            return url
        }

        // Try with full filename
        if let url = Bundle.main.url(forResource: fileName, withExtension: nil) {
            print("✅ Found video in Resources root (full name): \(url.path)")
            return url
        }

        // Try DrillVideos subdirectory as fallback
        if let url = Bundle.main.url(forResource: fileNameWithoutExt, withExtension: "mp4", subdirectory: "DrillVideos") {
            print("✅ Found video in DrillVideos: \(url.path)")
            return url
        }

        if let url = Bundle.main.url(forResource: fileNameWithoutExt, withExtension: "mov", subdirectory: "DrillVideos") {
            print("✅ Found video in DrillVideos: \(url.path)")
            return url
        }

        // List all bundle resources to debug
        if let resourcePath = Bundle.main.resourcePath {
            print("📁 Bundle resource path: \(resourcePath)")
            if let resources = try? FileManager.default.contentsOfDirectory(atPath: resourcePath) {
                let videos = resources.filter { $0.hasSuffix(".mp4") || $0.hasSuffix(".mov") }
                print("📹 Videos in bundle: \(videos)")
            }
        }

        print("❌ Could not find video: \(fileName)")
        return nil
    }
}

// MARK: - Video Player ViewModel
class VideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer?
    private var loopObserver: NSObjectProtocol?

    func setupPlayer(with url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = true // Mute by default

        // Setup looping
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }

        // Start playing
        player?.play()
    }

    func cleanup() {
        player?.pause()
        player = nil

        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        loopObserver = nil
    }
}

// MARK: - UIKit AVPlayerViewController Wrapper
private struct PlayerViewControllerContainer: UIViewControllerRepresentable {
    let url: URL
    let player: AVPlayer?

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        controller.view.backgroundColor = .black

        // Create player immediately (fixes race condition)
        let activePlayer = player ?? AVPlayer(url: url)
        activePlayer.isMuted = true
        activePlayer.volume = 0.0
        activePlayer.actionAtItemEnd = .none
        controller.player = activePlayer

        // Start playback
        activePlayer.play()

        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        // Update player if it changed
        if let player, controller.player !== player {
            controller.player = player
            player.isMuted = true
            player.volume = 0.0
            player.actionAtItemEnd = .none
            player.play()
        }

        // Ensure playback continues
        controller.player?.play()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {}
}

// MARK: - Preview
#Preview {
    ZStack {
        DrillVideoPlayer(videoFileName: "AroundTheWorldWarmUp.mp4")

        VStack {
            Spacer()
            Text("AROUND THE WORLD")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .shadow(radius: 10)
            Text("2:00")
                .font(.system(size: 84, weight: .black))
                .foregroundColor(.white)
                .monospacedDigit()
            Spacer()
        }
    }
}
