import SwiftUI

// MARK: - Camera Quality Tutorial
struct CameraQualityTutorial: View {
    @Binding var isShowing: Bool
    @Environment(\.theme) var theme
    @State private var dontShowAgain = false
    
    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Header
            VStack(spacing: theme.spacing.xs) {
                Image(systemName: "camera.badges")
                    .font(.system(size: 48))
                    .foregroundColor(theme.primary)
                
                Text("Quality Indicators")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(theme.text)
                
                Text("Get the best shots for AI analysis")
                    .font(.system(size: 16))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.top, theme.spacing.md)
            
            // Tutorial rows
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                TutorialRow(
                    icon: "dot.radiowaves.left.and.right",
                    color: theme.primary,
                    title: "Movement",
                    text: "Watch the bars react as you move"
                )
                
                TutorialRow(
                    icon: "sun.max.fill",
                    color: theme.primary,
                    title: "Brightness",
                    text: "Get tips for better lighting"
                )
            }
            .padding(.horizontal, theme.spacing.lg)
            
            // Status explanation
            VStack(spacing: theme.spacing.xs) {
                HStack(spacing: theme.spacing.lg) {
                    StatusIndicator(color: theme.success, label: "Good")
                    StatusIndicator(color: theme.error, label: "Needs Attention")
                }
                
                Text("Keep indicators green for best results!")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.top, theme.spacing.sm)
            
            // Don't show again checkbox
            HStack {
                Toggle(isOn: $dontShowAgain) {
                    Text("Don't show this again")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textSecondary)
                }
                .toggleStyle(CheckboxToggleStyle())
            }
            .padding(.top, theme.spacing.sm)
            
            // Got it button
            AppButton(
                title: "Got it!",
                action: {
                    if dontShowAgain {
                        UserDefaults.standard.set(true, forKey: "neverShowCameraQualityTutorial")
                    }
                    UserDefaults.standard.set(true, forKey: "hasSeenCameraQualityTutorial")
                    withAnimation(.easeOut(duration: 0.3)) {
                        isShowing = false
                    }
                },
                style: .primary,
                size: .medium
            )
            .padding(.horizontal, theme.spacing.lg)
            .padding(.bottom, theme.spacing.md)
        }
        .frame(maxWidth: 400)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.background)
                .shadow(color: Color.black.opacity(0.2), radius: 20, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.divider.opacity(0.3), lineWidth: 1)
        )
        .padding(theme.spacing.lg)
    }
}

// MARK: - Tutorial Row
private struct TutorialRow: View {
    let icon: String
    let color: Color
    let title: String
    let text: String
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: theme.spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.text)
                
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Status Indicator
private struct StatusIndicator: View {
    let color: Color
    let label: String
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(theme.textSecondary)
        }
    }
}

// MARK: - Checkbox Toggle Style
struct CheckboxToggleStyle: ToggleStyle {
    @Environment(\.theme) var theme
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: theme.spacing.xs) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .font(.system(size: 20))
                .foregroundColor(configuration.isOn ? theme.primary : theme.textSecondary)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}