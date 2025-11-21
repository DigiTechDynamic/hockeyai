import SwiftUI

/// Persistent top bar for workout execution screens
///
/// **Usage:**
/// ```swift
/// WorkoutTopBar(
///     elapsedTime: 540,           // 9:00 elapsed
///     currentExercise: 3,         // Exercise 3
///     totalExercises: 6,          // of 6 total
///     isPaused: false,
///     onPauseToggle: {
///         // Toggle pause state
///     },
///     onClose: {
///         // Close workout
///     }
/// )
/// ```
///
/// **Features:**
/// - Left: Elapsed time (12:34 format) | Exercise counter (3/6)
/// - Right: Pause button (circle with ⏸ icon)
/// - Glassmorphic background (matches ExerciseDetailView header style)
/// - 56pt touch target for pause button (accessibility)
/// - Smooth animations
struct WorkoutTopBar: View {
    @Environment(\.theme) var theme

    /// Total elapsed time in seconds
    let elapsedTime: TimeInterval

    /// Current exercise number (1-based for display)
    let currentExercise: Int

    /// Total number of exercises
    let totalExercises: Int

    /// Is workout paused?
    let isPaused: Bool

    /// Pause/resume toggle callback
    let onPauseToggle: () -> Void

    /// Close/exit callback
    let onClose: () -> Void

    /// Show exercise counter? (default: true, false during GetReady)
    var showExerciseCounter: Bool = true

    // MARK: - Computed Properties

    /// Formatted elapsed time (mm:ss)
    private var elapsedTimeString: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Exercise counter (e.g., "3/6")
    private var exerciseCounter: String {
        "\(currentExercise)/\(totalExercises)"
    }

    /// Pause/play icon
    private var pauseIcon: String {
        isPaused ? "play.circle.fill" : "pause.circle.fill"
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: theme.spacing.md) {
                // Left side: Time & Exercise counter
                HStack(spacing: 16) {
                    // Elapsed time
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.primary)

                        Text(elapsedTimeString)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(theme.text)
                            .monospacedDigit()
                    }

                    // Divider & Exercise counter (only show during exercises/rest)
                    if showExerciseCounter {
                        Rectangle()
                            .fill(theme.textSecondary.opacity(0.3))
                            .frame(width: 1, height: 20)

                        // Exercise counter
                        HStack(spacing: 6) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.primary)

                            Text(exerciseCounter)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(theme.text)
                                .monospacedDigit()
                        }
                    }
                }

                Spacer(minLength: 0)

                // Right side: Pause & Close buttons
                HStack(spacing: 12) {
                    // Pause/Play button
                    Button(action: onPauseToggle) {
                        ZStack {
                            Circle()
                                .fill(theme.surface)
                                .frame(width: 44, height: 44)

                            Image(systemName: pauseIcon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(isPaused ? theme.success : theme.primary)
                        }
                    }
                    .buttonStyle(.plain)

                    // Close button
                    Button(action: onClose) {
                        ZStack {
                            Circle()
                                .fill(theme.surface)
                                .frame(width: 44, height: 44)

                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 56)
            .padding(.horizontal, theme.spacing.md)
            .background(headerBackground)

            // Underline (gradient)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.0),
                            theme.primary.opacity(0.30),
                            theme.primary.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var headerBackground: some View {
        ZStack {
            // Glassmorphic material
            Rectangle()
                .fill(.ultraThinMaterial)

            // Gradient overlay (matches ExerciseDetailView header)
            LinearGradient(
                colors: [
                    theme.surface.opacity(0.9),
                    theme.background.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Preview

#Preview("Active Workout - Playing") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            WorkoutTopBar(
                elapsedTime: 540,        // 9:00
                currentExercise: 3,
                totalExercises: 6,
                isPaused: false,
                onPauseToggle: {},
                onClose: {}
            )

            Spacer()
        }
    }
}

#Preview("Active Workout - Paused") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            WorkoutTopBar(
                elapsedTime: 1234,       // 20:34
                currentExercise: 5,
                totalExercises: 8,
                isPaused: true,
                onPauseToggle: {},
                onClose: {}
            )

            Spacer()
        }
    }
}

#Preview("Workout Start") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            WorkoutTopBar(
                elapsedTime: 0,
                currentExercise: 1,
                totalExercises: 6,
                isPaused: false,
                onPauseToggle: {},
                onClose: {}
            )

            Spacer()
        }
    }
}

#Preview("Long Workout") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            WorkoutTopBar(
                elapsedTime: 3600,       // 60:00 (1 hour)
                currentExercise: 12,
                totalExercises: 15,
                isPaused: false,
                onPauseToggle: {},
                onClose: {}
            )

            Spacer()
        }
    }
}

#Preview("Short Workout - Almost Done") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            WorkoutTopBar(
                elapsedTime: 180,        // 3:00
                currentExercise: 3,
                totalExercises: 3,
                isPaused: false,
                onPauseToggle: {},
                onClose: {}
            )

            Spacer()
        }
    }
}
