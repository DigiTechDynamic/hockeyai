import SwiftUI

/// Dedicated image card for exercises (separate from video handling)
struct ExerciseImageCard: View {
    @Environment(\.theme) var theme

    let exercise: Exercise
    let overlayText: String?
    let height: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black

                // Image with proper aspect fill
                if let uiImage = UIImage(named: exercise.category.imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    // Fallback gradient
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.3),
                            theme.primary.opacity(0.15),
                            theme.accent.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Text(exercise.category.icon)
                        .font(.system(size: 72))
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
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
                        .shadow(color: .black.opacity(0.9), radius: 8, x: 0, y: 4)
                        .shadow(color: .black.opacity(0.7), radius: 18, x: 0, y: 10)
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.45), radius: 18, x: 0, y: 12)
    }
}
