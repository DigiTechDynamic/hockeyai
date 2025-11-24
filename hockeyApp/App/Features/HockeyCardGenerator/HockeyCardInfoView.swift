import SwiftUI

// MARK: - Hockey Card Info View
/// Initial screen for collecting player information before generating hockey card
struct HockeyCardInfoView: View {
    @Environment(\.theme) var theme
    @StateObject private var viewModel = HockeyCardInfoViewModel()
    let onDismiss: () -> Void

    @State private var showingJerseySelection = false
    @State private var showingCardGeneration = false
    @State private var selectedJersey: JerseySelection? = nil

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

                // Content
                ScrollView {
                    VStack(spacing: 32) {
                        // Title and description
                        titleSection
                            .padding(.top, 10)

                        // Photo upload section
                        photoUploadSection

                        // Player info card
                        playerInfoCard

                        Spacer(minLength: 80) // Space for bottom CTA
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
        .onChange(of: showingJerseySelection) { newValue in
            print("🔵 [HockeyCardInfoView] showingJerseySelection changed to: \(newValue)")
        }
        .onChange(of: showingCardGeneration) { newValue in
            print("🔵 [HockeyCardInfoView] showingCardGeneration changed to: \(newValue)")
        }
        .sheet(isPresented: $showingJerseySelection) {
            JerseySelectionView(
                playerInfo: viewModel.getPlayerCardInfo(),
                onContinue: { jerseySelection in
                    selectedJersey = jerseySelection
                    showingJerseySelection = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingCardGeneration = true
                    }
                },
                onBack: {
                    showingJerseySelection = false
                }
            )
        }
        .fullScreenCover(isPresented: $showingCardGeneration) {
            if let jersey = selectedJersey {
                CardGenerationView(
                    playerInfo: viewModel.getPlayerCardInfo(),
                    jerseySelection: jersey,
                    onDismiss: {
                        showingCardGeneration = false
                        onDismiss()
                    }
                )
            } else {
                // Fallback for error state
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.yellow)
                    Text("Something went wrong")
                        .font(.headline)
                        .foregroundColor(.white)
                    Button("Close") { showingCardGeneration = false }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
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

            // Invisible spacer to balance the close button
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
            // Large neon title removed per user feedback
            
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
                    // Add Photo Button (Always first if empty, or last if not full)
                    if viewModel.canAddMorePhotos {
                        addPhotoButton
                    }
                    
                    // Existing Photos
                    ForEach(Array(viewModel.playerPhotos.enumerated()), id: \.offset) { index, image in
                        photoThumbnail(image: image, index: index)
                    }
                }
                .padding(.vertical, 4) // Space for shadows
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

            // Remove button badge
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

    // MARK: - Player Info Card
    private var playerInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("INFORMATION", systemImage: "person.text.rectangle.fill")
                .font(theme.fonts.caption)
                .fontWeight(.bold)
                .foregroundColor(theme.primary)
                .tracking(1)

            VStack(spacing: 16) {
                // Name Input
                modernInputRow(
                    title: "Name",
                    value: viewModel.playerName.isEmpty ? "Enter Name" : viewModel.playerName,
                    icon: "person.fill",
                    customIcon: "icon_player_profile", // Use new custom asset
                    isSet: !viewModel.playerName.isEmpty,
                    action: { viewModel.showingNameEditor = true }
                )

                // Number Input
                modernInputRow(
                    title: "Number",
                    value: viewModel.jerseyNumber.isEmpty ? "--" : "#\(viewModel.jerseyNumber)",
                    icon: "number",
                    isSet: !viewModel.jerseyNumber.isEmpty,
                    action: { viewModel.showingNumberEditor = true }
                )

                // Position Input
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

    private func modernInputRow(title: String, value: String, icon: String, customIcon: String? = nil, isSet: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon container
                ZStack {
                    Circle()
                        .fill(isSet ? theme.primary.opacity(0.15) : theme.surface)
                        .frame(width: 44, height: 44)
                    
                    if let customIcon = customIcon, let uiImage = UIImage(named: customIcon) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 24, height: 24) // Slightly larger for custom icons
                            .foregroundColor(isSet ? theme.primary : theme.textSecondary)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isSet ? theme.primary : theme.textSecondary)
                    }
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

    // MARK: - Bottom CTA
    private var bottomCTA: some View {
        Button(action: {
            HapticManager.shared.playSelection()
            showingJerseySelection = true
        }) {
            HStack {
                Text("Continue")
                    .font(theme.fonts.button)
                    .fontWeight(.bold)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(theme.background)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                viewModel.isFormValid ? theme.primary : theme.textSecondary
            )
            .cornerRadius(28)
            .shadow(color: viewModel.isFormValid ? theme.primary.opacity(0.4) : Color.clear, radius: 10, x: 0, y: 5)
        }
        .disabled(!viewModel.isFormValid)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(
            LinearGradient(colors: [theme.background.opacity(0), theme.background], startPoint: .top, endPoint: .bottom)
                .frame(height: 100)
                .offset(y: 20)
        )
    }

    // MARK: - Editor Sheets (Kept similar but styled)
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

// MARK: - Hockey Card Info View Model
class HockeyCardInfoViewModel: ObservableObject {
    @Published var playerName: String = ""
    @Published var jerseyNumber: String = ""
    @Published var position: Position? = nil
    @Published var playerPhotos: [UIImage] = []  // Changed to array for multiple photos (max 3)

    @Published var showingNameEditor = false
    @Published var showingNumberEditor = false
    @Published var showingPositionEditor = false
    @Published var showingPhotoOptions = false
    @Published var showingImagePicker = false
    @Published var photoSourceType: UIImagePickerController.SourceType = .photoLibrary
    @Published var currentPhotoIndex: Int = 0  // Track which photo slot we're editing

    var isFormValid: Bool {
        !playerName.isEmpty && !jerseyNumber.isEmpty && position != nil && !playerPhotos.isEmpty
    }

    var canAddMorePhotos: Bool {
        playerPhotos.count < 3  // Maximum 3 reference photos
    }

    init() {
        loadProfileData()

        // Listen for profile updates from Profile screen
        NotificationCenter.default.addObserver(
            forName: Notification.Name("PlayerProfileUpdated"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadProfileData()
        }
    }

    private func loadProfileData() {
        // Load ALL player data from PlayerProfile in UserDefaults
        if let profileData = UserDefaults.standard.data(forKey: "playerProfile"),
           let profile = try? JSONDecoder().decode(PlayerProfile.self, from: profileData) {
            // Load name
            if let name = profile.name, !name.isEmpty {
                playerName = name
            } else if let displayName = AuthenticationManager.shared.currentUser?.displayName {
                // Fallback to auth manager if profile name is empty
                playerName = displayName
            }

            // Load jersey number
            if let number = profile.jerseyNumber {
                jerseyNumber = number
            }

            // Load position
            position = profile.position

            print("✅ [HockeyCardInfo] Loaded profile data - Name: \(playerName), #\(jerseyNumber), \(position?.rawValue ?? "N/A")")
        } else if let displayName = AuthenticationManager.shared.currentUser?.displayName {
            // If no profile exists, use auth manager name as fallback
            playerName = displayName
            print("✅ [HockeyCardInfo] No profile found, using auth name: \(playerName)")
        }
    }

    func saveProfileData() {
        // Save name, jersey number, and position to UserDefaults PlayerProfile
        if let profileData = UserDefaults.standard.data(forKey: "playerProfile"),
           var profile = try? JSONDecoder().decode(PlayerProfile.self, from: profileData) {
            // Update existing profile
            profile.name = playerName.isEmpty ? nil : playerName
            profile.jerseyNumber = jerseyNumber.isEmpty ? nil : jerseyNumber
            profile.position = position

            if let encoded = try? JSONEncoder().encode(profile) {
                UserDefaults.standard.set(encoded, forKey: "playerProfile")
                print("✅ [HockeyCardInfo] Saved profile data: \(playerName), #\(jerseyNumber), \(position?.rawValue ?? "N/A")")
            }
        } else {
            // Create new profile if none exists
            var profile = PlayerProfile()
            profile.name = playerName.isEmpty ? nil : playerName
            profile.jerseyNumber = jerseyNumber.isEmpty ? nil : jerseyNumber
            profile.position = position

            if let encoded = try? JSONEncoder().encode(profile) {
                UserDefaults.standard.set(encoded, forKey: "playerProfile")
                print("✅ [HockeyCardInfo] Created and saved new profile: \(playerName), #\(jerseyNumber), \(position?.rawValue ?? "N/A")")
            }
        }
    }

    func getPlayerCardInfo() -> PlayerCardInfo {
        return PlayerCardInfo(
            playerName: playerName,
            jerseyNumber: jerseyNumber,
            position: position ?? .center,
            playerPhoto: playerPhotos.first ?? UIImage(),  // Primary photo for backwards compatibility
            playerPhotos: playerPhotos,  // All photos for AI reference
            photoUploadType: nil  // This view doesn't use photo type selection
        )
    }

    func addPhoto(_ image: UIImage) {
        if playerPhotos.count < 3 {
            playerPhotos.append(image)
            print("✅ [HockeyCardInfo] Added photo \(playerPhotos.count)/3")
        }
    }

    func removePhoto(at index: Int) {
        guard index < playerPhotos.count else { return }
        playerPhotos.remove(at: index)
        print("✅ [HockeyCardInfo] Removed photo, now \(playerPhotos.count)/3")
    }
}

// MARK: - Image Picker (Multiple) - Using optimized CustomCameraView
struct ImagePickerMultiple: View {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var capturedImage: UIImage?

    var body: some View {
        Group {
            if sourceType == .camera {
                // Use optimized CustomCameraView for camera
                CustomCameraView(capturedImage: $capturedImage, mode: .image)
                    .onChange(of: capturedImage) { _, newImage in
                        if let image = newImage {
                            onImagePicked(image)
                            dismiss()
                        }
                    }
            } else {
                // Use system picker for photo library
                LegacyImagePicker(sourceType: sourceType, onImagePicked: onImagePicked)
            }
        }
    }
}

// MARK: - Legacy Image Picker for Photo Library Only
private struct LegacyImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: LegacyImagePicker

        init(_ parent: LegacyImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // Optimize image before passing to parent to prevent lag
                DispatchQueue.global(qos: .userInitiated).async {
                    var optimizedImage = image

                    // Resize if too large
                    let maxDimension: CGFloat = 2048
                    if image.size.width > maxDimension || image.size.height > maxDimension {
                        let scale = maxDimension / max(image.size.width, image.size.height)
                        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

                        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                        image.draw(in: CGRect(origin: .zero, size: newSize))
                        if let resized = UIGraphicsGetImageFromCurrentImageContext() {
                            optimizedImage = resized
                        }
                        UIGraphicsEndImageContext()
                    }

                    // Compress
                    if let compressedData = optimizedImage.jpegData(compressionQuality: 0.85),
                       let compressed = UIImage(data: compressedData) {
                        optimizedImage = compressed
                    }

                    DispatchQueue.main.async {
                        self.parent.onImagePicked(optimizedImage)
                        self.parent.dismiss()
                    }
                }
            } else {
                parent.dismiss()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
