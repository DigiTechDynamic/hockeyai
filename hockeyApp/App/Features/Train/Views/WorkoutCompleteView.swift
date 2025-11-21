import SwiftUI
import AVFoundation

/// Celebration screen shown when a workout is completed
/// Shows summary stats, completed exercises, and provides "Done" action
struct WorkoutCompleteView: View {
    @Environment(\.theme) var theme
    let workout: Workout
    let totalDuration: TimeInterval
    let onDismiss: () -> Void

    // MARK: - Computed Properties

    private var formattedDuration: String {
        let minutes = Int(totalDuration) / 60
        let seconds = Int(totalDuration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    private var exerciseCountText: String {
        let total = workout.exercises.count
        return "\(total)/\(total)"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                ScrollView {
                    VStack(spacing: 24) {
                        // Celebration header
                        celebrationHeader

                        // Summary stats card
                        statsCard

                        // Exercise list
                        exerciseList

                        // Bottom padding
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, theme.spacing.md)
                }
            }
            .overlay(alignment: .bottom) {
                // Fixed bottom "Done" button
                doneButton
            }
        }
        .onAppear {
            // Audio cue on mount - removed for now
            // TODO: Add optional text-to-speech celebration
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(spacing: theme.spacing.md) {
                Spacer()

                // Title
                Text("Complete")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.95)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()
            }
            .frame(height: 56)
            .padding(.horizontal, theme.spacing.md)
            .background(headerBackground)

            // Underline
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.0),
                            theme.primary.opacity(0.30),
                            theme.primary.opacity(0.0)
                        ],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var headerBackground: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            LinearGradient(
                colors: [theme.surface.opacity(0.9), theme.background.opacity(0.7)],
                startPoint: .top, endPoint: .bottom
            )
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Celebration Header

    private var celebrationHeader: some View {
        VStack(spacing: 8) {
            // Encourage without repeating title
            Text("Excellent work!")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        // Use the app’s premium card style with neon border + subtle glow
        BaseCard(style: .premium) {
            VStack(spacing: 20) {
                // Total time
                statRow(
                    icon: "clock.fill",
                    label: "Total Time",
                    value: formattedDuration
                )

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.primary.opacity(0.0),
                                theme.primary.opacity(0.25),
                                theme.primary.opacity(0.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                // Exercises completed
                statRow(
                    icon: "checkmark.circle.fill",
                    label: "Exercises Completed",
                    value: exerciseCountText
                )

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.primary.opacity(0.0),
                                theme.primary.opacity(0.25),
                                theme.primary.opacity(0.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                // Streak (hardcoded for now, placeholder for future)
                statRow(
                    icon: "flame.fill",
                    label: "Streak",
                    value: "2-day streak!"
                )
            }
            .padding(20)
        }
        // Outer neon glow to match app cards
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(theme.primary.opacity(0.35), lineWidth: 1)
                .blur(radius: 10)
                .opacity(0.6)
        )
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.primary.opacity(0.18),
                                theme.primary.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(theme.primary.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: theme.primary.opacity(0.25), radius: 6, x: 0, y: 2)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.primary, theme.primary.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Label and value
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textSecondary)

                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.text)
            }

            Spacer()
        }
    }

    // MARK: - Exercise List

    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("EXERCISES COMPLETED")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme.textSecondary.opacity(0.7))
                .tracking(0.5)

            // Exercise items
            VStack(spacing: 12) {
                ForEach(workout.exercises) { exercise in
                    completedExerciseRow(exercise)
                }
            }
        }
    }

    private func completedExerciseRow(_ exercise: Exercise) -> some View {
        HStack(spacing: 12) {
            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.success, theme.success.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: theme.success.opacity(0.3), radius: 4)

            // Exercise name and config
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.text)
                    .lineLimit(1)

                Text(exercise.config.displaySummary)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.success.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Done Button

    private var doneButton: some View {
        GlassFooterButton(
            title: "Done",
            icon: "checkmark",
            isEnabled: true
        ) {
            onDismiss()
        }
        .trackScreen("workout_complete")
    }
}

// MARK: - Preview

#Preview {
    let sampleWorkout = Workout(
        name: "Elite Shooting",
        exercises: [
            Exercise(
                name: "Quick Release Snap Shots",
                description: "Practice rapid-fire shooting",
                category: .shooting,
                config: .repsOnly(reps: 50),
                equipment: [.stick, .pucks, .net]
            ),
            Exercise(
                name: "One-Timer Spot Shooting",
                description: "Focus on one-timer technique",
                category: .shooting,
                config: .repsOnly(reps: 40),
                equipment: [.stick, .pucks, .net]
            ),
            Exercise(
                name: "Backhand Shelf Shots",
                description: "Elevate backhand shots",
                category: .shooting,
                config: .repsOnly(reps: 30),
                equipment: [.stick, .pucks, .net]
            )
        ],
        estimatedTimeMinutes: 30
    )

    return WorkoutCompleteView(
        workout: sampleWorkout,
        totalDuration: 1845, // 30 minutes 45 seconds
        onDismiss: {}
    )
}
