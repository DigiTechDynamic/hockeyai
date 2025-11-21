import SwiftUI

// MARK: - Action Sheet Item
public struct ActionSheetItem: Identifiable {
    public let id = UUID()
    public let icon: String
    public let iconColor: Color
    public let gradientColors: [Color]
    public let title: String
    public let subtitle: String
    public let action: () -> Void
    
    public init(
        icon: String,
        iconColor: Color,
        gradientColors: [Color]? = nil,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.gradientColors = gradientColors ?? [iconColor, iconColor.opacity(0.7)]
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
}

// MARK: - Action Sheet Style
public enum ActionSheetStyle {
    case fullScreen
    case bottomSheet
}

// MARK: - Action Sheet Component
public struct ActionSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss
    
    private let title: String
    private let items: [ActionSheetItem]
    private let style: ActionSheetStyle
    private let showDragIndicator: Bool
    
    @State private var dragOffset: CGFloat = 0
    @State private var contentOpacity: Double = 0
    @State private var rowScales: [UUID: CGFloat] = [:]
    @State private var rowOpacities: [UUID: Double] = [:]
    
    public init(
        title: String,
        items: [ActionSheetItem],
        style: ActionSheetStyle = .bottomSheet,
        showDragIndicator: Bool = false
    ) {
        self.title = title
        self.items = items
        self.style = style
        self.showDragIndicator = showDragIndicator
    }
    
    public var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithHaptic()
                }
            
            // Content
            switch style {
            case .fullScreen:
                fullScreenContent
            case .bottomSheet:
                bottomSheetContent
            }
        }
        .onAppear {
            animateIn()
        }
    }
    
    // MARK: - Full Screen Content
    private var fullScreenContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.text)
                
                Spacer()
                
                // Close button
                Button(action: dismissWithHaptic) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(theme.surface.opacity(0.3))
                        )
                }
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.top, 60)
            .padding(.bottom, theme.spacing.xl)
            
            // Items
            ScrollView {
                VStack(spacing: theme.spacing.md) {
                    ForEach(items) { item in
                        ActionSheetRow(
                            item: item,
                            scale: rowScales[item.id] ?? 1.0,
                            opacity: rowOpacities[item.id] ?? 0
                        )
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, theme.spacing.xxl)
            }
        }
        .background(theme.background.ignoresSafeArea())
        .opacity(contentOpacity)
    }
    
    // MARK: - Bottom Sheet Content
    private var bottomSheetContent: some View {
        VStack(spacing: 0) {
            // Content container
            VStack(spacing: 0) {
                // Drag indicator
                if showDragIndicator {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.divider.opacity(0.4))
                        .frame(width: 40, height: 5)
                        .padding(.top, theme.spacing.sm)
                        .padding(.bottom, theme.spacing.xs)
                }
                
                // Header
                HStack {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(theme.text)
                    
                    Spacer()
                    
                    // Close button
                    Button(action: dismissWithHaptic) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(theme.surface.opacity(0.3))
                            )
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.vertical, theme.spacing.md)
                
                // Items
                VStack(spacing: theme.spacing.sm) {
                    ForEach(items) { item in
                        ActionSheetRow(
                            item: item,
                            scale: rowScales[item.id] ?? 1.0,
                            opacity: rowOpacities[item.id] ?? 0
                        )
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, theme.spacing.xl)
            }
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.cardBackground)
                    .ignoresSafeArea(edges: .bottom)
            )
            .offset(y: dragOffset)
            .gesture(
                showDragIndicator ? DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if value.translation.height > 100 {
                                dismissWithHaptic()
                            } else {
                                dragOffset = 0
                            }
                        }
                    } : nil
            )
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(edges: .bottom)
        .opacity(contentOpacity)
    }
    
    // MARK: - Helper Methods
    private func animateIn() {
        // Initialize states
        items.forEach { item in
            rowScales[item.id] = 0.8
            rowOpacities[item.id] = 0
        }
        
        // Animate content
        withAnimation(.easeOut(duration: 0.3)) {
            contentOpacity = 1
        }
        
        // Staggered row animations
        for (index, item) in items.enumerated() {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05)) {
                rowScales[item.id] = 1.0
                rowOpacities[item.id] = 1.0
            }
        }
    }
    
    private func dismissWithHaptic() {
        HapticManager.shared.playImpact(style: .light)
        dismiss()
    }
}

// MARK: - Action Sheet Row
private struct ActionSheetRow: View {
    @Environment(\.theme) var theme
    let item: ActionSheetItem
    let scale: CGFloat
    let opacity: Double
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playFeedback(.selection, haptic: .medium)
            item.action()
        }) {
            HStack(spacing: theme.spacing.md) {
                // Icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: item.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.text)
                    
                    Text(item.subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textSecondary.opacity(0.5))
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.surface.opacity(0.5))
            )
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - View Extension for Presentation
extension View {
    public func actionSheet(
        title: String,
        items: [ActionSheetItem],
        isPresented: Binding<Bool>,
        style: ActionSheetStyle = .bottomSheet,
        showDragIndicator: Bool = false
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            ActionSheet(
                title: title,
                items: items,
                style: style,
                showDragIndicator: showDragIndicator
            )
            .presentationDetents(style == .bottomSheet ? [.height(calculateSheetHeight(items: items))] : [.large])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(24)
            .presentationBackground(.clear)
        }
    }
}

// Helper to calculate sheet height
private func calculateSheetHeight(items: [ActionSheetItem]) -> CGFloat {
    // Base: header + padding
    var height: CGFloat = 120
    
    // Each item is approximately 84 points tall
    let itemHeight: CGFloat = 84
    height += CGFloat(items.count) * itemHeight
    
    // Bottom padding
    height += 40
    
    return height
}