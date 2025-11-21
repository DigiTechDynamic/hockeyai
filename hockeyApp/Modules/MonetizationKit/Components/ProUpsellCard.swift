import SwiftUI

struct ProUpsellCard: View {
    let title: String
    let subtitle: String
    let bullets: [String]
    let source: String
    let onDismiss: (() -> Void)?

    @Environment(\.theme) private var theme
    @State private var showPaywall = false

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .foregroundColor(theme.primary)
                Text(title)
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(theme.text)

            Text(subtitle)
                .font(theme.fonts.body)
                .foregroundColor(theme.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(bullets, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.primary)
                            .padding(.top, 2)
                        Text(item)
                            .font(theme.fonts.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }

            HStack(spacing: 10) {
                Button(action: { showPaywall = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                        Text("Unlock Pro")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(theme.primary))
                }

                Button(action: { onDismiss?() }) {
                    Text("Not now")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.text)
                        .frame(maxWidth: 120)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.divider.opacity(0.6), lineWidth: 1)
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.divider.opacity(0.5), lineWidth: 1)
                )
        )
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallPresenter(source: source)
                .preferredColorScheme(.dark)
        }
    }
}

struct ProChip: View {
    @Environment(\.theme) private var theme
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown")
                .font(.system(size: 8, weight: .semibold))
            Text("PRO")
                .font(.system(size: 9, weight: .heavy))
                .textCase(.uppercase)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .foregroundColor(.white.opacity(0.9))
        .background(
            Capsule()
                .fill(theme.surface.opacity(0.5))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
        )
    }
}
