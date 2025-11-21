import SwiftUI

// MARK: - Card Configuration
struct CardConfiguration {
    var style: CardStyle = .elevated
    var padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    var cornerRadius: CGFloat = AppSettings.Constants.Layout.cornerRadiusMedium
    var animation: Animation = .spring(response: 0.2, dampingFraction: 0.7)
    var hapticEnabled: Bool = true
    var shadowConfig: ShadowConfiguration? = ShadowConfiguration()
    var borderConfig: BorderConfiguration? = nil
    
    struct ShadowConfiguration {
        var color: Color = Color.black.opacity(0.08)
        var radius: CGFloat = 12
        var x: CGFloat = 0
        var y: CGFloat = 4
    }
    
    struct BorderConfiguration {
        var color: Color
        var width: CGFloat = 1
        var gradient: LinearGradient? = nil
    }
}

// MARK: - Card Style
enum CardStyle {
    case elevated
    case outlined
    case filled
    case glass
    case premium
    case gradient(colors: [Color])
    case neumorphic
    case minimal
    
    func configuration(theme: AppTheme) -> CardConfiguration {
        var config = CardConfiguration()
        
        switch self {
        case .elevated:
            config.shadowConfig = CardConfiguration.ShadowConfiguration(
                color: Color.black.opacity(0.08),
                radius: 12,
                x: 0,
                y: 4
            )
        case .outlined:
            config.shadowConfig = nil
            config.borderConfig = CardConfiguration.BorderConfiguration(
                color: theme.divider,
                width: 1
            )
        case .filled:
            config.shadowConfig = nil
        case .glass:
            config.shadowConfig = CardConfiguration.ShadowConfiguration(
                color: Color.black.opacity(0.1),
                radius: 10,
                x: 0,
                y: 5
            )
            config.borderConfig = CardConfiguration.BorderConfiguration(
                color: theme.divider.opacity(0.3),
                width: 1
            )
        case .premium:
            config.shadowConfig = CardConfiguration.ShadowConfiguration(
                color: theme.primary.opacity(0.2),
                radius: 20,
                x: 0,
                y: 10
            )
            config.borderConfig = CardConfiguration.BorderConfiguration(
                color: theme.primary,
                width: 1,
                gradient: theme.primaryGradient
            )
        case .gradient(let colors):
            config.shadowConfig = CardConfiguration.ShadowConfiguration(
                color: colors.first?.opacity(0.3) ?? Color.clear,
                radius: 15,
                x: 0,
                y: 8
            )
        case .neumorphic:
            config.shadowConfig = nil // Will be handled specially
        case .minimal:
            config.shadowConfig = nil
            config.padding = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        }
        
        return config
    }
}

// MARK: - Base Card Component
struct BaseCard<Header: View, Content: View>: View {
    @Environment(\.theme) var theme
    @State private var isPressed = false
    
    let header: Header?
    let content: Content
    var config: CardConfiguration
    var onTap: (() -> Void)?
    
    init(
        config: CardConfiguration = CardConfiguration(),
        header: Header? = nil,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.config = config
        self.header = header
        self.onTap = onTap
        self.content = content()
    }
    
    
    var cardBackground: some View {
        Group {
            switch config.style {
            case .elevated, .filled:
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .fill(theme.cardBackground)
                
            case .outlined:
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .fill(theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: config.cornerRadius)
                            .stroke(config.borderConfig?.color ?? theme.divider, 
                                   lineWidth: config.borderConfig?.width ?? 1)
                    )
                
            case .glass:
                ZStack {
                    RoundedRectangle(cornerRadius: config.cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: config.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.background.opacity(0.2),
                                    theme.background.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    if let borderConfig = config.borderConfig {
                        RoundedRectangle(cornerRadius: config.cornerRadius)
                            .stroke(borderConfig.color, lineWidth: borderConfig.width)
                    }
                }
                
            case .premium:
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .fill(theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: config.cornerRadius)
                            .stroke(config.borderConfig?.gradient ?? theme.primaryGradient,
                                   lineWidth: config.borderConfig?.width ?? 1)
                    )
                
            case .gradient(let colors):
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
            case .neumorphic:
                ZStack {
                    RoundedRectangle(cornerRadius: config.cornerRadius)
                        .fill(theme.surface)
                        .shadow(color: Color.white.opacity(0.8), radius: 10, x: -5, y: -5)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 5, y: 5)
                }
                
            case .minimal:
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .fill(theme.surface.opacity(0.5))
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let header = header {
                header
                    .padding(.bottom, -config.padding.top)
            }
            
            content
                .padding(config.padding)
        }
        .background(cardBackground)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .opacity(isPressed ? 0.9 : 1.0)
        .animation(config.animation, value: isPressed)
        .conditionalModifier(config.shadowConfig != nil) { view in
            view.shadow(
                color: config.shadowConfig!.color,
                radius: config.shadowConfig!.radius,
                x: config.shadowConfig!.x,
                y: config.shadowConfig!.y
            )
        }
        .onTapGesture {
            if let onTap = onTap {
                withAnimation(.spring(response: 0.2)) {
                    isPressed = true
                }
                
                if config.hapticEnabled {
                    SafeManagers.playHaptic(style: .light, intensity: 0.6)
                }
                
                onTap()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.2)) {
                        isPressed = false
                    }
                }
            }
        }
    }
}

// MARK: - Convenience Extensions
extension BaseCard {
    init(
        style: CardStyle = .elevated,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) where Header == EmptyView {
        let theme = ThemeManager.shared.activeTheme
        self.init(
            config: style.configuration(theme: theme),
            header: nil,
            onTap: onTap,
            content: content
        )
    }
}

// MARK: - View Extension for Conditional Modifiers
extension View {
    @ViewBuilder
    func conditionalModifier<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Common Card Templates
extension BaseCard {
    // Feature Card Template
    static func feature(
        title: String,
        subtitle: String,
        icon: String,
        primaryColor: Color,
        secondaryColor: Color? = nil,
        lastResult: String? = nil,
        onTap: @escaping () -> Void
    ) -> some View where Header == EmptyView, Content == FeatureCardContent {
        BaseCard(
            style: .elevated,
            onTap: onTap
        ) {
            FeatureCardContent(
                title: title,
                subtitle: subtitle,
                icon: icon,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor ?? primaryColor.opacity(0.7),
                lastResult: lastResult
            )
        }
    }
    
    // Stat Card Template
    static func stat(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String? = nil,
        trend: Double? = nil,
        style: CardStyle = .elevated
    ) -> some View where Header == EmptyView, Content == StatCardContent {
        BaseCard(style: style) {
            StatCardContent(
                title: title,
                value: value,
                subtitle: subtitle,
                icon: icon,
                trend: trend
            )
        }
    }
}

// MARK: - Feature Card Content
struct FeatureCardContent: View {
    @Environment(\.theme) var theme
    
    let title: String
    let subtitle: String
    let icon: String
    let primaryColor: Color
    let secondaryColor: Color
    let lastResult: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [primaryColor.opacity(0.3), secondaryColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 72, height: 72)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [primaryColor.opacity(0.1), secondaryColor.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(primaryColor)
                }
                
                Spacer()
                
                if let lastResult = lastResult {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("RECENT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(primaryColor)
                            .tracking(0.5)
                        
                        Text(lastResult)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.text)
                    }
                }
            }
            .padding(.bottom, theme.spacing.md)
            
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.text)
                
                Text(subtitle)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Stat Card Content
struct StatCardContent: View {
    @Environment(\.theme) var theme
    
    let title: String
    let value: String
    let subtitle: String?
    let icon: String?
    let trend: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                Spacer(minLength: 4)
                
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(theme.primary)
                        .font(.system(size: 16))
                }
            }
            
            Spacer(minLength: 0)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(theme.text)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                }
                
                if let trend = trend {
                    HStack(spacing: 3) {
                        Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10))
                        Text("\(abs(trend), specifier: "%.1f")%")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(trend > 0 ? theme.success : theme.error)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}