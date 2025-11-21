import SwiftUI

// MARK: - Sheet Presentation Modifier
struct SheetPresentationModifier: ViewModifier {
    @Environment(\.theme) var theme
    let detents: Set<PresentationDetent>
    let showDragIndicator: Bool
    
    init(detents: Set<PresentationDetent> = [.large], showDragIndicator: Bool = true) {
        self.detents = detents
        self.showDragIndicator = showDragIndicator
    }
    
    func body(content: Content) -> some View {
        content
            .presentationDetents(detents)
            .presentationDragIndicator(showDragIndicator ? .visible : .hidden)
            .presentationCornerRadius(theme.cornerRadius * 1.5)
            .presentationBackground {
                theme.background
                    .overlay(
                        LinearGradient(
                            colors: [
                                theme.surface.opacity(0.3),
                                theme.background
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
    }
}

// MARK: - View Extension
extension View {
    func appSheetPresentation(
        detents: Set<PresentationDetent> = [.large],
        showDragIndicator: Bool = true
    ) -> some View {
        self.modifier(SheetPresentationModifier(
            detents: detents,
            showDragIndicator: showDragIndicator
        ))
    }
}

// MARK: - Sheet Header Component
struct SheetHeader: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    
    let title: String
    var subtitle: String? = nil
    var showCloseButton: Bool = true
    var trailingContent: (() -> AnyView)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Indicator
            Capsule()
                .fill(theme.divider)
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, theme.spacing.sm)
            
            // Header Content
            HStack(alignment: .center) {
                // Close Button or Back Button
                if showCloseButton {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(theme.textSecondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Title Section
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(theme.fonts.headline)
                        .foregroundColor(theme.text)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(theme.fonts.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Trailing Content
                if let trailingContent = trailingContent {
                    trailingContent()
                }
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.bottom, theme.spacing.md)
            
            // Divider
            Rectangle()
                .fill(theme.divider)
                .frame(height: 1)
        }
        .background(theme.background)
    }
}