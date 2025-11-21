import SwiftUI

struct ExerciseLibraryView: View {
    @Environment(\.theme) var theme
    @EnvironmentObject var workoutManager: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedExercise: Exercise?
    @State private var selectedIds: Set<UUID> = []
    @State private var selectedCategories: Set<DrillCategory> = []
    @State private var selectedEquipment: Set<Equipment> = []

    let onAddExercise: (Exercise) -> Void

    private var availableCategories: [DrillCategory] {
        // Only show categories that have exercises
        let categoriesWithExercises = Set(workoutManager.allExercises.map { $0.category })
        return DrillCategory.allCases.filter { categoriesWithExercises.contains($0) }
    }

    private var availableEquipment: [Equipment] {
        // Get all unique equipment from exercises
        let allEquipment = Set(workoutManager.allExercises.flatMap { $0.equipment })
        return Equipment.allCases.filter { allEquipment.contains($0) }.sorted { $0.rawValue < $1.rawValue }
    }

    private var filteredExercises: [Exercise] {
        var exercises = workoutManager.allExercises

        // Filter by search text
        if !searchText.isEmpty {
            exercises = exercises.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter by categories (show exercises that match ANY selected category)
        if !selectedCategories.isEmpty {
            exercises = exercises.filter { selectedCategories.contains($0.category) }
        }

        // Filter by equipment (show exercises that have ANY of the selected equipment)
        if !selectedEquipment.isEmpty {
            exercises = exercises.filter { exercise in
                // If "None" is selected, show exercises with no equipment or explicitly marked as none
                if selectedEquipment.contains(.none) {
                    if exercise.equipment.contains(.none) || exercise.equipment.isEmpty {
                        return true
                    }
                }
                // Check if exercise has any of the selected equipment
                return !Set(exercise.equipment).isDisjoint(with: selectedEquipment)
            }
        }

        return exercises
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header styled to match Profile/Trim header
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Glowing title
                    Text("Add Exercise")
                        .font(.system(size: 22, weight: .black))
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
                        .shadow(color: Color.white.opacity(0.3), radius: 0, x: 0, y: 0)
                        .shadow(color: Color.white.opacity(0.2), radius: 4, x: 0, y: 0)
                        .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 2)

                    Spacer()

                    // Close button (glass style)
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            theme.primary.opacity(0.15),
                                            theme.primary.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 42, height: 42)
                                .overlay(
                                    Circle()
                                        .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: theme.primary.opacity(0.2), radius: 8, x: 0, y: 2)

                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(theme.primary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        // Glass morphism background
                        Rectangle()
                            .fill(.ultraThinMaterial)

                        // Gradient overlay
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
                )

                // Subtle green separator line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.primary.opacity(0),
                                theme.primary.opacity(0.3),
                                theme.primary.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }

            // Content
            ScrollView {
                VStack(spacing: 16) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(theme.textSecondary)

                        TextField("Search exercises...", text: $searchText)
                            .font(.system(size: 16))
                            .foregroundColor(theme.text)
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(0.35))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Category Filter
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Category")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.textSecondary)

                            if !selectedCategories.isEmpty {
                                Button(action: { selectedCategories.removeAll() }) {
                                    Text("Clear")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(theme.primary)
                                }
                            }

                            Spacer()

                            if !selectedCategories.isEmpty {
                                Text("\(selectedCategories.count) selected")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(theme.primary)
                            }
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(availableCategories, id: \.self) { category in
                                    FilterChip(
                                        title: category.rawValue,
                                        icon: category.icon,
                                        isSelected: selectedCategories.contains(category)
                                    ) {
                                        if selectedCategories.contains(category) {
                                            selectedCategories.remove(category)
                                        } else {
                                            selectedCategories.insert(category)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Equipment Filter
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Equipment")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.textSecondary)

                            if !selectedEquipment.isEmpty {
                                Button(action: { selectedEquipment.removeAll() }) {
                                    Text("Clear")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(theme.primary)
                                }
                            }

                            Spacer()

                            if !selectedEquipment.isEmpty {
                                Text("\(selectedEquipment.count) selected")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(theme.primary)
                            }
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(availableEquipment, id: \.self) { equipment in
                                    FilterChip(
                                        title: equipment.rawValue,
                                        icon: nil,
                                        isSelected: selectedEquipment.contains(equipment)
                                    ) {
                                        if selectedEquipment.contains(equipment) {
                                            selectedEquipment.remove(equipment)
                                        } else {
                                            selectedEquipment.insert(equipment)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Exercise Selectable List
                    VStack(spacing: 8) {
                        ForEach(filteredExercises) { exercise in
                            ExerciseSelectableRow(
                                exercise: exercise,
                                isSelected: selectedIds.contains(exercise.id),
                                onToggle: {
                                    if selectedIds.contains(exercise.id) {
                                        selectedIds.remove(exercise.id)
                                    } else {
                                        selectedIds.insert(exercise.id)
                                    }
                                },
                                onViewDetails: { selectedExercise = exercise }
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
            .fullScreenCover(item: $selectedExercise) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
        .background(theme.background)
        .overlay(alignment: .bottom) {
            if selectedIds.count > 0 {
                let count = selectedIds.count
                GlassFooterButton(
                    title: count == 1 ? "Add 1 exercise" : "Add \(count) exercises",
                    icon: "plus.circle.fill",
                    isEnabled: true
                ) {
                    let toAdd = workoutManager.allExercises.filter { selectedIds.contains($0.id) }
                    toAdd.forEach { onAddExercise($0) }
                    dismiss()
                }
            }
        }
        .trackScreen("exercise_library")
    }
}

// MARK: - Exercise Selectable Row
private struct ExerciseSelectableRow: View {
    @Environment(\.theme) var theme
    let exercise: Exercise
    let isSelected: Bool
    let onToggle: () -> Void
    let onViewDetails: () -> Void

    var body: some View {
        HStack(spacing: 12) {
                // Title + view details
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.text)

                    Button(action: onViewDetails) {
                        HStack(spacing: 4) {
                            Text("View details")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.primary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Selection circle
                ZStack {
                    Circle()
                        .stroke(isSelected ? theme.primary : theme.textSecondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.primary)
                    }
                }
        }
        .padding(12)
        .background(Color(.systemGray6).opacity(0.35))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
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

// MARK: - Flow Layout (for wrapping badges)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))

                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    ExerciseLibraryView { _ in }
        .environmentObject(WorkoutViewModel())
}
