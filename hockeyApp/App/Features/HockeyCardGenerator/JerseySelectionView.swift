import SwiftUI

// MARK: - Jersey Selection View
/// Second screen where user selects jersey type for hockey card
struct JerseySelectionView: View {
    @Environment(\.theme) var theme
    @StateObject private var viewModel = JerseySelectionViewModel()
    let playerInfo: PlayerCardInfo
    let onContinue: (JerseySelection) -> Void
    let onBack: () -> Void

    init(playerInfo: PlayerCardInfo, onContinue: @escaping (JerseySelection) -> Void, onBack: @escaping () -> Void) {
        self.playerInfo = playerInfo
        self.onContinue = onContinue
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            
            // Ambient background glow
            GeometryReader { proxy in
                Circle()
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: proxy.size.width * 1.2)
                    .blur(radius: 60)
                    .offset(x: proxy.size.width * 0.3, y: -proxy.size.height * 0.2)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Content
                ScrollView {
                    VStack(spacing: 32) {
                        // Title
                        titleSection
                            .padding(.top, 10)

                        // Jersey options (Grid)
                        jerseyOptionsGrid

                        // Sub-selection (if applicable)
                        if let selectedOption = viewModel.selectedOption {
                            subSelectionView(for: selectedOption)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .scrollIndicators(.hidden)
            }
            
            // Bottom CTA
            VStack {
                Spacer()
                bottomCTA
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button(action: onBack) {
                ZStack {
                    Circle()
                        .fill(theme.surface.opacity(0.5))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            Spacer()

            Text("Choose Jersey")
                .font(.system(size: 20, weight: .black))
                .glowingHeaderText()

            Spacer()

            // Invisible spacer
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

            Text("Select a jersey style for your card.")
                .font(theme.fonts.body)
                .foregroundColor(theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Jersey Options Grid
    private var jerseyOptionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            // Option 1: Custom
            jerseyOptionCard(
                icon: "camera.fill",
                title: "Custom",
                description: "Upload Photo",
                isSelected: viewModel.selectedOption == .custom,
                action: { viewModel.selectedOption = .custom }
            )

            // Option 2: NHL
            jerseyOptionCard(
                icon: "hockey.puck.fill",
                title: "NHL Team",
                description: "Official Teams",
                isSelected: viewModel.selectedOption == .nhl,
                action: { viewModel.selectedOption = .nhl }
            )

            // Option 3: STY (Full width)
            jerseyOptionCard(
                icon: "star.fill",
                title: "STY Athletic",
                description: "Premium Brand",
                isSelected: viewModel.selectedOption == .sty,
                action: { viewModel.selectedOption = .sty }
            )
            .gridCellColumns(2)
        }
    }

    // MARK: - Jersey Option Card
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
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? theme.primary : theme.surface)
                        .frame(width: 60, height: 60)
                        .shadow(color: isSelected ? theme.primary.opacity(0.5) : Color.clear, radius: 10)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(isSelected ? .black : theme.primary)
                }

                // Text
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

    // MARK: - Sub-Selection View
    @ViewBuilder
    private func subSelectionView(for option: JerseyOption) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("CONFIGURATION", systemImage: "slider.horizontal.3")
                .font(theme.fonts.caption)
                .fontWeight(.bold)
                .foregroundColor(theme.primary)
                .tracking(1)

            switch option {
            case .usePhoto:
                usePhotoJerseyPreview
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

    // MARK: - Custom Jersey Upload
    private var customJerseyUploadView: some View {
        Button(action: {
            viewModel.showingJerseyPhotoPicker = true
        }) {
            if let image = viewModel.customJerseyImage {
                // Show selected jersey
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
                // Empty state
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

    // MARK: - NHL Team Selection
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

    // MARK: - Use Photo Jersey Preview
    private var usePhotoJerseyPreview: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(theme.success)

            VStack(alignment: .leading, spacing: 4) {
                Text("Jersey from Your Photo")
                    .font(theme.fonts.headline)
                    .foregroundColor(.white)

                Text("The jersey in your uploaded photo will be used")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(theme.success.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - STY Jersey Preview
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
            guard let selection = viewModel.getJerseySelection() else { return }
            HapticManager.shared.playNotification(type: .success)
            onContinue(selection)
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
                viewModel.canContinue ? theme.primary : theme.textSecondary
            )
            .cornerRadius(28)
            .shadow(color: viewModel.canContinue ? theme.primary.opacity(0.4) : Color.clear, radius: 10, x: 0, y: 5)
        }
        .disabled(!viewModel.canContinue)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(
            LinearGradient(colors: [theme.background.opacity(0), theme.background], startPoint: .top, endPoint: .bottom)
                .frame(height: 100)
                .offset(y: 20)
        )
    }
}

// MARK: - Jersey Selection View Model
class JerseySelectionViewModel: ObservableObject {
    @Published var selectedOption: JerseyOption? = nil
    @Published var customJerseyImage: UIImage? = nil
    @Published var selectedNHLTeam: NHLTeam? = nil
    @Published var showingJerseyPhotoPicker = false
    @Published var showingNHLTeamPicker = false

    var canContinue: Bool {
        guard let option = selectedOption else { return false }

        switch option {
        case .usePhoto:
            return true
        case .custom:
            return customJerseyImage != nil
        case .nhl:
            return selectedNHLTeam != nil
        case .sty:
            return true
        }
    }

    func getJerseySelection() -> JerseySelection? {
        guard let option = selectedOption else { return nil }

        switch option {
        case .usePhoto:
            return .usePhoto
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
}

// MARK: - Jersey Option Enum
enum JerseyOption {
    case usePhoto
    case custom
    case nhl
    case sty
}

// MARK: - Jersey Selection Result
enum JerseySelection {
    case usePhoto
    case custom(jerseyImage: UIImage)
    case nhl(team: NHLTeam)
    case sty
}

// MARK: - Player Card Info
struct PlayerCardInfo {
    let playerName: String
    let jerseyNumber: String
    let position: Position
    let playerPhoto: UIImage  // Primary photo (backwards compatibility)
    let playerPhotos: [UIImage]  // All reference photos (1-3 images)
}

// MARK: - NHL Team Picker Sheet
struct NHLTeamPickerSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTeam: NHLTeam?

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(NHLTeams.allTeams, id: \.id) { team in
                        Button(action: {
                            selectedTeam = team
                            HapticManager.shared.playSelection()
                            dismiss()
                        }) {
                            VStack(spacing: 12) {
                                Circle()
                                    .fill(theme.surface)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Text(String(team.name.prefix(1)))
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(theme.primary)
                                    )
                                
                                VStack(spacing: 4) {
                                    Text(team.city)
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)
                                    Text(team.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedTeam?.id == team.id ? theme.primary.opacity(0.2) : theme.surface.opacity(0.4))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedTeam?.id == team.id ? theme.primary : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(20)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle("Select Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.primary)
                }
            }
        }
    }
}

// MARK: - Jersey Image Picker
struct JerseyImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
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
        let parent: JerseyImagePicker

        init(_ parent: JerseyImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
