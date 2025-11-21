import SwiftUI

/// Segmented dot progress indicator for workout exercises
///
/// **Usage:**
/// ```swift
/// WorkoutProgressBar(
///     currentIndex: 2,        // Currently on exercise 3
///     totalExercises: 6,      // Total of 6 exercises
///     elapsedTime: 540        // 9 minutes elapsed
/// )
/// ```
///
/// **Features:**
/// - Dots: filled (completed), current (outlined/pulsing), empty (future)
/// - Shows "Exercise 3/6" label
/// - Shows elapsed time below in small text
/// - Theme-aware styling
/// - Accessible (clear visual states)
struct WorkoutProgressBar: View {
    @Environment(\.theme) var theme

    /// Current exercise index (0-based)
    let currentIndex: Int

    /// Total number of exercises
    let totalExercises: Int

    /// Elapsed time in seconds (optional)
    var elapsedTime: TimeInterval? = nil

    // MARK: - Computed Properties

    /// Formatted elapsed time (mm:ss)
    private var elapsedTimeString: String {
        guard let elapsedTime = elapsedTime else { return "" }
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Exercise label (1-based for user display)
    private var exerciseLabel: String {
        "Exercise \(currentIndex + 1)/\(totalExercises)"
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // Exercise counter label
            Text(exerciseLabel)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.textSecondary)
                .tracking(0.5)

            // Dot progress indicator
            HStack(spacing: 8) {
                ForEach(0..<totalExercises, id: \.self) { index in
                    DotIndicator(
                        state: dotState(for: index),
                        color: theme.primary
                    )
                }
            }

            // Elapsed time (if provided)
            if let _ = elapsedTime {
                Text("Elapsed: \(elapsedTimeString)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.textSecondary.opacity(0.7))
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface.opacity(0.3))
        )
    }

    // MARK: - Helper Methods

    /// Determine dot state based on index
    private func dotState(for index: Int) -> DotState {
        if index < currentIndex {
            return .completed
        } else if index == currentIndex {
            return .current
        } else {
            return .empty
        }
    }
}

// MARK: - Dot Indicator

/// Individual dot indicator
private struct DotIndicator: View {
    @Environment(\.theme) var theme

    let state: DotState
    let color: Color

    /// Pulsing animation state
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(fillColor)
                .frame(width: 10, height: 10)

            // Outline for current state
            if state == .current {
                Circle()
                    .stroke(color, lineWidth: 2)
                    .frame(width: 14, height: 14)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .opacity(isPulsing ? 0.5 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: isPulsing
                    )
                    .onAppear {
                        isPulsing = true
                    }
            }
        }
    }

    private var fillColor: Color {
        switch state {
        case .completed:
            return color
        case .current:
            return color.opacity(0.4)
        case .empty:
            return theme.textSecondary.opacity(0.2)
        }
    }
}

// MARK: - Dot State

/// Visual state of a progress dot
private enum DotState {
    case completed  // Filled
    case current    // Outlined + pulsing
    case empty      // Dim gray
}

// MARK: - Preview

#Preview("Exercise 1 of 6 - Start") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 30) {
            WorkoutProgressBar(
                currentIndex: 0,
                totalExercises: 6,
                elapsedTime: 0
            )
        }
        .padding()
    }
}

#Preview("Exercise 3 of 6 - Mid-Workout") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 30) {
            WorkoutProgressBar(
                currentIndex: 2,
                totalExercises: 6,
                elapsedTime: 540 // 9 minutes
            )
        }
        .padding()
    }
}

#Preview("Exercise 6 of 6 - Almost Done") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 30) {
            WorkoutProgressBar(
                currentIndex: 5,
                totalExercises: 6,
                elapsedTime: 1800 // 30 minutes
            )
        }
        .padding()
    }
}

#Preview("Exercise 4 of 8 - No Time") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 30) {
            WorkoutProgressBar(
                currentIndex: 3,
                totalExercises: 8
            )
        }
        .padding()
    }
}

#Preview("Exercise 1 of 3 - Short Workout") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 30) {
            WorkoutProgressBar(
                currentIndex: 0,
                totalExercises: 3,
                elapsedTime: 120
            )
        }
        .padding()
    }
}
