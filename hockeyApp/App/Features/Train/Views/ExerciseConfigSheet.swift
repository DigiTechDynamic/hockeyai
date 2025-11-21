import SwiftUI

struct ExerciseConfigSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    let exercise: Exercise
    let onSave: (Exercise) -> Void

    @State private var editedExercise: Exercise

    init(exercise: Exercise, onSave: @escaping (Exercise) -> Void) {
        self.exercise = exercise
        self.onSave = onSave
        _editedExercise = State(initialValue: exercise)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Fixed Header
            VStack(spacing: 0) {
                // Horizontal Exercise Header
                HStack(spacing: 12) {
                    // Exercise name
                    Text(exercise.name.uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    // Type badge
                    Text(typeBadgeText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(typeColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(typeColor.opacity(0.15))
                        .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
                .padding(.bottom, 16)

                // Divider
                Rectangle()
                    .fill(theme.textSecondary.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 24)
            }

            // Configuration Section (scrollable, fills available space)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("CONFIGURATION")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(theme.textSecondary.opacity(0.7))
                        .tracking(0.5)
                        .padding(.horizontal, 24)

                    configurationContent
                        .padding(.horizontal, 24)

                    // Rest Time Configuration (if exercise has sets)
                    if editedExercise.hasSets {
                        Divider()
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)

                        Text("REST TIME")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(theme.textSecondary.opacity(0.7))
                            .tracking(0.5)
                            .padding(.horizontal, 24)

                        restTimeConfig
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
            }

            // Fixed bottom button
            VStack(spacing: 12) {
                // Save button
                Button(action: {
                    onSave(editedExercise)
                    dismiss()
                }) {
                    Text("Save Changes")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(theme.primary.opacity(0.12))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.primary.opacity(0.5), lineWidth: 2)
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 34)
            .background(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.95),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .background(theme.background.ignoresSafeArea())
    }

    // MARK: - Configuration Content
    @ViewBuilder
    private var configurationContent: some View {
        switch editedExercise.config {
        // MARK: Count-Based
        case .countBased(let count):
            countBasedConfig(count: count)

        // MARK: Time-Based
        case .timeBased(let duration):
            timeBasedConfig(duration: duration)

        // MARK: Reps Only
        case .repsOnly(let reps):
            repsOnlyConfig(reps: reps)

        // MARK: Reps + Sets
        case .repsSets(let reps, let sets):
            repsSetsConfig(reps: reps, sets: sets)

        // MARK: Distance
        case .distance(let distance, let unit):
            distanceConfig(distance: distance, unit: unit)

        // MARK: Weight + Reps + Sets
        case .weightRepsSets(let weight, let reps, let sets, let unit):
            weightRepsSetsConfig(weight: weight, reps: reps, sets: sets, unit: unit)

        // MARK: Time + Sets
        case .timeSets(let duration, let sets, let restTime):
            timeSetsConfig(duration: duration, sets: sets, restTime: restTime)
        }
    }

    // MARK: - Config Components

    // Count-Based Configuration
    func countBasedConfig(count: Int) -> some View {
        HStack(spacing: 16) {
            stepperButton(icon: "minus", enabled: count > 5) {
                editedExercise.config = .countBased(targetCount: count - 5)
            }

            Text("\(count)")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.primary, theme.accent],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(maxWidth: .infinity)

            stepperButton(icon: "plus", enabled: true) {
                editedExercise.config = .countBased(targetCount: count + 5)
            }
        }
    }

    // Time-Based Configuration
    func timeBasedConfig(duration: TimeInterval) -> some View {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        return HStack(spacing: 20) {
            // Minutes
            VStack(spacing: 8) {
                Text("MIN")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.textSecondary.opacity(0.7))

                HStack(spacing: 8) {
                    smallStepperButton(icon: "minus", enabled: minutes > 0) {
                        let newDuration = TimeInterval((minutes - 1) * 60 + seconds)
                        editedExercise.config = .timeBased(duration: max(0, newDuration))
                    }

                    Text("\(minutes)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.primary, theme.accent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 60)

                    smallStepperButton(icon: "plus", enabled: true) {
                        let newDuration = TimeInterval((minutes + 1) * 60 + seconds)
                        editedExercise.config = .timeBased(duration: newDuration)
                    }
                }
            }

            Text(":")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(theme.textSecondary)

            // Seconds
            VStack(spacing: 8) {
                Text("SEC")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.textSecondary.opacity(0.7))

                HStack(spacing: 8) {
                    smallStepperButton(icon: "minus", enabled: seconds >= 15) {
                        let newDuration = TimeInterval(minutes * 60 + seconds - 15)
                        editedExercise.config = .timeBased(duration: max(0, newDuration))
                    }

                    Text("\(seconds)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.primary, theme.accent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 60)

                    smallStepperButton(icon: "plus", enabled: true) {
                        var newSeconds = seconds + 15
                        var newMinutes = minutes
                        if newSeconds >= 60 {
                            newSeconds = 0
                            newMinutes += 1
                        }
                        let newDuration = TimeInterval(newMinutes * 60 + newSeconds)
                        editedExercise.config = .timeBased(duration: newDuration)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // Reps Only Configuration
    func repsOnlyConfig(reps: Int) -> some View {
        HStack(spacing: 16) {
            stepperButton(icon: "minus", enabled: reps > 1) {
                editedExercise.config = .repsOnly(reps: reps - 1)
            }

            Text("\(reps)")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.primary, theme.accent],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(maxWidth: .infinity)

            stepperButton(icon: "plus", enabled: true) {
                editedExercise.config = .repsOnly(reps: reps + 1)
            }
        }
    }

    // Reps + Sets Configuration
    func repsSetsConfig(reps: Int, sets: Int) -> some View {
        VStack(spacing: 20) {
            // Sets
            VStack(spacing: 8) {
                Text("SETS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.textSecondary.opacity(0.7))

                HStack(spacing: 16) {
                    smallStepperButton(icon: "minus", enabled: sets > 1) {
                        editedExercise.config = .repsSets(reps: reps, sets: sets - 1)
                    }

                    Text("\(sets)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.primary, theme.accent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(maxWidth: .infinity)

                    smallStepperButton(icon: "plus", enabled: true) {
                        editedExercise.config = .repsSets(reps: reps, sets: sets + 1)
                    }
                }
            }

            // Reps
            VStack(spacing: 8) {
                Text("REPS PER SET")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.textSecondary.opacity(0.7))

                HStack(spacing: 16) {
                    smallStepperButton(icon: "minus", enabled: reps > 1) {
                        editedExercise.config = .repsSets(reps: reps - 1, sets: sets)
                    }

                    Text("\(reps)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.primary, theme.accent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(maxWidth: .infinity)

                    smallStepperButton(icon: "plus", enabled: true) {
                        editedExercise.config = .repsSets(reps: reps + 1, sets: sets)
                    }
                }
            }
        }
    }

    // Distance Configuration
    func distanceConfig(distance: Double, unit: DistanceUnit) -> some View {
        let increment = unit == .laps ? 1.0 : 10.0

        return VStack(spacing: 16) {
            HStack(spacing: 16) {
                stepperButton(icon: "minus", enabled: distance > increment) {
                    editedExercise.config = .distance(distance: distance - increment, unit: unit)
                }

                Text("\(Int(distance))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.primary, theme.accent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(maxWidth: .infinity)

                stepperButton(icon: "plus", enabled: true) {
                    editedExercise.config = .distance(distance: distance + increment, unit: unit)
                }
            }

            // Unit Picker
            HStack(spacing: 8) {
                ForEach([DistanceUnit.meters, .yards, .feet, .laps], id: \.self) { distUnit in
                    Button(action: {
                        editedExercise.config = .distance(distance: distance, unit: distUnit)
                    }) {
                        Text(distUnit.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(unit == distUnit ? .white : theme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(unit == distUnit ? theme.primary.opacity(0.3) : theme.surface.opacity(0.3))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(unit == distUnit ? theme.primary : Color.clear, lineWidth: 1.5)
                            )
                    }
                }
            }
        }
    }

    // Weight + Reps + Sets Configuration
    func weightRepsSetsConfig(weight: Double, reps: Int, sets: Int, unit: WeightUnit) -> some View {
        VStack(spacing: 20) {
            // Weight + Unit Toggle
            VStack(spacing: 8) {
                HStack {
                    Text("WEIGHT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(theme.textSecondary.opacity(0.7))

                    Spacer()

                    // Unit Toggle
                    HStack(spacing: 4) {
                        ForEach([WeightUnit.lbs, .kg], id: \.self) { weightUnit in
                            Button(action: {
                                editedExercise.config = .weightRepsSets(weight: weight, reps: reps, sets: sets, unit: weightUnit)
                            }) {
                                Text(weightUnit.rawValue)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(unit == weightUnit ? .white : theme.textSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(unit == weightUnit ? theme.primary.opacity(0.3) : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(unit == weightUnit ? theme.primary : theme.textSecondary.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }

                HStack(spacing: 16) {
                    smallStepperButton(icon: "minus", enabled: weight > 5) {
                        editedExercise.config = .weightRepsSets(weight: weight - 5, reps: reps, sets: sets, unit: unit)
                    }

                    Text("\(Int(weight))")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.primary, theme.accent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(maxWidth: .infinity)

                    smallStepperButton(icon: "plus", enabled: true) {
                        editedExercise.config = .weightRepsSets(weight: weight + 5, reps: reps, sets: sets, unit: unit)
                    }
                }
            }

            // Sets
            VStack(spacing: 8) {
                Text("SETS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.textSecondary.opacity(0.7))

                HStack(spacing: 16) {
                    smallStepperButton(icon: "minus", enabled: sets > 1) {
                        editedExercise.config = .weightRepsSets(weight: weight, reps: reps, sets: sets - 1, unit: unit)
                    }

                    Text("\(sets)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.primary, theme.accent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(maxWidth: .infinity)

                    smallStepperButton(icon: "plus", enabled: true) {
                        editedExercise.config = .weightRepsSets(weight: weight, reps: reps, sets: sets + 1, unit: unit)
                    }
                }
            }

            // Reps
            VStack(spacing: 8) {
                Text("REPS PER SET")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.textSecondary.opacity(0.7))

                HStack(spacing: 16) {
                    smallStepperButton(icon: "minus", enabled: reps > 1) {
                        editedExercise.config = .weightRepsSets(weight: weight, reps: reps - 1, sets: sets, unit: unit)
                    }

                    Text("\(reps)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.primary, theme.accent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(maxWidth: .infinity)

                    smallStepperButton(icon: "plus", enabled: true) {
                        editedExercise.config = .weightRepsSets(weight: weight, reps: reps + 1, sets: sets, unit: unit)
                    }
                }
            }
        }
    }

    // Time + Sets Configuration
    func timeSetsConfig(duration: TimeInterval, sets: Int, restTime: TimeInterval?) -> some View {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let restMinutes = Int(restTime ?? 0) / 60
        let restSeconds = Int(restTime ?? 0) % 60

        return VStack(spacing: 20) {
            // Duration per Set
            VStack(spacing: 8) {
                Text("DURATION PER SET")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.textSecondary.opacity(0.7))

                HStack(spacing: 12) {
                    // Minutes
                    VStack(spacing: 4) {
                        Text("MIN")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(theme.textSecondary.opacity(0.6))

                        HStack(spacing: 6) {
                            tinyStepperButton(icon: "minus", enabled: minutes > 0) {
                                let newDuration = TimeInterval((minutes - 1) * 60 + seconds)
                                editedExercise.config = .timeSets(duration: max(0, newDuration), sets: sets, restTime: restTime)
                            }

                            Text("\(minutes)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [theme.primary, theme.accent],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 40)

                            tinyStepperButton(icon: "plus", enabled: true) {
                                let newDuration = TimeInterval((minutes + 1) * 60 + seconds)
                                editedExercise.config = .timeSets(duration: newDuration, sets: sets, restTime: restTime)
                            }
                        }
                    }

                    Text(":")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(theme.textSecondary)

                    // Seconds
                    VStack(spacing: 4) {
                        Text("SEC")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(theme.textSecondary.opacity(0.6))

                        HStack(spacing: 6) {
                            tinyStepperButton(icon: "minus", enabled: seconds >= 15) {
                                let newDuration = TimeInterval(minutes * 60 + seconds - 15)
                                editedExercise.config = .timeSets(duration: max(0, newDuration), sets: sets, restTime: restTime)
                            }

                            Text("\(seconds)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [theme.primary, theme.accent],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 40)

                            tinyStepperButton(icon: "plus", enabled: true) {
                                var newSeconds = seconds + 15
                                var newMinutes = minutes
                                if newSeconds >= 60 {
                                    newSeconds = 0
                                    newMinutes += 1
                                }
                                let newDuration = TimeInterval(newMinutes * 60 + newSeconds)
                                editedExercise.config = .timeSets(duration: newDuration, sets: sets, restTime: restTime)
                            }
                        }
                    }
                }
            }

            // Sets
            VStack(spacing: 8) {
                Text("SETS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.textSecondary.opacity(0.7))

                HStack(spacing: 16) {
                    smallStepperButton(icon: "minus", enabled: sets > 1) {
                        editedExercise.config = .timeSets(duration: duration, sets: sets - 1, restTime: restTime)
                    }

                    Text("\(sets)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.primary, theme.accent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(maxWidth: .infinity)

                    smallStepperButton(icon: "plus", enabled: true) {
                        editedExercise.config = .timeSets(duration: duration, sets: sets + 1, restTime: restTime)
                    }
                }
            }

            // Rest Time (Optional)
            VStack(spacing: 8) {
                Text("REST BETWEEN SETS (OPTIONAL)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.textSecondary.opacity(0.7))

                HStack(spacing: 12) {
                    // Minutes
                    VStack(spacing: 4) {
                        Text("MIN")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(theme.textSecondary.opacity(0.6))

                        HStack(spacing: 6) {
                            tinyStepperButton(icon: "minus", enabled: restMinutes > 0) {
                                let newRest = TimeInterval((restMinutes - 1) * 60 + restSeconds)
                                editedExercise.config = .timeSets(duration: duration, sets: sets, restTime: newRest > 0 ? newRest : nil)
                            }

                            Text("\(restMinutes)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [theme.primary, theme.accent],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 40)

                            tinyStepperButton(icon: "plus", enabled: true) {
                                let newRest = TimeInterval((restMinutes + 1) * 60 + restSeconds)
                                editedExercise.config = .timeSets(duration: duration, sets: sets, restTime: newRest)
                            }
                        }
                    }

                    Text(":")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(theme.textSecondary)

                    // Seconds
                    VStack(spacing: 4) {
                        Text("SEC")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(theme.textSecondary.opacity(0.6))

                        HStack(spacing: 6) {
                            tinyStepperButton(icon: "minus", enabled: restSeconds >= 15) {
                                let newRest = TimeInterval(restMinutes * 60 + restSeconds - 15)
                                editedExercise.config = .timeSets(duration: duration, sets: sets, restTime: newRest > 0 ? newRest : nil)
                            }

                            Text("\(restSeconds)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [theme.primary, theme.accent],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 40)

                            tinyStepperButton(icon: "plus", enabled: true) {
                                var newRestSeconds = restSeconds + 15
                                var newRestMinutes = restMinutes
                                if newRestSeconds >= 60 {
                                    newRestSeconds = 0
                                    newRestMinutes += 1
                                }
                                let newRest = TimeInterval(newRestMinutes * 60 + newRestSeconds)
                                editedExercise.config = .timeSets(duration: duration, sets: sets, restTime: newRest)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Button Helpers

    func stepperButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(enabled ? theme.primary : theme.textSecondary.opacity(0.3))
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.surface.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.primary.opacity(enabled ? 0.3 : 0.1), lineWidth: 1)
                )
        }
        .disabled(!enabled)
    }

    func smallStepperButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(enabled ? theme.primary : theme.textSecondary.opacity(0.3))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(theme.surface.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(theme.primary.opacity(enabled ? 0.3 : 0.1), lineWidth: 1)
                )
        }
        .disabled(!enabled)
    }

    func tinyStepperButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(enabled ? theme.primary : theme.textSecondary.opacity(0.3))
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.surface.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.primary.opacity(enabled ? 0.3 : 0.1), lineWidth: 1)
                )
        }
        .disabled(!enabled)
    }

    // MARK: - Rest Time Configuration

    @ViewBuilder
    private var restTimeConfig: some View {
        VStack(spacing: 16) {
            // Rest between sets
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Between Sets")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.text)

                    Spacer()

                    if editedExercise.restBetweenSets == nil {
                        Text("Default: \(formatRestTime(editedExercise.category.defaultRestBetweenSets))")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(theme.textSecondary.opacity(0.7))
                    }
                }

                // Rest time options
                HStack(spacing: 8) {
                    ForEach([0, 30, 45, 60, 90, 120], id: \.self) { seconds in
                        Button(action: {
                            editedExercise.restBetweenSets = TimeInterval(seconds)
                        }) {
                            Text(formatRestTimeShort(TimeInterval(seconds)))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(
                                    (editedExercise.restBetweenSets ?? editedExercise.category.defaultRestBetweenSets) == TimeInterval(seconds)
                                    ? .white
                                    : theme.textSecondary
                                )
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            (editedExercise.restBetweenSets ?? editedExercise.category.defaultRestBetweenSets) == TimeInterval(seconds)
                                            ? theme.primary.opacity(0.3)
                                            : theme.surface.opacity(0.3)
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            (editedExercise.restBetweenSets ?? editedExercise.category.defaultRestBetweenSets) == TimeInterval(seconds)
                                            ? theme.primary
                                            : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                        }
                    }
                }
            }

            // Rest after exercise (optional, in disclosure group)
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("After Exercise")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.text)

                        Spacer()

                        if editedExercise.restAfterExercise == nil {
                            Text("Default: \(formatRestTime(editedExercise.category.defaultRestAfterExercise))")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(theme.textSecondary.opacity(0.7))
                        }
                    }

                    HStack(spacing: 8) {
                        ForEach([30, 45, 60, 90, 120], id: \.self) { seconds in
                            Button(action: {
                                editedExercise.restAfterExercise = TimeInterval(seconds)
                            }) {
                                Text(formatRestTimeShort(TimeInterval(seconds)))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(
                                        (editedExercise.restAfterExercise ?? editedExercise.category.defaultRestAfterExercise) == TimeInterval(seconds)
                                        ? .white
                                        : theme.textSecondary
                                    )
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                (editedExercise.restAfterExercise ?? editedExercise.category.defaultRestAfterExercise) == TimeInterval(seconds)
                                                ? theme.primary.opacity(0.3)
                                                : theme.surface.opacity(0.3)
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                (editedExercise.restAfterExercise ?? editedExercise.category.defaultRestAfterExercise) == TimeInterval(seconds)
                                                ? theme.primary
                                                : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                            }
                        }
                    }
                }
            } label: {
                Text("Advanced Settings")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }
        }
    }

    private func formatRestTime(_ seconds: TimeInterval) -> String {
        if seconds == 0 {
            return "None"
        }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if mins > 0 && secs > 0 {
            return "\(mins)m \(secs)s"
        } else if mins > 0 {
            return "\(mins)m"
        } else {
            return "\(secs)s"
        }
    }

    private func formatRestTimeShort(_ seconds: TimeInterval) -> String {
        if seconds == 0 {
            return "OFF"
        }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if mins > 0 && secs > 0 {
            return "\(mins)m\(secs)s"
        } else if mins > 0 {
            return "\(mins)m"
        } else {
            return "\(secs)s"
        }
    }

    // MARK: - Helpers

    private var exerciseIcon: String {
        switch exercise.config.type {
        case .weightRepsSets: return "dumbbell.fill"
        case .timeBased: return "timer"
        case .repsOnly, .repsSets: return "figure.strengthtraining.traditional"
        case .countBased: return "hockey.puck"
        case .distance: return "figure.run"
        case .timeSets: return "clock.fill"
        }
    }

    private var typeBadgeText: String {
        switch exercise.config.type {
        case .timeBased: return "Time Based"
        case .repsOnly: return "Reps Only"
        case .countBased: return "Countbased"
        case .weightRepsSets: return "Weight • Reps • Sets"
        case .distance: return "Distance"
        case .repsSets: return "Reps • Sets"
        case .timeSets: return "Time • Sets"
        }
    }

    private var typeColor: Color {
        switch exercise.config.type {
        case .timeBased: return .blue
        case .repsOnly: return .green
        case .countBased: return .orange
        case .weightRepsSets: return .purple
        case .distance: return .red
        case .repsSets: return .teal
        case .timeSets: return .indigo
        }
    }
}

#Preview {
    ExerciseConfigSheet(
        exercise: SampleExercises.all[0],
        onSave: { _ in }
    )
}
