import Foundation

// MARK: - Workout State

/// Represents the current state of workout execution
enum WorkoutState: String, Codable {
    case preWorkout     // Before workout starts (equipment check, overview)
    case getReady       // 10-second countdown before first exercise
    case exerciseActive // Currently performing an exercise
    case restBetweenExercises // Rest period between exercises
    case completed      // Workout finished
}

// MARK: - Workout Session

/// Main model for tracking workout execution state with timestamp-based timing
/// Uses Date timestamps instead of counters for accurate elapsed time calculation
/// that works correctly even when app backgrounds or is force-quit
struct WorkoutSession: Codable {
    // MARK: - Identifiers

    let workoutId: UUID
    let workoutName: String

    // MARK: - Exercises

    let exercises: [ExerciseSession]
    var currentExerciseIndex: Int

    // MARK: - Timing (Timestamp-Based)

    /// When the workout started (nil if not started yet)
    var startTime: Date?

    /// When the workout was paused (nil if not paused)
    var pausedTime: Date?

    /// Total accumulated paused duration in seconds
    /// Used to calculate actual workout time excluding pauses
    var accumulatedPausedDuration: TimeInterval

    // MARK: - Configuration

    /// Global rest duration between exercises (user-adjustable 15s-5min)
    /// Default: 45 seconds
    var restDuration: TimeInterval

    /// Whether audio coaching is enabled for this session
    var audioEnabled: Bool

    // MARK: - Initialization

    init(
        workout: Workout,
        currentExerciseIndex: Int = 0,
        startTime: Date? = nil,
        pausedTime: Date? = nil,
        accumulatedPausedDuration: TimeInterval = 0,
        restDuration: TimeInterval = 45,
        audioEnabled: Bool = true
    ) {
        self.workoutId = workout.id
        self.workoutName = workout.name
        self.exercises = workout.exercises.map { ExerciseSession(exercise: $0) }
        self.currentExerciseIndex = currentExerciseIndex
        self.startTime = startTime
        self.pausedTime = pausedTime
        self.accumulatedPausedDuration = accumulatedPausedDuration
        self.restDuration = restDuration
        self.audioEnabled = audioEnabled
    }

    // MARK: - Computed Properties

    /// Total elapsed time since workout started (excluding pauses)
    /// Returns 0 if workout hasn't started yet
    var elapsedTime: TimeInterval {
        guard let start = startTime else { return 0 }

        let now = Date()
        var elapsed = now.timeIntervalSince(start)

        // Subtract accumulated paused time
        elapsed -= accumulatedPausedDuration

        // If currently paused, also subtract time since pause began
        if let pauseStart = pausedTime {
            elapsed -= now.timeIntervalSince(pauseStart)
        }

        return max(0, elapsed)
    }

    /// Current exercise being performed
    var currentExercise: ExerciseSession? {
        guard exercises.indices.contains(currentExerciseIndex) else { return nil }
        return exercises[currentExerciseIndex]
    }

    /// Next exercise to be performed
    var nextExercise: ExerciseSession? {
        let nextIndex = currentExerciseIndex + 1
        guard exercises.indices.contains(nextIndex) else { return nil }
        return exercises[nextIndex]
    }

    /// Whether workout is currently paused
    var isPaused: Bool {
        pausedTime != nil
    }

    /// Total number of exercises in workout
    var totalExercises: Int {
        exercises.count
    }

    /// Number of completed exercises
    var completedExercisesCount: Int {
        exercises.filter { $0.isCompleted }.count
    }

    /// Progress percentage (0.0 to 1.0)
    var progressPercentage: Double {
        guard totalExercises > 0 else { return 0 }
        return Double(completedExercisesCount) / Double(totalExercises)
    }

    /// Whether all exercises are completed
    var isWorkoutComplete: Bool {
        completedExercisesCount == totalExercises
    }
}

// MARK: - Exercise Session

/// Tracks the state and timing of a single exercise during workout execution
struct ExerciseSession: Codable, Identifiable {
    // MARK: - Identifiers

    let id: UUID
    let exerciseName: String
    let exerciseCategory: DrillCategory

    // MARK: - Configuration

    let config: ExerciseConfig
    let equipment: [Equipment]

    // MARK: - Execution State

    /// When this exercise started (nil if not started)
    var startTime: Date?

    /// When this exercise ended (nil if not completed)
    var endTime: Date?

    /// When this exercise was paused (nil if not paused)
    var pausedAt: Date?

    /// Accumulated paused time for this exercise only
    var accumulatedPausedTime: TimeInterval

    /// Whether this exercise was skipped
    var skipped: Bool

    // MARK: - Actual Performance Data

    /// Actual reps completed (for rep-based exercises)
    var actualReps: Int?

    /// Actual sets completed (for set-based exercises)
    var actualSets: Int?

    /// Actual weight used (for weight-based exercises)
    var actualWeight: Double?

    /// Notes about performance
    var notes: String?

    // MARK: - Initialization

    init(
        exercise: Exercise,
        startTime: Date? = nil,
        endTime: Date? = nil,
        pausedAt: Date? = nil,
        accumulatedPausedTime: TimeInterval = 0,
        skipped: Bool = false,
        actualReps: Int? = nil,
        actualSets: Int? = nil,
        actualWeight: Double? = nil,
        notes: String? = nil
    ) {
        self.id = exercise.id
        self.exerciseName = exercise.name
        self.exerciseCategory = exercise.category
        self.config = exercise.config
        self.equipment = exercise.equipment
        self.startTime = startTime
        self.endTime = endTime
        self.pausedAt = pausedAt
        self.accumulatedPausedTime = accumulatedPausedTime
        self.skipped = skipped
        self.actualReps = actualReps
        self.actualSets = actualSets
        self.actualWeight = actualWeight
        self.notes = notes
    }

    // MARK: - Computed Properties

    /// Whether exercise is currently active (started but not ended)
    var isActive: Bool {
        startTime != nil && endTime == nil
    }

    /// Whether exercise is completed (either finished or skipped)
    var isCompleted: Bool {
        endTime != nil || skipped
    }

    /// Whether exercise is currently paused
    var isPaused: Bool {
        pausedAt != nil
    }

    /// Elapsed time for this exercise (excluding pauses)
    /// Returns time from start to end for completed exercises
    /// Returns time from start to now for active exercises
    var elapsedTime: TimeInterval {
        guard let start = startTime else { return 0 }

        let end = endTime ?? Date()
        var elapsed = end.timeIntervalSince(start)

        // Subtract accumulated paused time
        elapsed -= accumulatedPausedTime

        // If currently paused, also subtract time since pause began
        if let pause = pausedAt {
            elapsed -= Date().timeIntervalSince(pause)
        }

        return max(0, elapsed)
    }

    /// Time remaining for time-based exercises
    /// Returns nil for non-time-based exercises
    var timeRemaining: TimeInterval? {
        switch config {
        case .timeBased(let duration):
            return max(0, duration - elapsedTime)
        case .timeSets(let duration, _, _):
            return max(0, duration - elapsedTime)
        default:
            return nil
        }
    }

    /// Target duration for time-based exercises
    var targetDuration: TimeInterval? {
        switch config {
        case .timeBased(let duration):
            return duration
        case .timeSets(let duration, _, _):
            return duration
        default:
            return nil
        }
    }

    /// Target reps for rep-based exercises
    var targetReps: Int? {
        switch config {
        case .repsOnly(let reps):
            return reps
        case .repsSets(let reps, _):
            return reps
        case .weightRepsSets(_, let reps, _, _):
            return reps
        case .countBased(let count):
            return count
        default:
            return nil
        }
    }

    /// Target sets for set-based exercises
    var targetSets: Int? {
        switch config {
        case .repsSets(_, let sets):
            return sets
        case .weightRepsSets(_, _, let sets, _):
            return sets
        case .timeSets(_, let sets, _):
            return sets
        default:
            return nil
        }
    }
}

// MARK: - Workout History (for future persistence)

/// Record of a completed workout session (not persisted in MVP - session only)
/// Future: Save to WorkoutHistoryStore for tracking progress and streaks
struct WorkoutHistory: Codable, Identifiable {
    let id: UUID
    let workoutId: UUID
    let workoutName: String

    let startTime: Date
    let endTime: Date

    let exercises: [ExerciseCompletion]

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var completionRate: Double {
        let completed = exercises.filter { $0.completed }.count
        guard exercises.count > 0 else { return 0 }
        return Double(completed) / Double(exercises.count)
    }
}

/// Record of exercise completion within a workout
struct ExerciseCompletion: Codable {
    let exerciseId: UUID
    let exerciseName: String
    let completed: Bool
    let skipped: Bool
    let actualDuration: TimeInterval?
    let actualReps: Int?
    let actualSets: Int?
    let actualWeight: Double?
}
