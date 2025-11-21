import SwiftUI

enum HeaderProCTAMode {
    case pill
    case icon
}

struct HeaderProCTA: View {
    let label: String
    let mode: HeaderProCTAMode
    let isLoading: Bool
    let onTap: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: { if !isLoading { onTap() } }) {
            ZStack {
                if mode == .pill {
                    pillStyle
                } else {
                    iconStyle
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Go Pro")
        .opacity(isLoading ? 0.9 : 1)
    }

    private var pillStyle: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .tint(.white)
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "crown.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.30))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var iconStyle: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .background(Circle().fill(theme.surface.opacity(0.35)))
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(theme.primary.opacity(0.35), lineWidth: 1)
                )

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .tint(.white)
                    .scaleEffect(0.7)
            } else {
                Image(systemName: "crown.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}
