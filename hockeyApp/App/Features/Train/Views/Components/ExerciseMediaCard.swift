import SwiftUI

/// Unified media card for exercises with distinct styles for image vs. video
struct ExerciseMediaCard: View {
    @Environment(\.theme) var theme

    let exercise: Exercise
    /// Optional overlay text (e.g., timer). If nil, no centered overlay text is shown.
    let overlayText: String?
    /// Shows the name/config footer overlay (used on ActiveExercise).
    let showBottomFooter: Bool
    /// Optional override for the card height. If nil, uses defaults (dynamic per screen size).
    let height: CGFloat?
    /// Optional override as a fraction of screen height (0-1). Takes precedence over defaults when set.
    let heightFraction: CGFloat?

    init(
        exercise: Exercise,
        overlayText: String? = nil,
        showBottomFooter: Bool = false,
        height: CGFloat? = nil,
        heightFraction: CGFloat? = nil
    ) {
        self.exercise = exercise
        self.overlayText = overlayText
        self.showBottomFooter = showBottomFooter
        self.height = height
        self.heightFraction = heightFraction
    }

    private var usesVideo: Bool { exercise.videoFileName != nil }
    // Dynamic default height tuned per device size
    // - With footer: ~60% of screen height (clamped)
    // - Without footer: ~48% of screen height (clamped)
    private var containerHeight: CGFloat {
        if let height { return height }
        if let heightFraction, heightFraction > 0, heightFraction <= 1 {
            let screenHeight = UIScreen.main.bounds.height
            let raw = screenHeight * heightFraction
            // Clamp to avoid layout issues on very small/large devices
            let minH: CGFloat = showBottomFooter ? 420 : 300
            let maxH: CGFloat = showBottomFooter ? 560 : 520
            return min(max(raw, minH), maxH)
        }

        let screenHeight = UIScreen.main.bounds.height
        if showBottomFooter {
            let target = screenHeight * 0.60
            return min(max(target, 420), 540)
        } else {
            let target = screenHeight * 0.48
            return min(max(target, 300), 460)
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top media area
                ZStack {
                    // Media background (video or image)
                    Group {
                        if let name = exercise.videoFileName {
                            // Video style: distinct from image (no stroke border, subtle shadow, dark overlay for readability)
                            DrillVideoPlayer(videoFileName: name, showOverlay: true)
                                .frame(maxWidth: .infinity)
                                .frame(height: mediaHeight)
                                .clipped()
                        } else if let uiImage = UIImage(named: exercise.category.imageName) {
                            // Image style - match video background behavior
                            ZStack {
                                Color.black
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: mediaHeight)
                            .clipped()
                        } else {
                            // Gradient fallback with category icon
                            ZStack {
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
                            .frame(maxWidth: .infinity)
                            .frame(height: mediaHeight)
                        }
                    }

                    // Center overlay (e.g., time)
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
                            .shadow(color: .black.opacity(usesVideo ? 0.95 : 0.9), radius: usesVideo ? 10 : 8, x: 0, y: usesVideo ? 6 : 4)
                            .shadow(color: .black.opacity(usesVideo ? 0.75 : 0.7), radius: usesVideo ? 22 : 18, x: 0, y: usesVideo ? 12 : 10)
                    }
                }

                // Bottom name/config footer (ActiveExercise)
                if showBottomFooter {
                    ZStack(alignment: .bottomLeading) {
                        // Solid dark footer area inside card
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.95),
                                Color.black.opacity(0.92)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: footerHeight)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(exercise.name)
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            Text(exercise.config.displaySummary)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.85))
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 22)
                    }
                }
            }
        }
        .frame(height: containerHeight)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            Group {
                if !usesVideo {
                    // Image style: subtle stroke border to match rest screens
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 1
                        )
                }
            }
        )
        .shadow(
            color: .black.opacity(usesVideo ? 0.35 : 0.45),
            radius: usesVideo ? 14 : 18,
            x: 0,
            y: usesVideo ? 8 : 12
        )
    }
}

// MARK: - Private computed sizes
private extension ExerciseMediaCard {
    var footerHeight: CGFloat { showBottomFooter ? 140 : 0 }
    var mediaHeight: CGFloat { max(0, containerHeight - footerHeight) }
}
