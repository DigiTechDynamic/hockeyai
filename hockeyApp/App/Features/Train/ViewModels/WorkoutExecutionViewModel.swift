import Foundation
import SwiftUI
import Combine
import AVFoundation

// MARK: - Workout Execution State

/// Represents the current state of the workout execution flow
/// Note: Pausing is handled by isPaused flag, not a separate state
/// Note: PreWorkout removed - settings now handled in WorkoutDetailView
enum WorkoutExecutionState: Equatable {
    case getReady            // 10-second countdown before first exercise
    case exerciseActive      // Exercise is currently active
    case restBetweenExercises // Rest period between exercises
    case completed           // All exercises finished
}

// MARK: - Workout Execution ViewModel

/// Manages workout execution with state machine, timestamp-based timer, and audio integration
@MainActor
class WorkoutExecutionViewModel: ObservableObject {

    // MARK: - Published State

    @Published var state: WorkoutExecutionState = .getReady
    @Published var timeRemaining: TimeInterval = 0  // Countdown for current phase
    @Published var workoutElapsedTime: TimeInterval = 0  // Total workout time
    @Published var currentExerciseIndex: Int = 0
    @Published var restDuration: TimeInterval = 45  // Will be overridden by saved default
    @Published var audioEnabled: Bool = true
    @Published var isPaused: Bool = false
    @Published var backgroundDuration: TimeInterval = 0

    // MARK: - Exercise Progress Tracking (Manual Completion)

    @Published var currentExerciseElapsedTime: TimeInterval = 0  // Time spent on current exercise
    @Published var currentCount: Int = 0  // For countBased exercises
    @Published var currentReps: Int = 0   // For reps-based exercises
    @Published var currentSet: Int = 1    // For set-based exercises
    @Published var isRestingBetweenSets: Bool = false  // True when resting between sets
    @Published var setRestDuration: TimeInterval = 30  // Rest between sets (default 30s)

    // MARK: - Private State

    private let workout: Workout
    private var audioController: AudioController

    // DEBUG: Different voices for each state (for testing)
    #if DEBUG
    private let debugVoices: [WorkoutExecutionState: String] = [
        .getReady: "com.apple.voice.compact.en-AU.Karen",           // Australian - Energetic
        .exerciseActive: "com.apple.voice.compact.en-GB.Daniel",    // British Male - Commanding
        .restBetweenExercises: "com.apple.voice.compact.en-US.Zoe", // Female - Calming
        .completed: "com.apple.voice.compact.en-US.Samantha"        // Female - Celebratory
    ]
    #else
    private let debugVoices: [WorkoutExecutionState: String] = [:]
    #endif

    // Timestamp-based timer tracking
    private var workoutStartDate: Date?
    private var phaseStartDate: Date?  // Start of current phase (exercise/rest/getReady)
    private var pausedAt: Date?
    private var accumulatedPausedTime: TimeInterval = 0
    private var backgroundedAt: Date?

    // Timer
    private var timerCancellable: AnyCancellable?

    // Constants
    private let getReadyDuration: TimeInterval = 10
    private let minRestDuration: TimeInterval = 15
    private let maxRestDuration: TimeInterval = 300
    private let restAdjustmentIncrement: TimeInterval = 15

    // Persistence keys
    private let stateKey = "workout.execution.state"

    // MARK: - Initialization

    init(workout: Workout) {
        self.workout = workout
        self.audioController = AudioController()

        setupLifecycleObservers()

        // Initialize rest duration from user preference or app default
        if let saved = UserDefaults.standard.object(forKey: AppSettings.StorageKeys.defaultRestDuration) as? Double {
            self.restDuration = saved
        } else {
            self.restDuration = TimeInterval(AppSettings.Training.restBetweenDrills)
        }
    }

    // MARK: - Public Methods

    /// Start the workout with get ready countdown
    func startWorkout() {
        // No guard needed - always starts fresh from WorkoutDetailView

        workoutStartDate = Date()
        state = .getReady
        timeRemaining = getReadyDuration
        phaseStartDate = Date()

        // Audio: "Get ready for [Exercise Name]"
        if let firstExercise = workout.exercises.first, audioEnabled {
            let voice = debugVoices[.getReady]
            audioController.speak("Get ready for \(firstExercise.name)", priority: .important, phaseId: "getReady:0", voiceIdentifier: voice)
        }

        startUITimer()

        // Prevent screen sleep during workout
        UIApplication.shared.isIdleTimerDisabled = true
    }

    /// Begin an exercise at the specified index
    func startExercise(at index: Int) {
        guard index < workout.exercises.count else {
            completeWorkout()
            return
        }

        currentExerciseIndex = index
        state = .exerciseActive
        phaseStartDate = Date()
        accumulatedPausedTime = 0

        // Reset exercise progress tracking
        currentExerciseElapsedTime = 0
        currentCount = 0
        currentReps = 0
        currentSet = 1
        isRestingBetweenSets = false

        let exercise = workout.exercises[index]

        // Set rest duration between sets (if applicable)
        switch exercise.config {
        case .timeSets(_, _, let restTime):
            setRestDuration = restTime ?? 30
        case .repsSets, .weightRepsSets:
            // Use category default or 30s
            setRestDuration = exercise.category.defaultRestBetweenSets > 0
                ? exercise.category.defaultRestBetweenSets
                : 30
        default:
            setRestDuration = 30
        }

        // Set time remaining based on exercise config
        switch exercise.config {
        case .timeBased(let duration):
            timeRemaining = duration
        case .timeSets(let duration, _, _):
            timeRemaining = duration
        default:
            // Manual completion exercises (countBased, repsOnly, etc.)
            // Don't set a countdown timer - use stopwatch mode
            timeRemaining = 0
        }

        // No voice announcement - START sound already played in handlePhaseCompletion
        startUITimer()
    }

    /// Start rest period before the next exercise
    func startRest(beforeExerciseAt index: Int) {
        guard index < workout.exercises.count else {
            completeWorkout()
            return
        }

        state = .restBetweenExercises
        phaseStartDate = Date()
        accumulatedPausedTime = 0

        // Use exercise-specific rest duration or global default
        let exercise = workout.exercises[currentExerciseIndex]
        timeRemaining = exercise.effectiveRestAfterExercise > 0 ? exercise.effectiveRestAfterExercise : restDuration

        // No voice announcement - "Up next" already spoken after DONE sound
        startUITimer()
    }

    /// Pause the current timer
    func pause() {
        guard !isPaused else { return }

        pausedAt = Date()
        isPaused = true
        timerCancellable?.cancel()

        // Stop all audio when pausing
        audioController.pauseAll()
    }

    /// Resume the timer
    func resume() {
        guard isPaused else { return }

        if let pauseDate = pausedAt {
            accumulatedPausedTime += Date().timeIntervalSince(pauseDate)
        }
        pausedAt = nil
        isPaused = false

        // Reset de-bounce for new phase
        let phaseId = stateString() + ":\(currentExerciseIndex)"
        audioController.resetDeBounce(phaseId: phaseId)

        startUITimer()
        if audioEnabled {
            // Use current state's voice for resume
            let voice = debugVoices[state]
            audioController.speak("Resume", priority: .critical, phaseId: "resume", voiceIdentifier: voice)
        }
    }

    /// Skip the current rest period
    func skipRest() {
        guard state == .restBetweenExercises else { return }

        // Stop all audio
        audioController.stopAll()

        timerCancellable?.cancel()

        // Move to next exercise
        let nextIndex = currentExerciseIndex + 1
        if nextIndex < workout.exercises.count {
            startExercise(at: nextIndex)
        } else {
            completeWorkout()
        }
    }

    /// Adjust rest timer by adding or subtracting seconds
    func adjustRestTimer(by seconds: Int) {
        guard state == .restBetweenExercises else { return }

        let newDuration = restDuration + TimeInterval(seconds)

        // Clamp to min/max bounds
        restDuration = max(minRestDuration, min(maxRestDuration, newDuration))

        // Recalculate time remaining based on elapsed time in current rest
        guard let phaseStart = phaseStartDate else { return }
        let elapsed = Date().timeIntervalSince(phaseStart) - accumulatedPausedTime
        timeRemaining = max(0, restDuration - elapsed)
    }

    /// Complete the entire workout
    func completeWorkout() {
        state = .completed
        timerCancellable?.cancel()
        isPaused = false

        // Re-enable screen sleep
        UIApplication.shared.isIdleTimerDisabled = false

        // Calculate total workout time
        if let startDate = workoutStartDate {
            workoutElapsedTime = Date().timeIntervalSince(startDate) - accumulatedPausedTime
        }

        // Audio: DONE sound + completion message (voice only, no delay needed)
        if audioEnabled {
            let voice = debugVoices[.completed]
            audioController.speak("Workout complete! You crushed it!", priority: .important, phaseId: "complete", voiceIdentifier: voice)
        }

        // Clean up
        clearSavedState()
    }

    /// Abandon the workout without completing
    func abandonWorkout() {
        timerCancellable?.cancel()
        UIApplication.shared.isIdleTimerDisabled = false

        // Stop all audio
        audioController.stopAll()

        clearSavedState()

        state = .completed
        isPaused = false
    }

    // MARK: - Manual Exercise Control

    /// Increment count/reps for manual completion exercises
    func incrementCount(by amount: Int = 1) {
        guard state == .exerciseActive else { return }
        guard let exercise = currentExercise else { return }

        switch exercise.config {
        case .countBased(let targetCount):
            currentCount = min(currentCount + amount, targetCount)
            HapticManager.shared.playImpact(style: .light)
        case .repsOnly(let targetReps):
            currentReps = min(currentReps + amount, targetReps)
            HapticManager.shared.playImpact(style: .light)
        default:
            break
        }
    }

    /// Decrement count/reps for manual completion exercises
    func decrementCount(by amount: Int = 1) {
        guard state == .exerciseActive else { return }
        guard let exercise = currentExercise else { return }

        switch exercise.config {
        case .countBased:
            currentCount = max(0, currentCount - amount)
            HapticManager.shared.playImpact(style: .light)
        case .repsOnly:
            currentReps = max(0, currentReps - amount)
            HapticManager.shared.playImpact(style: .light)
        default:
            break
        }
    }

    /// Manually complete the current exercise and advance to next
    func completeCurrentExercise() {
        guard state == .exerciseActive else { return }

        // Trigger the same flow as automatic completion
        handlePhaseCompletion()
    }

    // MARK: - Set-Based Exercise Control

    /// Complete current set for set-based exercises
    func completeCurrentSet() {
        guard state == .exerciseActive, !isRestingBetweenSets else { return }
        guard let exercise = currentExercise else { return }

        let totalSets: Int
        switch exercise.config {
        case .repsSets(_, let sets), .weightRepsSets(_, _, let sets, _), .timeSets(_, let sets, _):
            totalSets = sets
        default:
            return  // Not a set-based exercise
        }

        // Check if this was the last set
        if currentSet >= totalSets {
            // Last set complete → finish exercise
            handlePhaseCompletion()
        } else {
            // Start rest between sets
            startSetRest()
        }
    }

    /// Start rest period between sets
    private func startSetRest() {
        isRestingBetweenSets = true
        phaseStartDate = Date()
        accumulatedPausedTime = 0
        timeRemaining = setRestDuration

        // Play sound/haptic for set completion
        HapticManager.shared.playNotification(type: .success)

        // Continue UI timer (it's already running)
        // Timer will count down during rest
    }

    /// Complete rest between sets and start next set
    func completeSetRest() {
        isRestingBetweenSets = false
        currentSet += 1
        phaseStartDate = Date()
        accumulatedPausedTime = 0
        currentExerciseElapsedTime = 0  // Reset per-set time

        // Play START sound for new set
        audioController.playStart()
        HapticManager.shared.playImpact(style: .medium)

        // Set time remaining based on exercise type
        guard let exercise = currentExercise else { return }
        switch exercise.config {
        case .timeSets(let duration, _, _):
            timeRemaining = duration
        default:
            timeRemaining = 0  // Stopwatch mode for manual sets
        }
    }

    // MARK: - Private Methods

    /// Start the UI update timer (Combine Timer Publisher)
    private func startUITimer() {
        // Update UI every 1 second
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    /// Timer tick - update countdown and handle transitions
    private func tick() {
        guard !isPaused, let phaseStart = phaseStartDate else { return }

        // Calculate elapsed time since phase start (timestamp-based, not counter-based)
        let elapsed = Date().timeIntervalSince(phaseStart) - accumulatedPausedTime

        // Update workout elapsed time
        if let workoutStart = workoutStartDate {
            workoutElapsedTime = Date().timeIntervalSince(workoutStart) - accumulatedPausedTime
        }

        // Update current exercise elapsed time (for stopwatch mode, but not during set rest)
        if state == .exerciseActive && !isRestingBetweenSets {
            currentExerciseElapsedTime = elapsed
        }

        // Calculate time remaining
        let phaseDuration: TimeInterval
        switch state {
        case .getReady:
            phaseDuration = getReadyDuration
        case .exerciseActive:
            if isRestingBetweenSets {
                phaseDuration = setRestDuration  // Rest between sets
            } else {
                phaseDuration = getExerciseDuration()  // Active set
            }
        case .restBetweenExercises:
            phaseDuration = restDuration
        default:
            return
        }

        timeRemaining = max(0, phaseDuration - elapsed)

        // Audio cues at specific times
        handleAudioCues()

        // Check for completion
        if timeRemaining <= 0 {
            // Handle based on current state
            switch state {
            case .getReady, .restBetweenExercises:
                // Always advance for these states
                if requiresAutoCompletion {
                    handlePhaseCompletion()
                }

            case .exerciseActive:
                if isRestingBetweenSets {
                    // Set rest complete → start next set
                    completeSetRest()
                } else if requiresAutoCompletion {
                    // Auto-advancing exercises
                    if isSetBasedExercise {
                        // Auto-complete set (timeSets only)
                        completeCurrentSet()
                    } else {
                        // Regular exercise completion (timeBased)
                        handlePhaseCompletion()
                    }
                }

            default:
                break
            }
        }
    }

    /// Check if current exercise is set-based
    private var isSetBasedExercise: Bool {
        guard let exercise = currentExercise else { return false }
        switch exercise.config {
        case .repsSets, .weightRepsSets, .timeSets:
            return true
        default:
            return false
        }
    }

    /// Check if current exercise requires automatic completion (timer-based)
    private var requiresAutoCompletion: Bool {
        guard currentExerciseIndex < workout.exercises.count else { return false }
        let exercise = workout.exercises[currentExerciseIndex]

        switch state {
        case .getReady, .restBetweenExercises:
            return true  // Always auto-complete get ready and rest
        case .exerciseActive:
            // Only auto-complete for time-based exercises
            switch exercise.config {
            case .timeBased, .timeSets:
                return true
            default:
                return false  // Manual completion required
            }
        default:
            return false
        }
    }

    /// Get the duration of the current exercise
    private func getExerciseDuration() -> TimeInterval {
        guard currentExerciseIndex < workout.exercises.count else { return 0 }

        let exercise = workout.exercises[currentExerciseIndex]
        switch exercise.config {
        case .timeBased(let duration):
            return duration
        case .timeSets(let duration, _, _):
            return duration
        default:
            return 30  // Default for non-timed exercises
        }
    }

    /// Handle audio cues at specific timestamps
    private func handleAudioCues() {
        guard audioEnabled else { return }

        let remaining = Int(timeRemaining)
        let phaseId = isRestingBetweenSets
            ? "setRest:\(currentExerciseIndex):\(currentSet)"
            : stateString() + ":\(currentExerciseIndex)"

        switch state {
        case .getReady:
            // 5-1: Subtle tick only (no voice, no beep)
            if remaining <= 5 && remaining >= 1 {
                audioController.playTick(second: remaining, phaseId: phaseId)
            }

        case .exerciseActive:
            if isRestingBetweenSets {
                // Resting between sets: 5-1 countdown ticks
                if remaining <= 5 && remaining >= 1 {
                    audioController.playTick(second: remaining, phaseId: phaseId)
                }
            } else {
                // Active set: 5-1 countdown ticks (only for timed sets)
                if remaining <= 5 && remaining >= 1 {
                    audioController.playTick(second: remaining, phaseId: phaseId)
                }
            }

        case .restBetweenExercises:
            // 5-1: Subtle tick only (no voice - "up next" already spoken after done sound)
            if remaining <= 5 && remaining >= 1 {
                audioController.playTick(second: remaining, phaseId: phaseId)
            }

        default:
            break
        }
    }

    /// Handle phase completion and state transitions
    private func handlePhaseCompletion() {
        timerCancellable?.cancel()

        // Reset de-bounce for new phase
        let newPhaseId = stateString() + ":\(currentExerciseIndex + 1)"
        audioController.resetDeBounce(phaseId: newPhaseId)

        switch state {
        case .getReady:
            // Get ready countdown complete → Start first exercise
            // Play START sound (no voice)
            audioController.playStart()
            // Haptic: emphasize phase change into exercise
            HapticManager.shared.playImpact(style: .medium)
            startExercise(at: 0)

        case .exerciseActive:
            // Exercise complete
            let nextIndex = currentExerciseIndex + 1

            if nextIndex < workout.exercises.count {
                // Play DONE sound + announce "Up next: [Exercise]"
                let nextExercise = workout.exercises[nextIndex]
                audioController.playDoneAndAnnounceNext(nextExerciseName: nextExercise.name)
                // Haptic: success on exercise completion
                HapticManager.shared.playNotification(type: .success)

                // Start rest period before next exercise
                startRest(beforeExerciseAt: nextIndex)
            } else {
                // Last exercise - just play DONE sound (completion message happens in completeWorkout)
                audioController.playDone()
                completeWorkout()
            }

        case .restBetweenExercises:
            // Rest complete → Start next exercise
            // Play START sound (no voice - "up next" already announced)
            audioController.playStart()
            // Haptic: nudge when rest ends
            HapticManager.shared.playImpact(style: .light)
            let nextIndex = currentExerciseIndex + 1
            startExercise(at: nextIndex)

        default:
            break
        }
    }

    // MARK: - Lifecycle Observers

    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc private func willEnterForeground() {
        // Calculate time spent in background
        if let backgroundTime = backgroundedAt {
            backgroundDuration = Date().timeIntervalSince(backgroundTime)
            backgroundedAt = nil
        }

        // Recalculate elapsed time when returning from background
        tick()

        // Restart UI timer if workout was active and not paused
        if !isPaused && (state == .getReady || state == .exerciseActive || state == .restBetweenExercises) {
            startUITimer()
        }
    }

    @objc private func didEnterBackground() {
        // Record when we backgrounded
        backgroundedAt = Date()

        // Auto-pause workout when app goes to background
        if !isPaused && (state == .getReady || state == .exerciseActive || state == .restBetweenExercises) {
            pause()
        }

        // Save state before backgrounding
        saveState()

        // Stop UI timer (will restart on foreground)
        timerCancellable?.cancel()
    }

    // MARK: - State Persistence

    private func saveState() {
        // NOTE: State persistence is disabled per user requirements
        // (No workout history persistence - session only)
        // The workout state is maintained in memory while the app is active
        // but not restored after app termination

        // If we need to restore state after backgrounding (not killing the app),
        // the timestamp-based timer will recalculate correctly when returning to foreground
    }

    private func clearSavedState() {
        UserDefaults.standard.removeObject(forKey: stateKey)
    }

    private func stateString() -> String {
        switch state {
        case .getReady: return "getReady"
        case .exerciseActive: return "exerciseActive"
        case .restBetweenExercises: return "rest"
        case .completed: return "completed"
        }
    }

    func toggleAudio() {
        audioEnabled.toggle()
        audioController.toggleAudio()
    }

    // Computed properties for UI bindings
    var voiceEnabled: Bool {
        get { audioController.voiceEnabled }
        set { audioController.voiceEnabled = newValue }
    }

    var sfxEnabled: Bool {
        get { audioController.sfxEnabled }
        set { audioController.sfxEnabled = newValue }
    }

    // MARK: - Deinitialization

    deinit {
        NotificationCenter.default.removeObserver(self)
        UIApplication.shared.isIdleTimerDisabled = false
        timerCancellable?.cancel()
    }
}

// MARK: - Helper Extensions

extension WorkoutExecutionViewModel {
    /// Get the current exercise
    var currentExercise: Exercise? {
        guard currentExerciseIndex < workout.exercises.count else { return nil }
        return workout.exercises[currentExerciseIndex]
    }

    /// Get the next exercise
    var nextExercise: Exercise? {
        let nextIndex = currentExerciseIndex + 1
        guard nextIndex < workout.exercises.count else { return nil }
        return workout.exercises[nextIndex]
    }

    /// Progress percentage (0.0 to 1.0)
    var progress: Double {
        guard workout.exercises.count > 0 else { return 0 }
        return Double(currentExerciseIndex) / Double(workout.exercises.count)
    }

    /// Format time remaining as MM:SS
    var formattedTimeRemaining: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Format workout elapsed time as MM:SS
    var formattedWorkoutElapsedTime: String {
        let minutes = Int(workoutElapsedTime) / 60
        let seconds = Int(workoutElapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Get state description for UI
    var stateDescription: String {
        switch state {
        case .getReady:
            return "Get Ready"
        case .exerciseActive:
            return "Exercise \(currentExerciseIndex + 1) of \(workout.exercises.count)"
        case .restBetweenExercises:
            return "Rest Period"
        case .completed:
            return "Workout Complete"
        }
    }

    /// Get formatted welcome back message
    var welcomeBackMessage: String {
        let minutes = Int(backgroundDuration) / 60
        let seconds = Int(backgroundDuration) % 60

        if minutes > 0 {
            return "Welcome back! You were gone \(minutes):\(String(format: "%02d", seconds)), resuming workout..."
        } else {
            return "Welcome back! You were gone \(seconds)s, resuming workout..."
        }
    }

    /// Can adjust rest timer (only during rest period)
    var canAdjustRest: Bool {
        state == .restBetweenExercises && !isPaused
    }

    /// Can skip rest (only during rest period)
    var canSkipRest: Bool {
        state == .restBetweenExercises && !isPaused
    }
}
