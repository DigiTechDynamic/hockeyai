import SwiftUI
import Combine

// MARK: - Unified Hockey Card Creation View
/// Single scrollable screen for creating hockey cards - combines player info and jersey selection
struct HockeyCardCreationView: View {
    @Environment(\.theme) var theme
    @StateObject private var viewModel = HockeyCardCreationViewModel()
    let onDismiss: () -> Void

    @State private var showingCardGeneration = false
    @State private var showingHistory = false

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

                        // Only show remaining sections after photo is uploaded
                        if !viewModel.playerPhotos.isEmpty {
                            // Divider
                            sectionDivider

                            // SECTION 2: Player info
                            playerInfoSection

                            // Divider
                            sectionDivider

                            // SECTION 3: Jersey Selection
                            jerseySelectionSection
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .scrollIndicators(.hidden)
            }

            // Bottom CTA (Floating) - only show when form is complete
            if viewModel.isFormComplete {
                VStack {
                    Spacer()
                    bottomCTA
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
                        showingCardGeneration = false
                        onDismiss()
                    }
                )
            }
        }
        .sheet(isPresented: $showingHistory) {
            CardHistoryView()
        }
        .sheet(isPresented: $viewModel.showingPhotoTypePicker) {
            photoTypePickerSheet
        }
    }

    // MARK: - Photo Type Picker Sheet
    private var photoTypePickerSheet: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    Text("Select Photo Type")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                Divider().background(theme.divider)
            }

            // Photo preview - smaller
            if let image = viewModel.playerPhotos.first {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.primary.opacity(0.3), lineWidth: 2)
                    )
                    .padding(.top, 20)
                    .padding(.bottom, 8)
            }

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(PhotoUploadType.allCases, id: \.self) { type in
                        photoTypeSelectionCard(type: type)
                    }
                }
                .padding(20)
            }

            Spacer()
        }
        .background(theme.background.ignoresSafeArea())
        .presentationDetents([.large])
        .interactiveDismissDisabled(viewModel.selectedPhotoType == nil)
    }

    private func photoTypeSelectionCard(type: PhotoUploadType) -> some View {
        Button(action: {
            HapticManager.shared.playSelection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectedPhotoType = type
            }
            // Delay dismissal slightly for visual feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                viewModel.showingPhotoTypePicker = false
            }
        }) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(theme.surface.opacity(0.6))
                        .frame(width: 48, height: 48)

                    Image(systemName: type.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(theme.primary)
                }

                // Text content - more concise
                VStack(alignment: .leading, spacing: 3) {
                    Text(type.rawValue)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    Text(type.pros)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                // Radio button selection indicator
                ZStack {
                    Circle()
                        .strokeBorder(theme.primary, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if viewModel.selectedPhotoType == type {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.surface.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(viewModel.selectedPhotoType == type ? theme.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
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

    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: 12) {
            // Removed redundant description - educational card below is more useful
        }
    }

    // MARK: - Photo Upload Section
    private var photoUploadSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("PHOTOS", systemImage: "camera.fill")
                .font(theme.fonts.caption)
                .fontWeight(.bold)
                .foregroundColor(theme.primary)
                .tracking(1)

            Text("Upload a photo and we'll help you create the perfect card.")
                .font(theme.fonts.caption)
                .foregroundColor(theme.textSecondary)

            // Show educational info before upload
            if viewModel.playerPhotos.isEmpty {
                photoTypeEducationalCard
            }

            // Show uploaded photo
            if let image = viewModel.playerPhotos.first {
                photoThumbnail(image: image, index: 0)

                // Show selected photo type info after categorization
                if let photoType = viewModel.selectedPhotoType {
                    photoTypeInfoCard(photoType)
                }
            }

            // Upload button (always visible if no photo)
            if viewModel.playerPhotos.isEmpty {
                addPhotoButton
            }
        }
    }

    // MARK: - Photo Type Educational Card
    private var photoTypeEducationalCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Photo Types We Support:")
                .font(theme.fonts.bodyBold)
                .foregroundColor(.white)

            ForEach(PhotoUploadType.allCases, id: \.self) { type in
                photoTypeInfoRow(type: type)
            }

            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(theme.accent)

                Text("Don't worry - you can choose which type after uploading!")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.textSecondary)
                    .italic()
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(theme.surface.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.primary.opacity(0.2), lineWidth: 1)
        )
    }

    private func photoTypeInfoRow(type: PhotoUploadType) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(type.rawValue)
                    .font(theme.fonts.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(type.description)
                    .font(.system(size: 12))
                    .foregroundColor(theme.textSecondary)
                    .lineSpacing(2)

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(theme.success)
                    Text(type.pros)
                        .font(.system(size: 11))
                        .foregroundColor(theme.textSecondary.opacity(0.8))
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func photoTypeInfoCard(_ type: PhotoUploadType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(theme.primary)

                Text("Photo Type: \(type.rawValue)")
                    .font(theme.fonts.caption)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primary)

                Spacer()

                Button(action: {
                    viewModel.showingPhotoTypePicker = true
                }) {
                    Text("Change")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.accent)
                }
            }

            Text(type.description)
                .font(theme.fonts.caption)
                .foregroundColor(theme.textSecondary)
                .lineSpacing(2)
        }
        .padding(12)
        .background(theme.primary.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.primary.opacity(0.3), lineWidth: 1)
        )
    }

    private var addPhotoButton: some View {
        Button(action: {
            viewModel.currentPhotoIndex = 0
            viewModel.showingPhotoOptions = true
        }) {
            VStack(spacing: 16) {
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
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .background(theme.surface.opacity(0.3))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                    .foregroundColor(theme.primary.opacity(0.3))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog("Add Your Photo", isPresented: $viewModel.showingPhotoOptions) {
            Button("📸 Take Photo Now") {
                viewModel.photoSourceType = .camera
                viewModel.showingImagePicker = true
            }
            Button("🖼️ Choose from Photos") {
                viewModel.photoSourceType = .photoLibrary
                viewModel.showingImagePicker = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose an action shot, headshot, full body, or hockey gear photo")
        }
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePickerMultiple(
                sourceType: viewModel.photoSourceType,
                onImagePicked: { image in
                    viewModel.addPhoto(image)
                    // Show photo type picker after upload
                    viewModel.showingPhotoTypePicker = true
                }
            )
        }
    }

    private func photoThumbnail(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(theme.primary.opacity(0.5), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)

            Button(action: {
                withAnimation {
                    viewModel.removePhoto(at: index)
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
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

            Text("Enter your player details that will appear on your card.")
                .font(theme.fonts.caption)
                .foregroundColor(theme.textSecondary)

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
        VStack(alignment: .leading, spacing: 20) {
            Label("JERSEY STYLE", systemImage: "tshirt.fill")
                .font(theme.fonts.caption)
                .fontWeight(.bold)
                .foregroundColor(theme.primary)
                .tracking(1)

            // Jersey options - single column list for better readability
            VStack(spacing: 12) {
                if viewModel.shouldShowUsePhotoOption {
                    jerseyOptionRow(
                        icon: "photo.fill",
                        title: "Use Photo Jersey",
                        description: "Jersey from your uploaded photo",
                        isSelected: viewModel.selectedJerseyOption == .usePhoto,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectedJerseyOption = .usePhoto
                            }
                        }
                    )
                }

                jerseyOptionRow(
                    icon: "hockey.puck.fill",
                    title: "NHL Team",
                    description: "Choose from official NHL teams",
                    isSelected: viewModel.selectedJerseyOption == .nhl,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedJerseyOption = .nhl
                        }
                    }
                )

                jerseyOptionRow(
                    icon: "star.fill",
                    title: "STY Athletic",
                    description: "Premium branded design",
                    isSelected: viewModel.selectedJerseyOption == .sty,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedJerseyOption = .sty
                        }
                    }
                )
            }

            // Sub-selection view with better spacing
            if let selectedOption = viewModel.selectedJerseyOption {
                subSelectionView(for: selectedOption)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .padding(.top, 8)
            }
        }
    }

    // New row-based design for jersey options
    private func jerseyOptionRow(
        icon: String,
        title: String,
        description: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            HapticManager.shared.playSelection()
            action()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? theme.primary : theme.surface.opacity(0.6))
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isSelected ? .black : theme.primary)
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(theme.fonts.bodyBold)
                        .foregroundColor(.white)

                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.primary)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(theme.textSecondary.opacity(0.3))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? theme.primary.opacity(0.12) : theme.surface.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
        VStack(alignment: .leading, spacing: 0) {
            switch option {
            case .usePhoto:
                usePhotoJerseyPreview
            case .nhl:
                nhlTeamSelectionView
            case .sty:
                styJerseyPreview
            }
        }
        .padding(16)
        .background(theme.primary.opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.primary.opacity(0.3), lineWidth: 1)
        )
    }


    private var nhlTeamSelectionView: some View {
        VStack(spacing: 0) {
            if let selectedTeam = viewModel.selectedNHLTeam {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(theme.success.opacity(0.2))
                            .frame(width: 44, height: 44)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(theme.success)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedTeam.city)
                            .font(.system(size: 13))
                            .foregroundColor(theme.textSecondary)
                        Text(selectedTeam.name)
                            .font(theme.fonts.bodyBold)
                            .foregroundColor(.white)
                    }

                    Spacer()
                }
                .padding(.bottom, 12)
            }

            Button(action: {
                viewModel.showingNHLTeamPicker = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.selectedNHLTeam == nil ? "plus.circle.fill" : "arrow.triangle.2.circlepath")
                        .font(.system(size: 18))
                        .foregroundColor(theme.primary)

                    Text(viewModel.selectedNHLTeam == nil ? "Select Team" : "Change Team")
                        .font(theme.fonts.bodyBold)
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(14)
                .background(theme.surface.opacity(0.5))
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $viewModel.showingNHLTeamPicker) {
            NHLTeamPickerSheet(selectedTeam: $viewModel.selectedNHLTeam)
        }
    }

    private var usePhotoJerseyPreview: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.success.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(theme.success)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Jersey from Your Photo")
                    .font(theme.fonts.bodyBold)
                    .foregroundColor(.white)

                Text("Using the jersey in your uploaded photo")
                    .font(.system(size: 13))
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()
        }
    }

    private var styJerseyPreview: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.success.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(theme.success)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("STY Athletic Official")
                    .font(theme.fonts.bodyBold)
                    .foregroundColor(.white)

                Text("Premium branded hockey design")
                    .font(.system(size: 13))
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()
        }
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
    @Published var selectedPhotoType: PhotoUploadType? = nil

    // Jersey Selection Fields
    @Published var selectedJerseyOption: JerseyOption? = nil
    @Published var selectedNHLTeam: NHLTeam? = nil

    // UI State
    @Published var showingNameEditor = false
    @Published var showingNumberEditor = false
    @Published var showingPositionEditor = false
    @Published var showingPhotoOptions = false
    @Published var showingImagePicker = false
    @Published var showingPhotoTypePicker = false
    @Published var showingNHLTeamPicker = false
    @Published var photoSourceType: UIImagePickerController.SourceType = .photoLibrary
    @Published var currentPhotoIndex: Int = 0

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

    // Check if "Use Photo" option should be shown based on selected photo type
    var shouldShowUsePhotoOption: Bool {
        guard let photoType = selectedPhotoType else {
            // If no photo type selected yet, show all options
            return true
        }

        // Only show "Use Photo" for action shots and hockey gear photos
        // Hide it for headshots and full body photos (no jersey to extract)
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

        // Watch for photo type changes and auto-reset jersey selection if needed
        setupPhotoTypeObserver()
    }

    private func setupPhotoTypeObserver() {
        $selectedPhotoType
            .sink { [weak self] photoType in
                guard let self = self else { return }

                // If "Use Photo" is selected but photo type changes to one that doesn't support it
                if self.selectedJerseyOption == .usePhoto && !self.shouldShowUsePhotoOption {
                    // Auto-deselect to prevent invalid state
                    self.selectedJerseyOption = nil
                }
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

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

    func addPhoto(_ image: UIImage) {
        if playerPhotos.isEmpty {
            playerPhotos.append(image)
        } else {
            playerPhotos[0] = image
        }
    }

    func removePhoto(at index: Int) {
        guard index < playerPhotos.count else { return }
        playerPhotos.remove(at: index)
    }
}
