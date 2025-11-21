import SwiftUI
import PhotosUI
import AVKit
import UniformTypeIdentifiers

// MARK: - Media Picker Item
private struct MediaPickerItem: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let gradientColors: [Color]
    let title: String
    let subtitle: String
    let action: () -> Void
    
    init(
        icon: String,
        iconColor: Color,
        gradientColors: [Color]? = nil,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.gradientColors = gradientColors ?? [iconColor, iconColor.opacity(0.7)]
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
}



// MARK: - Media Source Options Configuration
public struct MediaSourceOptions {
    let canTakePhoto: Bool
    let canTakeVideo: Bool
    let canSelectPhotoFromLibrary: Bool
    let canSelectVideoFromLibrary: Bool

    public init(
        canTakePhoto: Bool,
        canTakeVideo: Bool,
        canSelectPhotoFromLibrary: Bool,
        canSelectVideoFromLibrary: Bool
    ) {
        self.canTakePhoto = canTakePhoto
        self.canTakeVideo = canTakeVideo
        self.canSelectPhotoFromLibrary = canSelectPhotoFromLibrary
        self.canSelectVideoFromLibrary = canSelectVideoFromLibrary
    }
    
    // Convenience initializers
    public static let photoOnly = MediaSourceOptions(
        canTakePhoto: true,
        canTakeVideo: false,
        canSelectPhotoFromLibrary: true,
        canSelectVideoFromLibrary: false
    )
    
    public static let videoOnly = MediaSourceOptions(
        canTakePhoto: false,
        canTakeVideo: true,
        canSelectPhotoFromLibrary: false,
        canSelectVideoFromLibrary: true
    )
    
    public static let all = MediaSourceOptions(
        canTakePhoto: true,
        canTakeVideo: true,
        canSelectPhotoFromLibrary: true,
        canSelectVideoFromLibrary: true
    )
}

// MARK: - Selected Source Result
public enum SelectedSource {
    case cameraPhoto
    case cameraVideo
    case libraryPhoto
    case libraryVideo
}

// MARK: - Media Picker Source Selector (Using ActionSheet)
public struct MediaPickerSourceSelector: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let options: MediaSourceOptions
    let onSelect: (SelectedSource) -> Void
    let isBottomSheet: Bool
    
    @State private var itemOpacities: [Int: Double] = [:]
    @State private var itemScales: [Int: CGFloat] = [:]
    @State private var dragIndicatorOpacity: Double = 0
    @State private var headerOpacity: Double = 0
    
    public init(
        options: MediaSourceOptions,
        onSelect: @escaping (SelectedSource) -> Void,
        isBottomSheet: Bool = true
    ) {
        self.options = options
        self.onSelect = onSelect
        self.isBottomSheet = isBottomSheet
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 20)
                .opacity(dragIndicatorOpacity)
            
            // Header
            HStack {
                Text(getTitle())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color.primary)
                
                Spacer()
                
                // Close button
                Button(action: { 
                    dismiss() 
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.secondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color(.secondarySystemBackground).opacity(0.3))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .opacity(headerOpacity)
            
            // Options
            VStack(spacing: 12) {
                ForEach(Array(createMediaPickerItems().enumerated()), id: \.element.id) { index, item in
                    MediaPickerButton(
                        item: item,
                        opacity: itemOpacities[index] ?? 0,
                        scale: itemScales[index] ?? 0.95
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .onAppear {
            animateIn()
        }
    }
    
    // MARK: - Helper Methods
    private func createMediaPickerItems() -> [MediaPickerItem] {
        var items: [MediaPickerItem] = []
        
        if options.canTakePhoto {
            items.append(MediaPickerItem(
                icon: "camera.fill",
                iconColor: Color.orange,
                gradientColors: [Color.orange, Color.orange.opacity(0.7)],
                title: "Take Photo",
                subtitle: "Use camera to capture a photo",
                action: {
                    dismiss()
                    onSelect(.cameraPhoto)
                }
            ))
        }
        
        if options.canTakeVideo {
            items.append(MediaPickerItem(
                icon: "video.fill",
                iconColor: Color.orange,
                gradientColors: [Color.orange, Color.red.opacity(0.8)],
                title: "Record Video",
                subtitle: "Use camera to record a video",
                action: {
                    dismiss()
                    onSelect(.cameraVideo)
                }
            ))
        }
        
        if options.canSelectPhotoFromLibrary {
            items.append(MediaPickerItem(
                icon: "photo.fill",
                iconColor: Color.green,
                gradientColors: [Color.green, Color.green.opacity(0.7)],
                title: "Choose from Library",
                subtitle: "Select a photo from your library",
                action: {
                    dismiss()
                    onSelect(.libraryPhoto)
                }
            ))
        }
        
        if options.canSelectVideoFromLibrary {
            items.append(MediaPickerItem(
                icon: "play.rectangle.fill",
                iconColor: Color.green,
                gradientColors: [Color.green, Color.blue.opacity(0.8)],
                title: "Choose Video from Library",
                subtitle: "Select a video from your library",
                action: {
                    dismiss()
                    onSelect(.libraryVideo)
                }
            ))
        }
        
        return items
    }
    
    private func getTitle() -> String {
        let hasPhoto = options.canTakePhoto || options.canSelectPhotoFromLibrary
        let hasVideo = options.canTakeVideo || options.canSelectVideoFromLibrary
        
        if hasPhoto && hasVideo {
            return "Add Video"  // Matching your screenshot
        } else if hasPhoto {
            return "Add Photo"
        } else {
            return "Add Video"
        }
    }
    
    private func animateIn() {
        // Initialize states
        let itemCount = createMediaPickerItems().count
        for i in 0..<itemCount {
            itemOpacities[i] = 0
            itemScales[i] = 0.95
        }
        
        // Animate drag indicator and header
        withAnimation(.easeOut(duration: 0.2)) {
            dragIndicatorOpacity = 1
        }
        
        withAnimation(.easeOut(duration: 0.25).delay(0.05)) {
            headerOpacity = 1
        }
        
        // Staggered button animations
        for i in 0..<itemCount {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1 + Double(i) * 0.05)) {
                itemOpacities[i] = 1
                itemScales[i] = 1
            }
        }
    }
}

// MARK: - Media Picker Button
private struct MediaPickerButton: View {
    let item: MediaPickerItem
    let opacity: Double
    let scale: CGFloat
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            item.action()
        }) {
            HStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: item.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.primary)
                    
                    Text(item.subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color.secondary)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.secondary.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemBackground).opacity(0.5))
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(scale * (isPressed ? 0.98 : 1.0))
        .opacity(opacity)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Permission Aware Media Picker (keeping existing functionality)
public struct PermissionAwareMediaPicker: View {
    enum PickerType {
        case camera
        case photoLibrary
        case videoCamera
        case videoLibrary
    }
    
    let type: PickerType
    let onImageSelected: ((UIImage?) -> Void)?
    let onVideoSelected: ((URL?) -> Void)?
    @Environment(\.dismiss) var dismiss
    
    @State private var showPermissionAlert = false
    @State private var alertConfig: PermissionAlertConfig?
    @State private var showPicker = false
    @State private var capturedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedVideoItem: PhotosPickerItem?
    
    private let permissionsManager = PermissionsManager.shared
    
    public var body: some View {
        Group {
            if showPicker {
                pickerView
            } else {
                Color.clear
                    .onAppear {
                        checkPermission()
                    }
            }
        }
        .alert(alertConfig?.title ?? "", isPresented: $showPermissionAlert) {
            Button(alertConfig?.settingsButtonTitle ?? "Settings") {
                permissionsManager.openSettings()
            }
            Button(alertConfig?.cancelButtonTitle ?? "Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(alertConfig?.message ?? "")
        }
    }
    
    @ViewBuilder
    private var pickerView: some View {
        switch type {
        case .camera:
            CustomCameraView(capturedImage: $capturedImage, mode: .image)
                .onChange(of: capturedImage) { _, newImage in
                    if let image = newImage {
                        onImageSelected?(image)
                        dismiss()
                    }
                }
        case .photoLibrary:
            PhotoLibraryPicker(onImageSelected: onImageSelected ?? { _ in })
        case .videoCamera:
            CustomCameraView(capturedImage: .constant(nil), onVideoCaptured: { url in
                // Symmetric finish notification for camera capture handoff
                NotificationCenter.default.post(name: Notification.Name("VideoProcessingFinished"), object: nil)
                onVideoSelected?(url)
                // Don't dismiss here - let the parent handle navigation
                // The parent (ShotVideoCaptureView) will show the trimmer
            }, mode: .video)
        case .videoLibrary:
            VideoLibraryPicker(onVideoSelected: onVideoSelected ?? { _ in })
        }
    }
    
    private func checkPermission() {
        let requiredPermission: PermissionType
        switch type {
        case .camera, .videoCamera:
            requiredPermission = .camera
        case .photoLibrary, .videoLibrary:
            requiredPermission = .photoLibrary
        }
        
        permissionsManager.requestPermission(requiredPermission) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let status):
                    if status == .authorized {
                        showPicker = true
                    } else {
                        setupAlertForStatus(status, permission: requiredPermission)
                        showPermissionAlert = true
                    }
                case .failure(let error):
                    setupAlertForError(error)
                    showPermissionAlert = true
                }
            }
        }
    }
    
    private func setupAlertForStatus(_ status: PermissionStatus, permission: PermissionType) {
        alertConfig = PermissionAlertConfig(
            for: permission,
            status: status,
            isRequired: true,
            customMessage: nil
        )
    }
    
    private func setupAlertForError(_ error: PermissionError) {
        alertConfig = PermissionAlertConfig(
            title: "Permission Error",
            message: error.localizedDescription,
            settingsButtonTitle: "Settings",
            cancelButtonTitle: "Cancel"
        )
    }
    
    // MARK: - Convenience static methods for common use cases
    public static func camera(onImageSelected: @escaping (UIImage?) -> Void) -> Self {
        Self(type: .camera, onImageSelected: onImageSelected, onVideoSelected: nil)
    }
    
    public static func imageLibrary(onImageSelected: @escaping (UIImage?) -> Void) -> Self {
        Self(type: .photoLibrary, onImageSelected: onImageSelected, onVideoSelected: nil)
    }
    
    // Alias for backward compatibility
    public static func photoLibrary(onImageSelected: @escaping (UIImage?) -> Void) -> Self {
        Self(type: .photoLibrary, onImageSelected: onImageSelected, onVideoSelected: nil)
    }
    
    public static func videoCamera(onVideoSelected: @escaping (URL?) -> Void) -> Self {
        Self(type: .videoCamera, onImageSelected: nil, onVideoSelected: onVideoSelected)
    }
    
    public static func videoLibrary(onVideoSelected: @escaping (URL?) -> Void) -> Self {
        Self(type: .videoLibrary, onImageSelected: nil, onVideoSelected: onVideoSelected)
    }
}

// MARK: - Photo Library Picker
private struct PhotoLibraryPicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage?) -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker
        
        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            print("📱 [MediaPicker] PHPicker didFinishPicking called")
            parent.dismiss()
            print("📱 [MediaPicker] Dismiss called")
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.onImageSelected(image as? UIImage)
                    }
                }
            }
        }
    }
}

// MARK: - Video Library Picker
private struct VideoLibraryPicker: UIViewControllerRepresentable {
    let onVideoSelected: (URL?) -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoLibraryPicker
        
        init(_ parent: VideoLibraryPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Show loading state BEFORE dismissing picker
            if results.first?.itemProvider != nil {
                DispatchQueue.main.async {
                    // Notify immediately that processing has started
                    NotificationCenter.default.post(name: Notification.Name("VideoProcessingStarted"), object: nil)
                }
            }
            
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { 
                DispatchQueue.main.async {
                    // Symmetric finish notification (no selection)
                    NotificationCenter.default.post(name: Notification.Name("VideoProcessingFinished"), object: nil)
                    self.parent.onVideoSelected(nil)
                }
                return 
            }
            
            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                print("📱 [MediaPicker] Loading video file representation")
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    print("📱 [MediaPicker] File representation loaded")
                    // This completion handler is already on a background thread.
                    guard let sourceURL = url else {
                        if let error = error {
                            print("Failed to load file representation: \(error)")
                        }
                        DispatchQueue.main.async {
                            self.parent.onVideoSelected(nil)
                        }
                        return
                    }
                    
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
                    
                    do {
                        // Perform the copy synchronously within this background handler
                        // to avoid a race condition with the temporary file's deletion.
                        try FileManager.default.copyItem(at: sourceURL, to: tempURL)
                        
                        // Now that the file is safely copied, dispatch the result to the main thread.
                        // CRITICAL: Add delay to let picker fully dismiss and avoid AX blocking
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            // Symmetric finish notification (success)
                            NotificationCenter.default.post(name: Notification.Name("VideoProcessingFinished"), object: nil)
                            self.parent.onVideoSelected(tempURL)
                        }
                    } catch {
                        print("Failed to copy video: \(error)")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            // Symmetric finish notification (error)
                            NotificationCenter.default.post(name: Notification.Name("VideoProcessingFinished"), object: nil)
                            self.parent.onVideoSelected(nil)
                        }
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Symmetric finish notification (unsupported type)
                    NotificationCenter.default.post(name: Notification.Name("VideoProcessingFinished"), object: nil)
                    self.parent.onVideoSelected(nil)
                }
            }
        }
    }
}

// MARK: - Movie Transferable
private struct Movie: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}

// MARK: - Permission Alert Configuration Extension
private extension PermissionAlertConfig {
    init(for permission: PermissionType, status: PermissionStatus, isRequired: Bool, customMessage: String?) {
        let title: String
        let message: String
        
        switch permission {
        case .camera:
            title = "Camera Access"
            message = customMessage ?? "This app needs access to your camera to take photos. Please enable camera access in Settings."
        case .photoLibrary:
            title = "Photo Library Access"
            message = customMessage ?? "This app needs access to your photo library to select photos. Please enable photo library access in Settings."
        case .microphone:
            title = "Microphone Access"
            message = customMessage ?? "This app needs access to your microphone to record audio. Please enable microphone access in Settings."
        case .motion:
            title = "Motion Access"
            message = customMessage ?? "This app needs access to motion data to improve recording quality. Please enable motion access in Settings."
        }
        
        let settingsButtonTitle = "Open Settings"
        let cancelButtonTitle = isRequired ? "Cancel" : "Continue Without Access"
        
        self.init(
            title: title,
            message: message,
            settingsButtonTitle: settingsButtonTitle,
            cancelButtonTitle: cancelButtonTitle
        )
    }
}
