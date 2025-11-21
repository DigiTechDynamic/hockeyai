import Foundation

// MARK: - Shot Rater Result Store
/// Lightweight persistence for Shot Rater analysis results to support deep links from notifications
final class ShotRaterResultStore {
    static let shared = ShotRaterResultStore()

    private let userDefaults = UserDefaults.standard
    private let keyPrefix = "shotRater.result."

    private init() {}

    func save(result: ShotAnalysisResult, id: String) {
        do {
            let data = try JSONEncoder().encode(result)
            userDefaults.set(data, forKey: keyPrefix + id)
            print("🗂️ [ShotRaterResultStore] Saved result id=\(id), type=\(result.type.rawValue)")
        } catch {
            print("❌ [ShotRaterResultStore] Failed to save result: \(error)")
        }
    }

    func load(id: String) -> ShotAnalysisResult? {
        guard let data = userDefaults.data(forKey: keyPrefix + id) else { return nil }
        do {
            let result = try JSONDecoder().decode(ShotAnalysisResult.self, from: data)
            print("🗂️ [ShotRaterResultStore] Loaded result id=\(id), type=\(result.type.rawValue)")
            return result
        } catch {
            print("❌ [ShotRaterResultStore] Failed to load result: \(error)")
            return nil
        }
    }
}
