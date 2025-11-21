import Foundation
import Combine

// MARK: - Shot Rater Background Manager
/// Tracks background analysis state by shot type so other views can reflect progress
@MainActor
final class ShotRaterBackgroundManager: ObservableObject {
    static let shared = ShotRaterBackgroundManager()

    @Published private(set) var analyzing: [ShotType: Bool] = [:]
    @Published private(set) var latestResults: [ShotType: ShotAnalysisResult] = [:]
    private var analysisTasks: [ShotType: Task<Void, Never>] = [:]
    private var cancelledTypes: Set<ShotType> = []

    private init() {}

    func setAnalyzing(_ value: Bool, for type: ShotType) {
        analyzing[type] = value
    }

    func isAnalyzing(_ type: ShotType) -> Bool {
        analyzing[type] ?? false
    }

    func setLatestResult(_ result: ShotAnalysisResult, for type: ShotType) {
        latestResults[type] = result
    }

    func latestResult(for type: ShotType) -> ShotAnalysisResult? {
        latestResults[type]
    }

    func clearResult(for type: ShotType) {
        latestResults[type] = nil
    }

    func setAnalysisTask(for type: ShotType, task: Task<Void, Never>) {
        analysisTasks[type]?.cancel()
        analysisTasks[type] = task
        cancelledTypes.remove(type)
    }

    func cancelAnalysis(for type: ShotType, broadcast: Bool = true) {
        analysisTasks[type]?.cancel()
        analysisTasks[type] = nil
        cancelledTypes.insert(type)
        setAnalyzing(false, for: type)
        clearResult(for: type)
        // Also broadcast to any visible flow to cancel immediately (optional)
        if broadcast {
            NotificationCenter.default.post(name: Notification.Name("AIFlowCancel"), object: "shot-rater")
        }
    }

    func isCancelled(_ type: ShotType) -> Bool {
        cancelledTypes.contains(type)
    }

    func consumeCancellationFlag(for type: ShotType) -> Bool {
        if cancelledTypes.contains(type) {
            cancelledTypes.remove(type)
            return true
        }
        return false
    }
}
