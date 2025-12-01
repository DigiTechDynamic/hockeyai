import Foundation
import UIKit
import Combine

// MARK: - Stored Analysis Result Types

/// Stored STY Check result with metadata
struct StoredSTYCheckResult: Codable, Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let overallScore: Int
    let archetype: String
    let archetypeEmoji: String
    let aiComment: String?
    let photoFileName: String?
    let premiumIntangibles: PremiumIntangibles?

    static func == (lhs: StoredSTYCheckResult, rhs: StoredSTYCheckResult) -> Bool {
        lhs.id == rhs.id
    }
}

/// Stored Skill Check result with metadata
struct StoredSkillCheckResult: Codable, Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let overallScore: Int
    let category: String?
    let aiComment: String
    let videoFileName: String?
    let thumbnailFileName: String?
    let premiumBreakdown: PremiumSkillBreakdown

    static func == (lhs: StoredSkillCheckResult, rhs: StoredSkillCheckResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Analysis Results Store

/// Persistent store for STY Check and Skill Check analysis results
/// Saves results to Documents directory with media files (photos/videos)
final class AnalysisResultsStore: ObservableObject {
    static let shared = AnalysisResultsStore()

    // MARK: - Published State
    @Published private(set) var styCheckResults: [StoredSTYCheckResult] = []
    @Published private(set) var skillCheckResults: [StoredSkillCheckResult] = []

    // MARK: - Private Properties
    private let fileManager = FileManager.default
    private let workQueue = DispatchQueue(label: "AnalysisResultsStore.work")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let directoryURL: URL
    private let styIndexURL: URL
    private let skillIndexURL: URL

    // Maximum results to keep (prevent unbounded storage growth)
    private let maxResults = 50

    // MARK: - Initialization

    private init() {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.directoryURL = documents.appendingPathComponent("AnalysisResults", isDirectory: true)
        self.styIndexURL = directoryURL.appendingPathComponent("sty_index.json")
        self.skillIndexURL = directoryURL.appendingPathComponent("skill_index.json")

        // Ensure directory exists
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        // Load existing results
        loadResults()

        print("📊 [AnalysisResultsStore] Initialized - STY: \(styCheckResults.count), Skill: \(skillCheckResults.count)")
    }

    // MARK: - Public API - STY Check

    /// Save a STY Check result with optional photo
    func saveSTYCheckResult(_ rating: PlayerRating, photo: UIImage?) {
        workQueue.async { [weak self] in
            guard let self = self else { return }

            let id = UUID()
            var photoFileName: String? = nil

            // Save photo if provided
            if let photo = photo {
                let fileName = "sty_\(id.uuidString).jpg"
                let photoURL = self.directoryURL.appendingPathComponent(fileName)
                if let data = photo.jpegData(compressionQuality: 0.8) {
                    try? data.write(to: photoURL, options: [.atomic])
                    photoFileName = fileName
                }
            }

            let storedResult = StoredSTYCheckResult(
                id: id,
                createdAt: Date(),
                overallScore: rating.overallScore,
                archetype: rating.archetype,
                archetypeEmoji: rating.archetypeEmoji,
                aiComment: rating.aiComment,
                photoFileName: photoFileName,
                premiumIntangibles: rating.premiumIntangibles
            )

            // Add to list and trim if needed
            var updated = self.styCheckResults
            updated.insert(storedResult, at: 0) // Newest first
            if updated.count > self.maxResults {
                let removed = updated.removeLast()
                self.cleanupSTYResult(removed)
            }

            // Persist
            self.persistSTYIndex(updated)

            DispatchQueue.main.async {
                self.styCheckResults = updated
                print("✅ [AnalysisResultsStore] Saved STY Check result - Score: \(rating.overallScore)")
            }
        }
    }

    /// Delete a STY Check result
    func deleteSTYCheckResult(_ result: StoredSTYCheckResult) {
        workQueue.async { [weak self] in
            guard let self = self else { return }

            self.cleanupSTYResult(result)
            let updated = self.styCheckResults.filter { $0.id != result.id }
            self.persistSTYIndex(updated)

            DispatchQueue.main.async {
                self.styCheckResults = updated
            }
        }
    }

    /// Load photo for a STY Check result
    func loadSTYPhoto(for result: StoredSTYCheckResult) -> UIImage? {
        guard let fileName = result.photoFileName else { return nil }
        let url = directoryURL.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: url.path)
    }

    /// Get latest STY Check result
    var latestSTYResult: StoredSTYCheckResult? {
        styCheckResults.first
    }

    // MARK: - Public API - Skill Check

    /// Save a Skill Check result with optional video thumbnail
    func saveSkillCheckResult(_ result: SkillAnalysisResult, videoURL: URL?, thumbnail: UIImage?) {
        workQueue.async { [weak self] in
            guard let self = self else { return }

            let id = UUID()
            var videoFileName: String? = nil
            var thumbnailFileName: String? = nil

            // Save video if provided
            if let videoURL = videoURL, self.fileManager.fileExists(atPath: videoURL.path) {
                let fileName = "skill_\(id.uuidString).mp4"
                let destURL = self.directoryURL.appendingPathComponent(fileName)
                try? self.fileManager.copyItem(at: videoURL, to: destURL)
                videoFileName = fileName
            }

            // Save thumbnail if provided
            if let thumbnail = thumbnail {
                let fileName = "skill_thumb_\(id.uuidString).jpg"
                let thumbURL = self.directoryURL.appendingPathComponent(fileName)
                if let data = thumbnail.jpegData(compressionQuality: 0.7) {
                    try? data.write(to: thumbURL, options: [.atomic])
                    thumbnailFileName = fileName
                }
            }

            let storedResult = StoredSkillCheckResult(
                id: id,
                createdAt: Date(),
                overallScore: result.overallScore,
                category: result.category,
                aiComment: result.aiComment,
                videoFileName: videoFileName,
                thumbnailFileName: thumbnailFileName,
                premiumBreakdown: result.premiumBreakdown
            )

            // Add to list and trim if needed
            var updated = self.skillCheckResults
            updated.insert(storedResult, at: 0) // Newest first
            if updated.count > self.maxResults {
                let removed = updated.removeLast()
                self.cleanupSkillResult(removed)
            }

            // Persist
            self.persistSkillIndex(updated)

            DispatchQueue.main.async {
                self.skillCheckResults = updated
                print("✅ [AnalysisResultsStore] Saved Skill Check result - Score: \(result.overallScore)")
            }
        }
    }

    /// Delete a Skill Check result
    func deleteSkillCheckResult(_ result: StoredSkillCheckResult) {
        workQueue.async { [weak self] in
            guard let self = self else { return }

            self.cleanupSkillResult(result)
            let updated = self.skillCheckResults.filter { $0.id != result.id }
            self.persistSkillIndex(updated)

            DispatchQueue.main.async {
                self.skillCheckResults = updated
            }
        }
    }

    /// Load video URL for a Skill Check result
    func loadSkillVideoURL(for result: StoredSkillCheckResult) -> URL? {
        guard let fileName = result.videoFileName else { return nil }
        let url = directoryURL.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    /// Load thumbnail for a Skill Check result
    func loadSkillThumbnail(for result: StoredSkillCheckResult) -> UIImage? {
        guard let fileName = result.thumbnailFileName else { return nil }
        let url = directoryURL.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: url.path)
    }

    /// Get latest Skill Check result
    var latestSkillResult: StoredSkillCheckResult? {
        skillCheckResults.first
    }

    // MARK: - Private Methods

    private func loadResults() {
        // Load STY results
        if let data = try? Data(contentsOf: styIndexURL),
           let saved = try? decoder.decode([StoredSTYCheckResult].self, from: data) {
            self.styCheckResults = saved
        }

        // Load Skill results
        if let data = try? Data(contentsOf: skillIndexURL),
           let saved = try? decoder.decode([StoredSkillCheckResult].self, from: data) {
            self.skillCheckResults = saved
        }
    }

    private func persistSTYIndex(_ results: [StoredSTYCheckResult]) {
        do {
            let data = try encoder.encode(results)
            let tmp = directoryURL.appendingPathComponent("sty_index.tmp")
            try data.write(to: tmp, options: [.atomic])
            if fileManager.fileExists(atPath: styIndexURL.path) {
                try? fileManager.removeItem(at: styIndexURL)
            }
            try? fileManager.moveItem(at: tmp, to: styIndexURL)
        } catch {
            print("❌ [AnalysisResultsStore] Failed to persist STY index: \(error)")
        }
    }

    private func persistSkillIndex(_ results: [StoredSkillCheckResult]) {
        do {
            let data = try encoder.encode(results)
            let tmp = directoryURL.appendingPathComponent("skill_index.tmp")
            try data.write(to: tmp, options: [.atomic])
            if fileManager.fileExists(atPath: skillIndexURL.path) {
                try? fileManager.removeItem(at: skillIndexURL)
            }
            try? fileManager.moveItem(at: tmp, to: skillIndexURL)
        } catch {
            print("❌ [AnalysisResultsStore] Failed to persist Skill index: \(error)")
        }
    }

    private func cleanupSTYResult(_ result: StoredSTYCheckResult) {
        if let fileName = result.photoFileName {
            let url = directoryURL.appendingPathComponent(fileName)
            try? fileManager.removeItem(at: url)
        }
    }

    private func cleanupSkillResult(_ result: StoredSkillCheckResult) {
        if let fileName = result.videoFileName {
            let url = directoryURL.appendingPathComponent(fileName)
            try? fileManager.removeItem(at: url)
        }
        if let fileName = result.thumbnailFileName {
            let url = directoryURL.appendingPathComponent(fileName)
            try? fileManager.removeItem(at: url)
        }
    }
}
