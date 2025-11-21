import Foundation
import AVFoundation
import Photos
import UIKit
import CoreMotion

// MARK: - Permission Types
public enum PermissionType {
    case camera
    case photoLibrary
    case microphone
    case motion
    
    var displayName: String {
        switch self {
        case .camera:
            return "Camera"
        case .photoLibrary:
            return "Photo Library"
        case .microphone:
            return "Microphone"
        case .motion:
            return "Motion"
        }
    }
}

// MARK: - Permission Status
public enum PermissionStatus {
    case authorized
    case denied
    case restricted
    case notDetermined
    case limited // For photo library on iOS 14+
    
    var isGranted: Bool {
        switch self {
        case .authorized, .limited:
            return true
        case .denied, .restricted, .notDetermined:
            return false
        }
    }
}

// MARK: - Permission Error
public enum PermissionError: LocalizedError {
    case denied(PermissionType)
    case restricted(PermissionType)
    case systemError(PermissionType, Error?)
    
    public var errorDescription: String? {
        switch self {
        case .denied(let type):
            return "\(type.displayName) access denied. Please enable in Settings."
        case .restricted(let type):
            return "\(type.displayName) access is restricted on this device."
        case .systemError(let type, let error):
            return "Failed to access \(type.displayName): \(error?.localizedDescription ?? "Unknown error")"
        }
    }
}

// MARK: - Permission Alert Configuration
public struct PermissionAlertConfig {
    let title: String
    let message: String
    let settingsButtonTitle: String
    let cancelButtonTitle: String
    
    public init(
        title: String,
        message: String,
        settingsButtonTitle: String = "Settings",
        cancelButtonTitle: String = "Cancel"
    ) {
        self.title = title
        self.message = message
        self.settingsButtonTitle = settingsButtonTitle
        self.cancelButtonTitle = cancelButtonTitle
    }
}

// MARK: - Permissions Manager
/// Centralized manager for all app permissions
public final class PermissionsManager {
    
    // MARK: - Singleton
    public static let shared = PermissionsManager()
    
    // MARK: - Properties
    private let queue = DispatchQueue(label: "com.hockeyapp.permissions", qos: .userInitiated)
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Check the current status of a permission
    public func checkPermissionStatus(_ permission: PermissionType) -> PermissionStatus {
        switch permission {
        case .camera:
            return checkCameraStatus()
        case .photoLibrary:
            return checkPhotoLibraryStatus()
        case .microphone:
            return checkMicrophoneStatus()
        case .motion:
            return checkMotionStatus()
        }
    }
    
    /// Request permission with completion handler
    public func requestPermission(
        _ permission: PermissionType,
        completion: @escaping (Result<PermissionStatus, PermissionError>) -> Void
    ) {
        switch permission {
        case .camera:
            requestCameraPermission(completion: completion)
        case .photoLibrary:
            requestPhotoLibraryPermission(completion: completion)
        case .microphone:
            requestMicrophonePermission(completion: completion)
        case .motion:
            requestMotionPermission(completion: completion)
        }
    }
    
    /// Request multiple permissions
    public func requestPermissions(
        _ permissions: [PermissionType],
        completion: @escaping ([PermissionType: Result<PermissionStatus, PermissionError>]) -> Void
    ) {
        var results: [PermissionType: Result<PermissionStatus, PermissionError>] = [:]
        let group = DispatchGroup()
        
        for permission in permissions {
            group.enter()
            requestPermission(permission) { result in
                self.queue.async {
                    results[permission] = result
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(results)
        }
    }
    
    /// Check if permission is granted
    public func isPermissionGranted(_ permission: PermissionType) -> Bool {
        return checkPermissionStatus(permission).isGranted
    }
    
    /// Open app settings
    public func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    /// Get default alert configuration for permission
    public func defaultAlertConfig(for permission: PermissionType) -> PermissionAlertConfig {
        switch permission {
        case .camera:
            return PermissionAlertConfig(
                title: "Camera Permission Required",
                message: "Please enable camera access in Settings to take photos and videos."
            )
        case .photoLibrary:
            return PermissionAlertConfig(
                title: "Photo Library Permission Required",
                message: "Please enable photo library access in Settings to select photos and videos."
            )
        case .microphone:
            return PermissionAlertConfig(
                title: "Microphone Permission Required",
                message: "Please enable microphone access in Settings to record audio with videos."
            )
        case .motion:
            return PermissionAlertConfig(
                title: "Motion Permission Required",
                message: "Please enable motion access in Settings to improve recording quality feedback."
            )
        }
    }
    
    // MARK: - Private Methods
    
    // MARK: Camera
    private func checkCameraStatus() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }
    
    private func requestCameraPermission(completion: @escaping (Result<PermissionStatus, PermissionError>) -> Void) {
        let currentStatus = checkCameraStatus()
        
        switch currentStatus {
        case .authorized:
            completion(.success(.authorized))
        case .denied:
            completion(.failure(.denied(.camera)))
        case .restricted:
            completion(.failure(.restricted(.camera)))
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        completion(.success(.authorized))
                    } else {
                        completion(.failure(.denied(.camera)))
                    }
                }
            }
        case .limited:
            completion(.success(.limited))
        }
    }
    
    // MARK: Photo Library
    private func checkPhotoLibraryStatus() -> PermissionStatus {
        let status: PHAuthorizationStatus
        
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            status = PHPhotoLibrary.authorizationStatus()
        }
        
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        case .limited:
            return .limited
        @unknown default:
            return .notDetermined
        }
    }
    
    private func requestPhotoLibraryPermission(completion: @escaping (Result<PermissionStatus, PermissionError>) -> Void) {
        let currentStatus = checkPhotoLibraryStatus()
        
        switch currentStatus {
        case .authorized, .limited:
            completion(.success(currentStatus))
        case .denied:
            completion(.failure(.denied(.photoLibrary)))
        case .restricted:
            completion(.failure(.restricted(.photoLibrary)))
        case .notDetermined:
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    DispatchQueue.main.async {
                        switch status {
                        case .authorized:
                            completion(.success(.authorized))
                        case .limited:
                            completion(.success(.limited))
                        case .denied:
                            completion(.failure(.denied(.photoLibrary)))
                        case .restricted:
                            completion(.failure(.restricted(.photoLibrary)))
                        case .notDetermined:
                            completion(.failure(.systemError(.photoLibrary, nil)))
                        @unknown default:
                            completion(.failure(.systemError(.photoLibrary, nil)))
                        }
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization { status in
                    DispatchQueue.main.async {
                        switch status {
                        case .authorized:
                            completion(.success(.authorized))
                        case .denied:
                            completion(.failure(.denied(.photoLibrary)))
                        case .restricted:
                            completion(.failure(.restricted(.photoLibrary)))
                        case .notDetermined:
                            completion(.failure(.systemError(.photoLibrary, nil)))
                        @unknown default:
                            completion(.failure(.systemError(.photoLibrary, nil)))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Microphone
    private func checkMicrophoneStatus() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }
    
    private func requestMicrophonePermission(completion: @escaping (Result<PermissionStatus, PermissionError>) -> Void) {
        let currentStatus = checkMicrophoneStatus()
        
        switch currentStatus {
        case .authorized:
            completion(.success(.authorized))
        case .denied:
            completion(.failure(.denied(.microphone)))
        case .restricted:
            completion(.failure(.restricted(.microphone)))
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if granted {
                        completion(.success(.authorized))
                    } else {
                        completion(.failure(.denied(.microphone)))
                    }
                }
            }
        case .limited:
            completion(.success(.limited))
        }
    }
    
    // MARK: Motion
    private let motionManager = CMMotionManager()
    
    private func checkMotionStatus() -> PermissionStatus {
        // CoreMotion doesn't have an explicit permission check
        // It returns .authorized if motion is available and not restricted
        if motionManager.isDeviceMotionAvailable {
            return .authorized
        } else {
            return .restricted
        }
    }
    
    private func requestMotionPermission(completion: @escaping (Result<PermissionStatus, PermissionError>) -> Void) {
        let currentStatus = checkMotionStatus()
        
        switch currentStatus {
        case .authorized:
            completion(.success(.authorized))
        case .restricted:
            completion(.failure(.restricted(.motion)))
        default:
            // CoreMotion doesn't require explicit permission request
            // It will prompt on first use automatically
            completion(.success(.authorized))
        }
    }
    
    /// Check if motion is authorized (convenience property)
    public var isMotionAuthorized: Bool {
        return checkMotionStatus() == .authorized
    }
}

// MARK: - Async/Await Support
@available(iOS 13.0, *)
public extension PermissionsManager {
    
    /// Request permission using async/await
    func requestPermission(_ permission: PermissionType) async throws -> PermissionStatus {
        return try await withCheckedThrowingContinuation { continuation in
            requestPermission(permission) { result in
                switch result {
                case .success(let status):
                    continuation.resume(returning: status)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Request multiple permissions using async/await
    func requestPermissions(_ permissions: [PermissionType]) async -> [PermissionType: Result<PermissionStatus, PermissionError>] {
        return await withCheckedContinuation { continuation in
            requestPermissions(permissions) { results in
                continuation.resume(returning: results)
            }
        }
    }
}

// MARK: - SwiftUI Support
import SwiftUI

@available(iOS 13.0, *)
public struct PermissionRequestModifier: ViewModifier {
    let permission: PermissionType
    let onResult: (Result<PermissionStatus, PermissionError>) -> Void
    
    @State private var hasRequested = false
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasRequested {
                    hasRequested = true
                    PermissionsManager.shared.requestPermission(permission, completion: onResult)
                }
            }
    }
}

@available(iOS 13.0, *)
public extension View {
    /// Request permission when view appears
    func requestPermission(
        _ permission: PermissionType,
        onResult: @escaping (Result<PermissionStatus, PermissionError>) -> Void
    ) -> some View {
        modifier(PermissionRequestModifier(permission: permission, onResult: onResult))
    }
}