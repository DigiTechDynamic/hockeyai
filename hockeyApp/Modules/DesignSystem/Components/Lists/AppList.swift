import SwiftUI

// MARK: - App List Component
public struct AppList<Content: View>: View {
    @Environment(\.theme) private var theme
    
    public let style: AppListStyle
    public let content: Content
    
    public init(
        style: AppListStyle = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.content = content()
    }
    
    public var body: some View {
        LazyVStack(spacing: style.itemSpacing) {
            content
        }
        .padding(style.contentPadding)
        .background(style.background(theme))
        .cornerRadius(style.cornerRadius(theme))
    }
}

// MARK: - App List Style
public enum AppListStyle {
    case standard
    case compact
    case settings
    case cards
    
    var itemSpacing: CGFloat {
        switch self {
        case .standard: return 12
        case .compact: return 6
        case .settings: return 16
        case .cards: return 16
        }
    }
    
    var contentPadding: EdgeInsets {
        switch self {
        case .standard: return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        case .compact: return EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        case .settings: return EdgeInsets(top: 20, leading: 16, bottom: 20, trailing: 16)
        case .cards: return EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0)
        }
    }
    
    func background(_ theme: AppTheme) -> Color {
        switch self {
        case .standard, .compact: return theme.background
        case .settings: return theme.surface
        case .cards: return theme.background.opacity(0)
        }
    }
    
    func cornerRadius(_ theme: AppTheme) -> CGFloat {
        switch self {
        case .standard, .compact, .settings: return theme.cornerRadius
        case .cards: return 0
        }
    }
}

// MARK: - App List Item
public struct AppListItem<Content: View>: View {
    @Environment(\.theme) private var theme
    
    public let content: Content
    public let style: AppListItemStyle
    public let onTap: (() -> Void)?
    
    public init(
        style: AppListItemStyle = .standard,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.onTap = onTap
        self.content = content()
    }
    
    public var body: some View {
        if let onTap = onTap {
            Button(action: onTap) {
                itemContent
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            itemContent
        }
    }
    
    private var itemContent: some View {
        HStack(spacing: theme.spacing.md) {
            content
        }
        .padding(style.itemPadding(theme))
        .background(style.background(theme))
        .cornerRadius(style.cornerRadius(theme))
        .overlay(
            RoundedRectangle(cornerRadius: style.cornerRadius(theme))
                .stroke(style.borderColor(theme), lineWidth: style.borderWidth)
        )
    }
}

// MARK: - App List Item Style
public enum AppListItemStyle {
    case standard
    case compact
    case settings
    case card
    
    func itemPadding(_ theme: AppTheme) -> EdgeInsets {
        switch self {
        case .standard: return EdgeInsets(top: theme.spacing.md, leading: theme.spacing.md, bottom: theme.spacing.md, trailing: theme.spacing.md)
        case .compact: return EdgeInsets(top: theme.spacing.sm, leading: theme.spacing.sm, bottom: theme.spacing.sm, trailing: theme.spacing.sm)
        case .settings: return EdgeInsets(top: theme.spacing.lg, leading: theme.spacing.md, bottom: theme.spacing.lg, trailing: theme.spacing.md)
        case .card: return EdgeInsets(top: theme.spacing.lg, leading: theme.spacing.lg, bottom: theme.spacing.lg, trailing: theme.spacing.lg)
        }
    }
    
    func background(_ theme: AppTheme) -> Color {
        switch self {
        case .standard, .compact: return theme.background
        case .settings: return theme.surface
        case .card: return theme.cardBackground
        }
    }
    
    func cornerRadius(_ theme: AppTheme) -> CGFloat {
        switch self {
        case .standard, .compact: return theme.cornerRadius / 2
        case .settings, .card: return theme.cornerRadius
        }
    }
    
    func borderColor(_ theme: AppTheme) -> Color {
        switch self {
        case .standard, .compact: return theme.divider.opacity(0.3)
        case .settings: return theme.divider.opacity(0.5)
        case .card: return theme.primary.opacity(0.1)
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .standard, .compact, .settings: return 0.5
        case .card: return 1
        }
    }
}

// MARK: - Convenience Extensions
public extension AppList {
    /// Standard list for general content
    static func standard<T: View>(@ViewBuilder content: @escaping () -> T) -> AppList<T> {
        AppList<T>(style: .standard, content: content)
    }
    
    /// Compact list for dense content
    static func compact<T: View>(@ViewBuilder content: @escaping () -> T) -> AppList<T> {
        AppList<T>(style: .compact, content: content)
    }
    
    /// Settings-style list with more spacing
    static func settings<T: View>(@ViewBuilder content: @escaping () -> T) -> AppList<T> {
        AppList<T>(style: .settings, content: content)
    }
    
    /// Card-based list layout
    static func cards<T: View>(@ViewBuilder content: @escaping () -> T) -> AppList<T> {
        AppList<T>(style: .cards, content: content)
    }
}

public extension AppListItem {
    /// Standard list item
    static func standard<T: View>(
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> T
    ) -> AppListItem<T> {
        AppListItem<T>(style: .standard, onTap: onTap, content: content)
    }
    
    /// Compact list item
    static func compact<T: View>(
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> T
    ) -> AppListItem<T> {
        AppListItem<T>(style: .compact, onTap: onTap, content: content)
    }
    
    /// Settings-style list item
    static func settings<T: View>(
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> T
    ) -> AppListItem<T> {
        AppListItem<T>(style: .settings, onTap: onTap, content: content)
    }
    
    /// Card-style list item
    static func card<T: View>(
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> T
    ) -> AppListItem<T> {
        AppListItem<T>(style: .card, onTap: onTap, content: content)
    }
}

// MARK: - Common List Item Components
public struct AppSettingsListItem: View {
    @Environment(\.theme) private var theme
    
    public let title: String
    public let subtitle: String?
    public let icon: String?
    public let accessoryView: AnyView?
    public let onTap: (() -> Void)?
    
    public init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        accessoryView: AnyView? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.accessoryView = accessoryView
        self.onTap = onTap
    }
    
    public var body: some View {
        let itemContent = HStack(spacing: theme.spacing.md) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(theme.fonts.headline)
                    .foregroundColor(theme.primary)
                    .frame(width: 24, height: 24)
            }
            
            VStack(alignment: .leading, spacing: theme.spacing.xs / 2) {
                Text(title)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.text)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Spacer()
            
            if let accessoryView = accessoryView {
                accessoryView
            } else if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding(AppListItemStyle.settings.itemPadding(theme))
        .background(AppListItemStyle.settings.background(theme))
        .cornerRadius(AppListItemStyle.settings.cornerRadius(theme))
        .overlay(
            RoundedRectangle(cornerRadius: AppListItemStyle.settings.cornerRadius(theme))
                .stroke(AppListItemStyle.settings.borderColor(theme), lineWidth: AppListItemStyle.settings.borderWidth)
        )
        
        if let onTap = onTap {
            Button(action: onTap) {
                itemContent
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            itemContent
        }
    }
}

public extension AnyView {
    static func toggle(_ binding: Binding<Bool>) -> AnyView {
        AnyView(Toggle("", isOn: binding).labelsHidden())
    }
    
    static func text(_ text: String) -> AnyView {
        AnyView(Text(text))
    }
}