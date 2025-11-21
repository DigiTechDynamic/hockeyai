import Foundation
import Combine
import UIKit

// MARK: - Video Storage Manager
/// Centralized manager for temporary video storage and cleanup
/// Handles automatic cleanup of video files to prevent memory leaks
@MainActor
public final class VideoStorageManager: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = VideoStorageManager()
    
    // MARK: - Properties
    private var managedVideos: Set<URL> = []
    private let fileManager = FileManager.default
    
    // MARK: - Initialization
    private init() {
        setupCleanupOnTermination()
    }
    
    // MARK: - Public Methods
    
    /// Register a video URL for automatic cleanup management
    /// - Parameter url: The video URL to manage
    public func registerVideo(_ url: URL) {
        managedVideos.insert(url)
        print("📹 [VideoStorageManager] Registered video: \(url.lastPathComponent)")
    }
    
    /// Register multiple video URLs for automatic cleanup management
    /// - Parameter urls: Array of video URLs to manage
    public func registerVideos(_ urls: [URL]) {
        urls.forEach { registerVideo($0) }
    }
    
    /// Clean up a specific video file
    /// - Parameter url: The video URL to clean up
    /// - Returns: True if cleanup succeeded, false otherwise
    @discardableResult
    public func cleanupVideo(_ url: URL) -> Bool {
        defer { managedVideos.remove(url) }
        
        do {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
                print("🗑️ [VideoStorageManager] Cleaned up video: \(url.lastPathComponent)")
                return true
            }
            return true // Already deleted
        } catch {
            print("⚠️ [VideoStorageManager] Failed to clean up video: \(error)")
            return false
        }
    }
    
    /// Clean up multiple video files
    /// - Parameter urls: Array of video URLs to clean up
    public func cleanupVideos(_ urls: [URL]) {
        urls.forEach { cleanupVideo($0) }
    }
    
    /// Clean up all managed videos
    public func cleanupAll() {
        let videos = Array(managedVideos)
        videos.forEach { cleanupVideo($0) }
        managedVideos.removeAll()
        print("✅ [VideoStorageManager] All managed videos cleaned up")
    }
    
    /// Clean up videos except the specified ones
    /// - Parameter keepURLs: URLs to keep (not delete)
    public func cleanupExcept(_ keepURLs: [URL]) {
        let urlsToClean = managedVideos.subtracting(keepURLs)
        urlsToClean.forEach { cleanupVideo($0) }
    }
    
    /// Get the total size of all managed videos
    /// - Returns: Total size in bytes
    public func totalManagedSize() -> Int64 {
        managedVideos.reduce(0) { total, url in
            total + (fileSize(at: url) ?? 0)
        }
    }
    
    /// Get the number of managed videos
    public var managedVideoCount: Int {
        managedVideos.count
    }
    
    // MARK: - Private Methods
    
    private func fileSize(at url: URL) -> Int64? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
    
    private func setupCleanupOnTermination() {
        // Register for app termination notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppTermination),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        
        // Register for memory warning
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleAppTermination() {
        // Clean up all videos when app terminates
        cleanupAll()
    }
    
    @objc private func handleMemoryWarning() {
        // Clean up videos when memory warning received
        print("⚠️ [VideoStorageManager] Memory warning - cleaning up videos")
        cleanupAll()
    }
}

// MARK: - Convenience Methods for ViewModels
public extension VideoStorageManager {
    
    /// Manages video lifecycle for a single video property
    /// Automatically cleans up old video when setting new one
    func updateManagedVideo(current: inout URL?, new: URL?) {
        // Don't do anything if it's the same URL
        if current == new {
            return
        }
        
        // Clean up old video if exists and different from new
        if let oldURL = current {
            cleanupVideo(oldURL)
        }
        
        // Set and register new video
        current = new
        if let newURL = new {
            registerVideo(newURL)
        }
    }
    
    /// Creates a scoped cleanup context for a feature
    /// Returns a cleanup function that should be called on view dismiss
    func createCleanupContext(for videos: [URL]) -> () -> Void {
        registerVideos(videos)
        return { [weak self] in
            self?.cleanupVideos(videos)
        }
    }
}

// MARK: - Debug Helpers
#if DEBUG
public extension VideoStorageManager {
    
    /// Print debug information about managed videos
    func printDebugInfo() {
        print("📊 [VideoStorageManager] Debug Info:")
        print("   Managed videos: \(managedVideoCount)")
        print("   Total size: \(ByteCountFormatter.string(fromByteCount: totalManagedSize(), countStyle: .file))")
        for url in managedVideos {
            let size = fileSize(at: url) ?? 0
            print("   - \(url.lastPathComponent): \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))")
        }
    }
}
#endif