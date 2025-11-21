import Foundation
import AVFoundation

// MARK: - Audio Provider Protocol

/// Protocol defining audio coaching capabilities for workout execution
/// Allows for multiple implementations (System TTS, ElevenLabs, etc.)
protocol AudioProvider {
    /// Speak text with specified priority
    func speak(_ text: String, priority: AudioPriority, completion: (() -> Void)?, voiceIdentifier: String?)

    /// Stop all current and queued audio
    func stopAll()

    /// Configure audio provider with settings
    func configure(settings: AudioCoachingSettings)

    /// Whether audio is currently playing
    var isPlaying: Bool { get }
}

// MARK: - Audio Priority

/// Priority levels for audio cues determine queue behavior
enum AudioPriority {
    case critical   // 3-2-1 countdown, "Go!", "Time!" - Never queued, interrupts everything
    case important  // Exercise names, warnings, "Up Next" - Queued if critical active
    case optional   // Motivational cues, form tips - Skipped if queue busy

    /// Music ducking level (0.0 = silent, 1.0 = full volume)
    var musicDuckLevel: Float {
        switch self {
        case .critical: return 0.2  // Duck to 20%
        case .important: return 0.3 // Duck to 30%
        case .optional: return 0.4  // Duck to 40%
        }
    }
}

// MARK: - Audio Coaching Settings

/// User preferences for audio coaching behavior
struct AudioCoachingSettings: Codable {
    var isEnabled: Bool = true
    var voiceIdentifier: String? = nil // System voice ID
    var speechRate: Float = 0.5 // Slightly slower than normal (0.0-1.0)
    var volume: Float = 1.0

    // Announcement toggles
    var announceExerciseNames: Bool = true
    var announceCountdowns: Bool = true
    var announceTimeWarnings: Bool = true
    var announceUpNext: Bool = true
    var announceMotivational: Bool = false // OFF by default
    var announceFormCues: Bool = false // OFF by default

    // Music ducking
    var duckBackgroundAudio: Bool = true
    var duckLevel: Float = 0.25 // 25% of original volume
}

// MARK: - System TTS Provider

/// Implementation using iOS AVSpeechSynthesizer
/// Provides free, offline audio coaching using system voices
class SystemTTSProvider: NSObject, AudioProvider {

    // MARK: - Properties

    private let synthesizer = AVSpeechSynthesizer()
    private let audioSession = AVAudioSession.sharedInstance()
    private var settings: AudioCoachingSettings = AudioCoachingSettings()

    private var criticalCue: AudioCue?
    private var importantQueue: [AudioCue] = [] // Max 2
    private var currentCompletion: (() -> Void)?

    // MARK: - Computed Properties

    var isPlaying: Bool {
        synthesizer.isSpeaking
    }

    // MARK: - Initialization

    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
        setupInterruptionHandling()
    }

    // MARK: - Audio Provider Protocol

    func speak(_ text: String, priority: AudioPriority, completion: (() -> Void)? = nil, voiceIdentifier: String? = nil) {
        let cue = AudioCue(text: text, priority: priority, completion: completion, voiceIdentifier: voiceIdentifier)
        enqueue(cue)
    }

    func stopAll() {
        synthesizer.stopSpeaking(at: .immediate)
        criticalCue = nil
        importantQueue.removeAll()
        currentCompletion = nil
        deactivateAudioSession()
    }

    func configure(settings: AudioCoachingSettings) {
        self.settings = settings
    }

    // MARK: - Audio Session Management

    private func configureAudioSession() {
        do {
            try audioSession.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [
                    .mixWithOthers,
                    .duckOthers,
                    .interruptSpokenAudioAndMixWithOthers
                ]
            )
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    private func activateAudioSession(duckLevel: Float) {
        guard settings.duckBackgroundAudio else { return }

        do {
            // Activate with ducking to lower background music
            try audioSession.setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }
    }

    private func deactivateAudioSession() {
        do {
            // Deactivate and notify other audio sessions to restore volume
            try audioSession.setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }

    // MARK: - Interruption Handling

    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: audioSession
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
            // System paused us (phone call, etc.) - just update state
            // Audio session is already deactivated by system
            break

        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)

            if options.contains(.shouldResume) {
                // Safe to resume - reactivate session if we have queued cues
                if !importantQueue.isEmpty || criticalCue != nil {
                    playNext()
                }
            }

        @unknown default:
            break
        }
    }

    // MARK: - Queue Management

    private func enqueue(_ cue: AudioCue) {
        guard settings.isEnabled else { return }

        switch cue.priority {
        case .critical:
            // Interrupt everything and play immediately
            if isPlaying {
                synthesizer.stopSpeaking(at: .immediate)
            }
            criticalCue = cue
            playNext()

        case .important:
            // Queue up to 2, discard oldest if full
            if importantQueue.count >= 2 {
                importantQueue.removeFirst()
            }
            importantQueue.append(cue)

            if !isPlaying {
                playNext()
            }

        case .optional:
            // Only play if queue is empty and nothing playing
            if !isPlaying && importantQueue.isEmpty && criticalCue == nil {
                play(cue)
            }
            // Otherwise skip silently
        }
    }

    private func playNext() {
        guard !isPlaying else { return }

        // Critical cues have highest priority
        if let critical = criticalCue {
            play(critical)
            criticalCue = nil
            return
        }

        // Important cues next
        if !importantQueue.isEmpty {
            let cue = importantQueue.removeFirst()
            play(cue)
            return
        }

        // Nothing to play
    }

    private func play(_ cue: AudioCue) {
        // Store completion handler
        currentCompletion = cue.completion

        // Activate audio session with appropriate duck level
        activateAudioSession(duckLevel: cue.priority.musicDuckLevel)

        // Create utterance
        let utterance = AVSpeechUtterance(string: cue.text)

        // Configure voice (custom voice overrides settings voice)
        if let customVoiceId = cue.voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: customVoiceId) {
            utterance.voice = voice
        } else if let voiceId = settings.voiceIdentifier,
                  let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
            utterance.voice = voice
        } else {
            // Use best available US English voice
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        // Configure speech parameters
        utterance.rate = settings.speechRate
        utterance.volume = settings.volume
        utterance.pitchMultiplier = 1.0

        // Speak
        synthesizer.speak(utterance)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SystemTTSProvider: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Call completion handler
        currentCompletion?()
        currentCompletion = nil

        // Play next cue in queue (if any)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }

            // Only deactivate audio session if queue is empty
            if self.importantQueue.isEmpty && self.criticalCue == nil {
                self.deactivateAudioSession()
            } else {
                self.playNext()
            }
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        currentCompletion = nil

        // Only deactivate if queue is empty
        if importantQueue.isEmpty && criticalCue == nil {
            deactivateAudioSession()
        }
    }
}

// MARK: - Audio Cue

/// Internal model representing a single audio cue
private struct AudioCue {
    let text: String
    let priority: AudioPriority
    let completion: (() -> Void)?
    let voiceIdentifier: String?
}

// MARK: - Future: ElevenLabs Provider

/// Premium audio provider using ElevenLabs AI voice synthesis
/// To be implemented in Phase 2 for premium tier subscribers
///
/// Features:
/// - Professional, energetic coaching voice
/// - Motivational tone variations
/// - Pre-caching of common phrases
/// - Network fallback to SystemTTSProvider
///
/// Implementation notes:
/// - Integrate ElevenLabs SDK
/// - Cache common phrases locally (0-9, "Go", "Rest", etc.)
/// - Generate exercise names dynamically
/// - Estimated cost: $0.01-0.05 per workout
class ElevenLabsProvider: AudioProvider {
    var isPlaying: Bool { false }

    func speak(_ text: String, priority: AudioPriority, completion: (() -> Void)?, voiceIdentifier: String?) {
        // TODO: Implement ElevenLabs integration
        completion?()
    }

    func stopAll() {
        // TODO: Implement
    }

    func configure(settings: AudioCoachingSettings) {
        // TODO: Implement
    }
}

// MARK: - Audio Provider Factory

/// Factory for creating appropriate audio provider based on user tier
enum AudioProviderFactory {
    static func create(isPremium: Bool = false) -> AudioProvider {
        if isPremium {
            // Phase 2: Return ElevenLabsProvider for premium users
            return ElevenLabsProvider()
        } else {
            return SystemTTSProvider()
        }
    }
}
