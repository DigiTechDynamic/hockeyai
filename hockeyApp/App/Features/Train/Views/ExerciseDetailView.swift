import SwiftUI
import UIKit

enum ExerciseDetailContext {
    case library
    case workout
}

struct ExerciseDetailView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    let exercise: Exercise
    var context: ExerciseDetailContext = .library
    var onStart: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Glowing title
                        Text("Exercise Details")
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

                        // Close
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

                ScrollView {
                    VStack(spacing: 0) {

                    // Hero Media Area
                    ZStack {
                        // Try to load category image, fallback to gradient
                        if let uiImage = UIImage(named: exercise.category.imageName) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 280)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .cornerRadius(20)
                        } else {
                            // Fallback gradient placeholder
                            LinearGradient(
                                colors: [
                                    theme.primary.opacity(0.3),
                                    theme.primary.opacity(0.15),
                                    theme.accent.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(height: 280)
                            .cornerRadius(20)

                            // Show category icon when using gradient
                            VStack(spacing: 12) {
                                Text(exercise.category.icon)
                                    .font(.system(size: 72))
                                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                            }
                        }

                        // Overlay badge (always show)
                        VStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Image(systemName: typeIcon)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(exercise.config.displaySummary)
                                    .font(.system(size: 14, weight: .semibold))
                                Text("•")
                                    .font(.system(size: 14, weight: .bold))
                                Text(exercise.category.rawValue)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule()
                                            .fill(Color.black.opacity(0.3))
                                    )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
                        }
                        .padding(.bottom, 12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name)
                            .font(.system(size: 32, weight: .bold))
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
                            .shadow(color: Color.white.opacity(0.2), radius: 6, x: 0, y: 0)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // START Button (only for workout context)
                    if context == .workout {
                        Button(action: {
                            onStart?()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 18, weight: .bold))
                                Text("START")
                                    .font(.system(size: 18, weight: .bold))
                                    .tracking(1)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [
                                        theme.primary,
                                        theme.primary.opacity(0.9)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: theme.primary.opacity(0.5), radius: 12, x: 0, y: 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }

                    // Quick Stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("QUICK STATS")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.textSecondary.opacity(0.7))
                            .tracking(0.5)

                        HStack(spacing: 12) {
                            QuickStatCard(
                                icon: typeIcon,
                                value: exercise.config.displaySummary,
                                label: "Duration"
                            )

                            QuickStatCard(
                                icon: exercise.category.icon,
                                value: exercise.category.rawValue,
                                label: "Type"
                            )

                            QuickStatCard(
                                icon: "🔥",
                                value: estimatedCalories,
                                label: "Est. Cal"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    // What You'll Improve (Benefits)
                    if let benefits = exercise.benefits, !benefits.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("WHAT YOU'LL IMPROVE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(theme.textSecondary.opacity(0.7))
                                .tracking(0.5)

                            Text(benefits)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(theme.text)
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    }

                    // Equipment
                    if !exercise.equipment.isEmpty && exercise.equipment != [.none] {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("EQUIPMENT (\(exercise.equipment.count))")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(theme.textSecondary.opacity(0.7))
                                .tracking(0.5)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(exercise.equipment, id: \.self) { equipment in
                                        EquipmentBadge(equipment: equipment)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    }

                    // Instructions
                    if let instructions = exercise.instructions, !instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("HOW TO DO IT")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(theme.textSecondary.opacity(0.7))
                                .tracking(0.5)

                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(Array(instructions.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.enumerated()), id: \.offset) { index, step in
                                    // Remove existing number prefix if present (e.g., "1. " or "1 ")
                                    let cleanedStep = step.replacingOccurrences(of: "^\\d+\\.?\\s*", with: "", options: .regularExpression)
                                    InstructionRow(number: index + 1, text: cleanedStep.trimmingCharacters(in: .whitespaces))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    }

                    // Pro Tips
                    if let tips = exercise.tips, !tips.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PRO TIP")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(theme.textSecondary.opacity(0.7))
                                .tracking(0.5)

                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(theme.accent)

                                Text(tips)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(theme.text)
                                    .lineSpacing(4)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(theme.accent.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    }

                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 40)
                }
            }
            .background(theme.background)
        }
        .navigationBarHidden(true)
        .trackScreen("exercise_detail")
    }

    private var typeIcon: String {
        switch exercise.config.type {
        case .timeBased: return "clock.fill"
        case .repsOnly: return "repeat"
        case .countBased: return "number"
        case .weightRepsSets: return "scalemass.fill"
        case .distance: return "figure.walk"
        case .repsSets: return "repeat"
        case .timeSets: return "clock.fill"
        }
    }

    private var estimatedCalories: String {
        // Simple estimation based on exercise type
        let baseCalories: Int
        switch exercise.config {
        case .timeBased(let duration):
            baseCalories = Int(duration / 60 * 15) // ~15 cal/min
        case .repsOnly(let reps):
            baseCalories = reps / 2
        case .countBased(let count):
            baseCalories = count / 2
        case .weightRepsSets(_, let reps, let sets, _):
            baseCalories = reps * sets * 2
        case .distance(let distance, _):
            baseCalories = Int(distance / 10)
        case .repsSets(let reps, let sets):
            baseCalories = reps * sets
        case .timeSets(let duration, let sets, _):
            baseCalories = Int(duration / 60 * 15 * Double(sets))
        }
        return "\(baseCalories)"
    }
}

// MARK: - Quick Stat Card
struct QuickStatCard: View {
    @Environment(\.theme) var theme
    let icon: String
    let value: String
    let label: String

    // Check if icon is a valid SF Symbol (supports names without dots like "repeat")
    private var isSystemIcon: Bool {
        UIImage(systemName: icon) != nil
    }

    var body: some View {
        VStack(spacing: 8) {
            // Render icon based on type
            if isSystemIcon {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(theme.primary)
            } else {
                Text(icon)
                    .font(.system(size: 24))
            }

            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(theme.text)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(theme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.primary.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    ExerciseDetailView(exercise: SampleExercises.all[0], context: .workout)
}
