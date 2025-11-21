import SwiftUI

// MARK: - Unified Modal System
/// A consolidated modal system for alerts, sheets, toasts, and overlays

// MARK: - Modal Types
public enum ModalType: Identifiable {
    case alert(AlertConfiguration)
    case sheet(SheetConfiguration)
    case toast(ToastConfiguration)
    case fullScreen(FullScreenConfiguration)
    case bottomDrawer(BottomDrawerConfiguration)
    
    public var id: String {
        switch self {
        case .alert(let config):
            return "alert-\(config.title)"
        case .sheet(let config):
            return "sheet-\(config.title ?? "untitled")"
        case .toast(let config):
            return "toast-\(config.message)"
        case .fullScreen:
            return "fullScreen"
        case .bottomDrawer(let config):
            return "bottomDrawer-\(config.title ?? "untitled")"
        }
    }
}

// MARK: - Alert Configuration
public struct AlertConfiguration {
    let title: String
    let message: String?
    let style: AlertStyle
    let primaryButton: ModalButton
    let secondaryButton: ModalButton?
    
    public enum AlertStyle {
        case `default`
        case success
        case warning
        case error
        case destructive
    }
    
    public init(
        title: String,
        message: String? = nil,
        style: AlertStyle = .default,
        primaryButton: ModalButton,
        secondaryButton: ModalButton? = nil
    ) {
        self.title = title
        self.message = message
        self.style = style
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }
}

// MARK: - Sheet Configuration
public struct SheetConfiguration {
    let content: AnyView
    let title: String?
    let showsCloseButton: Bool
    let showsDragIndicator: Bool
    let detents: Set<PresentationDetent>
    let dismissOnDrag: Bool
    
    public init<Content: View>(
        @ViewBuilder content: () -> Content,
        title: String? = nil,
        showsCloseButton: Bool = true,
        showsDragIndicator: Bool = true,
        detents: Set<PresentationDetent> = [.medium, .large],
        dismissOnDrag: Bool = true
    ) {
        self.content = AnyView(content())
        self.title = title
        self.showsCloseButton = showsCloseButton
        self.showsDragIndicator = showsDragIndicator
        self.detents = detents
        self.dismissOnDrag = dismissOnDrag
    }
}

// MARK: - Toast Configuration
public struct ToastConfiguration {
    let message: String
    let icon: String?
    let style: ToastStyle
    let duration: TimeInterval
    let position: ToastPosition
    let hapticFeedback: UINotificationFeedbackGenerator.FeedbackType?
    
    public enum ToastStyle {
        case info
        case success
        case warning
        case error
    }
    
    public enum ToastPosition {
        case top
        case center
        case bottom
    }
    
    public init(
        message: String,
        icon: String? = nil,
        style: ToastStyle = .info,
        duration: TimeInterval = 3.0,
        position: ToastPosition = .top,
        hapticFeedback: UINotificationFeedbackGenerator.FeedbackType? = nil
    ) {
        self.message = message
        self.icon = icon
        self.style = style
        self.duration = duration
        self.position = position
        self.hapticFeedback = hapticFeedback
    }
}

// MARK: - Full Screen Configuration
public struct FullScreenConfiguration {
    let content: AnyView
    let showsCloseButton: Bool
    let backgroundStyle: BackgroundStyle
    
    public enum BackgroundStyle {
        case solid
        case blur
        case dimmed
    }
    
    public init<Content: View>(
        @ViewBuilder content: () -> Content,
        showsCloseButton: Bool = true,
        backgroundStyle: BackgroundStyle = .solid
    ) {
        self.content = AnyView(content())
        self.showsCloseButton = showsCloseButton
        self.backgroundStyle = backgroundStyle
    }
}

// MARK: - Bottom Drawer Configuration
public struct BottomDrawerConfiguration {
    let content: AnyView
    let title: String?
    let showsDragIndicator: Bool
    let showsCloseButton: Bool
    let height: DrawerHeight
    
    public enum DrawerHeight {
        case fixed(CGFloat)
        case dynamic
        case percentage(CGFloat) // 0.0 to 1.0
    }
    
    public init<Content: View>(
        @ViewBuilder content: () -> Content,
        title: String? = nil,
        showsDragIndicator: Bool = true,
        showsCloseButton: Bool = false,
        height: DrawerHeight = .dynamic
    ) {
        self.content = AnyView(content())
        self.title = title
        self.showsDragIndicator = showsDragIndicator
        self.showsCloseButton = showsCloseButton
        self.height = height
    }
}

// MARK: - Modal Button
public struct ModalButton {
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    
    public enum ButtonStyle {
        case `default`
        case primary
        case secondary
        case destructive
        case cancel
    }
    
    public init(
        title: String,
        style: ButtonStyle = .default,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.action = action
    }
}

// MARK: - Modal Manager
public class ModalManager: ObservableObject {
    @Published public var activeModal: ModalType?
    @Published public var toastQueue: [ToastConfiguration] = []
    
    public static let shared = ModalManager()
    
    private init() {}
    
    // MARK: - Show Methods
    public func showAlert(_ configuration: AlertConfiguration) {
        activeModal = .alert(configuration)
    }
    
    public func showSheet(_ configuration: SheetConfiguration) {
        activeModal = .sheet(configuration)
    }
    
    public func showToast(_ configuration: ToastConfiguration) {
        toastQueue.append(configuration)
        
        // Auto-dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + configuration.duration) { [weak self] in
            self?.dismissToast(configuration)
        }
        
        // Play haptic if specified
        if let haptic = configuration.hapticFeedback {
            SafeManagers.playNotificationHaptic(type: haptic)
        }
    }
    
    public func showFullScreen(_ configuration: FullScreenConfiguration) {
        activeModal = .fullScreen(configuration)
    }
    
    public func showBottomDrawer(_ configuration: BottomDrawerConfiguration) {
        activeModal = .bottomDrawer(configuration)
    }
    
    // MARK: - Dismiss Methods
    public func dismiss() {
        activeModal = nil
    }
    
    private func dismissToast(_ toast: ToastConfiguration) {
        toastQueue.removeAll { $0.message == toast.message }
    }
    
    // MARK: - Convenience Methods
    public func showSuccessToast(_ message: String) {
        showToast(ToastConfiguration(
            message: message,
            icon: "checkmark.circle.fill",
            style: .success,
            hapticFeedback: .success
        ))
    }
    
    public func showErrorToast(_ message: String) {
        showToast(ToastConfiguration(
            message: message,
            icon: "xmark.circle.fill",
            style: .error,
            hapticFeedback: .error
        ))
    }
    
    public func showConfirmationAlert(
        title: String,
        message: String? = nil,
        confirmTitle: String = "Confirm",
        cancelTitle: String = "Cancel",
        onConfirm: @escaping () -> Void
    ) {
        showAlert(AlertConfiguration(
            title: title,
            message: message,
            style: .default,
            primaryButton: ModalButton(title: confirmTitle, style: .primary, action: onConfirm),
            secondaryButton: ModalButton(title: cancelTitle, style: .cancel, action: dismiss)
        ))
    }
}

// MARK: - Modal Presenter View Modifier
struct ModalPresenterModifier: ViewModifier {
    @ObservedObject private var modalManager = ModalManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                // Toast overlay
                VStack(spacing: 8) {
                    ForEach(modalManager.toastQueue, id: \.message) { toast in
                        ToastView(configuration: toast)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.top, 24)
                .animation(.spring(), value: modalManager.toastQueue.count)
            }
            .sheet(item: Binding<ModalType?>(
                get: { modalManager.activeModal },
                set: { modalManager.activeModal = $0 }
            )) { modal in
                switch modal {
                case .sheet(let config):
                    SheetView(configuration: config)
                case .bottomDrawer(let config):
                    BottomDrawerView(configuration: config)
                default:
                    EmptyView()
                }
            }
            .fullScreenCover(isPresented: Binding<Bool>(
                get: { 
                    if case .fullScreen = modalManager.activeModal {
                        return true
                    }
                    return false
                },
                set: { _ in modalManager.dismiss() }
            )) {
                if case .fullScreen(let config) = modalManager.activeModal {
                    FullScreenView(configuration: config)
                }
            }
            .alert(isPresented: Binding<Bool>(
                get: {
                    if case .alert = modalManager.activeModal {
                        return true
                    }
                    return false
                },
                set: { _ in modalManager.dismiss() }
            )) {
                if case .alert(let config) = modalManager.activeModal {
                    createAlert(from: config)
                } else {
                    Alert(title: Text(""))
                }
            }
    }
    
    private func createAlert(from config: AlertConfiguration) -> Alert {
        if let secondaryButton = config.secondaryButton {
            return Alert(
                title: Text(config.title),
                message: config.message.map { Text($0) },
                primaryButton: createAlertButton(from: config.primaryButton),
                secondaryButton: createAlertButton(from: secondaryButton)
            )
        } else {
            return Alert(
                title: Text(config.title),
                message: config.message.map { Text($0) },
                dismissButton: createAlertButton(from: config.primaryButton)
            )
        }
    }
    
    private func createAlertButton(from button: ModalButton) -> Alert.Button {
        switch button.style {
        case .cancel:
            return .cancel(Text(button.title), action: button.action)
        case .destructive:
            return .destructive(Text(button.title), action: button.action)
        default:
            return .default(Text(button.title), action: button.action)
        }
    }
}

// MARK: - Component Views

// Toast View
private struct ToastView: View {
    @Environment(\.theme) var theme
    let configuration: ToastConfiguration
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon = configuration.icon {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
            }
            
            Text(configuration.message)
                .font(theme.fonts.body)
                .foregroundColor(theme.text)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .cornerRadius(AppSettings.Constants.Layout.cornerRadiusMedium)
        .shadow(
            color: UnifiedColorSystem.Effects.shadowDefault,
            radius: AppSettings.Constants.Layout.shadowRadiusMedium
        )
    }
    
    private var backgroundColor: Color {
        switch configuration.style {
        case .info:
            return theme.surface
        case .success:
            return theme.success.opacity(0.2)
        case .warning:
            return theme.warning.opacity(0.2)
        case .error:
            return theme.error.opacity(0.2)
        }
    }
    
    private var iconColor: Color {
        switch configuration.style {
        case .info:
            return theme.primary
        case .success:
            return theme.success
        case .warning:
            return theme.warning
        case .error:
            return theme.error
        }
    }
}

// Sheet View
private struct SheetView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    let configuration: SheetConfiguration
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            if configuration.showsDragIndicator || configuration.showsCloseButton || configuration.title != nil {
                VStack(spacing: 8) {
                    if configuration.showsDragIndicator {
                        Capsule()
                            .fill(theme.divider)
                            .frame(width: 40, height: 4)
                            .padding(.top, 8)
                    }
                    
                    if configuration.showsCloseButton || configuration.title != nil {
                        HStack {
                            if let title = configuration.title {
                                Text(title)
                                    .font(theme.fonts.headline)
                                    .foregroundColor(theme.text)
                            }
                            
                            Spacer()
                            
                            if configuration.showsCloseButton {
                                AppCloseButton { dismiss() }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
                .background(theme.surface)
            }
            
            // Content
            configuration.content
        }
        .presentationDetents(configuration.detents)
        .presentationDragIndicator(configuration.showsDragIndicator ? .visible : .hidden)
        .interactiveDismissDisabled(!configuration.dismissOnDrag)
        .background(theme.background)
    }
}

// Full Screen View
private struct FullScreenView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    let configuration: FullScreenConfiguration
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            // Content
            configuration.content
            
            // Close button
            if configuration.showsCloseButton {
                VStack {
                    HStack {
                        Spacer()
                        AppCloseButton { dismiss() }
                            .padding(16)
                    }
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch configuration.backgroundStyle {
        case .solid:
            theme.background
        case .blur:
            theme.background
                .overlay(.ultraThinMaterial)
        case .dimmed:
            theme.background.opacity(0.9)
        }
    }
}

// Bottom Drawer View
private struct BottomDrawerView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    let configuration: BottomDrawerConfiguration
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            if configuration.showsDragIndicator {
                Capsule()
                    .fill(theme.divider)
                    .frame(width: 40, height: 4)
                    .padding(.vertical, 8)
            }
            
            // Header
            if configuration.title != nil || configuration.showsCloseButton {
                HStack {
                    if let title = configuration.title {
                        Text(title)
                            .font(theme.fonts.headline)
                            .foregroundColor(theme.text)
                    }
                    
                    Spacer()
                    
                    if configuration.showsCloseButton {
                        AppCloseButton { dismiss() }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            
            // Content
            configuration.content
                .frame(maxHeight: drawerHeight)
        }
        .padding(.bottom, 16)
        .background(theme.surface)
        .cornerRadius(AppSettings.Constants.Layout.cornerRadiusLarge, corners: [.topLeft, .topRight])
        .shadow(
            color: UnifiedColorSystem.Effects.shadowDefault,
            radius: AppSettings.Constants.Layout.shadowRadiusLarge
        )
    }
    
    private var drawerHeight: CGFloat? {
        switch configuration.height {
        case .fixed(let height):
            return height
        case .dynamic:
            return nil
        case .percentage(let percentage):
            return UIScreen.main.bounds.height * percentage
        }
    }
}

// MARK: - View Extensions
public extension View {
    /// Apply the modal presenter to handle all modal types
    func modalPresenter() -> some View {
        modifier(ModalPresenterModifier())
    }
    
    /// Show a confirmation alert
    func confirmationAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        confirmTitle: String = "Confirm",
        cancelTitle: String = "Cancel",
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.onChange(of: isPresented.wrappedValue) { newValue in
            if newValue {
                ModalManager.shared.showConfirmationAlert(
                    title: title,
                    message: message,
                    confirmTitle: confirmTitle,
                    cancelTitle: cancelTitle,
                    onConfirm: {
                        onConfirm()
                        isPresented.wrappedValue = false
                    }
                )
            }
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}