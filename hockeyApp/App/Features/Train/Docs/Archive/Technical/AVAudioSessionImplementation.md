# AVAudioSession Implementation Guide for Workout Apps

## Overview

This guide provides comprehensive best practices for implementing AVAudioSession in iOS workout applications that require:
- Background timer continuity
- Text-to-speech (TTS) voice cues during workouts
- Music ducking (playing cues over user's music)
- Interruption handling (phone calls, Siri, etc.)

---

## Table of Contents

1. [Background Audio Configuration](#background-audio-configuration)
2. [Audio Session Setup](#audio-session-setup)
3. [Music Ducking Implementation](#music-ducking-implementation)
4. [Interruption Handling](#interruption-handling)
5. [Route Change Handling](#route-change-handling)
6. [Best Practices](#best-practices)
7. [Common Pitfalls](#common-pitfalls)
8. [iOS 17+ Considerations](#ios-17-considerations)

---

## Background Audio Configuration

### Required Info.plist Entries

Add the `UIBackgroundModes` key to your `Info.plist` file:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

### Xcode Configuration

Alternatively, configure in Xcode:
1. Select your app target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **Background Modes**
5. Check **Audio, AirPlay, and Picture in Picture**

> **Important**: Only declare background audio if you actually use it. Apps that declare this capability without using it may be rejected from the App Store.

---

## Audio Session Setup

### Basic Configuration for Workout Apps

```swift
import AVFoundation

class WorkoutAudioManager {
    static let shared = WorkoutAudioManager()

    private init() {
        configureAudioSession()
        setupObservers()
    }

    func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            // Configure for workout app with voice cues
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [
                    .mixWithOthers,
                    .duckOthers,
                    .interruptSpokenAudioAndMixWithOthers
                ]
            )

            try audioSession.setActive(true)
            print("Audio session configured successfully")

        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
}
```

### Category Options Explained

| Option | Purpose | Use Case |
|--------|---------|----------|
| `.mixWithOthers` | Allows audio to mix with other apps | Play voice cues while music continues |
| `.duckOthers` | Reduces volume of other audio by ~50% | Make voice cues audible over music |
| `.interruptSpokenAudioAndMixWithOthers` | Pauses podcasts/audiobooks but not music | Interrupt spoken content, mix with music |

---

## Music Ducking Implementation

### Strategy: Duck Music for Voice Cues

The goal is to temporarily reduce music volume (to ~20-30%) during voice cues, then restore it afterward.

### Implementation with AVSpeechSynthesizer

```swift
import AVFoundation

class WorkoutVoiceManager: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    private let audioSession = AVAudioSession.sharedInstance()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        // Activate audio session with ducking
        do {
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
            )
            try audioSession.setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // Adjust speech rate

        synthesizer.speak(utterance)
    }
}

extension WorkoutVoiceManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Deactivate audio session to restore music volume
        do {
            try audioSession.setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
}
```

### Key Points

1. **Activate Before Speaking**: Set audio session active with `.duckOthers` before playing audio
2. **Deactivate After Speaking**: Use `.notifyOthersOnDeactivation` to allow music to resume at full volume
3. **Delegate Method**: Always implement `didFinish` to deactivate the session

### Alternative: Keep Session Active (For Frequent Cues)

If you have frequent voice cues (e.g., every 30 seconds), keep the session active:

```swift
class WorkoutAudioManager {
    private var isWorkoutActive = false

    func startWorkout() {
        isWorkoutActive = true
        activateAudioSession()
    }

    func endWorkout() {
        isWorkoutActive = false
        deactivateAudioSession()
    }

    private func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.duckOthers, .mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error activating audio session: \(error)")
        }
    }

    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        } catch {
            print("Error deactivating audio session: \(error)")
        }
    }
}
```

---

## Interruption Handling

### Setup Interruption Observer

```swift
class WorkoutAudioManager {
    private var timer: Timer?
    private var isWorkoutPaused = false

    func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Interruption began (phone call, Siri, etc.)
            handleInterruptionBegan()

        case .ended:
            // Interruption ended
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            handleInterruptionEnded(options: options)

        @unknown default:
            break
        }
    }

    private func handleInterruptionBegan() {
        // Pause timer and audio
        timer?.invalidate()
        isWorkoutPaused = true

        // Update UI to show paused state
        NotificationCenter.default.post(
            name: .workoutDidPause,
            object: nil,
            userInfo: ["reason": "interruption"]
        )
    }

    private func handleInterruptionEnded(options: AVAudioSession.InterruptionOptions) {
        if options.contains(.shouldResume) {
            // Safe to resume
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                resumeWorkout()
            } catch {
                print("Failed to reactivate audio session: \(error)")
            }
        } else {
            // Don't auto-resume (user may have paused via Siri)
            // Update UI to show manual resume option
        }
    }

    private func resumeWorkout() {
        isWorkoutPaused = false
        // Restart timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerTick()
        }

        NotificationCenter.default.post(
            name: .workoutDidResume,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// Notification names
extension Notification.Name {
    static let workoutDidPause = Notification.Name("workoutDidPause")
    static let workoutDidResume = Notification.Name("workoutDidResume")
}
```

### Important Interruption Handling Rules

1. **Don't Deactivate on Interruption Begin**: The system has already deactivated your session
2. **Check `shouldResume` Flag**: Don't auto-resume if the user explicitly paused via Siri
3. **No Guaranteed End**: Interruption `.began` may not always have a matching `.ended`
4. **Reactivate When Resuming**: Call `setActive(true)` before resuming audio playback

---

## Route Change Handling

### Handle Bluetooth/Headphone Changes

```swift
class WorkoutAudioManager {
    func setupRouteChangeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        switch reason {
        case .newDeviceAvailable:
            // Bluetooth headphones connected
            print("New audio device connected")

        case .oldDeviceUnavailable:
            // Headphones disconnected - pause workout
            if let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                for output in previousRoute.outputs {
                    if output.portType == .headphones || output.portType == .bluetoothA2DP {
                        // Headphones were unplugged, pause workout
                        pauseWorkout(reason: "headphones_disconnected")
                    }
                }
            }

        case .override:
            // User changed route via Control Center
            // Don't pause workout
            break

        default:
            break
        }
    }

    private func pauseWorkout(reason: String) {
        timer?.invalidate()
        isWorkoutPaused = true
        NotificationCenter.default.post(
            name: .workoutDidPause,
            object: nil,
            userInfo: ["reason": reason]
        )
    }
}
```

### Port Types to Check

```swift
// Common audio port types
AVAudioSession.Port.bluetoothA2DP  // Bluetooth headphones
AVAudioSession.Port.bluetoothHFP   // Bluetooth hands-free
AVAudioSession.Port.headphones     // Wired headphones
AVAudioSession.Port.builtInSpeaker // iPhone speaker
AVAudioSession.Port.airPlay        // AirPlay devices
```

---

## Best Practices

### 1. When to Activate/Deactivate

```swift
// ✅ Good: Activate when starting workout
func startWorkout() {
    do {
        try AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
        try AVAudioSession.sharedInstance().setActive(true)
    } catch {
        handleError(error)
    }
}

// ✅ Good: Deactivate when ending workout
func endWorkout() {
    do {
        try AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    } catch {
        handleError(error)
    }
}

// ❌ Bad: Don't deactivate during interruption
@objc func handleInterruption(notification: Notification) {
    if type == .began {
        // ❌ Don't do this - already deactivated by system
        // try AVAudioSession.sharedInstance().setActive(false)
    }
}
```

### 2. Error Handling

```swift
func configureAudioSession() {
    do {
        try AVAudioSession.sharedInstance().setCategory(
            .playback,
            options: [.duckOthers, .mixWithOthers]
        )
        try AVAudioSession.sharedInstance().setActive(true)
    } catch let error as NSError {
        switch error.code {
        case AVAudioSession.ErrorCode.cannotInterruptOthers.rawValue:
            print("Cannot interrupt other audio sessions")
        case AVAudioSession.ErrorCode.mediaServicesFailed.rawValue:
            print("Media services failed")
        case AVAudioSession.ErrorCode.isBusy.rawValue:
            print("Audio session is busy")
        default:
            print("Audio session error: \(error.localizedDescription)")
        }
    }
}
```

### 3. Background Audio Requirements

```swift
// ✅ Required for background audio
// 1. Info.plist: UIBackgroundModes = ["audio"]
// 2. Audio session category: .playback
// 3. Keep audio session active

class BackgroundAudioManager {
    func enableBackgroundAudio() {
        do {
            // Must use .playback category
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to enable background audio: \(error)")
        }
    }
}
```

### 4. Delay Between Configuration Changes

```swift
class AudioSessionManager {
    private var lastConfigChange = Date()
    private let minConfigInterval: TimeInterval = 0.2

    func updateAudioSession() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastConfigChange)

        guard elapsed >= minConfigInterval else {
            print("Throttling audio session changes")
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            lastConfigChange = now
        } catch {
            print("Error: \(error)")
        }
    }
}
```

### 5. Complete Workout Audio Manager Example

```swift
import AVFoundation

class WorkoutAudioManager: NSObject {
    static let shared = WorkoutAudioManager()

    private let synthesizer = AVSpeechSynthesizer()
    private var workoutTimer: Timer?
    private var isWorkoutActive = false

    private override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
        setupObservers()
    }

    // MARK: - Setup

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .duckOthers, .interruptSpokenAudioAndMixWithOthers]
            )
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    // MARK: - Workout Control

    func startWorkout() {
        isWorkoutActive = true
        activateAudioSession()
        startTimer()
    }

    func endWorkout() {
        isWorkoutActive = false
        stopTimer()
        deactivateAudioSession()
    }

    func pauseWorkout() {
        stopTimer()
    }

    func resumeWorkout() {
        startTimer()
    }

    // MARK: - Voice Cues

    func speak(_ text: String) {
        guard isWorkoutActive else { return }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }

    // MARK: - Audio Session Management

    private func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }
    }

    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }

    // MARK: - Interruption Handling

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            pauseWorkout()

        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)

            if options.contains(.shouldResume) {
                activateAudioSession()
                resumeWorkout()
            }

        @unknown default:
            break
        }
    }

    // MARK: - Route Change Handling

    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        if reason == .oldDeviceUnavailable {
            if let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                for output in previousRoute.outputs {
                    if output.portType == .headphones || output.portType == .bluetoothA2DP {
                        pauseWorkout()
                    }
                }
            }
        }
    }

    // MARK: - Timer

    private func startTimer() {
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            // Timer tick logic
        }
    }

    private func stopTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension WorkoutAudioManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Optional: Deactivate if needed (for infrequent cues)
        // deactivateAudioSession()
    }
}
```

---

## Common Pitfalls

### 1. ❌ Calling setCategory Too Frequently

```swift
// ❌ Bad: Rapid category changes cause crashes
func playSound() {
    try? AVAudioSession.sharedInstance().setCategory(.playback)
    // play sound
}

// ✅ Good: Set once, reuse
class AudioManager {
    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }
}
```

### 2. ❌ Deactivating During Interruption

```swift
// ❌ Bad
@objc func handleInterruption(notification: Notification) {
    if type == .began {
        try? AVAudioSession.sharedInstance().setActive(false) // Already inactive!
    }
}

// ✅ Good
@objc func handleInterruption(notification: Notification) {
    if type == .began {
        // Just pause UI/timer, session already deactivated
        pauseUI()
    }
}
```

### 3. ❌ Forgetting .notifyOthersOnDeactivation

```swift
// ❌ Bad: Music won't resume
try AVAudioSession.sharedInstance().setActive(false)

// ✅ Good: Music resumes
try AVAudioSession.sharedInstance().setActive(
    false,
    options: .notifyOthersOnDeactivation
)
```

### 4. ❌ Wrong Category for Background Audio

```swift
// ❌ Bad: Won't work in background
try AVAudioSession.sharedInstance().setCategory(.ambient)

// ✅ Good: Works in background
try AVAudioSession.sharedInstance().setCategory(.playback)
```

### 5. ❌ Not Handling Route Changes

```swift
// ❌ Bad: Workout continues at full volume when headphones unplugged

// ✅ Good: Pause when headphones disconnect
@objc func handleRouteChange(notification: Notification) {
    if reason == .oldDeviceUnavailable {
        pauseWorkout()
    }
}
```

### 6. ❌ Assuming Interruption Will End

```swift
// ❌ Bad: Waiting for .ended that may never come
var interruptionBegan = false

// ✅ Good: Design UI to handle missing .ended
func handleInterruptionBegan() {
    showPauseState()
    enableResumeButton() // User can manually resume
}
```

---

## iOS 17+ Considerations

### 1. Enhanced Ducking Control

iOS 17 introduces fine-grained ducking control via AVAudioEngine:

```swift
// iOS 17+ only
if #available(iOS 17.0, *) {
    // Configure custom ducking levels
    // Note: This requires AVAudioEngine, not just AVAudioSession
    let engine = AVAudioEngine()
    // Custom ducking implementation
}
```

### 2. Continued Best Practices

For most workout apps, the standard AVAudioSession approach remains the best choice:

```swift
// Works on iOS 12+, including iOS 17
try AVAudioSession.sharedInstance().setCategory(
    .playback,
    mode: .default,
    options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
)
```

### 3. Testing on Latest iOS

Always test your audio session configuration on:
- iOS 17+ devices
- Different audio routes (speaker, headphones, Bluetooth)
- With various music apps (Apple Music, Spotify, etc.)
- During phone calls and Siri interactions

---

## Testing Checklist

- [ ] App plays voice cues in background (screen locked)
- [ ] Music ducks to ~20-30% during voice cues
- [ ] Music volume restores after voice cues
- [ ] Timer continues when app backgrounded
- [ ] Workout auto-pauses during phone call
- [ ] Workout can resume after call ends
- [ ] Siri pause commands are respected
- [ ] Headphone disconnect pauses workout
- [ ] Bluetooth headphones work correctly
- [ ] Works with Apple Music
- [ ] Works with Spotify
- [ ] Works with podcast apps
- [ ] No crashes with rapid audio session changes
- [ ] Background audio permission in Info.plist

---

## Resources

### Apple Documentation
- [AVAudioSession Documentation](https://developer.apple.com/documentation/avfaudio/avaudiosession)
- [Handling Audio Interruptions](https://developer.apple.com/documentation/avfoundation/avaudiosession/responding_to_audio_session_interruptions)
- [Responding to Audio Route Changes](https://developer.apple.com/documentation/avfaudio/responding-to-audio-route-changes)
- [Configuring Background Execution Modes](https://developer.apple.com/documentation/xcode/configuring-background-execution-modes)

### Key Stack Overflow Discussions
- [AVSpeechSynthesizer in Background](https://stackoverflow.com/questions/45330499/)
- [Audio Session Interruption Handling](https://stackoverflow.com/questions/38800204/)
- [Music Ducking Implementation](https://stackoverflow.com/questions/9837353/)

---

## Conclusion

Implementing robust audio session management is critical for workout apps. The key principles are:

1. **Configure once**: Set up audio session at app launch
2. **Activate when needed**: Activate before starting workout
3. **Handle interruptions**: Pause on phone calls, respect Siri commands
4. **Duck gracefully**: Use `.duckOthers` for voice cues over music
5. **Deactivate properly**: Use `.notifyOthersOnDeactivation` when ending workout
6. **Test thoroughly**: Test with various music apps and scenarios

By following these guidelines, your workout app will provide a seamless audio experience that works harmoniously with users' music and handles system interruptions gracefully.
