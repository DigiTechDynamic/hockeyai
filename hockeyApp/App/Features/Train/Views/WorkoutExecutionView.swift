import SwiftUI

/// Main container for workout execution flow
/// Manages state transitions between all workout screens
struct WorkoutExecutionView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    let workout: Workout

    @StateObject private var viewModel: WorkoutExecutionViewModel

    @State private var showAbandonConfirmation = false
    @State private var showPauseAlert = false

    init(workout: Workout) {
        self.workout = workout
        self._viewModel = StateObject(wrappedValue: WorkoutExecutionViewModel(workout: workout))
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            // State-based view rendering
            Group {
                switch viewModel.state {
                case .getReady:
                    if let exercise = viewModel.currentExercise {
                        GetReadyView(
                            exercise: exercise,
                            timeRemaining: viewModel.timeRemaining,
                            totalDuration: 10, // Get ready is always 10 seconds
                            elapsedTime: viewModel.workoutElapsedTime,
                            currentExercise: viewModel.currentExerciseIndex + 1,
                            totalExercises: workout.exercises.count,
                            isPaused: viewModel.isPaused,
                            onPauseToggle: {
                                if viewModel.isPaused {
                                    viewModel.resume()
                                } else {
                                    viewModel.pause()
                                }
                            },
                            onClose: {
                                showAbandonConfirmation = true
                            }
                        )
                    }

                case .exerciseActive:
                    if let exercise = viewModel.currentExercise {
                        ActiveExerciseView(
                            exercise: exercise,
                            exerciseIndex: viewModel.currentExerciseIndex,
                            totalExercises: workout.exercises.count,
                            timeRemaining: viewModel.timeRemaining,
                            elapsedTime: viewModel.workoutElapsedTime,
                            isPaused: viewModel.isPaused,
                            onPauseToggle: {
                                if viewModel.isPaused {
                                    viewModel.resume()
                                } else {
                                    viewModel.pause()
                                }
                            },
                            onClose: {
                                showAbandonConfirmation = true
                            },
                            viewModel: viewModel
                        )
                    }

                case .restBetweenExercises:
                    RestTransitionView(
                        timeRemaining: viewModel.timeRemaining,
                        nextExercise: viewModel.nextExercise,
                        restDuration: viewModel.restDuration,
                        onSkip: {
                            viewModel.skipRest()
                        },
                        onAdjust: { newDuration in
                            // RestTransitionView handles the adjustment internally
                            // We just need to update the viewModel's rest duration
                            viewModel.restDuration = newDuration
                        },
                        elapsedTime: viewModel.workoutElapsedTime,
                        currentExercise: viewModel.currentExerciseIndex,
                        totalExercises: workout.exercises.count,
                        isPaused: viewModel.isPaused,
                        onPauseToggle: {
                            if viewModel.isPaused {
                                viewModel.resume()
                            } else {
                                viewModel.pause()
                            }
                        },
                        onClose: {
                            showAbandonConfirmation = true
                        }
                    )

                case .completed:
                    WorkoutCompleteView(
                        workout: workout,
                        totalDuration: viewModel.workoutElapsedTime,
                        onDismiss: {
                            dismiss()
                        }
                    )
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: viewModel.state)
        }
        .onChange(of: viewModel.isPaused) { _, isPaused in
            // Show pause alert when workout becomes paused (manual or auto-pause)
            if isPaused && (viewModel.state == .exerciseActive || viewModel.state == .restBetweenExercises || viewModel.state == .getReady) {
                showPauseAlert = true
            }
        }
        .alert("Workout Paused", isPresented: $showPauseAlert) {
            Button("Resume", role: .cancel) {
                viewModel.resume()
            }
        } message: {
            if viewModel.backgroundDuration > 0 {
                Text(viewModel.welcomeBackMessage)
            } else {
                Text("Tap Resume to continue your workout")
            }
        }
        .alert("Abandon Workout?", isPresented: $showAbandonConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Abandon", role: .destructive) {
                viewModel.abandonWorkout()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to abandon this workout? Your progress will not be saved.")
        }
        .onAppear {
            // Auto-start workout when view appears (goes straight to GetReady)
            viewModel.startWorkout()
        }
        .trackScreen("workout_execution")
    }
}

#Preview {
    WorkoutExecutionView(workout: SampleWorkouts.all[0])
}
