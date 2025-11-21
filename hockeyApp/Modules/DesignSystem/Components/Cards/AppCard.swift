import SwiftUI

// MARK: - AppCard Compatibility Layer
// This provides backward compatibility for existing code using AppCard
// All functionality is now provided by BaseCard

typealias AppCardStyle = CardStyle

struct AppCard<Content: View>: View {
    @Environment(\.theme) var theme
    
    let content: Content
    var style: CardStyle = .elevated
    var padding: CGFloat?
    var onTap: (() -> Void)?
    var enableHaptics: Bool = true
    
    init(style: CardStyle = .elevated, padding: CGFloat? = nil, onTap: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.style = style
        self.padding = padding
        self.onTap = onTap
    }
    
    var body: some View {
        BaseCard(style: style, onTap: onTap) {
            content
                .conditionalModifier(padding != nil) { view in
                    view.padding(padding! - theme.spacing.md) // Adjust for BaseCard's default padding
                }
        }
    }
}

// Convenience modifiers
extension AppCard {
    func cardStyle(_ style: AppCardStyle) -> some View {
        AppCard(style: style, padding: padding, onTap: onTap) { content }
    }
    
    func cardPadding(_ padding: CGFloat) -> some View {
        AppCard(style: style, padding: padding, onTap: onTap) { content }
    }
    
    func onTapGesture(perform action: @escaping () -> Void) -> some View {
        AppCard(style: style, padding: padding, onTap: action) { content }
    }
    
    func haptics(_ enabled: Bool) -> AppCard {
        var card = AppCard(style: style, padding: padding, onTap: onTap) { content }
        card.enableHaptics = enabled
        return card
    }
}

// Stat Card Component (commonly used) - Now uses BaseCard
struct AppStatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String?
    let trend: Double?
    var style: CardStyle = .elevated
    
    init(title: String, value: String, subtitle: String? = nil, icon: String? = nil, trend: Double? = nil, style: CardStyle = .elevated) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.trend = trend
        self.style = style
    }
    
    var body: some View {
        BaseCard.stat(
            title: title,
            value: value,
            subtitle: subtitle,
            icon: icon,
            trend: trend,
            style: style
        )
        .aspectRatio(1, contentMode: .fit)
        .frame(maxHeight: 140)
    }
}