import SwiftUI

// MARK: - Profile Header Section
struct ProfileHeaderSection: View {
    @Environment(\.theme) var theme
    @StateObject private var monetization = MonetizationManager.shared
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            // Avatar
            Button(action: {
                viewModel.showingPhotoOptions = true
            }) {
                ZStack {
                    if let profileImage = viewModel.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(theme.primary, lineWidth: 3)
                            )
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [theme.primary, theme.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(theme.fonts.display)
                                    .foregroundColor(theme.textOnPrimary)
                            )
                    }

                    // Crown badge (top-right) for Pro users
                    if monetization.isPremium {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                )
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.yellow)
                        }
                        .offset(x: 35, y: -35)
                    }

                    // Camera icon overlay (bottom-right)
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(theme.fonts.caption)
                                .foregroundColor(theme.textOnPrimary)
                        )
                        .offset(x: 35, y: 35)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Name and email
            VStack(spacing: theme.spacing.xs) {
                Text(viewModel.displayName.isEmpty ? "Player Name" : viewModel.displayName)
                    .font(theme.fonts.title)
                    .foregroundColor(theme.text)

                if !viewModel.email.isEmpty {
                    Text(viewModel.email)
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
    }
}
