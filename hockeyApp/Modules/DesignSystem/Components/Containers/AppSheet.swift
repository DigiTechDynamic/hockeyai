import SwiftUI

// MARK: - App Sheet Configuration
public struct AppSheet<Content: View> {
    public let title: String?
    public let showCloseButton: Bool
    public let detents: Set<PresentationDetent>
    public let dragIndicator: Visibility
    public let backgroundInteraction: PresentationBackgroundInteraction
    public let content: () -> Content
    
    public init(
        title: String? = nil,
        showCloseButton: Bool = true,
        detents: Set<PresentationDetent> = [.large],
        dragIndicator: Visibility = .automatic,
        backgroundInteraction: PresentationBackgroundInteraction = .automatic,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.showCloseButton = showCloseButton
        self.detents = detents
        self.dragIndicator = dragIndicator
        self.backgroundInteraction = backgroundInteraction
        self.content = content
    }
}

// MARK: - App Sheet Presets
public enum AppSheetPresets {
    /// Standard full-screen sheet
    public static func fullScreen<SheetContent: View>(
        title: String? = nil,
        showCloseButton: Bool = true,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> AppSheet<SheetContent> {
        AppSheet(
            title: title,
            showCloseButton: showCloseButton,
            detents: [.large],
            dragIndicator: .hidden,
            content: content
        )
    }
    
    /// Half-screen sheet with medium detent
    public static func halfScreen<SheetContent: View>(
        title: String? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> AppSheet<SheetContent> {
        AppSheet(
            title: title,
            showCloseButton: true,
            detents: [.medium, .large],
            dragIndicator: .visible,
            content: content
        )
    }
    
    /// Compact sheet for quick actions
    public static func compact<SheetContent: View>(
        title: String? = nil,
        height: CGFloat = 300,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> AppSheet<SheetContent> {
        AppSheet(
            title: title,
            showCloseButton: false,
            detents: [.height(height)],
            dragIndicator: .visible,
            backgroundInteraction: .enabled(upThrough: .height(height)),
            content: content
        )
    }
    
    /// Settings or configuration sheet
    public static func settings<SheetContent: View>(
        title: String = "Settings",
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> AppSheet<SheetContent> {
        AppSheet(
            title: title,
            showCloseButton: true,
            detents: [.medium, .large],
            dragIndicator: .hidden,
            content: content
        )
    }
}

// MARK: - Sheet Content Wrapper
private struct AppSheetContent<WrapperContent: View>: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    let sheet: AppSheet<WrapperContent>
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            if sheet.title != nil || sheet.showCloseButton {
                sheetHeader
            }
            
            // Content
            sheet.content()
        }
        .background(theme.background)
    }
    
    private var sheetHeader: some View {
        HStack {
            if let title = sheet.title {
                Text(title)
                    .font(theme.fonts.headline)
                    .foregroundColor(theme.text)
            }
            
            Spacer()
            
            if sheet.showCloseButton {
                AppCloseButton {
                    HapticManager.shared.playImpact(style: .light)
                    dismiss()
                }
            }
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.vertical, theme.spacing.md)
        .background(
            theme.surface
                .shadow(color: theme.divider.opacity(0.2), radius: 1, x: 0, y: 1)
        )
    }
}

// MARK: - View Extensions for App Sheets
public extension View {
    /// Present a standardized app sheet
    func appSheet<ViewContent: View>(
        _ sheet: AppSheet<ViewContent>,
        isPresented: Binding<Bool>
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            AppSheetContent(sheet: sheet)
                .presentationDetents(sheet.detents)
                .presentationDragIndicator(sheet.dragIndicator)
                .presentationBackgroundInteraction(sheet.backgroundInteraction)
        }
    }
    
    /// Present a simple app sheet with title and content
    func appSimpleSheet<ViewContent: View>(
        title: String,
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> ViewContent
    ) -> some View {
        self.appSheet(
            AppSheetPresets.settings(title: title, content: content),
            isPresented: isPresented
        )
    }
    
    /// Present a full-screen app sheet
    func appFullScreenSheet<ViewContent: View>(
        title: String? = nil,
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> ViewContent
    ) -> some View {
        self.fullScreenCover(isPresented: isPresented) {
            NavigationView {
                AppSheetContent(sheet: AppSheetPresets.fullScreen(title: title, content: content))
            }
        }
    }
    
    /// Present a compact action sheet
    func appActionSheet<ViewContent: View>(
        title: String? = nil,
        height: CGFloat = 300,
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> ViewContent
    ) -> some View {
        self.appSheet(
            AppSheetPresets.compact(title: title, height: height, content: content),
            isPresented: isPresented
        )
    }
    
    /// Present a half-screen sheet
    func appHalfSheet<ViewContent: View>(
        title: String? = nil,
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> ViewContent
    ) -> some View {
        self.appSheet(
            AppSheetPresets.halfScreen(title: title, content: content),
            isPresented: isPresented
        )
    }
}

// MARK: - Common Sheet Types
public extension View {
    /// Present a settings sheet
    func appSettingsSheet<ViewContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> ViewContent
    ) -> some View {
        self.appSimpleSheet(
            title: "Settings",
            isPresented: isPresented,
            content: content
        )
    }
    
    /// Present a filter/sort options sheet
    func appFilterSheet<ViewContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> ViewContent
    ) -> some View {
        self.appActionSheet(
            title: "Filter & Sort",
            height: 400,
            isPresented: isPresented,
            content: content
        )
    }
    
    /// Present an item picker sheet
    func appPickerSheet<ViewContent: View>(
        title: String = "Select Option",
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> ViewContent
    ) -> some View {
        self.appHalfSheet(
            title: title,
            isPresented: isPresented,
            content: content
        )
    }
}