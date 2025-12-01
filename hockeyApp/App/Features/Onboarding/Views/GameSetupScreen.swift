import SwiftUI

// MARK: - Game Setup Screen (Position, Skill Level, Handedness)
struct GameSetupScreen: View {
    @Environment(\.theme) var theme
    @ObservedObject var viewModel: OnboardingViewModel
    @ObservedObject var coordinator: OnboardingFlowCoordinator

    @State private var appeared = false
    @State private var selectedPosition: PositionCategory?
    @State private var selectedSkillLevel: SkillLevel?
    @State private var selectedHandedness: Handedness?

    enum PositionCategory: String, CaseIterable {
        case forward = "Forward"
        case defense = "Defense"
        case goalie = "Goalie"

        var icon: String {
            switch self {
            case .forward: return "figure.hockey"
            case .defense: return "shield.fill"
            case .goalie: return "hockey.puck.fill"
            }
        }

        var description: String {
            switch self {
            case .forward: return "C, LW, RW"
            case .defense: return "LD, RD"
            case .goalie: return "G"
            }
        }

        // Convert to Position enum (default to center position in category)
        var defaultPosition: Position {
            switch self {
            case .forward: return .center
            case .defense: return .leftDefense
            case .goalie: return .goalie
            }
        }
    }

    private var canContinue: Bool {
        return selectedPosition != nil && selectedSkillLevel != nil && selectedHandedness != nil
    }

    var body: some View {
        ZStack {
            // Animated background
            BackgroundAnimationView(type: .energyWaves, isActive: true, intensity: 0.25)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 40)

                    // Header
                    VStack(spacing: theme.spacing.sm) {
                        Text("Your game")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appeared)

                        Text("Helps us tailor coaching and analysis")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
                    }
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.xl)

                    // Form fields
                    VStack(spacing: theme.spacing.xl) {
                        // Position selection
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("What position do you play?")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.text)
                                Text("*")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(theme.primary)
                            }

                            VStack(spacing: 10) {
                                ForEach(PositionCategory.allCases, id: \.self) { position in
                                    Button {
                                        HapticManager.shared.playImpact(style: .light)
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedPosition = position
                                        }
                                    } label: {
                                        HStack(spacing: 14) {
                                            Image(systemName: position.icon)
                                                .font(.system(size: 24))
                                                .frame(width: 32)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(position.rawValue)
                                                    .font(.system(size: 17, weight: .semibold))
                                                Text(position.description)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(selectedPosition == position ? theme.primary.opacity(0.8) : theme.textSecondary)
                                            }

                                            Spacer()

                                            if selectedPosition == position {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 22))
                                                    .foregroundColor(theme.primary)
                                            }
                                        }
                                        .padding(16)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedPosition == position ? theme.primary.opacity(0.15) : theme.surface)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(selectedPosition == position ? theme.primary : theme.divider, lineWidth: selectedPosition == position ? 2 : 1)
                                                )
                                        )
                                        .foregroundColor(selectedPosition == position ? theme.primary : theme.text)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: appeared)

                        // Skill Level selection
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("What's your skill level?")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.text)
                                Text("*")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(theme.primary)
                            }

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(SkillLevel.allCases, id: \.self) { level in
                                    Button {
                                        HapticManager.shared.playImpact(style: .light)
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedSkillLevel = level
                                        }
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: level.icon)
                                                .font(.system(size: 20))

                                            Text(level.rawValue)
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedSkillLevel == level ? theme.primary.opacity(0.15) : theme.surface)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(selectedSkillLevel == level ? theme.primary : theme.divider, lineWidth: selectedSkillLevel == level ? 2 : 1)
                                                )
                                        )
                                        .foregroundColor(selectedSkillLevel == level ? theme.primary : theme.text)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25), value: appeared)

                        // Handedness selection
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Which hand do you shoot?")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.text)
                                Text("*")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(theme.primary)
                            }

                            HStack(spacing: 12) {
                                ForEach(Handedness.allCases, id: \.self) { hand in
                                    Button {
                                        HapticManager.shared.playImpact(style: .light)
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedHandedness = hand
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: hand == .left ? "hand.point.left.fill" : "hand.point.right.fill")
                                                .font(.system(size: 20))

                                            Text(hand.rawValue)
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedHandedness == hand ? theme.primary.opacity(0.15) : theme.surface)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(selectedHandedness == hand ? theme.primary : theme.divider, lineWidth: selectedHandedness == hand ? 2 : 1)
                                                )
                                        )
                                        .foregroundColor(selectedHandedness == hand ? theme.primary : theme.text)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35), value: appeared)
                    }
                    .padding(.horizontal, theme.spacing.lg)

                    Spacer(minLength: 20)
                }
                .padding(.bottom, 100) // Space for fixed button
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Fixed bottom CTA - matches welcome screen positioning
            VStack(spacing: theme.spacing.sm) {
                AppButton(title: "Continue", action: {
                    HapticManager.shared.playImpact(style: .medium)
                    saveGameData()
                    coordinator.navigateForward()
                })
                .buttonStyle(.primary)
                .withIcon("arrow.right")
                .buttonSize(.large)
                .disabled(!canContinue)
                .padding(.horizontal, theme.spacing.lg)

                // Maintain footer height consistency with welcome screen
                Text(" ")
                    .font(theme.fonts.body)
                    .foregroundColor(.clear)
                    .frame(height: 44)
            }
            .padding(.bottom, theme.spacing.lg)
            .background(
                LinearGradient(
                    colors: [.clear, theme.background.opacity(0.9), theme.background],
                    startPoint: .top,
                    endPoint: .center
                )
            )
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)
        }
        .onAppear {
            appeared = true
            HapticManager.shared.playNotification(type: .success)
        }
    }

    private func saveGameData() {
        var profile = viewModel.playerProfile ?? PlayerProfile()
        profile.position = selectedPosition?.defaultPosition
        profile.skillLevel = selectedSkillLevel
        profile.handedness = selectedHandedness
        viewModel.playerProfile = profile

        // Persist to UserDefaults
        viewModel.saveProfileToDefaults()
    }
}
