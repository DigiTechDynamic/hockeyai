import SwiftUI

struct TrainView: View {
    @Environment(\.theme) var theme
    @Environment(\.entranceAnimationTrigger) var entranceAnimationTrigger
    @StateObject private var workoutManager = WorkoutViewModel()
    @State private var selectedWorkout: Workout?
    @State private var weekScrollerRefreshID = UUID() // Trigger to refresh week scroller

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header removed per request

                // Week Scroller (moved above Green Machine card)
                WeekScroller { date in
                    // Placeholder: hook into scheduling or stats later
                }
                .id(weekScrollerRefreshID) // Force refresh when ID changes
                .padding(.horizontal, 4)
                .padding(.bottom, 8)

                // Green Machine Featured Card
                GreenMachineFeaturedCard(workoutManager: workoutManager, selectedWorkout: $selectedWorkout)
                    .padding(.bottom, 8)

                // Quick Actions Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("CHOOSE YOUR PATH")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(theme.textSecondary.opacity(0.7))
                        .tracking(0.5)
                        .padding(.horizontal, 4)

                    VStack(spacing: 12) {
                        // Create Custom Workout (Manual)
                        QuickActionCard(
                            icon: "plus.square.fill",
                            title: "Create Blank Workout",
                            color: theme.primary
                        ) {
                            // Create an unsaved draft workout. It will be
                            // persisted only after the first exercise is added.
                            let draft = Workout(name: "New Workout")
                            selectedWorkout = draft
                        }
                    }
                }
                .padding(.bottom, 8)

                // Workouts List
                VStack(alignment: .leading, spacing: 12) {
                    Text("YOUR WORKOUTS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(theme.textSecondary.opacity(0.7))
                        .tracking(0.5)
                        .padding(.horizontal, 4)

                    ForEach(workoutManager.workouts) { workout in
                        WorkoutCard(workout: workout) {
                            selectedWorkout = workout
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 40)
        }
        .fullScreenCover(item: $selectedWorkout) { workout in
            WorkoutFlowContainer(workout: workout, workoutManager: workoutManager)
        }
        .onChange(of: entranceAnimationTrigger) { oldValue, newValue in
            // Reset week scroller when tab is selected
            weekScrollerRefreshID = UUID()
        }
        .trackScreen("train")
    }
}

// MARK: - Workout Card
private struct WorkoutCard: View {
    @Environment(\.theme) var theme
    let workout: Workout
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            GradientCard {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(workout.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color.white,
                                            Color.white.opacity(0.9)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: Color.white.opacity(0.2), radius: 4, x: 0, y: 0)

                            HStack(spacing: 16) {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 14))
                                    Text("\(workout.estimatedTimeMinutes) min")
                                        .font(.system(size: 15, weight: .medium))
                                }

                                HStack(spacing: 6) {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 14))
                                    Text("\(workout.exerciseCount) exercises")
                                        .font(.system(size: 15, weight: .medium))
                                }
                            }
                            .foregroundColor(theme.textSecondary.opacity(0.8))
                        }

                        Spacer()

                        // Icon
                        ZStack {
                            Circle()
                                .fill(theme.primary.opacity(0.15))
                                .frame(width: 56, height: 56)

                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 24))
                                .foregroundColor(theme.primary)
                        }
                    }

                    // Equipment badges
                    if !workout.allEquipment.isEmpty && workout.allEquipment != [.none] {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("WHAT YOU'LL NEED")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(theme.textSecondary.opacity(0.6))
                                .tracking(0.5)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(workout.allEquipment.prefix(4), id: \.self) { equipment in
                                        EquipmentBadge(equipment: equipment)
                                    }
                                }
                            }
                        }
                    }

                    // CTA
                    HStack {
                        Text("View Workout")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.primary)

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.primary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(theme.primary.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(20)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Workout Flow Container
struct WorkoutFlowContainer: View {
    @Environment(\.theme) var theme
    let workout: Workout
    @ObservedObject var workoutManager: WorkoutViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            WorkoutDetailView(workout: workout)
                .environmentObject(workoutManager)
                // Use the app's custom header inside WorkoutDetailView
                // and hide the system navigation bar for consistency
                .navigationBarHidden(true)
        }
    }
}

// MARK: - Quick Action Card
private struct QuickActionCard: View {
    @Environment(\.theme) var theme
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 32)

                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Arrow indicator
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.35), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/*
// MARK: - Custom Workout Creator Sheet
private struct CustomWorkoutCreatorSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @ObservedObject var workoutManager: WorkoutViewModel
    @Binding var selectedWorkout: Workout?

    @State private var workoutName = ""
    @State private var selectedDuration = 30
    @State private var selectedFocus: DrillCategory = .stickhandling
    @State private var selectedEquipment: Set<Equipment> = [.stick, .pucks]

    let durations = [15, 30, 45, 60]

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header matching WorkoutDetailView style
                customHeader

                // Placeholder content
                VStack(spacing: 12) {
                    Image(systemName: "rectangle.dashed")
                        .font(.system(size: 44, weight: .regular))
                        .foregroundColor(theme.textSecondary.opacity(0.6))

                    Text("Placeholder Page")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(theme.text)

                    Text("This AI workout page has been removed and will be redesigned.")
                        .font(.system(size: 15))
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 48)
                .padding()
            }
        }
    }

    private var customHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: theme.spacing.md) {
                // Close button (matches WorkoutDetailView)
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

                // Title styled like workout header
                Text("AI Generate Workout")
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

                // Ellipsis menu placeholder to mirror layout
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(theme.surface)
                            .frame(width: 44, height: 44)

                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .disabled(true)
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

    private var workoutNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WORKOUT NAME")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme.textSecondary.opacity(0.7))
                .tracking(0.5)

            TextField("e.g., Morning Stickhandling", text: $workoutName)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(theme.text)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(theme.primary.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HOW LONG DO YOU HAVE?")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme.textSecondary.opacity(0.7))
                .tracking(0.5)

            HStack(spacing: 12) {
                ForEach(durations, id: \.self) { duration in
                    durationButton(duration)
                }
            }
        }
    }

    private func durationButton(_ duration: Int) -> some View {
        let isSelected = selectedDuration == duration
        return Button(action: {
            selectedDuration = duration
        }) {
            VStack(spacing: 4) {
                Text("\(duration)")
                    .font(.system(size: 24, weight: .bold))
                Text("min")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? theme.primary : theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? theme.primary.opacity(0.15) : theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? theme.primary : theme.primary.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var focusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WHAT'S YOUR FOCUS?")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme.textSecondary.opacity(0.7))
                .tracking(0.5)

            VStack(spacing: 8) {
                ForEach(DrillCategory.allCases, id: \.self) { category in
                    focusButton(category)
                }
            }
        }
    }

    private func focusButton(_ category: DrillCategory) -> some View {
        let isSelected = selectedFocus == category
        return Button(action: {
            selectedFocus = category
        }) {
            HStack {
                Image(systemName: category.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? theme.primary : theme.textSecondary)
                    .frame(width: 32)

                Text(category.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? theme.text : theme.textSecondary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(theme.primary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? theme.primary.opacity(0.1) : theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? theme.primary : theme.primary.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AVAILABLE EQUIPMENT")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme.textSecondary.opacity(0.7))
                .tracking(0.5)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach([Equipment.stick, .pucks, .cones, .net, .dumbbells, .none], id: \.self) { equipment in
                    equipmentButton(equipment)
                }
            }
        }
    }

    private func equipmentButton(_ equipment: Equipment) -> some View {
        let isSelected = selectedEquipment.contains(equipment)
        return Button(action: {
            if isSelected {
                selectedEquipment.remove(equipment)
            } else {
                selectedEquipment.insert(equipment)
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? theme.primary : theme.textSecondary.opacity(0.5))

                Text(equipment.rawValue)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(theme.text)

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(theme.primary.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var createButton: some View {
        let isDisabled = workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return VStack(spacing: 0) {
            Button(action: createWorkout) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))

                    Text("Generate with AI")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(isDisabled ? theme.textSecondary.opacity(0.5) : theme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isDisabled ? theme.textSecondary.opacity(0.3) : theme.primary,
                            lineWidth: 2
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(theme.surface.opacity(0.3))
                                .blur(radius: 10)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isDisabled)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [
                        theme.background.opacity(0.95),
                        theme.background.opacity(0.8)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .ignoresSafeArea()
            )
        }
    }

    private func createWorkout() {
        let trimmedName = workoutName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let workout = workoutManager.createWorkout(name: String(trimmedName.prefix(30)))
        dismiss()
        selectedWorkout = workout
    }
}

*/
// MARK: - Green Machine Featured Card
private struct GreenMachineFeaturedCard: View {
    @Environment(\.theme) var theme
    @ObservedObject var workoutManager: WorkoutViewModel
    @Binding var selectedWorkout: Workout?

    var body: some View {
        Button(action: {
            // Check if featured workout is already in user's workouts
            if let existingWorkout = workoutManager.workouts.first(where: { $0.id == GreenMachineContent.featuredWorkout.id }) {
                // Open existing copy
                selectedWorkout = existingWorkout
            } else {
                // Add featured workout to user's workouts so it can be edited
                let featuredCopy = GreenMachineContent.featuredWorkout
                workoutManager.addWorkout(featuredCopy)
                selectedWorkout = featuredCopy
            }
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Header Badge
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)

                    Text("FEATURED: GREEN MACHINE HOCKEY")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.textSecondary.opacity(0.95))
                        .tracking(0.7)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Featured Image with overlaid title
                ZStack(alignment: .bottomLeading) {
                    // Align image to top and bias slightly down to keep subject in frame
                    GeometryReader { proxy in
                        Image("shot_example")
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
                            // Fill to the very top; remove downward offset to avoid a flat band
                            .offset(y: 0)
                            .clipped()
                    }

                    // Darker bottom vignette for legibility
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.60)
                        ],
                        startPoint: .center,
                        endPoint: .bottom
                    )

                    // Title over image
                    Text(GreenMachineContent.featuredWorkout.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.6), radius: 6, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)
                }
                // Extend image height down to occupy the space the title previously used
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Workout Info
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        Label("\(GreenMachineContent.featuredWorkout.exerciseCount) drills", systemImage: "figure.hockey")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textSecondary)

                        Label("\(GreenMachineContent.featuredWorkout.estimatedTimeMinutes) min", systemImage: "clock")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textSecondary)

                        Label(GreenMachineContent.featuredDifficulty, systemImage: "star")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }

                    // CTA Button (original subtle filled + stroke)
                    HStack {
                        Text("Start This Workout")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(theme.primary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(theme.primary.opacity(0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(theme.primary, lineWidth: 1.2)
                    )
                    .shadow(color: theme.primary.opacity(0.25), radius: 6, x: 0, y: 4)
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.surface,
                                theme.surface.opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.6),
                                theme.accent.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: Color.green.opacity(0.2), radius: 12, x: 0, y: 4)
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TrainView()
}
