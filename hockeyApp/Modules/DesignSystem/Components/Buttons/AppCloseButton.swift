import SwiftUI

struct AppCloseButton: View {
    @Environment(\.theme) var theme
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playFeedback(.uiTap, haptic: .light)
            action()
        }) {
            ZStack {
                Circle()
                    .fill(theme.surface)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(theme.divider, lineWidth: 1)
                    )
                
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}