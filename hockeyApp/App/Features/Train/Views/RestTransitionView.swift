import SwiftUI

struct RestTransitionView: View {
    @Environment(\.theme) var theme

    let timeRemaining: TimeInterval
    let nextExercise: Exercise?
    let restDuration: TimeInterval
    let onSkip: () -> Void
    let onAdjust: (TimeInterval) -> Void
    let elapsedTime: TimeInterval
    let currentExercise: Int
    let totalExercises: Int
    let isPaused: Bool
    let onPauseToggle: () -> Void
    let onClose: () -> Void

    // MARK: - Computed Properties

    /// Format time remaining as MM:SS
    private var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Get exercise config summary for display
    private var configSummary: String {
        guard let exercise = nextExercise else { return "" }
        return exercise.config.displaySummary
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            WorkoutTopBar(
                elapsedTime: elapsedTime,
                currentExercise: currentExercise + 1,
                totalExercises: totalExercises,
                isPaused: isPaused,
                onPauseToggle: onPauseToggle,
                onClose: onClose
            )

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 10) {
                        Text("UP NEXT:")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(theme.textSecondary.opacity(0.7))
                            .tracking(2)

                        Text(nextExercise?.name ?? "Complete!")
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.95)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.white.opacity(0.5), radius: 0)
                            .shadow(color: Color.white.opacity(0.3), radius: 4)
                            .shadow(color: theme.primary.opacity(0.4), radius: 10)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Separate cards for video vs image
                    if let nextExercise = nextExercise {
                        if nextExercise.videoFileName != nil {
                            ExerciseVideoCard(
                                exercise: nextExercise,
                                overlayText: formattedTime,
                                height: 400
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        } else {
                            ExerciseImageCard(
                                exercise: nextExercise,
                                overlayText: formattedTime,
                                height: 400
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        }

                        // Rest Control Buttons
                        HStack(spacing: 12) {
                            // -15 sec button
                            Button {
                                let newDuration = max(15, restDuration - 15)
                                onAdjust(newDuration)
                                HapticManager.shared.playImpact(style: .light)
                                UserDefaults.standard.set(newDuration, forKey: AppSettings.StorageKeys.defaultRestDuration)
                            } label: {
                                controlButton(title: "-15 sec")
                            }

                            // Skip Rest button (center)
                            outlinedPrimaryButton(title: "Start This Workout", replaceTitle: "Skip Rest", icon: "arrow.right") {
                                onSkip()
                                HapticManager.shared.playImpact(style: .medium)
                            }

                            // +15 sec button
                            Button {
                                let newDuration = restDuration + 15
                                onAdjust(newDuration)
                                HapticManager.shared.playImpact(style: .light)
                                UserDefaults.standard.set(newDuration, forKey: AppSettings.StorageKeys.defaultRestDuration)
                            } label: {
                                controlButton(title: "+15 sec")
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Instructions Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("HOW TO PERFORM")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(theme.textSecondary.opacity(0.7))
                                .tracking(0.5)

                            Text(nextExercise.instructions ?? nextExercise.description)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(theme.text)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 32)

                        // Config Summary
                        HStack(spacing: 16) {
                            Label(configSummary, systemImage: "figure.strengthtraining.traditional")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(theme.textSecondary)

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
                .padding(.top, 1)
            }
        }
        .background(theme.background)
    }

    // MARK: - Components
    @ViewBuilder
    private func controlButton(title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.24), lineWidth: 1.2)
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 8)
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 1)
    }

    @ViewBuilder
    private func outlinedPrimaryButton(title: String, replaceTitle: String, icon: String? = nil, action: @escaping () -> Void) -> some View {
        // Matches TrainView "Start This Workout" CTA styling
        Button(action: action) {
            HStack(spacing: 12) {
                Text(replaceTitle)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(theme.primary)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.primary.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(theme.primary, lineWidth: 1.2)
            )
            .shadow(color: theme.primary.opacity(0.25), radius: 6, x: 0, y: 4)
        }
        .trackScreen("workout_rest")
    }
}

#Preview {
    RestTransitionView(
        timeRemaining: 20,
        nextExercise: SampleExercises.all[1],
        restDuration: 30,
        onSkip: {},
        onAdjust: { _ in },
        elapsedTime: 240,
        currentExercise: 1,
        totalExercises: 6,
        isPaused: false,
        onPauseToggle: {},
        onClose: {}
    )
}
