import Foundation

/// Repository for persisting and loading workout data
/// Handles first-launch initialization with sample workouts and all CRUD operations
final class WorkoutRepository {
    static let shared = WorkoutRepository()

    private let userDefaults = UserDefaults.standard
    private let storageKey = "train.workouts"
    private let firstLaunchKey = "train.firstLaunchComplete"

    private init() {
        loadDefaultsIfNeeded()
    }

    // MARK: - Public API

    /// Load all workouts from storage
    /// Returns sample workouts if no saved data exists
    func loadWorkouts() -> [Workout] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            print("⚠️ [WorkoutRepository] No saved workouts, returning samples")
            return SampleWorkouts.all
        }

        do {
            let workouts = try JSONDecoder().decode([Workout].self, from: data)
            print("✅ [WorkoutRepository] Loaded \(workouts.count) workouts from storage")
            return workouts
        } catch {
            print("❌ [WorkoutRepository] Failed to decode workouts: \(error)")
            return SampleWorkouts.all
        }
    }

    /// Save workouts to persistent storage
    /// Call this after any modification to workouts array
    func saveWorkouts(_ workouts: [Workout]) {
        do {
            let data = try JSONEncoder().encode(workouts)
            userDefaults.set(data, forKey: storageKey)
            print("✅ [WorkoutRepository] Saved \(workouts.count) workouts")
        } catch {
            print("❌ [WorkoutRepository] Failed to save workouts: \(error)")
        }
    }

    // MARK: - First Launch

    /// Load sample workouts on first launch
    private func loadDefaultsIfNeeded() {
        if !userDefaults.bool(forKey: firstLaunchKey) {
            print("🎉 [WorkoutRepository] First launch - loading sample workouts")
            saveWorkouts(SampleWorkouts.all)
            userDefaults.set(true, forKey: firstLaunchKey)
        }
    }

    // MARK: - Utilities

    /// Reset all workouts to default samples (useful for debugging/testing)
    func resetToDefaults() {
        print("🔄 [WorkoutRepository] Resetting to default workouts")
        saveWorkouts(SampleWorkouts.all)
    }
}
