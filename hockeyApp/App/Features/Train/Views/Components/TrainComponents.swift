import SwiftUI

// MARK: - Equipment Badge
struct EquipmentBadge: View {
    @Environment(\.theme) var theme
    let equipment: Equipment
    let compact: Bool

    init(equipment: Equipment, compact: Bool = false) {
        self.equipment = equipment
        self.compact = compact
    }

    var body: some View {
        HStack(spacing: compact ? 4 : 6) {
            Image(systemName: equipment.icon)
                .font(.system(size: compact ? 12 : 14))
            if !compact {
                Text(equipment.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
            }
        }
        .foregroundColor(theme.textSecondary)
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.vertical, compact ? 4 : 6)
        .background(theme.surface.opacity(0.4))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.textSecondary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Category Badge
struct CategoryBadge: View {
    @Environment(\.theme) var theme
    let category: DrillCategory
    let compact: Bool

    init(category: DrillCategory, compact: Bool = false) {
        self.category = category
        self.compact = compact
    }

    var body: some View {
        HStack(spacing: compact ? 4 : 6) {
            Text(category.icon)
                .font(.system(size: compact ? 12 : 14))
            if !compact {
                Text(category.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
            }
        }
        .foregroundColor(theme.textSecondary)
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.vertical, compact ? 4 : 6)
        .background(theme.surface.opacity(0.4))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.textSecondary.opacity(0.2), lineWidth: 1)
        )
    }
}


// MARK: - Gradient Card Container
struct GradientCard<Content: View>: View {
    @Environment(\.theme) var theme
    let content: Content
    let showBorder: Bool

    init(showBorder: Bool = true, @ViewBuilder content: () -> Content) {
        self.showBorder = showBorder
        self.content = content()
    }

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .fill(theme.surface)
                )

            if showBorder {
                // Gradient border
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                theme.primary.opacity(0.6),
                                theme.accent.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }

            content
        }
        .shadow(color: theme.primary.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Config Display Card
struct ConfigCard: View {
    @Environment(\.theme) var theme
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(theme.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textSecondary)

                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.text)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Glowing Status Indicator
struct TrainStatusIndicator: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .fill(color.opacity(0.4))
                        .frame(width: 14, height: 14)
                        .blur(radius: 3)
                )

            Text(text)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
                .tracking(0.5)
        }
    }
}

// MARK: - Action Button
struct TrainActionButton: View {
    @Environment(\.theme) var theme
    let title: String
    let subtitle: String?
    let systemImage: String?
    let style: ButtonStyle
    let action: () -> Void

    enum ButtonStyle {
        case filled
        case outlined
    }

    init(title: String, subtitle: String? = nil, systemImage: String? = nil, style: ButtonStyle = .outlined, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if let systemImage = systemImage {
                    HStack(spacing: 8) {
                        Image(systemName: systemImage)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(style == .filled ? .white : theme.primary)
                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(style == .filled ? .white : theme.primary)
                    }
                } else {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(style == .filled ? .white : theme.primary)
                }
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(style == .filled ? .white.opacity(0.85) : theme.primary.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                style == .filled ?
                    AnyView(theme.primaryGradient) :
                    AnyView(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(style == .outlined ? theme.primary : Color.clear, lineWidth: 2)
            )
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glass Footer Button (matches Trim "Use Clip")
struct GlassFooterButton: View {
    @Environment(\.theme) var theme
    let title: String
    var icon: String? = nil
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Separator line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.1),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)

            Button(action: action) {
                ZStack {
                    // Glassmorphic background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.surface.opacity(0.8),
                                    theme.surface.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: isEnabled && !isLoading ? [
                                            theme.success.opacity(0.6),
                                            theme.success.opacity(0.3)
                                        ] : [
                                            theme.primary.opacity(0.3),
                                            theme.primary.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: isEnabled && !isLoading ? 2 : 1
                                )
                        )

                    HStack(spacing: 10) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        } else if let icon = icon {
                            Image(systemName: icon)
                                .font(.system(size: 20, weight: .medium))
                        }

                        Text(isLoading ? "Processing..." : title)
                            .font(.system(size: 16, weight: .semibold))
                            .tracking(0.5)
                    }
                    .foregroundColor(isLoading || !isEnabled ? theme.text.opacity(0.4) : theme.text)
                }
                .frame(height: 56)
            }
            .disabled(!isEnabled || isLoading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 34)
        }
        .background(
            ZStack {
                // Gradient background behind the button
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.95),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Subtle pattern overlay
                LinearGradient(
                    colors: [
                        theme.primary.opacity(0.03),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
            }
            .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Exercise Card (inspired by SoftOnboardingUpsellView stat cards)
struct ExerciseCard: View {
    @Environment(\.theme) var theme
    let exercise: Exercise
    let onTap: () -> Void
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?

    init(exercise: Exercise, onTap: @escaping () -> Void, onEdit: (() -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.exercise = exercise
        self.onTap = onTap
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    private var exerciseIcon: String {
        // Map exercise types to appropriate icons
        switch exercise.config.type {
        case .weightRepsSets: return "dumbbell.fill"
        case .timeBased: return "timer"
        case .repsOnly, .repsSets: return "figure.strengthtraining.traditional"
        case .countBased: return "number.circle.fill"
        case .distance: return "figure.run"
        case .timeSets: return "clock.fill"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon with crown-style gradient
                Image(systemName: exerciseIcon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.primary, theme.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: theme.primary.opacity(0.3), radius: 8)
                    .frame(width: 24)

                // Exercise info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(exercise.config.displaySummary)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Menu button with edit and delete options
                if let onEdit = onEdit, let onDelete = onDelete {
                    Menu {
                        Button(action: {
                            onEdit()
                        }) {
                            Label("Configure Exercise", systemImage: "slider.horizontal.3")
                        }

                        Button(role: .destructive, action: {
                            onDelete()
                        }) {
                            Label("Delete Exercise", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.primary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(theme.primary.opacity(0.1))
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Exercise Row (for lists)
struct ExerciseRow: View {
    @Environment(\.theme) var theme
    let exercise: Exercise
    let showDragHandle: Bool
    let onTap: () -> Void
    let onMenu: () -> Void

    init(exercise: Exercise, showDragHandle: Bool = false, onTap: @escaping () -> Void, onMenu: @escaping () -> Void = {}) {
        self.exercise = exercise
        self.showDragHandle = showDragHandle
        self.onTap = onTap
        self.onMenu = onMenu
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if showDragHandle {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textSecondary.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.text)

                    Text(exercise.config.displaySummary)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                Button(action: onMenu) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Numbered Instruction Row
struct InstructionRow: View {
    @Environment(\.theme) var theme
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 28, height: 28)

                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.primary)
            }

            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(theme.text)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Gradient Header
struct GradientHeaderView: View {
    @Environment(\.theme) var theme
    let title: String
    let subtitle: String
    let showStatus: Bool

    init(title: String, subtitle: String, showStatus: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.showStatus = showStatus
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            theme.primary,
                            theme.primary.opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: theme.primary.opacity(0.4), radius: 0, x: 0, y: 0)
                .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 0)

            Text(subtitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.textSecondary)

            if showStatus {
                TrainStatusIndicator(text: "READY", color: .green)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            LinearGradient(
                colors: [
                    theme.surface.opacity(0.5),
                    theme.surface.opacity(0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
