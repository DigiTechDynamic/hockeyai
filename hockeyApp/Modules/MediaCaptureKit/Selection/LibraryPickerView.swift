import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Library Picker View
/// Clean interface for photo/video library selection
/// Used internally by MediaCaptureFacade
public struct LibraryPickerView: View {
    public let mediaType: MediaType
    public let onMediaSelected: (URL?) -> Void
    
    public init(mediaType: MediaType, onMediaSelected: @escaping (URL?) -> Void) {
        self.mediaType = mediaType
        self.onMediaSelected = onMediaSelected
    }
    @Environment(\.dismiss) var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var isProcessing = false
    
    public var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: mediaType == .image ? .images : .videos
        ) {
            EmptyView()
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let item = newItem else { return }
            processSelection(item)
        }
        .onAppear {
            // Trigger picker immediately
            // This is a workaround since PhotosPicker doesn't auto-present
        }
    }
    
    private func processSelection(_ item: PhotosPickerItem) {
        isProcessing = true
        
        Task {
            do {
                if mediaType == .image {
                    // Handle image selection
                    if let data = try await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        // Save image to temporary file
                        let tempURL = FileManager.default.temporaryDirectory
                            .appendingPathComponent("\(UUID().uuidString).jpg")
                        
                        if let jpegData = image.jpegData(compressionQuality: 0.9) {
                            try jpegData.write(to: tempURL)
                            await MainActor.run {
                                onMediaSelected(tempURL)
                                dismiss()
                            }
                        }
                    }
                } else {
                    // Handle video selection
                    if let movie = try await item.loadTransferable(type: VideoTransferable.self) {
                        await MainActor.run {
                            onMediaSelected(movie.url)
                            dismiss()
                        }
                    }
                }
            } catch {
                print("❌ [LibraryPickerView] Failed to load media: \(error)")
                await MainActor.run {
                    onMediaSelected(nil)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Video Transferable
/// Helper for loading videos from PhotosPicker
struct VideoTransferable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return VideoTransferable(url: tempURL)
        }
    }
}

// MARK: - Library Picker Wrapper
/// UIKit-based library picker for more control
public struct LibraryPickerWrapper: UIViewControllerRepresentable {
    public let mediaType: MediaType
    public let onMediaSelected: (URL?) -> Void
    
    public init(mediaType: MediaType, onMediaSelected: @escaping (URL?) -> Void) {
        self.mediaType = mediaType
        self.onMediaSelected = onMediaSelected
    }
    @Environment(\.dismiss) var dismiss
    
    public func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = mediaType == .image ? .images : .videos
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: LibraryPickerWrapper
        
        public init(_ parent: LibraryPickerWrapper) {
            self.parent = parent
        }
        
        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else {
                parent.onMediaSelected(nil)
                return
            }
            
            if parent.mediaType == .image {
                // Handle image
                if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { image, error in
                        if let image = image as? UIImage {
                            // Save to temp file
                            let tempURL = FileManager.default.temporaryDirectory
                                .appendingPathComponent("\(UUID().uuidString).jpg")
                            
                            if let jpegData = image.jpegData(compressionQuality: 0.9) {
                                try? jpegData.write(to: tempURL)
                                DispatchQueue.main.async {
                                    self.parent.onMediaSelected(tempURL)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.parent.onMediaSelected(nil)
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.parent.onMediaSelected(nil)
                            }
                        }
                    }
                }
            } else {
                // Handle video
                if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                        if let url = url {
                            // Copy to temp location
                            let tempURL = FileManager.default.temporaryDirectory
                                .appendingPathComponent("\(UUID().uuidString).mov")
                            do {
                                try FileManager.default.copyItem(at: url, to: tempURL)
                                DispatchQueue.main.async {
                                    self.parent.onMediaSelected(tempURL)
                                }
                            } catch {
                                print("❌ [LibraryPickerWrapper] Failed to copy video: \(error)")
                                DispatchQueue.main.async {
                                    self.parent.onMediaSelected(nil)
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.parent.onMediaSelected(nil)
                            }
                        }
                    }
                }
            }
        }
    }
}