import SwiftUI

// MARK: - Photo Upload View (Page 1)
struct PhotoUploadView: View {
    @Environment(\.theme) var theme
    @ObservedObject var viewModel: PlayerRaterViewModel
    @State private var selectedImage: UIImage?
    @State private var imageHeight: CGFloat = 460 // Default height
    // MediaCaptureKit-driven sheets
    @State private var activeSheet: ActiveSheet?

    // Bottom sheet options for MediaCaptureKit
    private enum ActiveSheet: Identifiable, Equatable {
        case sourceSelector
        case camera
        case photoLibrary

        var id: String {
            switch self {
            case .sourceSelector: return "sourceSelector"
            case .camera: return "camera"
            case .photoLibrary: return "photoLibrary"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: theme.spacing.xl) {
                    // Title with glow effect
                    VStack(spacing: theme.spacing.md) {
                        Text(viewModel.context == .onboarding ? "STY Entry Check" : "STY Rating")
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color.white.opacity(0.95)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: theme.primary.opacity(0.6), radius: 20, x: 0, y: 0)
                            .shadow(color: theme.primary.opacity(0.3), radius: 30, x: 0, y: 5)
                            .multilineTextAlignment(.center)

                        Text(viewModel.context == .onboarding ? "Upload any selfie to get validated" : "Let's see if you've got the gear to back it up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.text)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, theme.spacing.xl)
                    .padding(.top, theme.spacing.sm)

                    // Large player image in card - show selected image or default
                    GeometryReader { geometry in
                        ZStack {
                            // Dark background
                            Color.black.opacity(0.3)

                            // Image with proper aspect ratio handling
                            Group {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } else {
                                    Image("player")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                }
                            }
                        }
                        .frame(width: geometry.size.width, height: imageHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            theme.primary.opacity(0.5),
                                            theme.primary.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: theme.primary.opacity(0.3), radius: 16, x: 0, y: 6)
                        .shadow(color: Color.black.opacity(0.4), radius: 24, x: 0, y: 12)
                    }
                    .frame(height: imageHeight)
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.md)
                    .onTapGesture {
                        // Allow tapping the image/placeholder to open picker
                        activeSheet = .sourceSelector
                    }

                    // Guidance: clarify that any clear photo works (not just full gear)
                    if selectedImage == nil {
                        VStack(spacing: theme.spacing.sm) {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.textSecondary)

                                Text("Any clear photo of you works — full gear not required. For best results, make sure your face and upper body are visible and well-lit.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(theme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, theme.spacing.lg)
                    }
                }
            }

            // Upload button
            if selectedImage != nil {
                // Show continue button when photo is selected
                VStack(spacing: theme.spacing.md) {
                    Button(action: {
                        if let image = selectedImage {
                            viewModel.uploadPhoto(image)
                        }
                    }) {
                        HStack {
                            Text(viewModel.context == .onboarding ? "Get Validated" : "Analyze STY")
                                .font(theme.fonts.bodyBold)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(theme.primary)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, theme.spacing.lg)

                    Button(action: {
                        // Let the user replace the photo using MediaCaptureKit
                        selectedImage = nil
                        updateImageHeight(for: nil)
                        activeSheet = .sourceSelector
                    }) {
                        Text("Choose Different Photo")
                            .font(theme.fonts.body)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .padding(.bottom, theme.spacing.md)
            } else {
                // Show upload button (Primary style for better visibility)
                Button(action: {
                    activeSheet = .sourceSelector
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Add Photo")
                            .font(theme.fonts.bodyBold)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(theme.primary)
                    .cornerRadius(16)
                    .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, theme.spacing.xl + theme.spacing.md)
            }
        }
        // Background provided by PlayerRaterFlowView (ThemedBackground)
        .background(Color.clear)
        // MediaCaptureKit bottom sheet + pickers
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .sourceSelector:
                MediaPickerSourceSelector(
                    options: .photoOnly,
                    onSelect: { source in
                        // Slight delay for a smoother transition between sheets
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            handleSourceSelection(source)
                        }
                    }
                )
                .presentationDetents([.height(calculateBottomSheetHeight())])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(24)
                .presentationBackgroundInteraction(.enabled(upThrough: .height(calculateBottomSheetHeight())))

            case .camera:
                PermissionAwareMediaPicker.camera { image in
                    if let image = image {
                        selectedImage = image
                        updateImageHeight(for: image)

                        // Track photo selected (Step 3 in funnel)
                        if viewModel.context == .onboarding {
                            STYValidationAnalytics.trackPhotoSelected(source: "camera")
                        } else {
                            STYCheckAnalytics.trackPhotoSelected(source: "camera")
                        }
                    }
                }

            case .photoLibrary:
                PermissionAwareMediaPicker.imageLibrary { image in
                    if let image = image {
                        selectedImage = image
                        updateImageHeight(for: image)

                        // Track photo selected (Step 3 in funnel)
                        if viewModel.context == .onboarding {
                            STYValidationAnalytics.trackPhotoSelected(source: "library")
                        } else {
                            STYCheckAnalytics.trackPhotoSelected(source: "library")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private func handleSourceSelection(_ source: SelectedSource) {
        switch source {
        case .cameraPhoto:
            // Track picker opened (Step 2 in funnel)
            if viewModel.context == .onboarding {
                STYValidationAnalytics.trackPickerOpened(source: "camera")
            } else {
                STYCheckAnalytics.trackPickerOpened(source: "camera")
            }
            activeSheet = .camera

        case .libraryPhoto:
            // Track picker opened (Step 2 in funnel)
            if viewModel.context == .onboarding {
                STYValidationAnalytics.trackPickerOpened(source: "library")
            } else {
                STYCheckAnalytics.trackPickerOpened(source: "library")
            }
            activeSheet = .photoLibrary

        default:
            // Only photo sources are expected here
            activeSheet = nil
        }
    }

    private func calculateBottomSheetHeight() -> CGFloat {
        // Matches MediaCaptureKit style: drag indicator + header + two options
        var height: CGFloat = 100 // base
        height += 2 * 68          // two option rows
        height += 1               // divider
        height += 20              // bottom padding
        return height
    }

    private func calculateOptimalHeight(for image: UIImage) -> CGFloat {
        // Get screen width minus padding (lg padding on both sides = 32pt total)
        let availableWidth = UIScreen.main.bounds.width - 32

        // Calculate aspect ratio
        let aspectRatio = image.size.height / image.size.width

        // Calculate height based on width
        var calculatedHeight = availableWidth * aspectRatio

        // Constrain to reasonable bounds
        let minHeight: CGFloat = 300
        let maxHeight: CGFloat = 600

        calculatedHeight = min(max(calculatedHeight, minHeight), maxHeight)

        return calculatedHeight
    }

    private func updateImageHeight(for image: UIImage?) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let image = image {
                imageHeight = calculateOptimalHeight(for: image)
            } else {
                imageHeight = 460 // Default for placeholder
            }
        }
    }
}
