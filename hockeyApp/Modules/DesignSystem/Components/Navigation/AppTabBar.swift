import SwiftUI

// MARK: - App Tab Bar
struct AppTabBar: View {
    @Environment(\.theme) var theme
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedTab: Int
    let tabs: [AppTab]
    
    @Namespace private var tabNamespace
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab buttons
            HStack(spacing: 0) {
                ForEach(tabs.indices, id: \.self) { index in
                    AppTabButton(
                        tab: tabs[index],
                        isSelected: selectedTab == index,
                        namespace: tabNamespace
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    }
                }
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
            .frame(height: 60) // Fixed bar height
            
            // Removed underline indicator to match app style
        }
        .background(
            // Dark Glass Effect - Matching Header Style
            ZStack {
                // Base dark layer with subtle blur
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(white: 0.11).opacity(0.95))
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                    )

                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )

                // Inner border for definition
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        Color.white.opacity(0.08),
                        lineWidth: 0.5
                    )
            }
            .overlay(
                // Outer subtle border
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        Color.black.opacity(0.3),
                        lineWidth: 1
                    )
            )
            // Subtle shadow for depth
            .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, theme.spacing.lg)
        .padding(.bottom, theme.spacing.xs)
    }
}

// MARK: - App Tab Button
struct AppTabButton: View {
    @Environment(\.theme) var theme
    @EnvironmentObject var themeManager: ThemeManager
    let tab: AppTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    @State private var animateIcon = false
    
    var body: some View {
        Button(action: {
            action()
            impact()
        }) {
            VStack(spacing: 4) {
                // Icon (crisp, consistent with app style)
                ZStack {
                    if isSelected {
                        Image(systemName: tab.selectedIcon)
                            .symbolRenderingMode(.monochrome)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.primary)
                            .shadow(color: theme.primary.opacity(0.35), radius: 6)
                    } else {
                        Image(systemName: tab.icon)
                            .symbolRenderingMode(.monochrome)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.textSecondary.opacity(0.85))
                    }
                }
                .frame(height: 24) // Fixed icon height to prevent shifts
                .scaleEffect(animateIcon ? 1.08 : 1.0)
                .animation(.spring(response: 0.28, dampingFraction: 0.8), value: animateIcon)

                // Title (no glow underline)
                Text(tab.title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(
                        isSelected ?
                        theme.primary :
                        theme.textSecondary
                    )
                    .opacity(isSelected ? 1 : 0.75)
                    .lineLimit(1) // Prevent wrapping
                    .truncationMode(.tail) // Shorten if too long
                    .frame(minHeight: 20) // Fixed label height for alignment
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .frame(minHeight: 50) // Minimum height for the entire tab item
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .onChange(of: isSelected) { newValue in
            if newValue {
                // Subtle bounce
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    animateIcon = true
                }
                
                // Reset after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
                        animateIcon = false
                    }
                }
            }
        }
    }
    
    private func impact() {
        // Haptics only; no sound on tab selection
        HapticManager.shared.playImpact(style: .light)
    }
}

// MARK: - App Tab Model
struct AppTab {
    let title: String
    let icon: String
    let selectedIcon: String
}

// MARK: - Common Tab Examples
extension AppTab {
    // Example tabs that can be used as reference
    static let homeTab = AppTab(title: "Home", icon: "house", selectedIcon: "house.fill")
    static let searchTab = AppTab(title: "Search", icon: "magnifyingglass", selectedIcon: "magnifyingglass")
    static let profileTab = AppTab(title: "Profile", icon: "person", selectedIcon: "person.fill")
    static let settingsTab = AppTab(title: "Settings", icon: "gear", selectedIcon: "gear")
    static let activityTab = AppTab(title: "Activity", icon: "figure.walk", selectedIcon: "figure.walk")
}
