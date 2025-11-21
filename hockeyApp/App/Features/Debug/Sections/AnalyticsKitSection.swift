import SwiftUI

/// Simple controls for AnalyticsKit-related debugging
struct AnalyticsKitSection: View {
    @Environment(\.theme) var theme

    private var debugBinding: Binding<Bool> {
        Binding(
            get: { ScreenTracker.shared.isDebugEnabled },
            set: { _ in ScreenTracker.shared.toggleDebug() }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 16) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Screen Tracking Debug")
                            .foregroundColor(.white)
                        Text("Show real-time screen analytics")
                            .font(theme.fonts.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Toggle("", isOn: debugBinding)
                        .tint(theme.primary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    AnalyticsKitSection()
        .preferredColorScheme(.dark)
}

