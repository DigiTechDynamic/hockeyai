import SwiftUI

// MARK: - Progress Style
public enum AppProgressStyle {
    case linear
    case circular
    case ring
    case miniRing
}

// MARK: - Progress Size
public enum AppProgressSize {
    case small
    case medium
    case large
    case custom(CGFloat)
    
    var diameter: CGFloat {
        switch self {
        case .small: return 40
        case .medium: return 60
        case .large: return 80
        case .custom(let size): return size
        }
    }
    
    var lineWidth: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        case .custom(let size): return size * 0.1
        }
    }
}

// MARK: - App Progress View
public struct AppProgressView: View {
    @Environment(\.theme) private var theme
    
    private let progress: Double
    private let style: AppProgressStyle
    private let size: AppProgressSize
    private let showPercentage: Bool
    private let animated: Bool
    private let gradient: Bool
    
    public init(
        progress: Double,
        style: AppProgressStyle = .circular,
        size: AppProgressSize = .medium,
        showPercentage: Bool = true,
        animated: Bool = true,
        gradient: Bool = false
    ) {
        self.progress = max(0, min(1, progress))
        self.style = style
        self.size = size
        self.showPercentage = showPercentage
        self.animated = animated
        self.gradient = gradient
    }
    
    public var body: some View {
        switch style {
        case .linear:
            linearProgressView
        case .circular:
            circularProgressView
        case .ring:
            ringProgressView
        case .miniRing:
            miniRingProgressView
        }
    }
    
    // MARK: - Linear Progress
    private var linearProgressView: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if showPercentage {
                HStack {
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: size.lineWidth / 2)
                        .fill(theme.divider.opacity(0.3))
                        .frame(height: size.lineWidth)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: size.lineWidth / 2)
                        .fill(progressFill)
                        .frame(
                            width: geometry.size.width * progress,
                            height: size.lineWidth
                        )
                        .animation(
                            animated ? .spring(response: 0.5, dampingFraction: 0.8) : .none,
                            value: progress
                        )
                }
            }
            .frame(height: size.lineWidth)
        }
    }
    
    // MARK: - Circular Progress (Filled)
    private var circularProgressView: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(theme.divider.opacity(0.3))
                .frame(width: size.diameter, height: size.diameter)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .fill(progressFill)
                .frame(width: size.diameter, height: size.diameter)
                .rotationEffect(.degrees(-90))
                .animation(
                    animated ? .spring(response: 0.5, dampingFraction: 0.8) : .none,
                    value: progress
                )
            
            if showPercentage {
                percentageText
            }
        }
    }
    
    // MARK: - Ring Progress (Stroke)
    private var ringProgressView: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(theme.divider.opacity(0.3), lineWidth: size.lineWidth)
                .frame(width: size.diameter, height: size.diameter)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressStroke,
                    style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round)
                )
                .frame(width: size.diameter, height: size.diameter)
                .rotationEffect(.degrees(-90))
                .animation(
                    animated ? .spring(response: 0.5, dampingFraction: 0.8) : .none,
                    value: progress
                )
            
            if showPercentage {
                percentageText
            }
        }
    }
    
    // MARK: - Mini Ring Progress (Small indicator)
    private var miniRingProgressView: some View {
        ZStack {
            Circle()
                .stroke(theme.divider.opacity(0.3), lineWidth: 3)
                .frame(width: 24, height: 24)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(theme.primary, lineWidth: 3)
                .frame(width: 24, height: 24)
                .rotationEffect(.degrees(-90))
                .animation(
                    animated ? .spring(response: 0.3, dampingFraction: 0.7) : .none,
                    value: progress
                )
        }
    }
    
    // MARK: - Helper Views
    private var percentageText: some View {
        VStack(spacing: 0) {
            Text("\(Int(progress * 100))")
                .font(percentageFont)
                .fontWeight(.bold)
                .foregroundColor(theme.text)
            Text("%")
                .font(theme.fonts.caption)
                .foregroundColor(theme.textSecondary)
        }
    }
    
    private var percentageFont: Font {
        switch size {
        case .small: return theme.fonts.callout
        case .medium: return theme.fonts.headline
        case .large: return theme.fonts.title
        case .custom(let size):
            return .system(size: size * 0.3, weight: .bold, design: .rounded)
        }
    }
    
    private var progressFill: AnyShapeStyle {
        if gradient {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [theme.primary, theme.accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(theme.primary)
        }
    }
    
    private var progressStroke: AnyShapeStyle {
        if gradient {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [theme.primary, theme.accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(theme.primary)
        }
    }
}

// MARK: - Convenience Initializers
public extension AppProgressView {
    /// Create a simple progress ring
    static func ring(
        progress: Double,
        size: AppProgressSize = .medium,
        showPercentage: Bool = true
    ) -> AppProgressView {
        AppProgressView(
            progress: progress,
            style: .ring,
            size: size,
            showPercentage: showPercentage
        )
    }
    
    /// Create a gradient progress ring
    static func gradientRing(
        progress: Double,
        size: AppProgressSize = .medium,
        showPercentage: Bool = true
    ) -> AppProgressView {
        AppProgressView(
            progress: progress,
            style: .ring,
            size: size,
            showPercentage: showPercentage,
            gradient: true
        )
    }
    
    /// Create a linear progress bar
    static func linear(
        progress: Double,
        showPercentage: Bool = false
    ) -> AppProgressView {
        AppProgressView(
            progress: progress,
            style: .linear,
            showPercentage: showPercentage
        )
    }
    
    /// Create a mini ring for compact spaces
    static func mini(progress: Double) -> AppProgressView {
        AppProgressView(
            progress: progress,
            style: .miniRing,
            showPercentage: false
        )
    }
}

// MARK: - Preview
#if DEBUG
struct AppProgressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 32) {
            // Linear Progress
            VStack(alignment: .leading, spacing: 16) {
                Text("Linear Progress")
                    .font(.headline)
                
                AppProgressView.linear(progress: 0.3, showPercentage: true)
                AppProgressView.linear(progress: 0.7, showPercentage: false)
            }
            
            // Ring Progress
            HStack(spacing: 32) {
                VStack {
                    Text("Small Ring")
                        .font(.caption)
                    AppProgressView.ring(progress: 0.65, size: .small)
                }
                
                VStack {
                    Text("Medium Ring")
                        .font(.caption)
                    AppProgressView.ring(progress: 0.75, size: .medium)
                }
                
                VStack {
                    Text("Large Ring")
                        .font(.caption)
                    AppProgressView.ring(progress: 0.85, size: .large)
                }
            }
            
            // Gradient Ring
            VStack {
                Text("Gradient Ring")
                    .font(.caption)
                AppProgressView.gradientRing(progress: 0.9)
            }
            
            // Mini Ring
            HStack(spacing: 16) {
                Text("Mini Progress:")
                AppProgressView.mini(progress: 0.4)
                AppProgressView.mini(progress: 0.8)
                AppProgressView.mini(progress: 1.0)
            }
            
            // Circular (Filled)
            VStack {
                Text("Filled Circle")
                    .font(.caption)
                AppProgressView(progress: 0.6, style: .circular)
            }
        }
        .padding()
        .environmentObject(ThemeManager.shared)
    }
}
#endif