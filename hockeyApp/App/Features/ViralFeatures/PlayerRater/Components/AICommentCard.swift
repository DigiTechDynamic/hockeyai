import SwiftUI

// MARK: - AI Comment Card (Neon Quote Style)
/// Viral-optimized comment card with neon green accent and glass morphism
struct AICommentCard: View {
    @Environment(\.theme) var theme
    let comment: String
    let showContent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Greeny profile + name
            HStack(spacing: 10) {
                // Greeny profile pic (larger, more prominent)
                Image("GreenyProfilePic")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(theme.primary.opacity(0.3), lineWidth: 1.5)
                    )

                Text("Greeny")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Divider
            Rectangle()
                .fill(theme.primary.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 18)

            // Comment text
            Text(comment)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
        }
        .background(
            ZStack {
                // Darker base for better contrast
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.6))

                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Glass effect
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial.opacity(0.5))

                // Green accent border
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                theme.primary.opacity(0.6),
                                theme.primary.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: theme.primary.opacity(0.2), radius: 16, y: 8)
        .shadow(color: Color.black.opacity(0.4), radius: 24, y: 12)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 15)
    }
}
