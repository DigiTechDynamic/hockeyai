import SwiftUI

struct RestDurationWheelPicker: View {
    @Environment(\.theme) var theme

    @Binding var duration: TimeInterval
    var maxMinutes: Int = 5
    var secondStep: Int = 15

    @State private var minutes: Int = 0
    @State private var seconds: Int = 0

    private var secondsOptions: [Int] {
        if minutes >= maxMinutes { return [0] }
        return stride(from: 0, to: 60, by: max(1, secondStep)).map { $0 }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Minutes wheel
            Picker(selection: $minutes) {
                ForEach(0...maxMinutes, id: \.self) { m in
                    Text("\(m)").tag(m)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
            } label: { EmptyView() }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(alignment: .trailing) {
                Text("min")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
                    .padding(.trailing, 8)
            }

            // Seconds wheel
            Picker(selection: $seconds) {
                ForEach(secondsOptions, id: \.self) { s in
                    Text(String(format: "%d", s)).tag(s)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
            } label: { EmptyView() }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(alignment: .trailing) {
                Text("sec")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
                    .padding(.trailing, 8)
            }
        }
        .frame(height: 120)
        .padding(.horizontal, 0)
        .onAppear { syncPickersFromDuration() }
        .onChange(of: minutes) { _ in
            if minutes >= maxMinutes { seconds = 0 }
            updateDurationFromPickers(haptic: true)
        }
        .onChange(of: seconds) { _ in
            updateDurationFromPickers(haptic: true)
        }
        .accessibilityLabel("Rest Duration Picker")
    }

    private func syncPickersFromDuration() {
        let total = max(0, Int(duration))
        let m = min(maxMinutes, total / 60)
        let s = total % 60
        minutes = m
        // Snap seconds to nearest step
        let stepped = ((s + secondStep / 2) / secondStep) * secondStep
        seconds = min(59, stepped)
        if minutes >= maxMinutes { seconds = 0 }
    }

    private func updateDurationFromPickers(haptic: Bool) {
        var total = minutes * 60 + seconds
        if minutes >= maxMinutes { total = maxMinutes * 60 } // clamp
        duration = TimeInterval(total)
        if haptic { HapticManager.shared.playSelection() }
    }
}

#Preview {
    RestDurationWheelPicker(duration: .constant(105))
        .padding()
        .background(Color.black)
}
