import SwiftUI

// MARK: - Modal Convenience Extensions
/// Convenience methods for common modal presentations

public extension View {
    
    // MARK: - Alerts
    
    /// Show a simple information alert
    func infoAlert(
        _ title: String,
        message: String? = nil,
        buttonTitle: String = "OK"
    ) {
        ModalManager.shared.showAlert(AlertConfiguration(
            title: title,
            message: message,
            style: .default,
            primaryButton: ModalButton(title: buttonTitle, style: .primary) {
                ModalManager.shared.dismiss()
            }
        ))
    }
    
    /// Show an error alert
    func errorAlert(
        _ title: String = "Error",
        message: String,
        buttonTitle: String = "OK"
    ) {
        ModalManager.shared.showAlert(AlertConfiguration(
            title: title,
            message: message,
            style: .error,
            primaryButton: ModalButton(title: buttonTitle, style: .default) {
                ModalManager.shared.dismiss()
            }
        ))
    }
    
    /// Show a delete confirmation alert
    func deleteAlert(
        itemName: String,
        message: String? = nil,
        onDelete: @escaping () -> Void
    ) {
        let defaultMessage = message ?? "Are you sure you want to delete \(itemName)? This action cannot be undone."
        
        ModalManager.shared.showAlert(AlertConfiguration(
            title: "Delete \(itemName)?",
            message: defaultMessage,
            style: .destructive,
            primaryButton: ModalButton(title: "Delete", style: .destructive) {
                onDelete()
                ModalManager.shared.dismiss()
            },
            secondaryButton: ModalButton(title: "Cancel", style: .cancel) {
                ModalManager.shared.dismiss()
            }
        ))
    }
    
    // MARK: - Sheets
    
    /// Show a simple sheet with content
    func simpleSheet<Content: View>(
        title: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        ModalManager.shared.showSheet(SheetConfiguration(
            content: content,
            title: title
        ))
    }
    
    /// Show a settings sheet
    func settingsSheet<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) {
        ModalManager.shared.showSheet(SheetConfiguration(
            content: {
                VStack(spacing: 0) {
                    content()
                }
            },
            title: "Settings",
            detents: [.medium]
        ))
    }
    
    /// Show a picker sheet
    func pickerSheet<Content: View>(
        title: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        ModalManager.shared.showSheet(SheetConfiguration(
            content: content,
            title: title,
            showsCloseButton: true,
            detents: [.medium]
        ))
    }
    
    // MARK: - Bottom Drawers
    
    /// Show an action drawer with options
    func actionDrawer(
        title: String? = nil,
        actions: [(title: String, icon: String?, action: () -> Void)]
    ) {
        ModalManager.shared.showBottomDrawer(BottomDrawerConfiguration(
            content: {
                VStack(spacing: 0) {
                    ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                        Button(action: {
                            action.action()
                            ModalManager.shared.dismiss()
                        }) {
                            HStack(spacing: 16) {
                                if let icon = action.icon {
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .frame(width: 24)
                                }
                                
                                Text(action.title)
                                    .font(.system(size: 17))
                                
                                Spacer()
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                        
                        if index < actions.count - 1 {
                            Divider()
                                .padding(.leading, 24)
                        }
                    }
                }
            },
            title: title,
            height: .dynamic
        ))
    }
    
    // MARK: - Toasts
    
    /// Show a success toast
    func successToast(_ message: String) {
        ModalManager.shared.showSuccessToast(message)
    }
    
    /// Show an error toast
    func errorToast(_ message: String) {
        ModalManager.shared.showErrorToast(message)
    }
    
    /// Show an info toast
    func infoToast(_ message: String) {
        ModalManager.shared.showToast(ToastConfiguration(
            message: message,
            icon: "info.circle.fill",
            style: .info
        ))
    }
    
    /// Show a warning toast
    func warningToast(_ message: String) {
        ModalManager.shared.showToast(ToastConfiguration(
            message: message,
            icon: "exclamationmark.triangle.fill",
            style: .warning,
            hapticFeedback: .warning
        ))
    }
    
    // MARK: - Full Screen
    
    /// Show a full screen modal
    func fullScreenModal<Content: View>(
        showsCloseButton: Bool = true,
        backgroundStyle: FullScreenConfiguration.BackgroundStyle = .solid,
        @ViewBuilder content: @escaping () -> Content
    ) {
        ModalManager.shared.showFullScreen(FullScreenConfiguration(
            content: content,
            showsCloseButton: showsCloseButton,
            backgroundStyle: backgroundStyle
        ))
    }
}

// MARK: - Static Modal Methods
/// Static methods for showing modals from anywhere in the app
public struct Modal {
    
    // MARK: - Alerts
    
    /// Show a confirmation alert
    public static func confirm(
        title: String,
        message: String? = nil,
        confirmTitle: String = "Confirm",
        cancelTitle: String = "Cancel",
        onConfirm: @escaping () -> Void
    ) {
        ModalManager.shared.showConfirmationAlert(
            title: title,
            message: message,
            confirmTitle: confirmTitle,
            cancelTitle: cancelTitle,
            onConfirm: onConfirm
        )
    }
    
    /// Show an info alert
    public static func info(
        _ title: String,
        message: String? = nil
    ) {
        ModalManager.shared.showAlert(AlertConfiguration(
            title: title,
            message: message,
            style: .default,
            primaryButton: ModalButton(title: "OK", style: .primary) {
                ModalManager.shared.dismiss()
            }
        ))
    }
    
    /// Show an error alert
    public static func error(
        _ message: String,
        title: String = "Error"
    ) {
        ModalManager.shared.showAlert(AlertConfiguration(
            title: title,
            message: message,
            style: .error,
            primaryButton: ModalButton(title: "OK", style: .default) {
                ModalManager.shared.dismiss()
            }
        ))
    }
    
    // MARK: - Toasts
    
    /// Show a success toast
    public static func success(_ message: String) {
        ModalManager.shared.showSuccessToast(message)
    }
    
    /// Show an error toast
    public static func error(toast message: String) {
        ModalManager.shared.showErrorToast(message)
    }
    
    /// Show an info toast
    public static func info(toast message: String) {
        ModalManager.shared.showToast(ToastConfiguration(
            message: message,
            icon: "info.circle.fill",
            style: .info
        ))
    }
    
    /// Show a warning toast
    public static func warning(_ message: String) {
        ModalManager.shared.showToast(ToastConfiguration(
            message: message,
            icon: "exclamationmark.triangle.fill",
            style: .warning,
            hapticFeedback: .warning
        ))
    }
    
    // MARK: - Sheets
    
    /// Show a sheet
    public static func sheet<Content: View>(
        title: String? = nil,
        showsCloseButton: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        ModalManager.shared.showSheet(SheetConfiguration(
            content: content,
            title: title,
            showsCloseButton: showsCloseButton
        ))
    }
    
    /// Show a bottom drawer
    public static func bottomDrawer<Content: View>(
        title: String? = nil,
        height: BottomDrawerConfiguration.DrawerHeight = .dynamic,
        @ViewBuilder content: @escaping () -> Content
    ) {
        ModalManager.shared.showBottomDrawer(BottomDrawerConfiguration(
            content: content,
            title: title,
            height: height
        ))
    }
    
    /// Show a full screen modal
    public static func fullScreen<Content: View>(
        showsCloseButton: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        ModalManager.shared.showFullScreen(FullScreenConfiguration(
            content: content,
            showsCloseButton: showsCloseButton
        ))
    }
    
    /// Dismiss the current modal
    public static func dismiss() {
        ModalManager.shared.dismiss()
    }
}

// MARK: - Example Usage
/*
 
 // From a View:
 Button("Show Alert") {
     self.infoAlert("Hello", message: "This is a test alert")
 }
 
 Button("Delete Item") {
     self.deleteAlert(itemName: "Photo") {
         // Delete logic here
     }
 }
 
 Button("Show Toast") {
     self.successToast("Item saved successfully!")
 }
 
 // From anywhere in the app:
 Modal.success("Profile updated!")
 
 Modal.confirm(
     title: "Delete Account?",
     message: "This action cannot be undone.",
     onConfirm: {
         // Delete account logic
     }
 )
 
 Modal.sheet(title: "Select Option") {
     // Sheet content
 }
 
 */