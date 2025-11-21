import Foundation
import AVFoundation

/// Unified audio interface for workout execution
/// Coordinates TTS voice coaching, sound effects, and haptics
/// Owns AVAudioSession to prevent configuration thrash
@MainActor
class AudioController: ObservableObject {

    // MARK: - Settings

    @Published var audioEnabled: Bool = true
    @Published var voiceEnabled: Bool = true
    @Published var sfxEnabled: Bool = true

    // MARK: - Internal Providers

    private let ttsProvider: SystemTTSProvider
    private let soundManager = SoundManager.shared
    private let hapticManager = HapticManager.shared

    // MARK: - De-bounce State

    private var lastAnnouncedSecond: Int = -1
    private var lastPhaseId: String = ""

    // MARK: - Init

    init() {
        self.ttsProvider = SystemTTSProvider()
        configureAudioSession()
    }

    // MARK: - Audio Session (SINGLE OWNER)

    private func configureAudioSession() {
        do {
            // .playback allows background audio + mixes with TTS
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ AudioController: Failed to configure audio session: \(error)")
        }
    }

    func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ AudioController: Failed to deactivate audio session: \(error)")
        }
    }

    // MARK: - Configuration

    func toggleAudio() {
        audioEnabled.toggle()
        if !audioEnabled {
            stopAll()
        }
    }

    func toggleVoice() {
        voiceEnabled.toggle()
    }

    func toggleSFX() {
        sfxEnabled.toggle()
    }

    // MARK: - Voice Coaching (TTS)

    /// Speak a message with text-to-speech (de-bounced)
    /// - Parameters:
    ///   - message: Text to speak
    ///   - priority: Audio priority level
    ///   - phaseId: Unique identifier for current phase (for de-bounce)
    ///   - voiceIdentifier: Optional voice ID for debugging (e.g., "com.apple.voice.compact.en-US.Samantha")
    func speak(_ message: String, priority: AudioPriority = .important, phaseId: String = "", voiceIdentifier: String? = nil) {
        guard audioEnabled && voiceEnabled else { return }

        // De-bounce: don't repeat same message in same phase
        let debounceKey = "\(phaseId):\(message)"
        if debounceKey == lastPhaseId {
            return
        }
        lastPhaseId = debounceKey

        ttsProvider.speak(message, priority: priority, voiceIdentifier: voiceIdentifier)
    }

    // MARK: - Sound Effects (+ Haptics)

    /// Play countdown tick (5-1 seconds only) with subtle haptic
    /// Single unified tick sound - no voice, no beep, just subtle tick
    func playTick(second: Int, phaseId: String) {
        guard audioEnabled && sfxEnabled else { return }

        // De-bounce: don't play same second twice
        let debounceKey = "\(phaseId):\(second)"
        if lastAnnouncedSecond == second && lastPhaseId == debounceKey {
            return
        }
        lastAnnouncedSecond = second
        lastPhaseId = debounceKey

        soundManager.playSound(.workoutTick)
        hapticManager.playImpact(style: .light, intensity: 0.4)  // Softer haptic
    }

    /// Play "done" sound (exercise complete) with haptic
    func playDone() {
        guard audioEnabled && sfxEnabled else { return }

        soundManager.playSound(.workoutSuccess)
        hapticManager.playNotification(type: .success)
    }

    /// Play "done" sound, then speak "up next" message after sound finishes
    func playDoneAndAnnounceNext(nextExerciseName: String) {
        guard audioEnabled else { return }

        // Play done sound
        if sfxEnabled {
            soundManager.playSound(.workoutSuccess)
            hapticManager.playNotification(type: .success)
        }

        // Wait for done sound to finish (~0.4s), then announce next
        if voiceEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.ttsProvider.speak("Great work! Up next: \(nextExerciseName)", priority: .important)
            }
        }
    }

    /// Play "start" sound (rest complete, exercise starting) with haptic
    func playStart() {
        guard audioEnabled && sfxEnabled else { return }

        soundManager.playSound(.workoutTransition)
        hapticManager.playImpact(style: .medium)
    }

    // MARK: - Control

    func stopAll() {
        ttsProvider.stopAll()
        soundManager.stopAllSounds()

        // Reset de-bounce state
        lastAnnouncedSecond = -1
        lastPhaseId = ""

        // Deactivate audio session (already on MainActor since class is @MainActor)
        deactivateAudioSession()
    }

    func pauseAll() {
        stopAll()
    }

    func resetDeBounce(phaseId: String) {
        // Call when phase changes to allow cues to fire again
        lastPhaseId = phaseId
        lastAnnouncedSecond = -1
    }

    // MARK: - Deinit

    deinit {
        // Don't deactivate session in deinit - causes crash
        // Session will be cleaned up by system or next audio user
        ttsProvider.stopAll()
    }
}
