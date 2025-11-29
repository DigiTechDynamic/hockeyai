import SwiftUI
import PhotosUI

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) private var theme
    @StateObject private var viewModel: ProfileViewModel
    @StateObject private var monetization = MonetizationManager.shared

    // Popup state
    @State private var showingHeightPopup = false
    @State private var showingWeightPopup = false
    @State private var showingAgePopup = false
    @State private var showingGenderPopup = false
    @State private var showingPositionPopup = false
    @State private var showingHandednessPopup = false
    @State private var showingPlayStylePopup = false
    @State private var showingJerseyNumberPopup = false
    @State private var showingTeamSelector = false

    // Focus states
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isAgeFocused: Bool
    @FocusState private var isNameFocused: Bool

    // Device specific layout
    private var isIPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var contentMaxWidth: CGFloat { isIPad ? 700 : .infinity }
    private var horizontalPadding: CGFloat { isIPad ? 40 : 20 }

    init() {
        _viewModel = StateObject(wrappedValue: ProfileViewModel())
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.xxl) {
                    // Profile Header with Photo
                    ProfileHeaderSection(viewModel: viewModel)

                    // Personal Information
                    PersonalInfoSection(viewModel: viewModel)

                    // Physical Attributes
                    physicalAttributesSection

                    // Hockey Profile
                    hockeyProfileSection

                    // Body Scan
                    BodyScanCard()

                    // App Settings
                    appSettingsSection

                    // Privacy Policy Section
                    privacyPolicySection

                    // Reset App Section
                    deleteAccountSection
                }
                .frame(maxWidth: contentMaxWidth)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, theme.spacing.lg)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .confirmationDialog("Profile Photo", isPresented: $viewModel.showingPhotoOptions) {
            Button("Take Photo") {
                viewModel.mediaSourceType = .camera
                viewModel.showingCustomCamera = true
            }
            Button("Choose from Library") {
                viewModel.mediaSourceType = .photoLibrary
                viewModel.showingMediaPicker = true
            }
            if viewModel.profileImage != nil {
                Button("Remove Photo", role: .destructive) {
                    viewModel.profileImage = nil
                    ProfileImageService.shared.removeImage()
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showingHeightPopup) {
            ProfileConfigSheet(viewModel: viewModel, kind: .height)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingWeightPopup) {
            ProfileConfigSheet(viewModel: viewModel, kind: .weight)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAgePopup) {
            ProfileConfigSheet(viewModel: viewModel, kind: .age)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingGenderPopup) {
            ProfileConfigSheet(viewModel: viewModel, kind: .gender)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingPositionPopup) {
            ProfileConfigSheet(viewModel: viewModel, kind: .position)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingHandednessPopup) {
            ProfileConfigSheet(viewModel: viewModel, kind: .handedness)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingPlayStylePopup) {
            ProfileConfigSheet(viewModel: viewModel, kind: .playStyle)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingJerseyNumberPopup) {
            ProfileConfigSheet(viewModel: viewModel, kind: .jerseyNumber)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingTeamSelector) {
            NHLTeamSelectorSheet()
        }
    }

    // MARK: - Physical Attributes Section
    private var physicalAttributesSection: some View {
        ProfileSectionCard {
            VStack(spacing: theme.spacing.lg) {
                // Section Header with Unit Toggle
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "figure.stand")
                            .font(theme.fonts.body)
                            .foregroundColor(theme.primary)
                        Text("Physical Attributes")
                            .font(theme.fonts.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }

                    // Unit System Toggle
                    HStack {
                        Text("Unit System")
                            .font(theme.fonts.body)
                            .foregroundColor(.white)
                        Spacer()
                        Picker("Units", selection: $viewModel.useMetric) {
                            Text("Imperial").tag(false)
                            Text("Metric").tag(true)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 180)
                        .onChange(of: viewModel.useMetric) { newValue in
                            viewModel.updateUseMetric(newValue)
                        }
                    }
                }

                Divider().background(Color.white.opacity(0.1))

                // Editable Rows
                editableAttributeRow(
                    title: "Height",
                    icon: "ruler",
                    value: viewModel.getHeightDisplay(),
                    action: { showingHeightPopup = true }
                )

                editableAttributeRow(
                    title: "Weight",
                    icon: "scalemass",
                    value: viewModel.getWeightDisplay(),
                    action: { showingWeightPopup = true }
                )

                editableAttributeRow(
                    title: "Age",
                    icon: "calendar",
                    value: viewModel.getAgeDisplay(),
                    action: { showingAgePopup = true }
                )

                editableAttributeRow(
                    title: "Gender",
                    icon: "person.2",
                    value: viewModel.selectedGender?.rawValue ?? "Not set",
                    action: { showingGenderPopup = true }
                )
            }
        }
    }

    // MARK: - Hockey Profile Section
    private var hockeyProfileSection: some View {
        ProfileSectionCard {
            VStack(spacing: theme.spacing.lg) {
                HStack {
                    Image(systemName: "hockey.puck.fill")
                        .font(theme.fonts.body)
                        .foregroundColor(theme.primary)
                    Text("Hockey Profile")
                        .font(theme.fonts.headline)
                        .foregroundColor(.white)
                    Spacer()
                }

                Divider().background(Color.white.opacity(0.1))

                editableAttributeRow(
                    title: "Position",
                    icon: "sportscourt.fill",
                    value: viewModel.selectedPosition?.rawValue ?? "Not set",
                    action: { showingPositionPopup = true }
                )

                editableAttributeRow(
                    title: "Jersey Number",
                    icon: "number",
                    value: viewModel.getJerseyNumberDisplay(),
                    action: { showingJerseyNumberPopup = true }
                )

                editableAttributeRow(
                    title: "Shooting Hand",
                    icon: "hand.raised.fill",
                    value: viewModel.selectedHandedness?.rawValue ?? "Not set",
                    action: { showingHandednessPopup = true }
                )

                editableAttributeRow(
                    title: "Play Style",
                    icon: "star.fill",
                    value: viewModel.selectedPlayStyle?.rawValue ?? "Not set",
                    action: { showingPlayStylePopup = true }
                )
            }
        }
    }

    // MARK: - App Settings Section
    private var appSettingsSection: some View {
        ProfileSectionCard {
            VStack(spacing: theme.spacing.lg) {
                HStack {
                    Image(systemName: "gear")
                        .font(theme.fonts.body)
                        .foregroundColor(theme.primary)
                    Text("App Settings")
                        .font(theme.fonts.headline)
                        .foregroundColor(.white)
                    Spacer()
                }

                Divider().background(Color.white.opacity(0.1))

                // Haptic Feedback Toggle
                HStack {
                    Image(systemName: "hand.tap.fill")
                        .font(theme.fonts.body)
                        .foregroundColor(Color.white.opacity(0.8))
                        .frame(width: 24)

                    Text("Haptic Feedback")
                        .font(theme.fonts.body)
                        .foregroundColor(.white)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { HapticManager.shared.areHapticsEnabled() },
                        set: { HapticManager.shared.setHapticsEnabled($0) }
                    ))
                    .tint(theme.primary)
                }

                // Sound Effects Toggle
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(theme.fonts.body)
                        .foregroundColor(Color.white.opacity(0.8))
                        .frame(width: 24)

                    Text("Sound Effects")
                        .font(theme.fonts.body)
                        .foregroundColor(.white)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { HapticManager.shared.areSoundsEnabled() },
                        set: { HapticManager.shared.setSoundsEnabled($0) }
                    ))
                    .tint(theme.primary)
                }

                // STY Theme Toggle
                HStack {
                    Image(systemName: "sparkles")
                        .font(theme.fonts.body)
                        .foregroundColor(Color.white.opacity(0.8))
                        .frame(width: 24)

                    Text("STY Athletic Theme")
                        .font(theme.fonts.body)
                        .foregroundColor(.white)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: {
                            // Toggle is on when STY theme is active (no NHL team selected)
                            themeManager.getCurrentNHLTeam() == nil && themeManager.getCurrentThemeId() == "sty"
                        },
                        set: { isOn in
                            if isOn {
                                // Switch to STY theme
                                UserDefaults.standard.removeObject(forKey: "selectedNHLTeam")
                                themeManager.setTheme(themeId: "sty")
                            } else {
                                // If turning off and no NHL team selected, do nothing
                                // User needs to select an NHL team through the selector
                                if themeManager.getCurrentNHLTeam() == nil {
                                    showingTeamSelector = true
                                }
                            }
                        }
                    ))
                    .tint(theme.primary)
                }

                // NHL Team Selector
                nhlTeamSelector
            }
        }
    }

    // MARK: - NHL Team Selector
    private var nhlTeamSelector: some View {
        Button(action: {
            showingTeamSelector = true
        }) {
            HStack {
                Image(systemName: "hockey.puck.fill")
                    .font(theme.fonts.body)
                    .foregroundColor(theme.primary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("NHL Team Theme")
                        .font(theme.fonts.body)
                        .foregroundColor(.white)

                    if let currentTeam = themeManager.getCurrentNHLTeam() {
                        Text("\(currentTeam.city) \(currentTeam.name)")
                            .font(theme.fonts.caption)
                            .foregroundColor(Color.white.opacity(0.5))
                    } else {
                        Text("Choose your favorite team")
                            .font(theme.fonts.caption)
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.3))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Manage Subscription Section
    private var manageSubscriptionSection: some View {
        Button(action: {
            openSubscriptionManagement()
        }) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .font(theme.fonts.body)
                    .foregroundColor(theme.primary)

                Text("Manage Subscription")
                    .font(theme.fonts.body)
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.3))
            }
            .padding(.vertical, theme.spacing.md)
            .padding(.horizontal, theme.spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(Color.white.opacity(0.03))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Privacy Policy Section
    private var privacyPolicySection: some View {
        Link(destination: URL(string: "https://docs.google.com/document/d/1sVyqytQLQfAE1dFUzZvXx5H7wZQ7W-Nc3K9d0bIUM08/edit?tab=t.0#heading=h.57lx0vttzc7l")!) {
            HStack {
                Image(systemName: "hand.raised.fill")
                    .font(theme.fonts.body)
                    .foregroundColor(theme.primary)

                Text("Privacy Policy")
                    .font(theme.fonts.body)
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.3))
            }
            .padding(.vertical, theme.spacing.md)
            .padding(.horizontal, theme.spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(Color.white.opacity(0.03))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Reset App Section
    private var deleteAccountSection: some View {
        Button(action: {
            deleteAccount()
        }) {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                    .font(theme.fonts.body)
                    .foregroundColor(.white)

                Text("Reset App")
                    .font(theme.fonts.body)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange)
            .cornerRadius(theme.cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helper Methods

    /// Opens Apple's subscription management page
    private func openSubscriptionManagement() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else {
            print("❌ [ProfileView] Failed to create subscription management URL")
            return
        }

        UIApplication.shared.open(url) { success in
            if success {
                print("✅ [ProfileView] Opened subscription management")
            } else {
                print("❌ [ProfileView] Failed to open subscription management")
            }
        }
    }

    private func deleteAccount() {
        Task { @MainActor in
            // Dismiss any presented sheets first
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {

                // Dismiss any presented view controllers
                if rootVC.presentedViewController != nil {
                    rootVC.dismiss(animated: false)
                }

                // Wait a moment for dismissal
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

                // Now show confirmation alert
                let alert = UIAlertController(
                    title: "Reset App?",
                    message: "This will:\n• Clear all your data\n• Reset to fresh onboarding\n• Keep your theme and settings\n• Create new account on restart\n\nPerfect for testing or starting over!",
                    preferredStyle: .alert
                )

                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "Reset App", style: .destructive) { _ in
                    performDeletion()
                })

                rootVC.present(alert, animated: true)
            }
        }
    }

    private func performDeletion() {
        Task {
            print("🔄 [ProfileView] Starting app reset...")

            // AuthenticationManager.signOut() will:
            // - Delete the Firebase anonymous user (fresh UID on next launch)
            // - Clear UserDefaults (including onboarding)
            // - Log out of RevenueCat
            // - Clear all caches
            // - Post AppStateReset notification
            do {
                try await authManager.signOut()
                print("✅ [ProfileView] Sign out completed")
            } catch {
                print("❌ [ProfileView] Sign out failed: \(error.localizedDescription)")
            }

            // Give a moment for cleanup
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Force ThemeManager to reload theme from UserDefaults BEFORE restarting UI
            // (needed because @AppStorage caches values and doesn't auto-reload)
            await MainActor.run {
                print("🔄 [ProfileView] Reloading theme from UserDefaults...")
                ThemeManager.shared.reloadThemeFromUserDefaults()
            }

            // Small delay to ensure theme is applied
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

            // Restart the app with fresh state
            await MainActor.run {
                print("🔄 [ProfileView] Restarting app...")

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController = UIHostingController(
                        rootView: ThemeAwareContentView()
                            .environmentObject(ThemeManager.shared)
                            .environmentObject(MonetizationManager.shared)
                            .environmentObject(NoticeCenter.shared)
                    )
                    window.makeKeyAndVisible()
                    print("✅ [ProfileView] App restarted with fresh state")
                }
            }
        }
    }

    // MARK: - Helper Views
    private func editableAttributeRow(title: String, icon: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.playSelection()
            action()
        }) {
            HStack {
                Image(systemName: icon)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.textSecondary)
                    .frame(width: 20)

                Text(title)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.textSecondary)

                Spacer()

                Text(value)
                    .font(theme.fonts.body)
                    .foregroundColor(.white)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthenticationManager.shared)
            .environmentObject(ThemeManager.shared)
    }
}
