import SwiftUI

// MARK: - Feature Row
/// A reusable row component for displaying feature items with icon and text
struct FeatureRow: View {
    @Environment(\.theme) var theme
    
    let icon: String
    let text: String
    var iconColor: Color?
    var textColor: Color?
    var iconSize: CGFloat = 14
    var spacing: CGFloat?
    
    var body: some View {
        HStack(spacing: spacing ?? theme.spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(iconColor ?? theme.primary)
                .frame(width: 20)
            
            Text(text)
                .font(theme.fonts.caption)
                .foregroundColor(textColor ?? theme.text)
            
            Spacer()
        }
    }
}

// MARK: - Convenience Initializers
extension FeatureRow {
    /// Create a feature row with primary theme color
    init(icon: String, text: String) {
        self.icon = icon
        self.text = text
    }
    
    /// Create a feature row with custom icon color
    init(icon: String, text: String, iconColor: Color) {
        self.icon = icon
        self.text = text
        self.iconColor = iconColor
    }
}

// MARK: - Enhanced Feature Row
/// A feature row with additional styling options
struct EnhancedFeatureRow: View {
    @Environment(\.theme) var theme
    
    let icon: String
    let title: String
    let subtitle: String?
    var iconColor: Color?
    var badge: String?
    var isNew: Bool = false
    
    var body: some View {
        HStack(spacing: theme.spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor?.opacity(0.1) ?? theme.primary.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor ?? theme.primary)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: theme.spacing.xs) {
                    Text(title)
                        .font(theme.fonts.body)
                        .foregroundColor(theme.text)
                    
                    if isNew {
                        TagView("NEW", color: theme.accent)
                    }
                    
                    if let badge = badge {
                        TagView(badge, color: theme.secondary)
                    }
                }
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.textSecondary.opacity(0.5))
        }
    }
}

// MARK: - Compact Feature Row
/// A minimal feature row for tight spaces
struct CompactFeatureRow: View {
    @Environment(\.theme) var theme
    
    let icon: String
    let text: String
    var iconColor: Color?
    
    var body: some View {
        HStack(spacing: theme.spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(iconColor ?? theme.primary)
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(theme.text)
                .lineLimit(1)
        }
    }
}

// MARK: - Feature List
/// A convenience container for multiple feature rows
struct FeatureList<Content: View>: View {
    @Environment(\.theme) var theme
    
    let content: Content
    var spacing: CGFloat?
    
    init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing ?? theme.spacing.sm) {
            content
        }
    }
}

// MARK: - Preview
#if DEBUG
struct FeatureRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Basic Feature Rows
            VStack(alignment: .leading) {
                Text("Basic Feature Rows")
                    .font(.headline)
                
                FeatureRow(icon: "star.fill", text: "Basic feature")
                FeatureRow(icon: "bolt.fill", text: "With custom color", iconColor: .orange)
                FeatureRow(icon: "heart.fill", text: "Another feature", iconColor: .red)
            }
            
            Divider()
            
            // Enhanced Feature Rows
            VStack(alignment: .leading) {
                Text("Enhanced Feature Rows")
                    .font(.headline)
                
                EnhancedFeatureRow(
                    icon: "wand.and.stars",
                    title: "AI Analysis",
                    subtitle: "Get instant feedback",
                    iconColor: .purple,
                    isNew: true
                )
                
                EnhancedFeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Performance Tracking",
                    subtitle: "Monitor your progress",
                    iconColor: .green,
                    badge: "PRO"
                )
            }
            
            Divider()
            
            // Compact Feature Rows
            VStack(alignment: .leading) {
                Text("Compact Feature Rows")
                    .font(.headline)
                
                HStack {
                    CompactFeatureRow(icon: "checkmark", text: "Quick")
                    CompactFeatureRow(icon: "bolt", text: "Fast", iconColor: .yellow)
                    CompactFeatureRow(icon: "star", text: "Easy", iconColor: .orange)
                }
            }
        }
        .padding()
    }
}
#endif