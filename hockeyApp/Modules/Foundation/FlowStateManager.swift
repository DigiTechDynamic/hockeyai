import Foundation
import UIKit

// MARK: - Flow Types
/// Identifies the different multi-step flows in the app
enum FlowType: String, Codable, CaseIterable {
    case stickAnalyzer = "stick_analyzer"
    case aiCoach = "ai_coach"
    case skillCheck = "skill_check"
    case styCheck = "sty_check"
    case hockeyCard = "hockey_card"
    case shotRater = "shot_rater"

    var displayName: String {
        switch self {
        case .stickAnalyzer: return "Stick Analysis"
        case .aiCoach: return "AI Coach"
        case .skillCheck: return "Skill Check"
        case .styCheck: return "STY Check"
        case .hockeyCard: return "Hockey Card"
        case .shotRater: return "Shot Rater"
        }
    }
}

// MARK: - Persistable Flow State Protocol
/// Protocol for flow states that can be saved and restored
protocol PersistableFlowState: Codable {
    static var flowType: FlowType { get }
    var currentStageId: String { get }
    var savedAt: Date { get }

    /// Validate that the saved state is still usable (e.g., media files exist)
    func isValid() -> Bool
}

// MARK: - Flow State Manager
/// Manages persistence of flow states so users can resume where they left off
/// Useful when users hit paywalls or leave mid-flow
final class FlowStateManager {

    // MARK: - Singleton
    static let shared = FlowStateManager()

    // MARK: - Configuration
    private let stateExpirationDays: Int = 7
    private let mediaDirectoryName = "FlowMedia"

    // MARK: - Storage Keys
    private let userDefaults = UserDefaults.standard
    private func stateKey(for flowType: FlowType) -> String {
        return "flow_state_\(flowType.rawValue)"
    }

    // MARK: - Initialization
    private init() {
        // Create media directory if needed
        createMediaDirectoryIfNeeded()

        // Clean up expired states on launch
        cleanupExpiredStates()
    }

    // MARK: - Public Methods

    /// Save a flow state
    func save<T: PersistableFlowState>(_ state: T) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(state)
            userDefaults.set(data, forKey: stateKey(for: T.flowType))
            print("💾 [FlowStateManager] Saved \(T.flowType.displayName) state at stage: \(state.currentStageId)")
        } catch {
            print("❌ [FlowStateManager] Failed to save state: \(error)")
        }
    }

    /// Load a saved flow state
    func load<T: PersistableFlowState>(_ type: T.Type) -> T? {
        guard let data = userDefaults.data(forKey: stateKey(for: T.flowType)) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let state = try decoder.decode(T.self, from: data)

            // Check if expired
            if isExpired(state.savedAt) {
                print("⏰ [FlowStateManager] \(T.flowType.displayName) state expired, clearing...")
                clear(T.flowType)
                return nil
            }

            // Check if still valid (e.g., media files exist)
            if !state.isValid() {
                print("⚠️ [FlowStateManager] \(T.flowType.displayName) state invalid (missing files), clearing...")
                clear(T.flowType)
                return nil
            }

            print("📂 [FlowStateManager] Loaded \(T.flowType.displayName) state from stage: \(state.currentStageId)")
            return state
        } catch {
            print("❌ [FlowStateManager] Failed to load state: \(error)")
            clear(T.flowType)
            return nil
        }
    }

    /// Check if a saved state exists for a flow type
    func hasSavedState(for flowType: FlowType) -> Bool {
        guard let data = userDefaults.data(forKey: stateKey(for: flowType)) else {
            return false
        }

        // Try to decode just to check validity
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            // Decode as generic to check date
            struct MinimalState: Codable {
                let savedAt: Date
            }

            let minimal = try decoder.decode(MinimalState.self, from: data)

            if isExpired(minimal.savedAt) {
                clear(flowType)
                return false
            }

            return true
        } catch {
            return false
        }
    }

    /// Get saved state info without fully loading it
    func getSavedStateInfo(for flowType: FlowType) -> (stageId: String, savedAt: Date)? {
        guard let data = userDefaults.data(forKey: stateKey(for: flowType)) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            struct StateInfo: Codable {
                let currentStageId: String
                let savedAt: Date
            }

            let info = try decoder.decode(StateInfo.self, from: data)

            if isExpired(info.savedAt) {
                clear(flowType)
                return nil
            }

            return (info.currentStageId, info.savedAt)
        } catch {
            return nil
        }
    }

    /// Clear saved state for a flow type
    func clear(_ flowType: FlowType) {
        userDefaults.removeObject(forKey: stateKey(for: flowType))
        print("🗑️ [FlowStateManager] Cleared \(flowType.displayName) state")
    }

    /// Clear all saved states
    func clearAll() {
        for flowType in FlowType.allCases {
            clear(flowType)
        }

        // Also clean up media directory
        cleanupMediaDirectory()

        print("🗑️ [FlowStateManager] Cleared all flow states")
    }

    // MARK: - Media File Management

    /// Get the directory for storing flow media files
    var mediaDirectory: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(mediaDirectoryName, isDirectory: true)
    }

    /// Save an image to the flow media directory
    /// Returns the file path relative to documents directory
    func saveImage(_ image: UIImage, identifier: String, flowType: FlowType) -> String? {
        let fileName = "\(flowType.rawValue)_\(identifier)_\(UUID().uuidString).jpg"
        let fileURL = mediaDirectory.appendingPathComponent(fileName)

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("❌ [FlowStateManager] Failed to convert image to JPEG")
            return nil
        }

        do {
            try data.write(to: fileURL)
            print("📸 [FlowStateManager] Saved image: \(fileName)")
            return "\(mediaDirectoryName)/\(fileName)"
        } catch {
            print("❌ [FlowStateManager] Failed to save image: \(error)")
            return nil
        }
    }

    /// Save a video to the flow media directory
    /// Returns the file path relative to documents directory
    func saveVideo(from sourceURL: URL, identifier: String, flowType: FlowType) -> String? {
        let fileName = "\(flowType.rawValue)_\(identifier)_\(UUID().uuidString).mp4"
        let fileURL = mediaDirectory.appendingPathComponent(fileName)

        do {
            // Copy file to our managed directory
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: fileURL)
            print("🎬 [FlowStateManager] Saved video: \(fileName)")
            return "\(mediaDirectoryName)/\(fileName)"
        } catch {
            print("❌ [FlowStateManager] Failed to save video: \(error)")
            return nil
        }
    }

    /// Load an image from a saved path
    func loadImage(from relativePath: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(relativePath)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("⚠️ [FlowStateManager] Image not found: \(relativePath)")
            return nil
        }

        return UIImage(contentsOfFile: fileURL.path)
    }

    /// Get full URL for a saved media file
    func getMediaURL(for relativePath: String) -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(relativePath)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return fileURL
    }

    /// Check if a media file exists
    func mediaFileExists(at relativePath: String) -> Bool {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(relativePath)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// Delete a specific media file
    func deleteMediaFile(at relativePath: String) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(relativePath)

        do {
            try FileManager.default.removeItem(at: fileURL)
            print("🗑️ [FlowStateManager] Deleted media: \(relativePath)")
        } catch {
            print("⚠️ [FlowStateManager] Failed to delete media: \(error)")
        }
    }

    // MARK: - Private Methods

    private func isExpired(_ date: Date) -> Bool {
        let expirationDate = Calendar.current.date(byAdding: .day, value: stateExpirationDays, to: date)!
        return Date() > expirationDate
    }

    private func createMediaDirectoryIfNeeded() {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: mediaDirectory.path) {
            do {
                try fileManager.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
                print("📁 [FlowStateManager] Created media directory")
            } catch {
                print("❌ [FlowStateManager] Failed to create media directory: \(error)")
            }
        }
    }

    private func cleanupExpiredStates() {
        for flowType in FlowType.allCases {
            if let data = userDefaults.data(forKey: stateKey(for: flowType)) {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601

                    struct MinimalState: Codable {
                        let savedAt: Date
                    }

                    let minimal = try decoder.decode(MinimalState.self, from: data)

                    if isExpired(minimal.savedAt) {
                        clear(flowType)
                        print("🧹 [FlowStateManager] Cleaned up expired \(flowType.displayName) state")
                    }
                } catch {
                    // Invalid data, clear it
                    clear(flowType)
                }
            }
        }
    }

    private func cleanupMediaDirectory() {
        let fileManager = FileManager.default

        do {
            let files = try fileManager.contentsOfDirectory(at: mediaDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
            print("🧹 [FlowStateManager] Cleaned up media directory")
        } catch {
            print("⚠️ [FlowStateManager] Failed to cleanup media directory: \(error)")
        }
    }

    // MARK: - Debug Methods

    #if DEBUG
    /// Print status of all saved states
    func printStatus() {
        print("\n=== Flow State Manager Status ===")

        for flowType in FlowType.allCases {
            if let info = getSavedStateInfo(for: flowType) {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .abbreviated
                let timeAgo = formatter.localizedString(for: info.savedAt, relativeTo: Date())
                print("✅ \(flowType.displayName): Stage '\(info.stageId)' (saved \(timeAgo))")
            } else {
                print("⚪ \(flowType.displayName): No saved state")
            }
        }

        // Count media files
        do {
            let files = try FileManager.default.contentsOfDirectory(at: mediaDirectory, includingPropertiesForKeys: nil)
            print("📁 Media files: \(files.count)")
        } catch {
            print("📁 Media files: 0")
        }

        print("=================================\n")
    }
    #endif
}

// MARK: - Convenience Extensions

extension FlowStateManager {
    /// Format saved time for display
    func formattedSaveTime(for flowType: FlowType) -> String? {
        guard let info = getSavedStateInfo(for: flowType) else { return nil }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: info.savedAt, relativeTo: Date())
    }

    /// Get human-readable stage name for a flow type
    func getReadableStageInfo(for flowType: FlowType) -> String? {
        guard let info = getSavedStateInfo(for: flowType) else { return nil }

        // Map stage IDs to readable names
        let stageNames: [String: String] = [
            // Stick Analyzer
            "player-profile": "Player Profile",
            "body-scan": "Body Scan",
            "shooting-priority": "Shooting Priority",
            "primary-shot": "Primary Shot",
            "shooting-zone": "Shooting Zone",

            // AI Coach
            "shot-type-selection": "Shot Type Selection",
            "phone-setup-tutorial": "Phone Setup",
            "front-net-capture": "Front Net Video",
            "side-angle-capture": "Side Angle Video",

            // General
            "processing": "Processing",
            "results": "Results"
        ]

        return stageNames[info.stageId] ?? info.stageId.replacingOccurrences(of: "-", with: " ").capitalized
    }
}
