import SwiftUI

// MARK: - Body Scan Empty Card
/// Reusable card component for Body Scan empty state
/// Used in both Profile page and Stick Analyzer flow
struct BodyScanEmptyCard: View {
    @Environment(\.theme) var theme
    let onStartScan: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Hero image with border frame
            Image("body_scan_hero")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    theme.primary.opacity(0.6),
                                    theme.primary.opacity(0.2),
                                    theme.primary.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: theme.primary.opacity(0.2), radius: 12, y: 4)
                .padding(.top, 24)

            // Content
            VStack(spacing: 10) {
                Text("Body Scan")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text("Capture your body proportions for better stick recommendations")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 16)

            // Start button
            Button(action: {
                HapticManager.shared.playSelection()
                onStartScan()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Start Body Scan")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.surface)
        )
    }
}

// MARK: - Preview
#if DEBUG
struct BodyScanEmptyCard_Previews: PreviewProvider {
    static var previews: some View {
        BodyScanEmptyCard(onStartScan: {})
            .padding()
            .background(Color.black)
    }
}
#endif
