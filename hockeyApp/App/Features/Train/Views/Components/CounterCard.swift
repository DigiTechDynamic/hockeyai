import SwiftUI

/// Manual counter for reps/count-based exercises
///
/// **Usage:**
/// ```swift
/// CounterCard(
///     current: 68,
///     target: 100,
///     label: "touches",
///     onIncrement: { viewModel.incrementCount(by: 1) },
///     onIncrementFive: { viewModel.incrementCount(by: 5) },
///     onDecrement: { viewModel.decrementCount() }
/// )
/// ```
///
/// **Features:**
/// - Large progress display (68 / 100)
/// - Linear progress bar
/// - Quick increment buttons: -1, +1, +5
/// - Haptic feedback on button press
/// - Green theme matching workout UI
struct CounterCard: View {
    @Environment(\.theme) var theme

    /// Current progress value
    let current: Int

    /// Target value
    let target: Int

    /// Label for the unit (e.g., "reps", "touches", "shots")
    let label: String

    /// Increment by 1 callback
    let onIncrement: () -> Void

    /// Increment by 5 callback
    let onIncrementFive: () -> Void

    /// Decrement by 1 callback
    let onDecrement: () -> Void

    // MARK: - Computed Properties

    /// Progress percentage (0.0 to 1.0)
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    /// Is complete?
    private var isComplete: Bool {
        current >= target
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // Counter display
            VStack(spacing: 8) {
                // Current / Target
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(current)")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: isComplete
                                    ? [theme.success, theme.success.opacity(0.8)]
                                    : [Color.white, Color.white.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Text("/ \(target)")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                        .monospacedDigit()
                }
                .shadow(
                    color: isComplete ? theme.success.opacity(0.4) : Color.clear,
                    radius: 20
                )

                // Label
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .opacity(0.7)
                    .textCase(.uppercase)
                    .tracking(1)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.surface.opacity(0.3))
                        .frame(height: 8)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: isComplete
                                    ? [theme.success, theme.success.opacity(0.7)]
                                    : [theme.primary, theme.primary.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * progress,
                            height: 8
                        )
                        .animation(.spring(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 20)

            // Control buttons
            HStack(spacing: 16) {
                // Decrement button
                controlButton(
                    label: "-1",
                    icon: "minus",
                    color: theme.textSecondary,
                    action: onDecrement,
                    isEnabled: current > 0
                )

                Spacer()

                // Increment +1
                controlButton(
                    label: "+1",
                    icon: "plus",
                    color: theme.primary,
                    action: onIncrement,
                    isEnabled: current < target
                )

                // Increment +5
                controlButton(
                    label: "+5",
                    icon: "plus.square.on.square",
                    color: theme.primary,
                    action: onIncrementFive,
                    isEnabled: current < target
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func controlButton(
        label: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void,
        isEnabled: Bool
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(label)
                    .font(.system(size: 18, weight: .bold))
                    .monospacedDigit()
            }
            .foregroundColor(isEnabled ? color : theme.textSecondary.opacity(0.3))
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.surface.opacity(isEnabled ? 0.8 : 0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                isEnabled ? color.opacity(0.5) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(
                color: isEnabled ? color.opacity(0.2) : .clear,
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - Previews

#Preview("Count-Based - In Progress") {
    ZStack {
        Color.black.ignoresSafeArea()
        CounterCard(
            current: 68,
            target: 100,
            label: "touches",
            onIncrement: {},
            onIncrementFive: {},
            onDecrement: {}
        )
    }
}

#Preview("Reps-Only - Just Started") {
    ZStack {
        Color.black.ignoresSafeArea()
        CounterCard(
            current: 5,
            target: 50,
            label: "shots",
            onIncrement: {},
            onIncrementFive: {},
            onDecrement: {}
        )
    }
}

#Preview("Count-Based - Almost Done") {
    ZStack {
        Color.black.ignoresSafeArea()
        CounterCard(
            current: 95,
            target: 100,
            label: "touches",
            onIncrement: {},
            onIncrementFive: {},
            onDecrement: {}
        )
    }
}

#Preview("Reps-Only - Complete") {
    ZStack {
        Color.black.ignoresSafeArea()
        CounterCard(
            current: 50,
            target: 50,
            label: "reps",
            onIncrement: {},
            onIncrementFive: {},
            onDecrement: {}
        )
    }
}
