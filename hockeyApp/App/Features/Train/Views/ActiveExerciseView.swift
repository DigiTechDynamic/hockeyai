import SwiftUI

struct ActiveExerciseView: View {
    @Environment(\.theme) var theme

    let exercise: Exercise
    let exerciseIndex: Int
    let totalExercises: Int
    let timeRemaining: TimeInterval
    let elapsedTime: TimeInterval
    let isPaused: Bool
    let onPauseToggle: () -> Void
    let onClose: () -> Void

    // ViewModel for manual completion exercises
    @ObservedObject var viewModel: WorkoutExecutionViewModel

    // MARK: - Computed Properties

    /// Calculate total duration from exercise config (matches ViewModel logic)
    private var totalDuration: TimeInterval {
        switch exercise.config {
        case .timeBased(let duration):
            return duration
        case .timeSets(let duration, _, _):
            return duration
        default:
            return 30  // Fallback for non-timed exercises
        }
    }

    /// Check if exercise requires manual completion
    private var requiresManualCompletion: Bool {
        // Don't show button during rest between sets
        if viewModel.isRestingBetweenSets {
            return false
        }

        switch exercise.config {
        case .timeBased, .timeSets:
            return false  // Auto-completes
        case .repsSets, .weightRepsSets:
            return true  // Needs "Mark Set Done" button
        default:
            return true  // Needs "Mark Done" button
        }
    }

    /// Button text based on exercise type
    private var completionButtonText: String {
        switch exercise.config {
        case .repsSets, .weightRepsSets:
            let totalSets: Int
            switch exercise.config {
            case .repsSets(_, let sets), .weightRepsSets(_, _, let sets, _):
                totalSets = sets
            default:
                totalSets = 1
            }
            return viewModel.currentSet >= totalSets ? "Mark Done" : "Mark Set \(viewModel.currentSet) Done"
        default:
            return "Mark Done"
        }
    }

    /// Dynamic content based on exercise config type
    @ViewBuilder
    private var exerciseContentView: some View {
        switch exercise.config {
        case .timeBased:
            // Countdown now overlays image; no separate card below
            EmptyView()

        case .countBased, .repsOnly:
            // Stopwatch now overlays image; no separate card below
            EmptyView()

        case .repsSets(let reps, let sets):
            // Reps × Sets with stopwatch (rest handled separately)
            setBasedContent(
                totalSets: sets,
                mainDisplay: {
                    VStack(spacing: 16) {
                        // Show reps target
                        Text("\(reps) reps")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                    }
                }
            )

        case .weightRepsSets(let weight, let reps, let sets, let unit):
            // Weight + Reps × Sets with stopwatch (rest handled separately)
            setBasedContent(
                totalSets: sets,
                mainDisplay: {
                    VStack(spacing: 16) {
                        // Weight display
                        Text("\(Int(weight)) \(unit.rawValue)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(theme.primary)
                            .padding(.bottom, 8)

                        // Show reps target
                        Text("\(reps) reps")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                    }
                }
            )

        case .timeSets(let duration, let sets, _):
            // Timed sets with auto-completion (rest handled separately)
            setBasedContent(
                totalSets: sets,
                mainDisplay: {
                    // Countdown now overlays image; nothing additional here
                    EmptyView()
                }
            )

        default:
            // Stopwatch now overlays image; no separate card below
            EmptyView()
        }
    }

    /// Set-based layout with header, progress indicator, and main content
    @ViewBuilder
    private func setBasedContent<Content: View>(
        totalSets: Int,
        @ViewBuilder mainDisplay: () -> Content
    ) -> some View {
        VStack(spacing: 24) {
            // Set header
            VStack(spacing: 12) {
                Text("SET \(viewModel.currentSet) of \(totalSets)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.primary)
                    .tracking(1.5)

                // Set progress indicator
                SetProgressIndicator(
                    currentSet: viewModel.currentSet,
                    totalSets: totalSets,
                    isResting: false
                )
            }

            // Main timer/stopwatch display
            mainDisplay()
        }
    }

    /// Rest between sets view (matches RestTransitionView exactly)
    @ViewBuilder
    private var restBetweenSetsView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 10) {
                    Text("REST")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(theme.textSecondary.opacity(0.7))
                        .tracking(2)

                    Text(exercise.name)
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
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // Separate cards for video vs image
                if exercise.videoFileName != nil {
                    ExerciseVideoCard(
                        exercise: exercise,
                        overlayText: formattedRestTime,
                        height: 360
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                } else {
                    ExerciseImageCard(
                        exercise: exercise,
                        overlayText: formattedRestTime,
                        height: 360
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                // Rest Control Buttons
                HStack(spacing: 12) {
                    // -15 sec button
                    Button {
                        let newDuration = max(15, viewModel.setRestDuration - 15)
                        viewModel.setRestDuration = newDuration
                        HapticManager.shared.playImpact(style: .light)
                    } label: {
                        controlButton(title: "-15 sec")
                    }

                    // Skip Rest button (center)
                    Button {
                        viewModel.completeSetRest()
                        HapticManager.shared.playImpact(style: .medium)
                    } label: {
                        outlinedPrimaryButton(title: "Skip Rest", icon: "arrow.right")
                    }

                    // +15 sec button
                    Button {
                        let newDuration = viewModel.setRestDuration + 15
                        viewModel.setRestDuration = newDuration
                        HapticManager.shared.playImpact(style: .light)
                    } label: {
                        controlButton(title: "+15 sec")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Set Progress Indicator
                VStack(spacing: 12) {
                    // Get total sets
                    let totalSets: Int = {
                        switch exercise.config {
                        case .repsSets(_, let sets), .weightRepsSets(_, _, let sets, _), .timeSets(_, let sets, _):
                            return sets
                        default:
                            return 1
                        }
                    }()

                    SetProgressIndicator(
                        currentSet: viewModel.currentSet,
                        totalSets: totalSets,
                        isResting: true
                    )
                }
                .padding(.top, 32)
                .padding(.bottom, 40)
            }
            .padding(.top, 1)
        }
    }

    /// Formatted rest time as MM:SS
    private var formattedRestTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Whether current exercise uses a stopwatch (not a countdown)
    private var isStopwatchMode: Bool {
        switch exercise.config {
        case .timeBased, .timeSets:
            return false
        default:
            return true
        }
    }

    /// Whether current exercise is countdown-based (time remaining)
    private var isCountdownMode: Bool {
        switch exercise.config {
        case .timeBased, .timeSets:
            return true
        default:
            return false
        }
    }

    /// Formatted elapsed time as MM:SS for stopwatch overlay
    private var formattedElapsedTime: String {
        let minutes = Int(viewModel.currentExerciseElapsedTime) / 60
        let seconds = Int(viewModel.currentExerciseElapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Formatted remaining time as MM:SS for countdown overlay
    private var formattedRemainingTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Unifies overlay time text for stopwatch or countdown modes
    private var overlayTimeText: String {
        isStopwatchMode ? formattedElapsedTime : formattedRemainingTime
    }

    // MARK: - Rest Control Buttons

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
    private func outlinedPrimaryButton(title: String, icon: String? = nil) -> some View {
        HStack(spacing: 12) {
            Text(title)
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

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            WorkoutTopBar(
                elapsedTime: elapsedTime,
                currentExercise: exerciseIndex + 1,
                totalExercises: totalExercises,
                isPaused: isPaused,
                onPauseToggle: onPauseToggle,
                onClose: onClose
            )

            // If resting between sets, show rest overlay
            if viewModel.isRestingBetweenSets {
                restBetweenSetsView
            } else {
                // Normal exercise view
                ScrollView {
                    VStack(spacing: 0) {
                        // Separate cards for video vs image
                        if exercise.videoFileName != nil {
                            ExerciseVideoCard(
                                exercise: exercise,
                                overlayText: (isStopwatchMode || isCountdownMode) ? overlayTimeText : nil,
                                height: 360
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        } else {
                            ExerciseImageCard(
                                exercise: exercise,
                                overlayText: (isStopwatchMode || isCountdownMode) ? overlayTimeText : nil,
                                height: 360
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        }

                        // Title + Config below (matching RestTransitionView typography)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(exercise.name)
                                .font(.system(size: 32, weight: .black))
                                .glowingHeaderText()
                                .multilineTextAlignment(.leading)

                            Text(exercise.config.displaySummary)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                        // Dynamic content based on exercise config type
                        exerciseContentView
                            .padding(.top, 32)

                        // Instructions Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("HOW TO PERFORM")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(theme.textSecondary.opacity(0.7))
                                .tracking(0.5)

                            Text(exercise.instructions ?? exercise.description)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(theme.text)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        .padding(.bottom, requiresManualCompletion ? 180 : 40)
                    }
                    .padding(.top, 1)
                }
            }

            // Mark Done / Mark Set Done button (only for manual completion exercises)
            if requiresManualCompletion {
                Button(action: {
                    // Use appropriate completion method
                    switch exercise.config {
                    case .repsSets, .weightRepsSets:
                        viewModel.completeCurrentSet()
                    default:
                        viewModel.completeCurrentExercise()
                    }
                    HapticManager.shared.playNotification(type: .success)
                }) {
                    // Match Skip Rest pill style
                    outlinedPrimaryButton(title: completionButtonText, icon: "arrow.right")
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }

            // Progress footer removed per design simplification
        }
        .background(theme.background)
        .trackScreen("workout_active_exercise")
    }
}

