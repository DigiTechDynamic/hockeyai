import SwiftUI

// MARK: - Unified Hockey Card Creation View
/// Single scrollable screen for creating hockey cards - combines player info and jersey selection
struct HockeyCardCreationView: View {
    @Environment(\.theme) var theme
    @StateObject private var viewModel = HockeyCardCreationViewModel()
    let onDismiss: () -> Void

    @State private var showingCardGeneration = false

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
                    VStack(spacing: 32) {
                        // Title and description
                        titleSection
                            .padding(.top, 10)

                        // SECTION 1: Photo upload
                        photoUploadSection

                        // SECTION 2: Player info
                        playerInfoSection

                        // Divider
                        sectionDivider

                        // SECTION 3: Jersey Selection
                        jerseySelectionSection

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .scrollIndicators(.hidden)
            }

            // Bottom CTA (Floating)
            VStack {
                Spacer()
                bottomCTA
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingCardGeneration) {
            if let jersey = viewModel.getJerseySelection() {
                CardGenerationView(
                    playerInfo: viewModel.getPlayerCardInfo(),
                    jerseySelection: jersey,
                    onDismiss: {
                        showingCardGeneration = false
                        onDismiss()
                    }
                )
            }
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

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            theme.background.opacity(0.8)
                .blur(radius: 20)
                .ignoresSafeArea()
        )
    }

    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("Upload a photo and enter your player details to create your custom hockey card.")
                .font(theme.fonts.body)
                .foregroundColor(theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(4)
        }
    }

    // MARK: - Photo Upload Section
    private var photoUploadSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("PHOTOS", systemImage: "camera.fill")
                    .font(theme.fonts.caption)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primary)
                    .tracking(1)

                Spacer()

                Text("\(viewModel.playerPhotos.count)/3")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.surface)
                    .cornerRadius(8)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if viewModel.canAddMorePhotos {
                        addPhotoButton
                    }

                    ForEach(Array(viewModel.playerPhotos.enumerated()), id: \.offset) { index, image in
                        photoThumbnail(image: image, index: index)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 2)
            }
        }
    }

    private var addPhotoButton: some View {
        Button(action: {
            viewModel.currentPhotoIndex = viewModel.playerPhotos.count
            viewModel.showingPhotoOptions = true
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(theme.primary.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(theme.primary.opacity(0.5), lineWidth: 1)
                        )

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(theme.primary)
                }

                Text("Add Photo")
                    .font(theme.fonts.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 140, height: 180)
            .background(theme.surface.opacity(0.3))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                    .foregroundColor(theme.primary.opacity(0.3))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog("Player Photo", isPresented: $viewModel.showingPhotoOptions) {
            Button("Take Photo") {
                viewModel.photoSourceType = .camera
                viewModel.showingImagePicker = true
            }
            Button("Choose from Library") {
                viewModel.photoSourceType = .photoLibrary
                viewModel.showingImagePicker = true
            }
            if viewModel.currentPhotoIndex < viewModel.playerPhotos.count {
                Button("Remove Photo", role: .destructive) {
                    viewModel.removePhoto(at: viewModel.currentPhotoIndex)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePickerMultiple(
                sourceType: viewModel.photoSourceType,
                onImagePicked: { image in
                    if viewModel.currentPhotoIndex < viewModel.playerPhotos.count {
                        viewModel.playerPhotos[viewModel.currentPhotoIndex] = image
                    } else {
                        viewModel.addPhoto(image)
                    }
                }
            )
        }
    }

    private func photoThumbnail(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Button(action: {
                viewModel.currentPhotoIndex = index
                viewModel.showingPhotoOptions = true
            }) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(theme.surface.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                withAnimation {
                    viewModel.removePhoto(at: index)
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.red)
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            .offset(x: 8, y: -8)
        }
    }

    // MARK: - Player Info Section
    private var playerInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("INFORMATION", systemImage: "person.text.rectangle.fill")
                .font(theme.fonts.caption)
                .fontWeight(.bold)
                .foregroundColor(theme.primary)
                .tracking(1)

            VStack(spacing: 16) {
                modernInputRow(
                    title: "Name",
                    value: viewModel.playerName.isEmpty ? "Enter Name" : viewModel.playerName,
                    icon: "person.fill",
                    isSet: !viewModel.playerName.isEmpty,
                    action: { viewModel.showingNameEditor = true }
                )

                modernInputRow(
                    title: "Number",
                    value: viewModel.jerseyNumber.isEmpty ? "--" : "#\(viewModel.jerseyNumber)",
                    icon: "number",
                    isSet: !viewModel.jerseyNumber.isEmpty,
                    action: { viewModel.showingNumberEditor = true }
                )

                modernInputRow(
                    title: "Position",
                    value: viewModel.position?.rawValue ?? "Select",
                    icon: "sportscourt.fill",
                    isSet: viewModel.position != nil,
                    action: { viewModel.showingPositionEditor = true }
                )
            }
        }
        .sheet(isPresented: $viewModel.showingNameEditor) { nameEditorSheet }
        .sheet(isPresented: $viewModel.showingNumberEditor) { numberEditorSheet }
        .sheet(isPresented: $viewModel.showingPositionEditor) { positionEditorSheet }
    }

    private func modernInputRow(title: String, value: String, icon: String, isSet: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSet ? theme.primary.opacity(0.15) : theme.surface)
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSet ? theme.primary : theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.textSecondary)

                    Text(value)
                        .font(theme.fonts.bodyBold)
                        .foregroundColor(isSet ? .white : theme.textSecondary.opacity(0.7))
                }

                Spacer()

                if isSet {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.success)
                        .font(.system(size: 20))
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(theme.textSecondary.opacity(0.5))
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .padding(16)
            .background(theme.surface.opacity(0.4))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSet ? theme.primary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Section Divider
    private var sectionDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(theme.primary.opacity(0.3))
                .frame(height: 1)

            Image(systemName: "diamond.fill")
                .font(.system(size: 8))
                .foregroundColor(theme.primary.opacity(0.5))

            Rectangle()
                .fill(theme.primary.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Jersey Selection Section
    private var jerseySelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("JERSEY STYLE", systemImage: "tshirt.fill")
                .font(theme.fonts.caption)
                .fontWeight(.bold)
                .foregroundColor(theme.primary)
                .tracking(1)

            Text("Select a jersey style for your card.")
                .font(theme.fonts.caption)
                .foregroundColor(theme.textSecondary)

            // Jersey options grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                jerseyOptionCard(
                    icon: "camera.fill",
                    title: "Custom",
                    description: "Upload Photo",
                    isSelected: viewModel.selectedJerseyOption == .custom,
                    action: { viewModel.selectedJerseyOption = .custom }
                )

                jerseyOptionCard(
                    icon: "hockey.puck.fill",
                    title: "NHL Team",
                    description: "Official Teams",
                    isSelected: viewModel.selectedJerseyOption == .nhl,
                    action: { viewModel.selectedJerseyOption = .nhl }
                )

                jerseyOptionCard(
                    icon: "star.fill",
                    title: "STY Athletic",
                    description: "Premium Brand",
                    isSelected: viewModel.selectedJerseyOption == .sty,
                    action: { viewModel.selectedJerseyOption = .sty }
                )
                .gridCellColumns(2)
            }

            // Sub-selection view
            if let selectedOption = viewModel.selectedJerseyOption {
                subSelectionView(for: selectedOption)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private func jerseyOptionCard(
        icon: String,
        title: String,
        description: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            HapticManager.shared.playSelection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? theme.primary : theme.surface)
                        .frame(width: 60, height: 60)
                        .shadow(color: isSelected ? theme.primary.opacity(0.5) : Color.clear, radius: 10)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(isSelected ? .black : theme.primary)
                }

                VStack(spacing: 4) {
                    Text(title)
                        .font(theme.fonts.headline)
                        .foregroundColor(.white)

                    Text(description)
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.surface.opacity(isSelected ? 0.6 : 0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? theme.primary : theme.primary.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func subSelectionView(for option: JerseyOption) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("CONFIGURATION", systemImage: "slider.horizontal.3")
                .font(theme.fonts.caption)
                .fontWeight(.bold)
                .foregroundColor(theme.primary)
                .tracking(1)

            switch option {
            case .custom:
                customJerseyUploadView
            case .nhl:
                nhlTeamSelectionView
            case .sty:
                styJerseyPreview
            }
        }
        .padding(20)
        .background(theme.surface.opacity(0.3))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.primary.opacity(0.2), lineWidth: 1)
        )
    }

    private var customJerseyUploadView: some View {
        Button(action: {
            viewModel.showingJerseyPhotoPicker = true
        }) {
            if let image = viewModel.customJerseyImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        ZStack {
                            Color.black.opacity(0.3)
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                Text("Change Photo")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                        }
                    )
            } else {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.1))
                            .frame(width: 64, height: 64)

                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(theme.primary)
                    }

                    Text("Upload Jersey Photo")
                        .font(theme.fonts.headline)
                        .foregroundColor(.white)

                    Text("Select from library")
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.textSecondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(theme.surface.opacity(0.3))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                        .foregroundColor(theme.primary.opacity(0.4))
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $viewModel.showingJerseyPhotoPicker) {
            JerseyImagePicker(
                sourceType: .photoLibrary,
                selectedImage: $viewModel.customJerseyImage
            )
        }
    }

    private var nhlTeamSelectionView: some View {
        VStack(spacing: 16) {
            if let selectedTeam = viewModel.selectedNHLTeam {
                HStack {
                    VStack(alignment: .leading) {
                        Text(selectedTeam.city)
                            .font(theme.fonts.caption)
                            .foregroundColor(theme.textSecondary)
                        Text(selectedTeam.name)
                            .font(theme.fonts.title)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(theme.success)
                }
            }

            Button(action: {
                viewModel.showingNHLTeamPicker = true
            }) {
                HStack {
                    Text(viewModel.selectedNHLTeam == nil ? "Select Team" : "Change Team")
                        .font(theme.fonts.button)
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.white)
                .padding(16)
                .background(theme.primary.opacity(0.2))
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $viewModel.showingNHLTeamPicker) {
            NHLTeamPickerSheet(selectedTeam: $viewModel.selectedNHLTeam)
        }
    }

    private var styJerseyPreview: some View {
        HStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(theme.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text("STY Athletic Official")
                    .font(theme.fonts.headline)
                    .foregroundColor(.white)

                Text("Premium branded design")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(theme.primary.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - Bottom CTA
    private var bottomCTA: some View {
        Button(action: {
            HapticManager.shared.playSelection()
            showingCardGeneration = true
        }) {
            HStack {
                Text("Generate Card")
                    .font(theme.fonts.button)
                    .fontWeight(.bold)

                Image(systemName: "wand.and.stars")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(theme.background)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                viewModel.isFormComplete ? theme.primary : theme.textSecondary
            )
            .cornerRadius(28)
            .shadow(color: viewModel.isFormComplete ? theme.primary.opacity(0.4) : Color.clear, radius: 10, x: 0, y: 5)
        }
        .disabled(!viewModel.isFormComplete)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(
            LinearGradient(colors: [theme.background.opacity(0), theme.background], startPoint: .top, endPoint: .bottom)
                .frame(height: 100)
                .offset(y: 20)
        )
    }

    // MARK: - Editor Sheets
    private var nameEditorSheet: some View {
        VStack(spacing: 0) {
            sheetHeader(title: "PLAYER NAME")

            VStack(spacing: 24) {
                TextField("Enter player name", text: $viewModel.playerName)
                    .font(theme.fonts.title)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(20)
                    .background(theme.surface.opacity(0.3))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.primary.opacity(0.5), lineWidth: 1)
                    )

                Text("This name will appear on your card")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.textSecondary)
            }
            .padding(24)

            Spacer()

            saveButton(action: {
                viewModel.showingNameEditor = false
                viewModel.saveProfileData()
            })
        }
        .background(theme.background.ignoresSafeArea())
        .presentationDetents([.medium])
    }

    private var numberEditorSheet: some View {
        VStack(spacing: 0) {
            sheetHeader(title: "JERSEY NUMBER")

            VStack(spacing: 32) {
                Text(viewModel.jerseyNumber.isEmpty ? "--" : "#\(viewModel.jerseyNumber)")
                    .font(.system(size: 80, weight: .black))
                    .foregroundStyle(LinearGradient(colors: [theme.primary, theme.accent], startPoint: .top, endPoint: .bottom))
                    .shadow(color: theme.primary.opacity(0.3), radius: 10)

                Picker("Number", selection: Binding(
                    get: { Int(viewModel.jerseyNumber) ?? 0 },
                    set: { viewModel.jerseyNumber = "\($0)"; HapticManager.shared.playSelection() }
                )) {
                    ForEach(0...99, id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.wheel)
            }
            .padding(24)

            Spacer()

            saveButton(action: {
                viewModel.showingNumberEditor = false
                viewModel.saveProfileData()
            })
        }
        .background(theme.background.ignoresSafeArea())
        .presentationDetents([.medium])
    }

    private var positionEditorSheet: some View {
        VStack(spacing: 0) {
            sheetHeader(title: "POSITION")

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(Position.allCases, id: \.self) { position in
                        Button(action: {
                            HapticManager.shared.playSelection()
                            viewModel.position = position
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: position.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(viewModel.position == position ? .black : theme.primary)

                                Text(position.rawValue)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(viewModel.position == position ? .black : .white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(viewModel.position == position ? theme.primary : theme.surface.opacity(0.4))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(viewModel.position == position ? Color.clear : theme.primary.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(24)
            }

            saveButton(action: {
                viewModel.showingPositionEditor = false
                viewModel.saveProfileData()
            })
        }
        .background(theme.background.ignoresSafeArea())
        .presentationDetents([.large])
    }

    private func sheetHeader(title: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(theme.fonts.headline)
                    .foregroundColor(.white)
                    .tracking(1)
                Spacer()
            }
            .padding(24)

            Divider().background(theme.divider)
        }
    }

    private func saveButton(action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            HapticManager.shared.playNotification(type: .success)
        }) {
            Text("Save")
                .font(theme.fonts.button)
                .fontWeight(.bold)
                .foregroundColor(theme.background)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(theme.primary)
                .cornerRadius(28)
        }
        .padding(24)
    }
}

// MARK: - Unified View Model
class HockeyCardCreationViewModel: ObservableObject {
    // Player Info Fields
    @Published var playerName: String = ""
    @Published var jerseyNumber: String = ""
    @Published var position: Position? = nil
    @Published var playerPhotos: [UIImage] = []

    // Jersey Selection Fields
    @Published var selectedJerseyOption: JerseyOption? = nil
    @Published var customJerseyImage: UIImage? = nil
    @Published var selectedNHLTeam: NHLTeam? = nil

    // UI State
    @Published var showingNameEditor = false
    @Published var showingNumberEditor = false
    @Published var showingPositionEditor = false
    @Published var showingPhotoOptions = false
    @Published var showingImagePicker = false
    @Published var showingJerseyPhotoPicker = false
    @Published var showingNHLTeamPicker = false
    @Published var photoSourceType: UIImagePickerController.SourceType = .photoLibrary
    @Published var currentPhotoIndex: Int = 0

    var canAddMorePhotos: Bool {
        playerPhotos.count < 3
    }

    var isPlayerInfoComplete: Bool {
        !playerName.isEmpty && !jerseyNumber.isEmpty && position != nil && !playerPhotos.isEmpty
    }

    var isJerseySelectionComplete: Bool {
        guard let option = selectedJerseyOption else { return false }

        switch option {
        case .custom:
            return customJerseyImage != nil
        case .nhl:
            return selectedNHLTeam != nil
        case .sty:
            return true
        }
    }

    var isFormComplete: Bool {
        isPlayerInfoComplete && isJerseySelectionComplete
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
    }

    private func loadProfileData() {
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

    func saveProfileData() {
        if let profileData = UserDefaults.standard.data(forKey: "playerProfile"),
           var profile = try? JSONDecoder().decode(PlayerProfile.self, from: profileData) {
            profile.name = playerName.isEmpty ? nil : playerName
            profile.jerseyNumber = jerseyNumber.isEmpty ? nil : jerseyNumber
            profile.position = position

            if let encoded = try? JSONEncoder().encode(profile) {
                UserDefaults.standard.set(encoded, forKey: "playerProfile")
            }
        } else {
            var profile = PlayerProfile()
            profile.name = playerName.isEmpty ? nil : playerName
            profile.jerseyNumber = jerseyNumber.isEmpty ? nil : jerseyNumber
            profile.position = position

            if let encoded = try? JSONEncoder().encode(profile) {
                UserDefaults.standard.set(encoded, forKey: "playerProfile")
            }
        }
    }

    func getPlayerCardInfo() -> PlayerCardInfo {
        return PlayerCardInfo(
            playerName: playerName,
            jerseyNumber: jerseyNumber,
            position: position ?? .center,
            playerPhoto: playerPhotos.first ?? UIImage(),
            playerPhotos: playerPhotos
        )
    }

    func getJerseySelection() -> JerseySelection? {
        guard let option = selectedJerseyOption else { return nil }

        switch option {
        case .custom:
            guard let image = customJerseyImage else { return nil }
            return .custom(jerseyImage: image)
        case .nhl:
            guard let team = selectedNHLTeam else { return nil }
            return .nhl(team: team)
        case .sty:
            return .sty
        }
    }

    func addPhoto(_ image: UIImage) {
        if playerPhotos.count < 3 {
            playerPhotos.append(image)
        }
    }

    func removePhoto(at index: Int) {
        guard index < playerPhotos.count else { return }
        playerPhotos.remove(at: index)
    }
}
