import SwiftUI

struct WorkoutDetailView: View {
    @Environment(\.theme) var theme
    let workout: Workout
    @EnvironmentObject var workoutManager: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showExerciseLibrary = false
    @State private var selectedExercise: Exercise?
    @State private var showConfigSheet = false
    @State private var exerciseToConfig: Exercise?
    @State private var selectedDetent: PresentationDetent = .large
    @State private var showEditNameSheet = false
    @State private var editedWorkoutName = ""
    @State private var showDeleteConfirmation = false
    @State private var showDeleteExerciseConfirmation = false
    @State private var exerciseToDelete: Exercise?
    @State private var showWorkoutExecution = false

    // Settings state (NEW)
    @State private var restDuration: TimeInterval = 45
    @State private var audioEnabled: Bool = true
    @State private var showSettings: Bool = false

    // Get latest workout from manager
    private var currentWorkout: Workout {
        workoutManager.getWorkout(by: workout.id) ?? workout
    }

    // Estimated calories
    private var estimatedCalories: Int {
        currentWorkout.estimatedTimeMinutes * 10
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with tap-to-edit
            headerView

            ScrollView {
                VStack(spacing: 16) {
                    // Equipment Section
                    if !currentWorkout.allEquipment.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("WHAT YOU'LL NEED (\(currentWorkout.allEquipment.count))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(theme.textSecondary.opacity(0.7))
                                .tracking(0.5)
                                .padding(.top, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(currentWorkout.allEquipment, id: \.self) { equipment in
                                        EquipmentBadge(equipment: equipment)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Categories Section
                    if !currentWorkout.allCategories.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CATEGORIES (\(currentWorkout.allCategories.count))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(theme.textSecondary.opacity(0.7))
                                .tracking(0.5)
                                .padding(.top, currentWorkout.allEquipment.isEmpty ? 16 : 8)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(currentWorkout.allCategories, id: \.self) { category in
                                        CategoryBadge(category: category)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Settings Section (NEW)
                    settingsSection

                    // Exercises Header
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("WHAT YOU'LL DO")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(theme.textSecondary.opacity(0.7))
                                .tracking(0.5)

                            Text("\(currentWorkout.exerciseCount) exercises")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(theme.text)
                        }

                        Spacer()

                        Button {
                            showExerciseLibrary = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Add")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(theme.text)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .stroke(theme.textSecondary.opacity(0.3), lineWidth: 1.5)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, !currentWorkout.allEquipment.isEmpty || !currentWorkout.allCategories.isEmpty ? 0 : 16)

                    if currentWorkout.exercises.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "dumbbell")
                                .font(.system(size: 48))
                                .foregroundColor(theme.textSecondary.opacity(0.3))

                            Text("No exercises yet")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.textSecondary)

                            Text("Tap + Add to build your workout")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(theme.textSecondary.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        // Exercise cards
                        VStack(spacing: 12) {
                            ForEach(currentWorkout.exercises) { exercise in
                                ExerciseCard(
                                    exercise: exercise,
                                    onTap: {
                                        selectedExercise = exercise
                                    },
                                    onEdit: {
                                        exerciseToConfig = exercise
                                        showConfigSheet = true
                                    },
                                    onDelete: {
                                        exerciseToDelete = exercise
                                        showDeleteExerciseConfirmation = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Bottom padding before button
                    Spacer(minLength: 100)
                }
            }
        }
        .overlay(alignment: .bottom) {
            // Fixed bottom button using glass style from trimmer footer
            if !currentWorkout.exercises.isEmpty {
                GlassFooterButton(
                    title: "Start Workout",
                    icon: "play.circle.fill",
                    isEnabled: true
                ) {
                    showWorkoutExecution = true
                }
            }
        }
        .fullScreenCover(isPresented: $showExerciseLibrary) {
            ExerciseLibraryView { exercise in
                workoutManager.addExercise(exercise, to: currentWorkout)
            }
            .environmentObject(workoutManager)
        }
        .fullScreenCover(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
        .fullScreenCover(isPresented: $showWorkoutExecution) {
            WorkoutExecutionView(workout: currentWorkout)
                .onAppear {
                    // Save settings before starting
                    UserDefaults.standard.set(restDuration, forKey: AppSettings.StorageKeys.defaultRestDuration)
                    UserDefaults.standard.set(audioEnabled, forKey: "workout.audioEnabled")
                }
        }
        .onAppear {
            // Load saved settings
            if let savedRest = UserDefaults.standard.object(forKey: AppSettings.StorageKeys.defaultRestDuration) as? Double {
                restDuration = savedRest
            }
            audioEnabled = UserDefaults.standard.bool(forKey: "workout.audioEnabled") ? true : UserDefaults.standard.object(forKey: "workout.audioEnabled") != nil ? false : true
        }
        .sheet(isPresented: $showConfigSheet) {
            if let exercise = exerciseToConfig {
                ExerciseConfigSheet(
                    exercise: exercise,
                    onSave: { updatedExercise in
                        workoutManager.updateExercise(updatedExercise, in: currentWorkout)
                    }
                )
                .presentationDetents([.large], selection: $selectedDetent)
                .presentationDragIndicator(.visible)
            }
        }
        .background(theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Rename Workout", isPresented: $showEditNameSheet) {
            TextField("Workout Name", text: $editedWorkoutName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                let trimmedName = editedWorkoutName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedName.isEmpty {
                    workoutManager.updateWorkoutName(String(trimmedName.prefix(30)), for: currentWorkout)
                }
            }
        }
        .alert("Delete Workout?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                workoutManager.deleteWorkout(currentWorkout)
                dismiss()
            }
        } message: {
            Text("This will permanently delete \"\(currentWorkout.name)\" and all its exercises.")
        }
        .alert("Delete Exercise?", isPresented: $showDeleteExerciseConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let exercise = exerciseToDelete,
                   let exerciseIndex = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }) {
                    workoutManager.removeExercise(at: IndexSet(integer: exerciseIndex), from: currentWorkout)
                }
            }
        } message: {
            if let exercise = exerciseToDelete {
                Text("Remove \"\(exercise.name)\" from this workout?")
            }
        }
        .trackScreen("workout_detail")
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(spacing: theme.spacing.md) {
                // Close button
                Button(action: { dismiss() }) {
                    ZStack {
                        Circle()
                            .fill(theme.surface)
                            .frame(width: 44, height: 44)

                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                }

                Spacer(minLength: 0)

                // Title
                Text(currentWorkout.name)
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.95)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.white.opacity(0.45), radius: 0)
                    .shadow(color: Color.white.opacity(0.30), radius: 4)
                    .shadow(color: theme.primary.opacity(0.40), radius: 10, y: 2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)

                // Menu button
                Menu {
                    Button(action: {
                        editedWorkoutName = currentWorkout.name
                        showEditNameSheet = true
                    }) {
                        Label("Rename Workout", systemImage: "pencil")
                    }

                    Button(role: .destructive, action: {
                        showDeleteConfirmation = true
                    }) {
                        Label("Delete Workout", systemImage: "trash")
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(theme.surface)
                            .frame(width: 44, height: 44)

                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                }
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


    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Expandable header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showSettings.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundColor(theme.primary)

                    Text("WORKOUT SETTINGS")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(theme.text)
                        .tracking(0.5)

                    Spacer()

                    Image(systemName: showSettings ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: AppSettings.Constants.Layout.cornerRadiusMedium)
                        .fill(theme.surface.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSettings.Constants.Layout.cornerRadiusMedium)
                                .stroke(theme.primary.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(RoundedRectangle(cornerRadius: AppSettings.Constants.Layout.cornerRadiusMedium))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Workout settings")

            if showSettings {
                VStack(spacing: 12) {
                    // Audio Toggle Card
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: audioEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.system(size: 20))
                                .foregroundColor(theme.primary)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Audio Cues")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(theme.text)

                                Text("Voice guidance during workout")
                                    .font(.system(size: 13))
                                    .foregroundColor(theme.textSecondary)
                            }
                        }

                        Spacer()

                        Toggle("", isOn: $audioEnabled)
                            .labelsHidden()
                            .tint(theme.primary)
                    }
                    .padding(16)
                    .background(theme.surface.opacity(0.5))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.primary.opacity(0.2), lineWidth: 1)
                    )

                    // Rest Duration Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "timer")
                                .font(.system(size: 20))
                                .foregroundColor(theme.primary)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Rest Duration")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(theme.text)

                                Text("Between exercises")
                                    .font(.system(size: 13))
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        RestDurationWheelPicker(
                            duration: $restDuration,
                            maxMinutes: 5,
                            secondStep: 15
                        )
                        .padding(.horizontal, 0)
                        .padding(.bottom, 10)
                    }
                    .background(theme.surface.opacity(0.5))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.primary.opacity(0.2), lineWidth: 1)
                    )
                    .onChange(of: restDuration) { _, newValue in
                        // Auto-save on change
                        UserDefaults.standard.set(newValue, forKey: AppSettings.StorageKeys.defaultRestDuration)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}
