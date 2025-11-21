import SwiftUI

/// Visual indicator for set progress in multi-set exercises
///
/// **Usage:**
/// ```swift
/// SetProgressIndicator(
///     currentSet: 2,
///     totalSets: 4,
///     isResting: false
/// )
/// // Shows: ✅ ⏳ ⬜ ⬜
/// ```
///
/// **Features:**
/// - ✅ Completed sets (green checkmark)
/// - ⏳ Current set (animated hourglass or ring)
/// - ⬜ Upcoming sets (gray square)
/// - Compact horizontal layout
struct SetProgressIndicator: View {
    @Environment(\.theme) var theme

    /// Current set (1-based)
    let currentSet: Int

    /// Total number of sets
    let totalSets: Int

    /// Is currently resting between sets?
    let isResting: Bool

    var body: some View {
        HStack(spacing: 12) {
            ForEach(1...totalSets, id: \.self) { setNumber in
                setIndicator(for: setNumber)
            }
        }
    }

    @ViewBuilder
    private func setIndicator(for setNumber: Int) -> some View {
        ZStack {
            if setNumber < currentSet {
                // Completed set - Green checkmark
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(theme.success)
            } else if setNumber == currentSet {
                // Current set
                if isResting {
                    // Resting - Hourglass with pulse
                    Image(systemName: "hourglass")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(theme.accent)
                        .symbolEffect(.pulse)
                } else {
                    // Active - Ring with pulse
                    Image(systemName: "circle.circle")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(theme.primary)
                        .symbolEffect(.pulse)
                }
            } else {
                // Upcoming set - Gray circle outline
                Image(systemName: "circle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(theme.textSecondary.opacity(0.4))
            }
        }
        .frame(width: 32, height: 32)
    }
}

// MARK: - Previews

#Preview("Set 1 of 3 - Active") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            Text("Active Set 1")
                .foregroundColor(.white)
            SetProgressIndicator(
                currentSet: 1,
                totalSets: 3,
                isResting: false
            )
        }
    }
}

#Preview("Set 2 of 4 - Resting") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            Text("Resting after Set 2")
                .foregroundColor(.white)
            SetProgressIndicator(
                currentSet: 2,
                totalSets: 4,
                isResting: true
            )
        }
    }
}

#Preview("Set 3 of 3 - Active (Last Set)") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            Text("Final Set Active")
                .foregroundColor(.white)
            SetProgressIndicator(
                currentSet: 3,
                totalSets: 3,
                isResting: false
            )
        }
    }
}

#Preview("Set 4 of 5 - Active") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            Text("Set 4 of 5")
                .foregroundColor(.white)
            SetProgressIndicator(
                currentSet: 4,
                totalSets: 5,
                isResting: false
            )
        }
    }
}
