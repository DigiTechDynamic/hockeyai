import SwiftUI
import Combine

// MARK: - Hockey Card Saved State
/// Persistable state for resuming Hockey Card creation
struct HockeyCardSavedState: PersistableFlowState {
    static let flowType: FlowType = .hockeyCard

    let currentStageId: String  // For protocol conformance - we use "creation" always
    let savedAt: Date

    // Player info
    let playerName: String
    let jerseyNumber: String
    let position: Position?
    let photoType: PhotoUploadType?

    // Jersey selection
    let jerseyOption: JerseyOption?
    let nhlTeamId: String?  // Store team ID for lookup

    // Photo path
    let photoPath: String?

    func isValid() -> Bool {
        // If we have a photo path, verify the file exists
        if let path = photoPath {
            return FlowStateManager.shared.mediaFileExists(at: path)
        }
        // State without photo is still valid (user hasn't uploaded yet)
        return true
    }
}

// MARK: - Unified Hockey Card Creation View
/// Streamlined single-screen hockey card creator optimized for conversion
struct HockeyCardCreationView: View {
    @Environment(\.theme) var theme
    @StateObject private var viewModel = HockeyCardCreationViewModel()
    let onDismiss: () -> Void

    @State private var showingCardGeneration = false
    @State private var showingHistory = false
    @State private var showingPaywall = false
    @State private var showingDailyLimitAlert = false
    @State private var isKeyboardVisible = false
    // Resume state
    @State private var showResumePrompt = false
    @State private var savedStateToResume: HockeyCardSavedState? = nil

    var body: some View {
        ZStack {
            // Background
            theme.background.ignoresSafeArea()

            // Ambient background glow
            GeometryReader { proxy in
                Circle()
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: proxy.size.width * 1.2)
                    .blur(radius: 60)
                    .offset(x: -proxy.size.width * 0.3, y: -proxy.size.height * 0.2)

                Circle()
                    .fill(theme.accent.opacity(0.1))
                    .frame(width: proxy.size.width)
                    .blur(radius: 50)
                    .offset(x: proxy.size.width * 0.4, y: proxy.size.height * 0.3)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Single Scrollable Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Show inspiring empty state OR the creation form
                        if viewModel.playerPhotos.isEmpty {
                            inspiringEmptyState
                        } else {
                            // Photo uploaded - show compact creation flow
                            compactCreationFlow
                        }

                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                .scrollIndicators(.hidden)
                .onTapGesture {
                    // Dismiss keyboard when tapping outside text fields
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }

            // Sticky Bottom CTA - visible when photo is uploaded and keyboard is hidden
            if !viewModel.playerPhotos.isEmpty && !isKeyboardVisible {
                VStack {
                    Spacer()
                    stickyBottomCTA
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingCardGeneration) {
            if let jersey = viewModel.getJerseySelection() {
                CardGenerationView(
                    playerInfo: viewModel.getPlayerCardInfo(),
                    jerseySelection: jersey,
                    onDismiss: {
                        // Clear saved state on successful generation
                        FlowStateManager.shared.clear(.hockeyCard)
                        showingCardGeneration = false
                        onDismiss()
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showingHistory) {
            CardHistoryView()
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallPresenter(source: "hockey_card_limit")
        }
        .alert("Daily Limit Reached", isPresented: $showingDailyLimitAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You've reached your daily limit of 5 cards. Please come back tomorrow!")
        }
        .onAppear {
            // Check for saved state to resume
            checkForSavedState()

            // Track funnel start (Step 1)
            HockeyCardAnalytics.trackStarted(source: "hockey_card_home")
        }
        .sheet(isPresented: $showResumePrompt) {
            resumePromptSheet
        }
        .onChange(of: viewModel.playerPhotos) { _ in
            // Save state when meaningful progress is made
            saveFlowStateIfNeeded()
        }
        .onChange(of: viewModel.selectedNHLTeam) { _ in
            saveFlowStateIfNeeded()
        }
        .onChange(of: viewModel.selectedJerseyOption) { _ in
            saveFlowStateIfNeeded()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .fontWeight(.semibold)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button(action: onDismiss) {
                ZStack {
                    Circle()
                        .fill(theme.surface.opacity(0.5))
                        .frame(width: 40, height: 40)

                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            Spacer()

            Text("Create Hockey Card")
                .font(.system(size: 20, weight: .black))
                .glowingHeaderText()

            Spacer()

            Button(action: { showingHistory = true }) {
                ZStack {
                    Circle()
                        .fill(theme.surface.opacity(0.5))
                        .frame(width: 40, height: 40)

                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            theme.background.opacity(0.8)
                .blur(radius: 20)
                .ignoresSafeArea()
        )
    }

    // MARK: - Inspiring Empty State
    private var inspiringEmptyState: some View {
        VStack(spacing: 32) {
            // Hero section with example cards
            exampleCardsShowcase
                .padding(.top, 20)

            // Main CTA
            VStack(spacing: 16) {
                Text("Create YOUR Hockey Card")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: theme.primary.opacity(0.3), radius: 10)

                Text("Upload any photo and our AI will transform you into a pro hockey player card")
                    .font(.system(size: 15))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Big upload button
            bigUploadButton

            // Quick stats
            HStack(spacing: 32) {
                statBadge(icon: "person.3.fill", text: "10K+ cards")
                statBadge(icon: "star.fill", text: "32 NHL teams")
                statBadge(icon: "clock.fill", text: "~60 seconds")
            }
            .padding(.top, 8)
        }
    }

    private var exampleCardsShowcase: some View {
        // Hockey card placeholder
        Image("PlaceholderHockeyCard")
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.white.opacity(0.15), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
    }

    private func statBadge(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(theme.primary)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
    }

    private var bigUploadButton: some View {
        Button(action: {
            viewModel.showingPhotoOptions = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 20, weight: .bold))
                Text("Choose Photo")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(theme.primary)
            .cornerRadius(30)
            .shadow(color: theme.primary.opacity(0.5), radius: 15, x: 0, y: 8)
        }
        .padding(.horizontal, 20)
        .confirmationDialog("Add Your Photo", isPresented: $viewModel.showingPhotoOptions) {
            Button("Take Photo") {
                viewModel.photoSourceType = .camera
                viewModel.showingImagePicker = true
            }
            Button("Choose from Library") {
                viewModel.photoSourceType = .photoLibrary
                viewModel.showingImagePicker = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePickerMultiple(
                sourceType: viewModel.photoSourceType,
                onImagePicked: { image in
                    let source = viewModel.photoSourceType == .camera ? "camera" : "library"
                    viewModel.addPhoto(image, source: source)
                }
            )
        }
    }

    // MARK: - Compact Creation Flow (after photo upload)
    private var compactCreationFlow: some View {
        VStack(spacing: 20) {
            // Photo with inline type selector
            photoWithTypeSelector

            // Compact player info
            compactPlayerInfo

            // Visual team picker
            visualTeamPicker
        }
    }

    // MARK: - Photo with Inline Type Selector
    private var photoWithTypeSelector: some View {
        VStack(spacing: 12) {
            // Photo thumbnail with remove button
            ZStack(alignment: .topTrailing) {
                if let image = viewModel.playerPhotos.first {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(theme.primary.opacity(0.5), lineWidth: 2)
                        )
                }

                Button(action: {
                    withAnimation {
                        viewModel.removePhoto(at: 0)
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }
                .offset(x: 8, y: -8)
            }

            // Inline photo type chips
            inlinePhotoTypeSelector
        }
    }

    private var inlinePhotoTypeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PHOTO TYPE")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme.textSecondary)
                .tracking(1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PhotoUploadType.allCases, id: \.self) { type in
                        photoTypeChip(type: type)
                    }
                }
            }
        }
    }

    private func photoTypeChip(type: PhotoUploadType) -> some View {
        Button(action: {
            HapticManager.shared.playSelection()
            withAnimation(.spring(response: 0.3)) {
                viewModel.selectedPhotoType = type
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(type.rawValue)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(viewModel.selectedPhotoType == type ? theme.primary : theme.surface.opacity(0.5))
            )
            .foregroundColor(viewModel.selectedPhotoType == type ? .black : .white)
            .overlay(
                Capsule()
                    .stroke(viewModel.selectedPhotoType == type ? Color.clear : theme.primary.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Compact Player Info
    private var compactPlayerInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PLAYER INFO")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme.textSecondary)
                .tracking(1)

            HStack(spacing: 12) {
                // Name field
                compactInputField(
                    icon: "person.fill",
                    placeholder: "Name",
                    value: $viewModel.playerName,
                    width: .infinity
                )

                // Number field
                compactInputField(
                    icon: "number",
                    placeholder: "#",
                    value: $viewModel.jerseyNumber,
                    width: 80,
                    keyboardType: .numberPad
                )
            }

            // Position picker
            positionChipPicker
        }
    }

    private func compactInputField(
        icon: String,
        placeholder: String,
        value: Binding<String>,
        width: CGFloat? = nil,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(theme.primary)
                .frame(width: 20)

            TextField(placeholder, text: value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .submitLabel(.done)
                .onSubmit {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(theme.surface.opacity(0.4))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.primary.opacity(0.3), lineWidth: 1)
        )
        .frame(maxWidth: width == .infinity ? .infinity : width, alignment: .leading)
        .frame(width: width != .infinity ? width : nil)
    }

    private var positionChipPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Position.allCases, id: \.self) { position in
                    Button(action: {
                        HapticManager.shared.playSelection()
                        viewModel.position = position
                    }) {
                        Text(position.shortName)
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(viewModel.position == position ? theme.primary : theme.surface.opacity(0.5))
                            )
                            .foregroundColor(viewModel.position == position ? .black : .white)
                            .overlay(
                                Capsule()
                                    .stroke(viewModel.position == position ? Color.clear : theme.primary.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Visual Team Picker
    private var visualTeamPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("JERSEY")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme.textSecondary)
                .tracking(1)

            // Jersey type tabs
            HStack(spacing: 0) {
                jerseyTypeTab(title: "NHL Team", option: .nhl)
                jerseyTypeTab(title: "STY Athletic", option: .sty)
                if viewModel.shouldShowUsePhotoOption {
                    jerseyTypeTab(title: "From Photo", option: .usePhoto)
                }
            }
            .background(theme.surface.opacity(0.3))
            .cornerRadius(12)

            // Selection display based on jersey option
            if viewModel.selectedJerseyOption == .nhl {
                nhlTeamSelectionButton
            } else if viewModel.selectedJerseyOption == .sty {
                stySelectedBadge
            } else if viewModel.selectedJerseyOption == .usePhoto {
                usePhotoSelectedBadge
            }
        }
        .sheet(isPresented: $viewModel.showingNHLTeamPicker) {
            HockeyCardTeamPickerSheet(selectedTeam: $viewModel.selectedNHLTeam)
        }
    }

    private func jerseyTypeTab(title: String, option: JerseyOption) -> some View {
        Button(action: {
            HapticManager.shared.playSelection()
            withAnimation(.spring(response: 0.3)) {
                viewModel.selectedJerseyOption = option
                // Auto-open team picker when NHL is selected and no team chosen
                if option == .nhl && viewModel.selectedNHLTeam == nil {
                    viewModel.showingNHLTeamPicker = true
                }
            }
        }) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    viewModel.selectedJerseyOption == option ?
                    theme.primary : Color.clear
                )
                .foregroundColor(viewModel.selectedJerseyOption == option ? .black : .white)
                .cornerRadius(10)
        }
        .padding(3)
    }

    private var nhlTeamSelectionButton: some View {
        Button(action: {
            viewModel.showingNHLTeamPicker = true
        }) {
            HStack(spacing: 12) {
                if let team = viewModel.selectedNHLTeam {
                    // Team selected - show team info
                    ZStack {
                        Circle()
                            .fill(team.primaryColor)
                            .frame(width: 44, height: 44)

                        if let accent = team.accentColor {
                            Circle()
                                .stroke(accent, lineWidth: 2)
                                .frame(width: 44, height: 44)
                        }

                        Image(systemName: team.logoSymbol)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(team.city)
                            .font(.system(size: 12))
                            .foregroundColor(theme.textSecondary)
                        Text(team.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Text("Change")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.primary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                } else {
                    // No team selected - prompt to select
                    ZStack {
                        Circle()
                            .fill(theme.surface)
                            .frame(width: 44, height: 44)

                        Image(systemName: "hockey.puck.fill")
                            .font(.system(size: 20))
                            .foregroundColor(theme.primary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Select Your Team")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("Choose from 32 NHL teams")
                            .font(.system(size: 12))
                            .foregroundColor(theme.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
            }
            .padding(14)
            .background(theme.surface.opacity(0.4))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(viewModel.selectedNHLTeam != nil ? theme.primary.opacity(0.5) : theme.primary.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private var stySelectedBadge: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundColor(theme.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("STY Athletic")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text("Premium branded design")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(theme.success)
        }
        .padding(14)
        .background(theme.surface.opacity(0.4))
        .cornerRadius(14)
    }

    private var usePhotoSelectedBadge: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: "photo.fill")
                    .font(.system(size: 20))
                    .foregroundColor(theme.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Jersey from Photo")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text("Using your uploaded photo's jersey")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(theme.success)
        }
        .padding(14)
        .background(theme.surface.opacity(0.4))
        .cornerRadius(14)
    }

    // MARK: - Sticky Bottom CTA
    private var stickyBottomCTA: some View {
        VStack(spacing: 8) {
            // Simple validation message (if incomplete)
            if !viewModel.isFormComplete {
                Text(viewModel.nextRequiredField)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }

            Button(action: {
                HapticManager.shared.playSelection()

                if MonetizationManager.shared.canGenerateHockeyCard() {
                    // Save player info for next time
                    viewModel.savePlayerInfo()
                    showingCardGeneration = true
                } else {
                    if MonetizationManager.shared.isPremium {
                        showingDailyLimitAlert = true
                    } else {
                        showingPaywall = true
                    }
                }
            }) {
                HStack(spacing: 10) {
                    Text("Generate Card")
                        .font(.system(size: 18, weight: .bold))

                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(viewModel.isFormComplete ? .black : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    viewModel.isFormComplete ?
                    theme.primary :
                    theme.surface.opacity(0.5)
                )
                .cornerRadius(29)
                .shadow(color: viewModel.isFormComplete ? theme.primary.opacity(0.4) : Color.clear, radius: 12, x: 0, y: 6)
            }
            .disabled(!viewModel.isFormComplete)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .padding(.top, 12)
        .background(
            LinearGradient(
                colors: [theme.background.opacity(0), theme.background, theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - Flow State Persistence
extension HockeyCardCreationView {
    /// Check for saved state and show resume prompt if found
    private func checkForSavedState() {
        if let savedState = FlowStateManager.shared.load(HockeyCardSavedState.self) {
            // Only show resume prompt if there's meaningful progress (photo uploaded)
            if savedState.photoPath != nil {
                // First restore the data so user sees their progress behind the prompt
                resumeFromSavedState(savedState)

                // Then show the prompt asking if they want to continue or start fresh
                savedStateToResume = savedState
                showResumePrompt = true
                print("📂 [HockeyCardCreationView] Found saved state with photo - restored and showing prompt")
            }
        }
    }

    /// Save flow state when meaningful progress is made
    private func saveFlowStateIfNeeded() {
        // Only save if user has uploaded a photo (meaningful progress)
        guard !viewModel.playerPhotos.isEmpty else { return }

        // Save photo to persistent storage
        var photoPath: String? = nil
        if let photo = viewModel.playerPhotos.first {
            photoPath = FlowStateManager.shared.saveImage(
                photo,
                identifier: "player_photo",
                flowType: .hockeyCard
            )
        }

        let state = HockeyCardSavedState(
            currentStageId: "creation",
            savedAt: Date(),
            playerName: viewModel.playerName,
            jerseyNumber: viewModel.jerseyNumber,
            position: viewModel.position,
            photoType: viewModel.selectedPhotoType,
            jerseyOption: viewModel.selectedJerseyOption,
            nhlTeamId: viewModel.selectedNHLTeam?.id,
            photoPath: photoPath
        )

        FlowStateManager.shared.save(state)
    }

    /// Resume from saved state
    private func resumeFromSavedState(_ savedState: HockeyCardSavedState) {
        print("▶️ [HockeyCardCreationView] Resuming from saved state")

        // Restore player info
        viewModel.playerName = savedState.playerName
        viewModel.jerseyNumber = savedState.jerseyNumber
        viewModel.position = savedState.position
        viewModel.selectedPhotoType = savedState.photoType

        // Restore jersey selection
        viewModel.selectedJerseyOption = savedState.jerseyOption
        if let teamId = savedState.nhlTeamId {
            viewModel.selectedNHLTeam = NHLTeams.allTeams.first { $0.id == teamId }
        }

        // Restore photo
        if let photoPath = savedState.photoPath,
           let image = FlowStateManager.shared.loadImage(from: photoPath) {
            viewModel.playerPhotos = [image]
        }
    }

    /// Clear saved state on completion
    private func clearSavedState() {
        FlowStateManager.shared.clear(.hockeyCard)
    }

    /// Resume prompt sheet UI
    @ViewBuilder
    private var resumePromptSheet: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(theme.primary)

                Text("Continue Your Card?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.text)

                if let savedState = savedStateToResume {
                    let timeAgo = FlowStateManager.shared.formattedSaveTime(for: .hockeyCard) ?? "recently"

                    VStack(spacing: 4) {
                        if !savedState.playerName.isEmpty {
                            Text("\(savedState.playerName) #\(savedState.jerseyNumber)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(theme.text)
                        }
                        Text("Started \(timeAgo)")
                            .font(.system(size: 13))
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
            .padding(.top, 32)

            // Preview of saved photo
            if let savedState = savedStateToResume,
               let photoPath = savedState.photoPath,
               let image = FlowStateManager.shared.loadImage(from: photoPath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.primary.opacity(0.5), lineWidth: 2)
                    )
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button(action: {
                    // Data is already restored, just dismiss
                    showResumePrompt = false
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Continue")
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.primary)
                    .cornerRadius(theme.cornerRadius)
                }

                Button(action: {
                    showResumePrompt = false
                    // Clear the restored data and saved state
                    viewModel.playerPhotos = []
                    viewModel.playerName = ""
                    viewModel.jerseyNumber = ""
                    viewModel.position = nil
                    viewModel.selectedPhotoType = nil
                    viewModel.selectedJerseyOption = .nhl
                    viewModel.selectedNHLTeam = nil
                    FlowStateManager.shared.clear(.hockeyCard)
                    savedStateToResume = nil
                    // Reload profile defaults
                    viewModel.loadProfileDataPublic()
                }) {
                    Text("Start Fresh")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(theme.background)
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Position Extension
extension Position {
    var shortName: String {
        switch self {
        case .center: return "C"
        case .leftWing: return "LW"
        case .rightWing: return "RW"
        case .leftDefense: return "LD"
        case .rightDefense: return "RD"
        case .goalie: return "G"
        }
    }
}

// MARK: - Unified View Model
class HockeyCardCreationViewModel: ObservableObject {
    // Player Info Fields
    @Published var playerName: String = ""
    @Published var jerseyNumber: String = ""
    @Published var position: Position? = nil
    @Published var playerPhotos: [UIImage] = []
    @Published var selectedPhotoType: PhotoUploadType? = nil

    // Jersey Selection Fields
    @Published var selectedJerseyOption: JerseyOption? = .nhl  // Default to NHL
    @Published var selectedNHLTeam: NHLTeam? = nil

    // UI State
    @Published var showingPhotoOptions = false
    @Published var showingImagePicker = false
    @Published var showingNHLTeamPicker = false
    @Published var photoSourceType: UIImagePickerController.SourceType = .photoLibrary

    private var cancellables = Set<AnyCancellable>()

    var isPlayerInfoComplete: Bool {
        !playerName.isEmpty && !jerseyNumber.isEmpty && position != nil && !playerPhotos.isEmpty && selectedPhotoType != nil
    }

    var isJerseySelectionComplete: Bool {
        guard let option = selectedJerseyOption else { return false }

        switch option {
        case .usePhoto:
            return true
        case .nhl:
            return selectedNHLTeam != nil
        case .sty:
            return true
        }
    }

    var isFormComplete: Bool {
        isPlayerInfoComplete && isJerseySelectionComplete
    }

    /// Returns a friendly message about what's needed next
    var nextRequiredField: String {
        if selectedPhotoType == nil {
            return "Select a photo type above"
        }
        if playerName.isEmpty {
            return "Enter player name"
        }
        if jerseyNumber.isEmpty {
            return "Enter jersey number"
        }
        if position == nil {
            return "Select a position"
        }
        if !isJerseySelectionComplete {
            return "Select a team"
        }
        return ""
    }

    // Check if "Use Photo" option should be shown based on selected photo type
    var shouldShowUsePhotoOption: Bool {
        guard let photoType = selectedPhotoType else {
            return false  // Don't show until photo type is selected
        }

        // Only show for action shots and hockey gear photos
        switch photoType {
        case .actionShot, .hockeyGear:
            return true
        case .headshot, .fullBody:
            return false
        }
    }

    init() {
        loadProfileData()

        NotificationCenter.default.addObserver(
            forName: Notification.Name("PlayerProfileUpdated"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadProfileData()
        }

        setupPhotoTypeObserver()
    }

    private func setupPhotoTypeObserver() {
        $selectedPhotoType
            .sink { [weak self] photoType in
                guard let self = self else { return }

                // If "Use Photo" is selected but photo type changes to one that doesn't support it
                if self.selectedJerseyOption == .usePhoto && !self.shouldShowUsePhotoOption {
                    self.selectedJerseyOption = .nhl  // Reset to NHL
                }
            }
            .store(in: &cancellables)
    }

    private func loadProfileData() {
        loadProfileDataInternal()
    }

    /// Public method to reload profile defaults (used when starting fresh)
    func loadProfileDataPublic() {
        loadProfileDataInternal()
    }

    private func loadProfileDataInternal() {
        if let profileData = UserDefaults.standard.data(forKey: "playerProfile"),
           let profile = try? JSONDecoder().decode(PlayerProfile.self, from: profileData) {
            if let name = profile.name, !name.isEmpty {
                playerName = name
            } else if let displayName = AuthenticationManager.shared.currentUser?.displayName {
                playerName = displayName
            }

            if let number = profile.jerseyNumber {
                jerseyNumber = number
            }

            position = profile.position
        } else if let displayName = AuthenticationManager.shared.currentUser?.displayName {
            playerName = displayName
        }
    }

    func getPlayerCardInfo() -> PlayerCardInfo {
        return PlayerCardInfo(
            playerName: playerName,
            jerseyNumber: jerseyNumber,
            position: position ?? .center,
            playerPhoto: playerPhotos.first ?? UIImage(),
            playerPhotos: playerPhotos,
            photoUploadType: selectedPhotoType
        )
    }

    func getJerseySelection() -> JerseySelection? {
        guard let option = selectedJerseyOption else { return nil }

        switch option {
        case .usePhoto:
            return .usePhoto
        case .nhl:
            guard let team = selectedNHLTeam else { return nil }
            return .nhl(team: team)
        case .sty:
            return .sty
        }
    }

    func addPhoto(_ image: UIImage, source: String = "library") {
        if playerPhotos.isEmpty {
            playerPhotos.append(image)
        } else {
            playerPhotos[0] = image
        }
        // Track photo uploaded (Step 2)
        HockeyCardAnalytics.trackPhotoUploaded(source: source)
    }

    func removePhoto(at index: Int) {
        guard index < playerPhotos.count else { return }
        playerPhotos.remove(at: index)
        selectedPhotoType = nil  // Reset photo type when photo is removed
    }

    /// Save player info for next time
    func savePlayerInfo() {
        // Load existing profile or create new one
        var profile: PlayerProfile
        if let profileData = UserDefaults.standard.data(forKey: "playerProfile"),
           let existingProfile = try? JSONDecoder().decode(PlayerProfile.self, from: profileData) {
            profile = existingProfile
        } else {
            profile = PlayerProfile()
        }

        // Update with current values
        profile.name = playerName
        profile.jerseyNumber = jerseyNumber
        profile.position = position

        // Save back
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "playerProfile")
        }
    }
}
