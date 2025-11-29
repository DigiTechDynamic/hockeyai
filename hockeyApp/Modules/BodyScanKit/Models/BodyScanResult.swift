import Foundation
import UIKit

// MARK: - Body Scan Result Model
/// Stores body scan measurements and captured image for AI analysis context
struct BodyScanResult: Codable, Identifiable {
    let id: UUID
    let scanDate: Date

    // MARK: - Image Storage
    /// Relative path to saved image (stored in app documents)
    let imagePath: String?

    // MARK: - Detected Measurements (in inches, converted from pose detection)
    /// Arm span from fingertip to fingertip (T-pose)
    let armSpanInches: Double?

    /// Shoulder width
    let shoulderWidthInches: Double?

    /// Torso length (shoulder to hip)
    let torsoLengthInches: Double?

    /// Leg length (hip to ankle)
    let legLengthInches: Double?

    // MARK: - Calculated Ratios (useful for stick fitting)
    /// Arm span divided by height - typically ~1.0 for most people
    var armToHeightRatio: Double? {
        guard let armSpan = armSpanInches, let height = estimatedHeightInches else { return nil }
        return armSpan / height
    }

    /// Torso length divided by leg length
    var torsoToLegRatio: Double? {
        guard let torso = torsoLengthInches, let leg = legLengthInches, leg > 0 else { return nil }
        return torso / leg
    }

    /// Estimated height based on pose (or nil if using profile height)
    let estimatedHeightInches: Double?

    // MARK: - Detection Metadata
    /// Confidence score from pose detection (0.0 - 1.0)
    let poseConfidence: Double

    /// Which pose was detected/used
    let detectedPose: DetectedPose

    /// How we determined scale for measurements
    let referenceMethod: ReferenceMethod

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        scanDate: Date = Date(),
        imagePath: String? = nil,
        armSpanInches: Double? = nil,
        shoulderWidthInches: Double? = nil,
        torsoLengthInches: Double? = nil,
        legLengthInches: Double? = nil,
        estimatedHeightInches: Double? = nil,
        poseConfidence: Double = 0.0,
        detectedPose: DetectedPose = .relaxedStand,
        referenceMethod: ReferenceMethod = .userProvidedHeight
    ) {
        self.id = id
        self.scanDate = scanDate
        self.imagePath = imagePath
        self.armSpanInches = armSpanInches
        self.shoulderWidthInches = shoulderWidthInches
        self.torsoLengthInches = torsoLengthInches
        self.legLengthInches = legLengthInches
        self.estimatedHeightInches = estimatedHeightInches
        self.poseConfidence = poseConfidence
        self.detectedPose = detectedPose
        self.referenceMethod = referenceMethod
    }
}

// MARK: - Detected Pose Types
enum DetectedPose: String, Codable {
    /// Arms extended out to sides (best for arm span measurement)
    case tPose = "t_pose"

    /// Standing naturally with arms at sides
    case relaxedStand = "relaxed_stand"

    /// Slight crouch, hockey-ready position
    case hockeyStance = "hockey_stance"
}

// MARK: - Reference Method for Scale
enum ReferenceMethod: String, Codable {
    /// Using the user's profile height as reference for scaling
    case userProvidedHeight = "user_provided_height"

    /// Detected a door frame or known object for scale
    case doorFrame = "door_frame"

    /// Using a hockey stick of known length in frame
    case hockeyStick = "hockey_stick"
}

// MARK: - Display Helpers
extension BodyScanResult {
    /// Formatted height for display (e.g., "5'10"")
    var heightDisplay: String? {
        guard let inches = estimatedHeightInches else { return nil }
        let feet = Int(inches) / 12
        let remainingInches = Int(inches) % 12
        return "\(feet)'\(remainingInches)\""
    }

    /// Formatted arm span for display
    var armSpanDisplay: String? {
        guard let inches = armSpanInches else { return nil }
        let feet = Int(inches) / 12
        let remainingInches = Int(inches) % 12
        return "\(feet)'\(remainingInches)\""
    }

    /// Formatted shoulder width for display
    var shoulderWidthDisplay: String? {
        guard let inches = shoulderWidthInches else { return nil }
        return "\(Int(inches))\""
    }

    /// Formatted torso length for display
    var torsoLengthDisplay: String? {
        guard let inches = torsoLengthInches else { return nil }
        return "\(Int(inches))\""
    }

    /// Formatted leg length for display
    var legLengthDisplay: String? {
        guard let inches = legLengthInches else { return nil }
        return "\(Int(inches))\""
    }

    /// Confidence as percentage string
    var confidenceDisplay: String {
        "\(Int(poseConfidence * 100))%"
    }

    /// Whether scan has usable measurements
    var hasMeasurements: Bool {
        armSpanInches != nil || shoulderWidthInches != nil || torsoLengthInches != nil || estimatedHeightInches != nil
    }
}

// MARK: - Image Loading
extension BodyScanResult {
    /// Load the captured image from disk
    func loadImage() -> UIImage? {
        guard let path = imagePath else { return nil }
        let url = BodyScanStorage.documentsDirectory.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - Storage Manager
final class BodyScanStorage {
    static let shared = BodyScanStorage()
    private init() {}

    private let userDefaultsKey = "bodyScanResult"

    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Save/Load Result
    func save(_ result: BodyScanResult) {
        if let encoded = try? JSONEncoder().encode(result) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    func load() -> BodyScanResult? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let result = try? JSONDecoder().decode(BodyScanResult.self, from: data) else {
            return nil
        }
        return result
    }

    func clear() {
        // Delete image file if exists
        if let result = load(), let path = result.imagePath {
            let url = Self.documentsDirectory.appendingPathComponent(path)
            try? FileManager.default.removeItem(at: url)
        }
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    // MARK: - Save Image
    /// Saves image to documents directory and returns the relative path
    func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }

        let filename = "body_scan_\(UUID().uuidString).jpg"
        let url = Self.documentsDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: url)
            return filename
        } catch {
            print("[BodyScanStorage] Failed to save image: \(error)")
            return nil
        }
    }

    // MARK: - Check if scan exists
    var hasScan: Bool {
        load() != nil
    }
}
