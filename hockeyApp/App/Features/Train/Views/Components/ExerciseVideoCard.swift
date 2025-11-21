import SwiftUI

/// Dedicated video card for exercises (separate from image handling)
struct ExerciseVideoCard: View {
    @Environment(\.theme) var theme

    let exercise: Exercise
    let overlayText: String?
    let height: CGFloat

    var body: some View {
        ZStack {
            // Video player
            if let videoFileName = exercise.videoFileName {
                DrillVideoPlayer(videoFileName: videoFileName, showOverlay: true)
                    .frame(height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            } else {
                // Fallback if no video (shouldn't happen)
                Color.black
                    .frame(height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }

            // Timer overlay
            if let overlayText {
                Text(overlayText)
                    .font(.system(size: 84, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .monospacedDigit()
                    .shadow(color: .black.opacity(0.95), radius: 10, x: 0, y: 6)
                    .shadow(color: .black.opacity(0.75), radius: 22, x: 0, y: 12)
            }
        }
        .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 8)
    }
}
