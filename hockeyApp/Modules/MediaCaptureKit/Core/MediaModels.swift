import Foundation
import AVFoundation
import UIKit

// MARK: - Media Types
public enum MediaType: String, Codable {
    case image
    case video
    case audio
}


// MARK: - Media Item
public struct MediaItem: Codable, Equatable {
    public let id: String
    public let type: MediaType
    public let data: Data
    public let mimeType: String
    public let duration: Double? // for video/audio in seconds
    public let captureDate: Date
    public let metadata: [String: String]?
    
    public init(type: MediaType, data: Data, mimeType: String, duration: Double? = nil, metadata: [String: String]? = nil) {
        self.id = UUID().uuidString
        self.type = type
        self.data = data
        self.mimeType = mimeType
        self.duration = duration
        self.captureDate = Date()
        self.metadata = metadata
    }
}


// MARK: - Media Validation Result
public struct MediaValidationResult: Equatable {
    public let isValid: Bool
    public let errors: [MediaValidationError]
    public let warnings: [String]
    
    public init(isValid: Bool, errors: [MediaValidationError], warnings: [String]) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
    }
}

// MARK: - Media Validation Error
// MARK: - Video Validation Status
public enum VideoValidationStatus {
    case valid
    case tooLarge(sizeMB: Double, maxMB: Double)
    case tooShort(durationSeconds: Double, minSeconds: Double)
    case tooLong(durationSeconds: Double, maxSeconds: Double)
    case invalidFile
}

public enum MediaValidationError: LocalizedError, Equatable {
    case fileTooLarge(sizeMB: Double, maxMB: Double)
    case unsupportedFormat(format: String)
    case videoTooLong(seconds: Double, maxSeconds: Double)
    case videoTooShort(seconds: Double, minSeconds: Double)
    case corruptedFile
    case missingData
    
    public var errorDescription: String? {
        switch self {
        case .fileTooLarge(let size, let max):
            return String(format: "File too large (%.1f MB). Maximum: %.0f MB", size, max)
        case .unsupportedFormat(let format):
            return "Unsupported format: \(format)"
        case .videoTooLong(let seconds, let max):
            return String(format: "Video too long (%.0fs). Maximum: %.0fs", seconds, max)
        case .videoTooShort(let seconds, let min):
            return String(format: "Video too short (%.0fs). Minimum: %.0fs", seconds, min)
        case .corruptedFile:
            return "File appears to be corrupted"
        case .missingData:
            return "No data found in file"
        }
    }
}

// MARK: - Supported Media Formats
public struct SupportedMediaFormats {
    public static let images = ["image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"]
    public static let videos = ["video/mp4", "video/mpeg", "video/quicktime", "video/x-m4v", "video/mov"]
    public static let audio = ["audio/wav", "audio/mp3", "audio/mpeg", "audio/aac", "audio/x-m4a"]
}

// MARK: - Media Processing Options
public struct MediaProcessingOptions {
    public var maxImageSizeMB: Double = 20.0  // Increased to match inline limit
    public var maxVideoSizeMB: Double = 2000.0  // 2GB for file API
    public var maxAudioSizeMB: Double = 20.0
    public var imageCompressionQuality: Double = 1.0  // Lossless compression
    public var videoCompressionPreset: String = AVAssetExportPresetPassthrough  // Highest quality (no re-compression)
    public var targetVideoDurationRange: ClosedRange<Double> = 5.0...3600.0  // Up to 1 hour
    
    public init() {}
}

// MARK: - Processed Media Result
public struct ProcessedMediaResult {
    public let originalItem: MediaItem
    public let processedItem: MediaItem?
    public let processingNotes: [String]
    public let wasModified: Bool
    
    public init(originalItem: MediaItem, processedItem: MediaItem?, processingNotes: [String], wasModified: Bool) {
        self.originalItem = originalItem
        self.processedItem = processedItem
        self.processingNotes = processingNotes
        self.wasModified = wasModified
    }
}

// MARK: - Media Stage Data
public struct MediaStageData: Equatable {
    public var images: [UIImage] = []
    public var videos: [URL] = []
    public var textPrompt: String = ""
    
    public init(images: [UIImage] = [], videos: [URL] = [], textPrompt: String = "") {
        self.images = images
        self.videos = videos
        self.textPrompt = textPrompt
    }
    
    public static func == (lhs: MediaStageData, rhs: MediaStageData) -> Bool {
        // Compare counts and text since UIImage doesn't conform to Equatable
        return lhs.images.count == rhs.images.count &&
               lhs.videos == rhs.videos &&
               lhs.textPrompt == rhs.textPrompt
    }
}