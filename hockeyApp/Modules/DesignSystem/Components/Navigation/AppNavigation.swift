import SwiftUI

// MARK: - App Navigation Bar
public struct AppNavigationBar: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    public let title: String
    public let subtitle: String?
    public let showBackButton: Bool
    public let showCloseButton: Bool
    public let leadingActions: [AppNavigationAction]
    public let trailingActions: [AppNavigationAction]
    public let onBack: (() -> Void)?
    public let onClose: (() -> Void)?
    
    public init(
        title: String,
        subtitle: String? = nil,
        showBackButton: Bool = false,
        showCloseButton: Bool = false,
        leadingActions: [AppNavigationAction] = [],
        trailingActions: [AppNavigationAction] = [],
        onBack: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showBackButton = showBackButton
        self.showCloseButton = showCloseButton
        self.leadingActions = leadingActions
        self.trailingActions = trailingActions
        self.onBack = onBack
        self.onClose = onClose
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: theme.spacing.md) {
                // Leading section
                HStack(spacing: theme.spacing.sm) {
                    if showBackButton {
                        AppNavigationButton(
                            icon: "chevron.left",
                            style: .back
                        ) {
                            HapticManager.shared.playImpact(style: .light)
                            onBack?()
                        }
                    }
                    
                    if showCloseButton {
                        AppNavigationButton(
                            icon: "xmark",
                            style: .close
                        ) {
                            HapticManager.shared.playImpact(style: .light)
                            if let onClose = onClose {
                                onClose()
                            } else {
                                dismiss()
                            }
                        }
                    }
                    
                    ForEach(leadingActions.indices, id: \.self) { index in
                        AppNavigationButton(
                            action: leadingActions[index]
                        )
                    }
                }
                
                Spacer()
                
                // Center title section
                VStack(spacing: theme.spacing.xs / 2) {
                    Text(title)
                        .font(theme.fonts.headline)
                        .foregroundColor(theme.text)
                        .lineLimit(1)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(theme.fonts.caption)
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Trailing section
                HStack(spacing: theme.spacing.sm) {
                    ForEach(trailingActions.indices, id: \.self) { index in
                        AppNavigationButton(
                            action: trailingActions[index]
                        )
                    }
                }
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.vertical, theme.spacing.md)
            .background(theme.background)
            
            // Divider
            Rectangle()
                .fill(theme.divider)
                .frame(height: 1)
        }
    }
}

// MARK: - Navigation Action
public struct AppNavigationAction {
    public let icon: String
    public let title: String?
    public let style: AppNavigationButtonStyle
    public let action: () -> Void
    
    public init(
        icon: String,
        title: String? = nil,
        style: AppNavigationButtonStyle = .standard,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.style = style
        self.action = action
    }
}

// MARK: - Navigation Button
public struct AppNavigationButton: View {
    @Environment(\.theme) private var theme
    
    public let icon: String
    public let title: String?
    public let style: AppNavigationButtonStyle
    public let action: () -> Void
    
    public init(
        icon: String,
        title: String? = nil,
        style: AppNavigationButtonStyle = .standard,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.style = style
        self.action = action
    }
    
    public init(action: AppNavigationAction) {
        self.icon = action.icon
        self.title = action.title
        self.style = action.style
        self.action = action.action
    }
    
    public var body: some View {
        Button(action: {
            HapticManager.shared.playImpact(style: .light)
            action()
        }) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: icon)
                    .font(style.iconFont(theme))
                    .foregroundColor(style.iconColor(theme))
                
                if let title = title {
                    Text(title)
                        .font(style.textFont(theme))
                        .foregroundColor(style.textColor(theme))
                }
            }
            .padding(style.contentPadding(theme))
            .background(style.background(theme))
            .cornerRadius(style.cornerRadius(theme))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Navigation Button Style
public enum AppNavigationButtonStyle {
    case standard
    case back
    case close
    case primary
    case secondary
    case destructive
    
    func iconFont(_ theme: AppTheme) -> Font {
        switch self {
        case .standard, .primary, .secondary: return theme.fonts.body
        case .back: return .system(size: 20, weight: .medium)
        case .close: return .system(size: 18, weight: .medium)
        case .destructive: return theme.fonts.body
        }
    }
    
    func textFont(_ theme: AppTheme) -> Font {
        switch self {
        case .standard, .back, .close: return theme.fonts.body
        case .primary, .secondary: return theme.fonts.button
        case .destructive: return theme.fonts.body
        }
    }
    
    func iconColor(_ theme: AppTheme) -> Color {
        switch self {
        case .standard, .back, .close: return theme.text
        case .primary: return theme.textOnPrimary
        case .secondary: return theme.primary
        case .destructive: return theme.error
        }
    }
    
    func textColor(_ theme: AppTheme) -> Color {
        switch self {
        case .standard, .back, .close: return theme.text
        case .primary: return theme.textOnPrimary
        case .secondary: return theme.primary
        case .destructive: return theme.error
        }
    }
    
    func background(_ theme: AppTheme) -> Color {
        switch self {
        case .standard, .back, .close: return theme.background.opacity(0)
        case .primary: return theme.primary
        case .secondary: return theme.surface
        case .destructive: return theme.background.opacity(0)
        }
    }
    
    func contentPadding(_ theme: AppTheme) -> EdgeInsets {
        switch self {
        case .standard, .back, .close, .destructive: 
            return EdgeInsets(top: theme.spacing.sm, leading: theme.spacing.sm, bottom: theme.spacing.sm, trailing: theme.spacing.sm)
        case .primary, .secondary: 
            return EdgeInsets(top: theme.spacing.sm, leading: theme.spacing.md, bottom: theme.spacing.sm, trailing: theme.spacing.md)
        }
    }
    
    func cornerRadius(_ theme: AppTheme) -> CGFloat {
        switch self {
        case .standard, .back, .close, .destructive: return 0
        case .primary, .secondary: return theme.cornerRadius / 2
        }
    }
}

// MARK: - Navigation Extensions
public extension View {
    /// Apply a standardized navigation bar
    func appNavigationBar(
        title: String,
        subtitle: String? = nil,
        showBackButton: Bool = false,
        showCloseButton: Bool = false,
        leadingActions: [AppNavigationAction] = [],
        trailingActions: [AppNavigationAction] = [],
        onBack: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) -> some View {
        VStack(spacing: 0) {
            AppNavigationBar(
                title: title,
                subtitle: subtitle,
                showBackButton: showBackButton,
                showCloseButton: showCloseButton,
                leadingActions: leadingActions,
                trailingActions: trailingActions,
                onBack: onBack,
                onClose: onClose
            )
            
            self
        }
    }
    
    /// Simple navigation with back button
    func appBackNavigation(
        title: String,
        subtitle: String? = nil,
        onBack: (() -> Void)? = nil
    ) -> some View {
        appNavigationBar(
            title: title,
            subtitle: subtitle,
            showBackButton: true,
            onBack: onBack
        )
    }
    
    /// Modal navigation with close button
    func appModalNavigation(
        title: String,
        subtitle: String? = nil,
        onClose: (() -> Void)? = nil
    ) -> some View {
        appNavigationBar(
            title: title,
            subtitle: subtitle,
            showCloseButton: true,
            onClose: onClose
        )
    }
}

// MARK: - Common Navigation Actions
public extension AppNavigationAction {
    static func save(action: @escaping () -> Void) -> AppNavigationAction {
        AppNavigationAction(
            icon: "checkmark",
            title: "Save",
            style: .primary,
            action: action
        )
    }
    
    static func cancel(action: @escaping () -> Void) -> AppNavigationAction {
        AppNavigationAction(
            icon: "xmark",
            title: "Cancel",
            style: .secondary,
            action: action
        )
    }
    
    static func edit(action: @escaping () -> Void) -> AppNavigationAction {
        AppNavigationAction(
            icon: "pencil",
            title: "Edit",
            style: .secondary,
            action: action
        )
    }
    
    static func delete(action: @escaping () -> Void) -> AppNavigationAction {
        AppNavigationAction(
            icon: "trash",
            title: "Delete",
            style: .destructive,
            action: action
        )
    }
    
    static func share(action: @escaping () -> Void) -> AppNavigationAction {
        AppNavigationAction(
            icon: "square.and.arrow.up",
            style: .standard,
            action: action
        )
    }
    
    static func more(action: @escaping () -> Void) -> AppNavigationAction {
        AppNavigationAction(
            icon: "ellipsis",
            style: .standard,
            action: action
        )
    }
    
    static func filter(action: @escaping () -> Void) -> AppNavigationAction {
        AppNavigationAction(
            icon: "line.3.horizontal.decrease",
            style: .standard,
            action: action
        )
    }
    
    static func search(action: @escaping () -> Void) -> AppNavigationAction {
        AppNavigationAction(
            icon: "magnifyingglass",
            style: .standard,
            action: action
        )
    }
}