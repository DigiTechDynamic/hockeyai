import SwiftUI


// MARK: - Hockey Main View
struct HockeyMainView: View {
    @Environment(\.theme) var theme
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var monetization = MonetizationManager.shared
    @State private var selectedTab = 0
    @State private var showSettings = false
    @State private var previousTab = 0
    @State private var profileImage: UIImage?
    @State private var showSoftUpsell = false
    @State private var isHeaderVisible = true
    @Namespace private var headerAnimation
    @State private var showPaywallFromHeader = false
    // Trigger per-tab entrance animations without recreating views
    @State private var tabEntranceTick: [Int] = Array(repeating: 0, count: 3)
    
    var body: some View {
        ZStack {
            HockeyAppShellView(
                header: MinimalFloatingHeader(
                    profileImage: profileImage,
                    userInitials: userInitials,
                    onProfileTap: { showSettings = true },
                    isVisible: isHeaderVisible,
                    pageTitle: tabTitle,
                    showProCTA: showHeaderProCTA,
                    proCTALabel: "Go Pro",
                    proCTAMode: .pill,
                    onProCTATap: { handleHeaderProCTATap() }
                ),
                tabs: EmptyView(),
                content: content,
                bottom: tabs
            )
        }
        .fullScreenCover(isPresented: $showSettings) {
            SheetContainer(
                title: "Profile",
                onDismiss: { showSettings = false }
            ) {
                ProfileView()
            }
            .environmentObject(themeManager)
            .environmentObject(authManager)
        }
        .onAppear {
            loadProfileImage()
            checkForTeamSelector()
            // Prime entrance animations for the initial tab
            incrementEntranceTick(for: selectedTab)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            loadProfileImage()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ProfileImageUpdated"))) { _ in
            loadProfileImage()
        }
        .fullScreenCover(isPresented: $showSoftUpsell) {
            SoftOnboardingUpsellView()
                .preferredColorScheme(.dark)
        }
        .fullScreenCover(isPresented: $showPaywallFromHeader) {
            PaywallPresenter(source: headerPaywallSource)
                .preferredColorScheme(.dark)
        }
    }
    
    // MARK: - Tabs
    private var tabs: some View {
        AppTabBar(
            selectedTab: $selectedTab,
            tabs: [
                AppTab(title: "Home", icon: "house", selectedIcon: "house.fill"),
                AppTab(title: "AI Coach", icon: "brain", selectedIcon: "brain"),
                AppTab(title: "Equipment", icon: "hockey.puck", selectedIcon: "hockey.puck.fill")
            ]
        )
    }
    
    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        ZStack {
            ForEach(0..<3) { index in
                Group {
                    switch index {
                    case 0:
                        HomeView()
                    case 1:
                        AICoachView()
                    case 2:
                        EquipmentView()
                    default: EmptyView()
                    }
                }
                // Provide a per-tab animation trigger via environment
                .environment(\.entranceAnimationTrigger, tabEntranceTick[index])
                .opacity(selectedTab == index ? 1 : 0)
                .scaleEffect(selectedTab == index ? 1 : 0.95)
                .offset(y: selectedTab == index ? 0 : 20)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
                .zIndex(selectedTab == index ? 1 : 0)
            }
        }
        .onChange(of: selectedTab) { _ in
            // Show header when changing tabs
            withAnimation(.easeIn(duration: 0.2)) {
                isHeaderVisible = true
            }
            // Trigger entrance animations for the newly selected tab
            incrementEntranceTick(for: selectedTab)
        }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let threshold: CGFloat = 50
                    let horizontalAmount = abs(value.translation.width)
                    let verticalAmount = abs(value.translation.height)
                    
                    // Only trigger if horizontal swipe is dominant
                    if horizontalAmount > verticalAmount {
                        if value.translation.width > threshold && selectedTab > 0 {
                            // Swipe right - go to previous tab
                            selectedTab -= 1
                        } else if value.translation.width < -threshold && selectedTab < 2 {
                            // Swipe left - go to next tab
                            selectedTab += 1
                        }
                    }
                }
        )
        .onChange(of: selectedTab) { newValue in
            // Provide haptic feedback when switching tabs
            if newValue != previousTab {
                HapticManager.shared.playImpact(style: .light)
                previousTab = newValue
            }
        }
    }
    
    
    // MARK: - Helpers
    private var userInitials: String {
        let name = authManager.currentUser?.displayName ?? "P"
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let firstInitial = components[0].first ?? Character("P")
            let secondInitial = components[1].first ?? Character("")
            return "\(firstInitial)\(secondInitial)"
        } else {
            return String(name.prefix(2))
        }
    }
    
    private var tabTitle: String {
        switch selectedTab {
        case 0: return "Home"
        case 1: return "AI Coach"
        case 2: return "Equipment"
        default: return "Hockey AI"
        }
    }

    private var showHeaderProCTA: Bool {
        (selectedTab == 1 || selectedTab == 2) && !monetization.isPremium
    }

    private func handleHeaderProCTATap() {
        // Optional analytics for tap
        let source: String
        switch selectedTab {
        case 1: source = "ai_coach"
        case 2: source = "equipment"
        default: source = "home_screen"
        }
        AnalyticsManager.shared.track(eventName: "header_pro_cta_tapped", properties: ["source": source])
        showPaywallFromHeader = true
    }

    private var headerPaywallSource: String {
        // Use go_pro_header to distinguish from feature gates
        return "go_pro_header"
    }
    
    
    // MARK: - Load Profile Image
    private func loadProfileImage() {
        if let imageData = UserDefaults.standard.data(forKey: "profileImageData"),
           let image = UIImage(data: imageData) {
            profileImage = image
        }
    }
    
    // MARK: - Check for Post-Onboarding Flow
    private func checkForTeamSelector() {
        // MONETIZATION OPTIMIZATION: Show soft upsell immediately with no delay
        // Team selector removed to prevent interrupting monetization flow
        if UserDefaults.standard.bool(forKey: "showSoftUpsellAfterOnboarding") {
            UserDefaults.standard.set(false, forKey: "showSoftUpsellAfterOnboarding")
            // Show immediately - no delay
            showSoftUpsell = true
        }
    }

    private func incrementEntranceTick(for index: Int) {
        guard index >= 0 && index < tabEntranceTick.count else { return }
        tabEntranceTick[index] &+= 1
    }
}

