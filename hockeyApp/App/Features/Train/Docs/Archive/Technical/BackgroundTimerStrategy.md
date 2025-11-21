# iOS Background Timer Strategy for Workout Apps

## Executive Summary

This guide provides technical recommendations for implementing workout timers that continue functioning when the app is backgrounded. Based on extensive research of Apple documentation, Stack Overflow solutions, and real-world fitness app implementations.

**TL;DR:** Don't rely on timers in background. Use timestamp-based calculation with proper state preservation.

---

## Table of Contents

1. [Timer Implementation Options](#timer-implementation-options)
2. [Background Execution Reality](#background-execution-reality)
3. [Recommended Solution: Timestamp-Based Approach](#recommended-solution-timestamp-based-approach)
4. [State Preservation Patterns](#state-preservation-patterns)
5. [Background Task API](#background-task-api)
6. [Screen Sleep Prevention](#screen-sleep-prevention)
7. [Testing Strategies](#testing-strategies)
8. [Complete Implementation Example](#complete-implementation-example)

---

## Timer Implementation Options

### 1. Foundation Timer (NSTimer)

**Characteristics:**
- Simple, widely-used API
- "Best effort" execution - no precision guarantees
- Affected by RunLoop processing
- Stops when app backgrounds

**Accuracy:**
- Testing shows standard deviation: 0.2-0.8ms
- Maximum deviation: 2-8ms
- Accumulates jitter during long-running operations
- iOS won't allow drift - each fire date calculated from original

**Use Cases:**
- Simple countdown timers
- Non-critical periodic updates
- UI refresh cycles

**Example:**
```swift
var timer: Timer?

timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    self.secondsRemaining -= 1
}
```

**Pros:**
- Simple API
- Built-in to Foundation

**Cons:**
- Stops in background
- Less accurate over long periods
- RunLoop-dependent

---

### 2. Combine Timer Publisher

**Characteristics:**
- Modern, reactive approach
- Wrapper around Foundation Timer
- Same accuracy as Foundation Timer (uses Timer under the hood)
- Better for SwiftUI/reactive architectures

**Accuracy:**
- Identical to Foundation Timer
- Same "best effort" guarantees
- Also affected by RunLoop

**Use Cases:**
- SwiftUI apps
- Reactive workflows
- Combining timer events with other publishers

**Example:**
```swift
import Combine

private var timerCancellable: AnyCancellable?

timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
    .autoconnect()
    .sink { [weak self] _ in
        self?.secondsRemaining -= 1
    }
```

**Pros:**
- Modern, reactive
- Composable with other Combine operators
- Better memory management with `AnyCancellable`

**Cons:**
- Same background limitations as Foundation Timer
- Requires iOS 13+
- Additional Combine overhead

**Apple Developer Forums Discussion:**
> For workout apps, developers report that Foundation Timer can cause crashes when pausing workouts, whereas Timer Publisher works without issues when interacting with workout session state management.

---

### 3. DispatchSourceTimer (GCD Timer)

**Characteristics:**
- GCD-based, not RunLoop-dependent
- Nanosecond precision
- Most accurate option
- Continues in background (with caveats)

**Accuracy:**
- Standard deviation: 0.2-0.8ms (comparable to Timer in practice)
- Nanosecond theoretical precision
- Not affected by RunLoop blocking

**Use Cases:**
- High-precision timing requirements
- Background tasks
- Server-side/non-UI timers

**Example:**
```swift
var dispatchTimer: DispatchSourceTimer?

let queue = DispatchQueue(label: "com.app.timer")
dispatchTimer = DispatchSource.makeTimerSource(queue: queue)
dispatchTimer?.schedule(deadline: .now(), repeating: 1.0)
dispatchTimer?.setEventHandler { [weak self] in
    DispatchQueue.main.async {
        self?.secondsRemaining -= 1
    }
}
dispatchTimer?.resume()
```

**Pros:**
- Most accurate
- Not RunLoop-dependent
- Better for background scenarios

**Cons:**
- More complex API
- Still subject to system suspension
- Requires manual thread management

---

### 4. CADisplayLink

**Characteristics:**
- Tied to screen refresh rate (60Hz or 120Hz)
- Fires right after each frame render
- Designed for animations/graphics

**Accuracy:**
- Excellent for UI work (no dropped frames)
- Limited to screen refresh intervals (16.6ms @ 60Hz, 8.3ms @ 120Hz)
- Frame loss reduces accuracy

**Use Cases:**
- Smooth animations
- Game loops
- Visual effects

**Example:**
```swift
var displayLink: CADisplayLink?

displayLink = CADisplayLink(target: self, selector: #selector(update))
displayLink?.add(to: .main, forMode: .default)

@objc func update(displayLink: CADisplayLink) {
    // Called every frame
}
```

**Pros:**
- Perfect for animations
- Synced with screen refresh
- No dropped frames

**Cons:**
- **Not suitable for workout timers**
- Stops when screen locks
- Limited to UI thread
- Higher battery consumption

---

## Timer Comparison Table

| Feature | Foundation Timer | Combine Timer | DispatchSourceTimer | CADisplayLink |
|---------|-----------------|---------------|---------------------|---------------|
| **Accuracy** | 0.2-8ms variance | 0.2-8ms variance | 0.2-0.8ms variance | Frame-perfect |
| **Background** | ❌ Stops | ❌ Stops | ⚠️ Pauses | ❌ Stops |
| **Battery Impact** | Low | Low | Low | High |
| **Use Case** | General timers | SwiftUI/Reactive | High-precision | Animations only |
| **Complexity** | Simple | Moderate | Complex | Simple |
| **Recommended for Workout** | ✅ Yes | ✅ Yes (SwiftUI) | ⚠️ Advanced only | ❌ No |

---

## Background Execution Reality

### The Hard Truth

> "The answer to 'how can I run a timer while I'm in the background' questions is 'You can't'."
> — Stack Overflow consensus

**Key Facts:**
1. **Timers stop in background** - iOS suspends apps shortly after backgrounding
2. **No guaranteed execution time** - `beginBackgroundTask` provides ~30 seconds, not indefinite
3. **Audio session workaround is fragile** - Requires playing audio every few seconds, rejected by App Review
4. **Timer values are "best effort"** - No precision guarantees from iOS

### iOS Background Limitations

```
User backgrounds app
    ↓
iOS gives ~5-10 seconds to finish tasks
    ↓
App suspended (no CPU, no timers)
    ↓
[Unless: HealthKit workout session, audio playback, location updates, etc.]
```

### Background Modes That Work

**1. HealthKit Workout Sessions (Recommended for Fitness Apps)**
```swift
import HealthKit

let healthStore = HKHealthStore()
let configuration = HKWorkoutConfiguration()
configuration.activityType = .hockey

let workoutSession = try? HKWorkoutSession(
    healthStore: healthStore,
    configuration: configuration
)

workoutSession?.startActivity(with: Date())
// App can now run in background during workout
```

**Requirements:**
- Add HealthKit capability
- Add "Workout processing" background mode
- Request HealthKit permissions
- Active workout session

**Benefits:**
- Legitimate background execution
- Contributes to Activity Rings
- Heart rate monitoring (with Apple Watch)
- App Review approval

**2. Audio Playback (Not Recommended for Timers)**
- Requires continuous or frequent audio
- App Review often rejects timer apps using this
- Battery drain concerns

**3. Background Tasks (30-second limit)**
```swift
var backgroundTask: UIBackgroundTaskIdentifier = .invalid

backgroundTask = UIApplication.shared.beginBackgroundTask {
    // Expiration handler - called when time runs out
    UIApplication.shared.endBackgroundTask(backgroundTask)
}

// Do work here (you have ~30 seconds)

UIApplication.shared.endBackgroundTask(backgroundTask)
```

---

## Recommended Solution: Timestamp-Based Approach

### Why Timestamps Beat Timers

**Problem:**
```swift
// ❌ This breaks when app backgrounds
var secondsElapsed = 0
timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    secondsElapsed += 1
}
// User backgrounds app → timer stops → elapsed time is wrong
```

**Solution:**
```swift
// ✅ This works regardless of background state
let startTime = Date()

// When checking elapsed time:
let elapsed = Date().timeIntervalSince(startTime)
```

### Implementation Strategy

**Core Principle:** Store start timestamps, calculate elapsed time on-demand.

**Pattern:**
1. **On workout start:** Save `startDate` to UserDefaults + memory
2. **While active:** Use UI timer to refresh display (Combine or Foundation)
3. **On background:** Timer stops (expected), but `startDate` persists
4. **On foreground:** Calculate actual elapsed time from `startDate`
5. **On app kill:** `startDate` in UserDefaults allows recovery

---

## State Preservation Patterns

### Pattern 1: Simple Timestamp Tracking

**Use Case:** Basic workout timer

```swift
import SwiftUI
import Combine

@MainActor
class WorkoutTimer: ObservableObject {
    @Published var elapsedTime: TimeInterval = 0
    @Published var isActive: Bool = false

    private var startDate: Date?
    private var timerCancellable: AnyCancellable?
    private let userDefaultsKey = "workout.startDate"

    init() {
        // Restore saved start date if exists
        if let savedDate = UserDefaults.standard.object(forKey: userDefaultsKey) as? Date {
            startDate = savedDate
            resume()
        }

        // Listen for app lifecycle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    func start() {
        startDate = Date()
        UserDefaults.standard.set(startDate, forKey: userDefaultsKey)
        isActive = true
        startUITimer()
    }

    func pause() {
        isActive = false
        timerCancellable?.cancel()
        // Keep startDate for resume
    }

    func resume() {
        isActive = true
        startUITimer()
    }

    func stop() {
        isActive = false
        timerCancellable?.cancel()
        startDate = nil
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        elapsedTime = 0
    }

    private func startUITimer() {
        // UI refresh timer (stops in background, but that's OK)
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateElapsedTime()
            }
    }

    private func updateElapsedTime() {
        guard let start = startDate else { return }
        elapsedTime = Date().timeIntervalSince(start)
    }

    @objc private func willEnterForeground() {
        if isActive {
            // Recalculate elapsed time (covers backgrounded time)
            updateElapsedTime()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
```

**Usage:**
```swift
struct WorkoutView: View {
    @StateObject var timer = WorkoutTimer()

    var body: some View {
        VStack {
            Text(formatTime(timer.elapsedTime))
                .font(.system(size: 60, weight: .bold))

            HStack {
                Button(timer.isActive ? "Pause" : "Start") {
                    timer.isActive ? timer.pause() : timer.start()
                }

                Button("Stop") {
                    timer.stop()
                }
            }
        }
    }

    func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
```

---

### Pattern 2: Exercise-Based Tracking

**Use Case:** Multi-exercise workout with per-exercise timing

```swift
struct ExerciseSession: Codable {
    let exerciseId: UUID
    let exerciseName: String
    var startDate: Date?
    var endDate: Date?
    var elapsedTime: TimeInterval {
        guard let start = startDate else { return 0 }
        let end = endDate ?? Date()
        return end.timeIntervalSince(start)
    }
}

@MainActor
class WorkoutExecutionViewModel: ObservableObject {
    @Published var currentExerciseIndex: Int = 0
    @Published var exercises: [ExerciseSession]
    @Published var displayTime: TimeInterval = 0

    private var timerCancellable: AnyCancellable?
    private let workoutStateKey = "workout.currentState"

    init(exercises: [Exercise]) {
        self.exercises = exercises.map {
            ExerciseSession(exerciseId: $0.id, exerciseName: $0.name)
        }
        restoreState()
    }

    func startExercise() {
        exercises[currentExerciseIndex].startDate = Date()
        saveState()
        startUITimer()
    }

    func completeExercise() {
        exercises[currentExerciseIndex].endDate = Date()
        saveState()

        if currentExerciseIndex < exercises.count - 1 {
            currentExerciseIndex += 1
            startExercise()
        } else {
            completeWorkout()
        }
    }

    func skipExercise() {
        // Mark as skipped without end date
        if currentExerciseIndex < exercises.count - 1 {
            currentExerciseIndex += 1
            startExercise()
        } else {
            completeWorkout()
        }
    }

    private func startUITimer() {
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateDisplayTime()
            }
    }

    private func updateDisplayTime() {
        displayTime = exercises[currentExerciseIndex].elapsedTime
    }

    private func saveState() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(exercises) {
            UserDefaults.standard.set(encoded, forKey: workoutStateKey)
            UserDefaults.standard.set(currentExerciseIndex, forKey: "workout.currentIndex")
        }
    }

    private func restoreState() {
        if let data = UserDefaults.standard.data(forKey: workoutStateKey),
           let decoded = try? JSONDecoder().decode([ExerciseSession].self, from: data) {
            exercises = decoded
            currentExerciseIndex = UserDefaults.standard.integer(forKey: "workout.currentIndex")

            // Resume if there's an active exercise
            if exercises[currentExerciseIndex].startDate != nil &&
               exercises[currentExerciseIndex].endDate == nil {
                startUITimer()
            }
        }
    }

    private func completeWorkout() {
        timerCancellable?.cancel()
        // Save to workout history
        saveWorkoutHistory()
        clearState()
    }

    private func clearState() {
        UserDefaults.standard.removeObject(forKey: workoutStateKey)
        UserDefaults.standard.removeObject(forKey: "workout.currentIndex")
    }

    private func saveWorkoutHistory() {
        // Implementation for WorkoutHistoryStore
    }
}
```

---

### Pattern 3: Countdown Timer with Pause

**Use Case:** Time-based exercises (e.g., "2 minutes of stickhandling")

```swift
@MainActor
class CountdownTimer: ObservableObject {
    @Published var timeRemaining: TimeInterval
    @Published var isActive: Bool = false
    @Published var isPaused: Bool = false

    private let totalDuration: TimeInterval
    private var startDate: Date?
    private var pausedAt: Date?
    private var accumulatedPausedTime: TimeInterval = 0
    private var timerCancellable: AnyCancellable?

    init(duration: TimeInterval) {
        self.totalDuration = duration
        self.timeRemaining = duration
    }

    func start() {
        startDate = Date()
        accumulatedPausedTime = 0
        isActive = true
        isPaused = false
        startUITimer()
    }

    func pause() {
        pausedAt = Date()
        isPaused = true
        timerCancellable?.cancel()
    }

    func resume() {
        if let pausedDate = pausedAt {
            accumulatedPausedTime += Date().timeIntervalSince(pausedDate)
        }
        pausedAt = nil
        isPaused = false
        startUITimer()
    }

    func stop() {
        isActive = false
        isPaused = false
        timerCancellable?.cancel()
        timeRemaining = totalDuration
        startDate = nil
        accumulatedPausedTime = 0
    }

    private func startUITimer() {
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimeRemaining()
            }
    }

    private func updateTimeRemaining() {
        guard let start = startDate else { return }

        let elapsed = Date().timeIntervalSince(start) - accumulatedPausedTime
        timeRemaining = max(0, totalDuration - elapsed)

        if timeRemaining <= 0 {
            onComplete()
        }
    }

    private func onComplete() {
        timerCancellable?.cancel()
        isActive = false
        // Trigger completion callback/notification
    }
}
```

---

## Background Task API

### When to Use `beginBackgroundTask`

**Use Case:** Saving workout data when user backgrounds mid-session

```swift
class WorkoutManager {
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    func saveWorkoutOnBackground() {
        // Request background time to save data
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "SaveWorkout") {
            // Expiration handler - called when time runs out
            self.endBackgroundTask()
        }

        // Save workout data
        saveWorkoutToDatabase { [weak self] in
            // Done saving
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}
```

### Critical Rules

1. **Always end background tasks**
   - Failure to call `endBackgroundTask` = watchdog kills your app
   - Use named tasks for debugging: `beginBackgroundTask(withName:)`

2. **Don't rely on `backgroundTimeRemaining`**
   - Value can change at any time
   - No guaranteed execution time
   - Design to work regardless of value

3. **Handle expiration gracefully**
   - Expiration handler is your last chance to clean up
   - Save critical state
   - End task immediately

4. **Background tasks started while backgrounded have ~30 seconds**
   - Tasks started while foregrounded get more time
   - System can revoke at any moment

### Best Practices

```swift
// ✅ Good: Quick, essential work
backgroundTask = UIApplication.shared.beginBackgroundTask {
    // Save critical state
    self.saveCheckpoint()
    self.endBackgroundTask()
}

// Finish work quickly
saveWorkoutData()
endBackgroundTask()

// ❌ Bad: Long-running work
backgroundTask = UIApplication.shared.beginBackgroundTask {
    self.endBackgroundTask()
}

// Don't do this - will be killed
while true {
    updateTimer()
    sleep(1)
}
```

### Audio Session Background Mode

**Not recommended for timer apps** - frequently rejected by App Review.

```swift
// ❌ Hacky approach (App Review rejection risk)
import AVFoundation

let audioSession = AVAudioSession.sharedInstance()
try? audioSession.setCategory(.playback, options: .mixWithOthers)
try? audioSession.setActive(true)

// Play silent audio to keep app alive
// This is against App Store guidelines
```

### HealthKit Workout Session (Recommended)

**Legitimate background execution for fitness apps:**

```swift
import HealthKit

class WorkoutSessionManager: NSObject, HKWorkoutSessionDelegate {
    let healthStore = HKHealthStore()
    var workoutSession: HKWorkoutSession?
    var workoutBuilder: HKLiveWorkoutBuilder?

    func startWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .hockey
        configuration.locationType = .indoor

        do {
            workoutSession = try HKWorkoutSession(
                healthStore: healthStore,
                configuration: configuration
            )
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()

            workoutSession?.delegate = self
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            workoutSession?.startActivity(with: Date())
            try workoutBuilder?.beginCollection(withStart: Date()) { success, error in
                // Workout session active - app can run in background
            }
        } catch {
            print("Failed to start workout session: \(error)")
        }
    }

    func stopWorkout() {
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { success, error in
            // Finalize workout
            self.workoutBuilder?.finishWorkout { workout, error in
                // Workout saved to HealthKit
            }
        }
    }

    // HKWorkoutSessionDelegate methods
    func workoutSession(_ workoutSession: HKWorkoutSession,
                       didChangeTo toState: HKWorkoutSessionState,
                       from fromState: HKWorkoutSessionState,
                       date: Date) {
        // Handle state changes
    }

    func workoutSession(_ workoutSession: HKWorkoutSession,
                       didFailWithError error: Error) {
        // Handle errors
    }
}
```

**Requirements:**
```swift
// Info.plist
<key>UIBackgroundModes</key>
<array>
    <string>workout-processing</string>
</array>

// Capabilities
- HealthKit enabled

// Privacy - Health Share Usage Description
<key>NSHealthShareUsageDescription</key>
<string>This app needs access to save your hockey training workouts.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>This app needs access to record your workout data.</string>
```

---

## Screen Sleep Prevention

### When Active Workout is Running

```swift
class WorkoutViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Disable idle timer to keep screen on during workout
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Re-enable idle timer when leaving workout
        UIApplication.shared.isIdleTimerDisabled = false
    }
}
```

### SwiftUI Version

```swift
struct WorkoutExecutionView: View {
    var body: some View {
        VStack {
            // Workout UI
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}
```

### Important Notes

- **Don't disable globally** - only during active workouts
- **Battery impact** - screen is the biggest power consumer
- **User expectation** - fitness apps should keep screen on
- **Apple's guidance:** Most apps should let the system turn off the screen
- **Audio apps:** Playback continues when screen locks (no need to disable)

---

## Testing Strategies

### Test Cases Checklist

#### Basic Functionality
- [ ] Timer starts correctly
- [ ] Timer displays accurate time
- [ ] Timer can be paused/resumed
- [ ] Timer can be stopped/reset

#### Background Scenarios
- [ ] **App backgrounds during active timer**
  - [ ] Time continues counting (verified by timestamp)
  - [ ] UI updates correctly on foreground return
  - [ ] No time lost during background period

- [ ] **App backgrounds during paused timer**
  - [ ] Paused time preserved
  - [ ] Resume works correctly after foregrounding

- [ ] **Extended background (5+ minutes)**
  - [ ] Time calculation still accurate
  - [ ] State restored from UserDefaults

- [ ] **App force-quit during workout**
  - [ ] Timestamp saved to UserDefaults
  - [ ] On relaunch, can show "Resume workout?" prompt
  - [ ] Elapsed time calculated correctly

#### Edge Cases
- [ ] **Screen lock during workout**
  - [ ] Timer continues (if using HealthKit session)
  - [ ] Screen wakes to correct time

- [ ] **Phone call/FaceTime interruption**
  - [ ] Timer pauses or continues (configurable)
  - [ ] State preserved across interruption

- [ ] **Low battery mode**
  - [ ] Timer still functional
  - [ ] Background behavior documented

- [ ] **Date/time change**
  - [ ] Clock adjustment detected
  - [ ] Elapsed time still accurate

- [ ] **Timezone change**
  - [ ] Timestamp calculations unaffected (uses absolute time)

#### Long-Running Tests
- [ ] **1-hour workout**
  - [ ] No drift in time display
  - [ ] Memory usage stable
  - [ ] No performance degradation

- [ ] **Multiple background/foreground cycles**
  - [ ] State preserved across 10+ cycles
  - [ ] No accumulated errors

- [ ] **Overnight persistence**
  - [ ] Start workout, kill app, wait 12 hours, relaunch
  - [ ] Timestamp accurately reflects elapsed time

### Testing Environment

**Physical Device Required:**
- Background behavior differs from Simulator
- Timers behave differently when debugging
- Audio sessions don't work in Simulator

**Test Without Xcode Debugger:**
```bash
# Build and install via Xcode
# Stop debugging
# Launch app manually from home screen
# Test background scenarios
```

**Why:** Debugger keeps app alive in background, masking real behavior.

### Automated Testing

```swift
import XCTest

class TimerTests: XCTestCase {
    func testElapsedTimeCalculation() {
        let timer = WorkoutTimer()

        // Simulate 5 seconds elapsed
        let startDate = Date().addingTimeInterval(-5)
        timer.startDate = startDate

        timer.updateElapsedTime()

        XCTAssertEqual(timer.elapsedTime, 5.0, accuracy: 0.1)
    }

    func testBackgroundScenario() {
        let timer = WorkoutTimer()
        timer.start()

        // Simulate 10 seconds pass while backgrounded
        let futureDate = Date().addingTimeInterval(10)
        timer.startDate = futureDate.addingTimeInterval(-10)

        // Simulate foreground return
        timer.willEnterForeground()

        XCTAssertEqual(timer.elapsedTime, 10.0, accuracy: 0.1)
    }

    func testStatePersistence() {
        let timer = WorkoutTimer()
        timer.start()

        // Verify saved to UserDefaults
        let saved = UserDefaults.standard.object(forKey: "workout.startDate")
        XCTAssertNotNil(saved)

        // Simulate app restart
        let restoredTimer = WorkoutTimer()
        XCTAssertNotNil(restoredTimer.startDate)
    }
}
```

### Manual Test Script

```
1. Start workout timer
2. Verify timer is counting
3. Press home button (app backgrounds)
4. Wait 30 seconds
5. Reopen app
6. VERIFY: Timer shows correct elapsed time (~30 seconds)

7. Pause timer
8. Background app
9. Wait 30 seconds
10. Reopen app
11. VERIFY: Paused time hasn't changed

12. Resume timer
13. Background app
14. Wait 30 seconds
15. Reopen app
16. VERIFY: Timer continued from paused point

17. Start new workout
18. Wait 10 seconds
19. Force-quit app (swipe up from multitasking)
20. Reopen app
21. VERIFY: Workout state lost OR "Resume?" prompt shown
```

---

## Complete Implementation Example

### Full WorkoutExecutionViewModel

```swift
import SwiftUI
import Combine
import Foundation

// MARK: - Models

struct ExerciseSession: Codable, Identifiable {
    let id: UUID
    let exerciseName: String
    let targetDuration: TimeInterval?
    let targetReps: Int?

    var startDate: Date?
    var endDate: Date?
    var actualReps: Int?
    var skipped: Bool = false

    var isActive: Bool {
        startDate != nil && endDate == nil
    }

    var elapsedTime: TimeInterval {
        guard let start = startDate else { return 0 }
        let end = endDate ?? Date()
        return end.timeIntervalSince(start)
    }

    var isComplete: Bool {
        endDate != nil || skipped
    }
}

struct WorkoutState: Codable {
    var workoutId: UUID
    var workoutName: String
    var exercises: [ExerciseSession]
    var currentIndex: Int
    var workoutStartDate: Date?

    var totalElapsedTime: TimeInterval {
        guard let start = workoutStartDate else { return 0 }
        return Date().timeIntervalSince(start)
    }

    var currentExercise: ExerciseSession? {
        exercises.indices.contains(currentIndex) ? exercises[currentIndex] : nil
    }
}

// MARK: - ViewModel

@MainActor
class WorkoutExecutionViewModel: ObservableObject {
    // Published state
    @Published var state: WorkoutState
    @Published var displayTime: TimeInterval = 0
    @Published var isPaused: Bool = false
    @Published var isComplete: Bool = false

    // Private state
    private var timerCancellable: AnyCancellable?
    private var pausedAt: Date?
    private var accumulatedPausedTime: TimeInterval = 0

    // Constants
    private let stateKey = "workout.execution.state"
    private let pausedAtKey = "workout.execution.pausedAt"
    private let pausedTimeKey = "workout.execution.pausedTime"

    // MARK: - Initialization

    init(workout: Workout) {
        // Create new workout state
        let exercises = workout.exercises.map { exercise in
            ExerciseSession(
                id: exercise.id,
                exerciseName: exercise.name,
                targetDuration: exercise.config.duration,
                targetReps: exercise.config.reps
            )
        }

        self.state = WorkoutState(
            workoutId: workout.id,
            workoutName: workout.name,
            exercises: exercises,
            currentIndex: 0
        )

        // Try to restore saved state
        restoreState()

        // Listen for app lifecycle
        setupLifecycleObservers()
    }

    // MARK: - Public Methods

    func startWorkout() {
        state.workoutStartDate = Date()
        startExercise()
        saveState()
    }

    func startExercise() {
        guard !isComplete else { return }

        state.exercises[state.currentIndex].startDate = Date()
        isPaused = false
        accumulatedPausedTime = 0
        startUITimer()
        saveState()

        // Disable screen sleep during workout
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func pauseExercise() {
        guard !isPaused else { return }

        pausedAt = Date()
        isPaused = true
        timerCancellable?.cancel()
        saveState()
    }

    func resumeExercise() {
        guard isPaused else { return }

        if let pauseDate = pausedAt {
            accumulatedPausedTime += Date().timeIntervalSince(pauseDate)
        }
        pausedAt = nil
        isPaused = false
        startUITimer()
        saveState()
    }

    func completeExercise(actualReps: Int? = nil) {
        state.exercises[state.currentIndex].endDate = Date()
        state.exercises[state.currentIndex].actualReps = actualReps

        timerCancellable?.cancel()
        saveState()

        // Move to next or complete
        if state.currentIndex < state.exercises.count - 1 {
            state.currentIndex += 1
            // Option: Auto-start next exercise or wait for user
            // startExercise()
        } else {
            finishWorkout()
        }
    }

    func skipExercise() {
        state.exercises[state.currentIndex].skipped = true
        completeExercise()
    }

    func finishWorkout() {
        isComplete = true
        timerCancellable?.cancel()

        // Re-enable screen sleep
        UIApplication.shared.isIdleTimerDisabled = false

        // Save to history
        saveToHistory()

        // Clear saved state
        clearSavedState()
    }

    func abandonWorkout() {
        timerCancellable?.cancel()
        UIApplication.shared.isIdleTimerDisabled = false
        clearSavedState()
    }

    // MARK: - Private Methods

    private func startUITimer() {
        // Update UI every 100ms
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateDisplayTime()
            }
    }

    private func updateDisplayTime() {
        guard let exercise = state.currentExercise else { return }

        if isPaused {
            // Keep current display time when paused
            return
        }

        var elapsed = exercise.elapsedTime

        // Subtract paused time if currently paused
        if let pauseDate = pausedAt {
            elapsed -= Date().timeIntervalSince(pauseDate)
        }
        elapsed -= accumulatedPausedTime

        // For countdown exercises
        if let target = exercise.targetDuration {
            displayTime = max(0, target - elapsed)

            // Auto-complete when countdown reaches 0
            if displayTime <= 0 {
                completeExercise()
            }
        } else {
            // Count-up timer
            displayTime = elapsed
        }
    }

    // MARK: - State Persistence

    private func saveState() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(state) {
            UserDefaults.standard.set(encoded, forKey: stateKey)
        }
        if let pauseDate = pausedAt {
            UserDefaults.standard.set(pauseDate, forKey: pausedAtKey)
        }
        UserDefaults.standard.set(accumulatedPausedTime, forKey: pausedTimeKey)
    }

    private func restoreState() {
        guard let data = UserDefaults.standard.data(forKey: stateKey),
              let decoded = try? JSONDecoder().decode(WorkoutState.self, from: data) else {
            return
        }

        state = decoded

        // Restore pause state
        if let pauseDate = UserDefaults.standard.object(forKey: pausedAtKey) as? Date {
            pausedAt = pauseDate
            isPaused = true
        }

        accumulatedPausedTime = UserDefaults.standard.double(forKey: pausedTimeKey)

        // Resume UI timer if workout was active
        if let currentExercise = state.currentExercise,
           currentExercise.isActive && !isPaused {
            startUITimer()
        }
    }

    private func clearSavedState() {
        UserDefaults.standard.removeObject(forKey: stateKey)
        UserDefaults.standard.removeObject(forKey: pausedAtKey)
        UserDefaults.standard.removeObject(forKey: pausedTimeKey)
    }

    // MARK: - History

    private func saveToHistory() {
        let history = WorkoutHistory(
            id: UUID(),
            workoutId: state.workoutId,
            workoutName: state.workoutName,
            startDate: state.workoutStartDate ?? Date(),
            endDate: Date(),
            exercises: state.exercises.map { exercise in
                ExerciseCompletion(
                    exerciseId: exercise.id,
                    exerciseName: exercise.exerciseName,
                    completed: exercise.isComplete && !exercise.skipped,
                    skipped: exercise.skipped,
                    actualDuration: exercise.isComplete ? exercise.elapsedTime : nil,
                    actualReps: exercise.actualReps
                )
            }
        )

        // Save to WorkoutHistoryStore
        WorkoutHistoryStore.shared.save(history)
    }

    // MARK: - Lifecycle

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
        // Recalculate times (covers backgrounded period)
        updateDisplayTime()

        // Restart UI timer if workout was active
        if let currentExercise = state.currentExercise,
           currentExercise.isActive && !isPaused {
            startUITimer()
        }
    }

    @objc private func didEnterBackground() {
        // Save state before backgrounding
        saveState()

        // Stop UI timer (will restart on foreground)
        timerCancellable?.cancel()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

// MARK: - Supporting Types

struct WorkoutHistory: Codable, Identifiable {
    let id: UUID
    let workoutId: UUID
    let workoutName: String
    let startDate: Date
    let endDate: Date
    let exercises: [ExerciseCompletion]

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var completionRate: Double {
        let completed = exercises.filter { $0.completed }.count
        return Double(completed) / Double(exercises.count)
    }
}

struct ExerciseCompletion: Codable {
    let exerciseId: UUID
    let exerciseName: String
    let completed: Bool
    let skipped: Bool
    let actualDuration: TimeInterval?
    let actualReps: Int?
}
```

### SwiftUI View Example

```swift
struct WorkoutExecutionView: View {
    @StateObject var viewModel: WorkoutExecutionViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button(action: { viewModel.isPaused ? viewModel.resumeExercise() : viewModel.pauseExercise() }) {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                }

                Spacer()

                Text(viewModel.state.workoutName)
                    .font(.headline)

                Spacer()

                Button(action: confirmAbandon) {
                    Image(systemName: "xmark")
                }
            }
            .padding()

            // Progress
            if let currentExercise = viewModel.state.currentExercise {
                VStack {
                    Text("Exercise \(viewModel.state.currentIndex + 1) of \(viewModel.state.exercises.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(currentExercise.exerciseName)
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }

            Spacer()

            // Timer Display
            Text(formatTime(viewModel.displayTime))
                .font(.system(size: 72, weight: .bold))
                .monospacedDigit()

            if viewModel.isPaused {
                Text("PAUSED")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }

            Spacer()

            // Controls
            HStack(spacing: 20) {
                Button("Skip") {
                    viewModel.skipExercise()
                }
                .buttonStyle(.bordered)

                Button("Complete") {
                    viewModel.completeExercise()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .onAppear {
            if viewModel.state.workoutStartDate == nil {
                viewModel.startWorkout()
            }
        }
        .sheet(isPresented: $viewModel.isComplete) {
            WorkoutCompletionView(history: viewModel.state)
        }
    }

    func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func confirmAbandon() {
        // Show confirmation alert
    }
}
```

---

## Recommendations Summary

### For Hockey Training App

**Recommended Timer Implementation:**
- ✅ **Combine Timer Publisher** (for SwiftUI integration)
- ✅ **Timestamp-based elapsed time calculation**
- ✅ **UserDefaults state persistence**

**Background Strategy:**
- ✅ **HealthKit Workout Sessions** (legitimate background execution)
- ✅ **Save state on background** (resume on foreground)
- ❌ **Don't use audio session hacks** (App Review rejection)

**State Management:**
- ✅ **Save exercise start/end timestamps**
- ✅ **Calculate elapsed time from Date objects**
- ✅ **Handle pause/resume with accumulated paused time**
- ✅ **Persist to UserDefaults on every state change**

**Screen Management:**
- ✅ **Disable idle timer during active workouts**
- ✅ **Re-enable on workout completion/abandonment**

**Testing:**
- ✅ **Test on physical device without debugger**
- ✅ **Verify background/foreground transitions**
- ✅ **Test force-quit recovery**
- ✅ **Long-running accuracy tests (1+ hour)**

---

## Common Pitfalls to Avoid

1. **❌ Relying on timer ticks to accumulate time**
   - Breaks when app backgrounds
   - Use timestamps instead

2. **❌ Not saving state to persistent storage**
   - Force-quit loses all workout progress
   - Save to UserDefaults on every change

3. **❌ Using audio session to keep app alive**
   - Violates App Store guidelines
   - App Review rejection

4. **❌ Not handling pause correctly**
   - Must track accumulated paused time
   - Subtract from total elapsed time

5. **❌ Forgetting to re-enable idle timer**
   - Battery drain
   - User frustration

6. **❌ Not testing on physical device**
   - Debugger masks background issues
   - Simulator behavior differs

7. **❌ Assuming timers continue in background**
   - They don't (without special background modes)
   - Design around this limitation

8. **❌ Using CADisplayLink for workout timers**
   - Stops when screen locks
   - High battery consumption

9. **❌ Not recalculating time on foreground return**
   - UI shows stale/incorrect time
   - Always recalculate from saved timestamp

10. **❌ Ignoring timezone changes**
    - Use `Date()` (absolute time) not `Calendar`
    - Elapsed time unaffected by timezone

---

## Resources

### Apple Documentation
- [Timer - Apple Developer](https://developer.apple.com/documentation/foundation/timer)
- [Timer.publish() - Combine](https://developer.apple.com/documentation/combine/replacing-foundation-timers-with-timer-publishers)
- [HKWorkoutSession - HealthKit](https://developer.apple.com/documentation/healthkit/hkworkoutsession)
- [Background Execution - Energy Guide](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/WorkLessInTheBackground.html)

### Stack Overflow Discussions
- [Swift 3 - How to make timer work in background](https://stackoverflow.com/questions/42319172/swift-3-how-to-make-timer-work-in-background)
- [How can I use Date() and timestamps for elapsed time](https://stackoverflow.com/questions/51252211/)
- [SwiftUI: How to run a Timer in background](https://stackoverflow.com/questions/63765532/)

### Community Resources
- [Hacking with Swift - The Ultimate Guide to Timer](https://www.hackingwithswift.com/articles/117/the-ultimate-guide-to-timer)
- [Make App Pie - Timer Accuracy in iOS](https://makeapppie.com/2018/08/15/timer-accuracy-in-ios/)

---

## Conclusion

**The golden rule:** Don't fight iOS's background limitations - design around them.

Use timestamps, save state religiously, and leverage legitimate background modes (HealthKit for fitness apps). Your timers won't run in the background, but your workout data will always be accurate.

For the Hockey Training App, the recommended approach is:
1. **Combine Timer** for UI updates (stops in background, that's OK)
2. **Date timestamps** for accurate elapsed time (works always)
3. **UserDefaults persistence** for state preservation (survives force-quit)
4. **HealthKit workout sessions** for legitimate background execution
5. **Comprehensive testing** on physical devices without debugger

This architecture ensures accurate timing, resilient state management, and App Store compliance.

---

**Document Version:** 1.0
**Last Updated:** January 2025
**Author:** Research compiled from Apple Developer Documentation, Stack Overflow, and real-world fitness app implementations
**Next Review:** Before implementing WorkoutExecutionView (Phase 3)
