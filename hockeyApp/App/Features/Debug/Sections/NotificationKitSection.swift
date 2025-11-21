import SwiftUI

// Simple notification test section for debugging
struct NotificationKitSection: View {
    @Environment(\.theme) var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("NotificationKit Test")
                    .font(.title2)
                    .bold()
                    .padding(.horizontal)
                    .padding(.top)

                // Info Card
                VStack(alignment: .leading, spacing: 12) {
                    Label("Notifications are handled automatically", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)

                    Text("NotificationKit manages all notifications internally")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)

                // Test Button
            VStack(spacing: 16) {
                Text("Test Notification")
                    .font(.headline)

                Button(action: sendTestNotification) {
                    Label("Send Test Notification", systemImage: "bell.badge")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Text("Tap button, minimize app, then tap the notification")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

                Spacer(minLength: 50)
            }
        }
    }

    private func sendTestNotification() {
        Task {
            // Request permission first
            let granted = await NotificationKit.requestPermission()

            if granted {
                // Send test notification
                NotificationKit.sendShotAnalysisNotification(
                    shotType: "Test Shot",
                    score: 95,
                    delay: 3
                )

                // Show alert
                await MainActor.run {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        let alert = UIAlertController(
                            title: "Test Notification Sent",
                            message: "Minimize the app now and wait 3 seconds for the notification",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        window.rootViewController?.present(alert, animated: true)
                    }
                }
            } else {
                // Permission denied
                await MainActor.run {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        let alert = UIAlertController(
                            title: "Notifications Disabled",
                            message: "Please enable notifications in Settings to test this feature",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        window.rootViewController?.present(alert, animated: true)
                    }
                }
            }
        }
    }

}
