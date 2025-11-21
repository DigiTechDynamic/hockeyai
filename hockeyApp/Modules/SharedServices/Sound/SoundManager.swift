import AVFoundation
import UIKit
import AudioToolbox

// MARK: - Sound Type
enum SoundType: String, CaseIterable {
    // UI Feedback Sounds
    case uiPress = "ui_press"
    case confirmChime = "confirm_chime"
    case error = "error_buzz"
    case success = "success_bell"
    case warning = "warning_tone"
    
    // Navigation Sounds
    case pageTransition = "page_swoosh"
    case modalOpen = "modal_pop"
    case modalClose = "modal_close"
    
    // Interactive Sounds
    case toggle = "toggle_click"
    case sliderTick = "slider_tick"
    case refresh = "refresh_whoosh"
    
    // Game/Achievement Sounds
    case achievement = "achievement_fanfare"
    case levelUp = "level_up"
    case score = "score_ding"

    // Workout Timer Sounds
    case workoutTick = "workout_tick"          // Countdown tick 10-6
    case workoutBeep = "workout_beep"          // Final countdown 5-1
    case workoutSuccess = "workout_success"    // Exercise complete
    case workoutTransition = "workout_whoosh"  // Phase change

    // Default system sound IDs for fallback
    var systemSoundID: SystemSoundID {
        switch self {
        case .uiPress:
            return 1104 // Tock
        case .confirmChime:
            return 1026 // Glass - light, pleasant confirmation
        case .error:
            return 1073 // Error buzz
        case .success:
            return 1394 // Success haptic sound
        case .warning:
            return 1074 // Warning
        case .pageTransition:
            return 1003 // Slide transition
        case .modalOpen:
            return 1395 // Impact light
        case .modalClose:
            return 1396 // Impact medium
        case .toggle:
            return 1156 // Toggle switch
        case .sliderTick:
            return 1104 // Soft picker wheel sound
        case .refresh:
            return 1003 // Swoosh
        case .achievement:
            return 1025 // Fanfare
        case .levelUp:
            return 1024 // Ascending
        case .score:
            return 1052 // Ping

        // Workout sounds - use system sounds as fallback
        case .workoutTick:
            return 1105  // Tock (subtle, less aggressive)
        case .workoutBeep:
            return 1103  // Tink (sharp beep) - not used anymore
        case .workoutSuccess:
            return 1057  // Swish - clean completion sound (no trumpet)
        case .workoutTransition:
            return 1054  // Pop - clean start sound (not message sound)
        }
    }
}

// MARK: - Sound Manager
final class SoundManager {
    // MARK: - Singleton
    static let shared = SoundManager()
    
    // MARK: - Properties
    private var soundPlayers: [SoundType: AVAudioPlayer] = [:]
    private var isSoundEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: UserDefaults.moduleKey("soundEffectsEnabled")) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaults.moduleKey("soundEffectsEnabled")) }
    }
    
    // Volume control
    private var masterVolume: Float = 0.7
    private var categoryVolumes: [SoundCategory: Float] = [
        .ui: 0.6,
        .navigation: 0.5,
        .interactive: 0.7,
        .achievement: 0.9
    ]
    
    // MARK: - Sound Categories
    enum SoundCategory {
        case ui
        case navigation
        case interactive
        case achievement
        
        static func category(for soundType: SoundType) -> SoundCategory {
            switch soundType {
            case .uiPress, .confirmChime, .error, .success, .warning:
                return .ui
            case .pageTransition, .modalOpen, .modalClose:
                return .navigation
            case .toggle, .sliderTick, .refresh:
                return .interactive
            case .achievement, .levelUp, .score:
                return .achievement
            case .workoutTick, .workoutBeep, .workoutSuccess, .workoutTransition:
                return .interactive  // Workout sounds in interactive category
            }
        }
    }
    
    // MARK: - Initialization
    private init() {
        // Migration + sane defaults for sound effects setting
        let defaults = UserDefaults.standard
        let newKey = UserDefaults.moduleKey("soundEffectsEnabled")
        let legacyKey1 = UserDefaults.moduleKey("soundsEnabled")
        let legacyKey2 = UserDefaults.moduleKey("uiSoundEffectsEnabled")

        if defaults.object(forKey: newKey) == nil {
            if let legacy = defaults.object(forKey: legacyKey1) as? Bool {
                isSoundEnabled = legacy
            } else if let legacyUI = defaults.object(forKey: legacyKey2) as? Bool {
                isSoundEnabled = legacyUI
            } else {
                // Default to enabled so core app feedback sounds work out of the box
                isSoundEnabled = true
            }
        }

        // Preload common sounds (noop for system sounds)
        preloadSounds()
    }
    
    // MARK: - Sound Loading
    private func preloadSounds() {
        // No need to preload since we're using system sounds
    }
    
    private func loadSound(_ soundType: SoundType) -> AVAudioPlayer? {
        // Check if already loaded
        if let player = soundPlayers[soundType] {
            return player
        }
        
        // Try to load the sound file
        let bundle = ModuleConfigurationManager.shared.isConfigured ? 
                     ModuleConfigurationManager.shared.configuration.resourceBundle : 
                     Bundle.main
        
        guard let url = bundle.url(forResource: soundType.rawValue, withExtension: "wav") else {
            // Try with other common audio formats
            if let mp3Url = bundle.url(forResource: soundType.rawValue, withExtension: "mp3") {
                return createPlayer(from: mp3Url, for: soundType)
            } else if let m4aUrl = bundle.url(forResource: soundType.rawValue, withExtension: "m4a") {
                return createPlayer(from: m4aUrl, for: soundType)
            }
            
            // Don't print error - we'll use system sound as fallback
            return nil
        }
        
        return createPlayer(from: url, for: soundType)
    }
    
    private func createPlayer(from url: URL, for soundType: SoundType) -> AVAudioPlayer? {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            
            // Set volume based on category
            let category = SoundCategory.category(for: soundType)
            player.volume = masterVolume * (categoryVolumes[category] ?? 1.0)
            
            // Cache the player
            soundPlayers[soundType] = player
            
            return player
        } catch {
            print("Failed to create audio player for \(soundType.rawValue): \(error)")
            return nil
        }
    }
    
    // MARK: - Public Methods
    
    /// Play a sound effect
    func playSound(_ soundType: SoundType, volume: Float? = nil) {
        guard isSoundEnabled else { return }
        
        // Always use system sounds since we don't have custom sound files
        DispatchQueue.main.async {
            AudioServicesPlaySystemSound(soundType.systemSoundID)
        }
    }
    
    /// Play a sound with haptic feedback
    func playSoundWithHaptic(_ soundType: SoundType, hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        playSound(soundType)
        HapticManager.shared.playImpact(style: hapticStyle)
    }
    
    /// Play a UI interaction sound (convenience method)
    func playUISound(_ type: UIInteractionType) {
        switch type {
        case .buttonPress:
            playSound(.uiPress)
        case .buttonRelease:
            playSound(.confirmChime, volume: 0.5)
        case .toggle:
            playSound(.toggle)
        case .error:
            playSound(.error)
        case .success:
            playSound(.success)
        }
    }
    
    /// Stop all currently playing sounds
    func stopAllSounds() {
        soundPlayers.values.forEach { player in
            if player.isPlaying {
                player.stop()
            }
        }
    }
    
    /// Enable or disable sound effects
    func setSoundEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
        if !enabled {
            stopAllSounds()
        }
    }
    
    /// Check if sound effects are enabled
    func areSoundsEnabled() -> Bool {
        return isSoundEnabled
    }
    
    /// Set master volume (0.0 - 1.0)
    func setMasterVolume(_ volume: Float) {
        masterVolume = max(0.0, min(1.0, volume))
        
        // Update all cached players
        for (soundType, player) in soundPlayers {
            let category = SoundCategory.category(for: soundType)
            player.volume = masterVolume * (categoryVolumes[category] ?? 1.0)
        }
    }
    
    /// Set volume for a specific category
    func setCategoryVolume(_ category: SoundCategory, volume: Float) {
        categoryVolumes[category] = max(0.0, min(1.0, volume))
        
        // Update affected players
        for (soundType, player) in soundPlayers {
            if SoundCategory.category(for: soundType) == category {
                player.volume = masterVolume * volume
            }
        }
    }
    
    /// Prepare sounds for low-latency playback
    func prepareSounds(_ soundTypes: [SoundType]) {
        for soundType in soundTypes {
            _ = loadSound(soundType)
        }
    }
}

// MARK: - UI Interaction Types
enum UIInteractionType {
    case buttonPress
    case buttonRelease
    case toggle
    case error
    case success
}

// MARK: - SwiftUI Integration
import SwiftUI

struct SoundEffect: ViewModifier {
    let soundType: SoundType
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { newValue in
                if newValue {
                    SoundManager.shared.playSound(soundType)
                }
            }
    }
}

extension View {
    /// Play a sound effect when a condition changes to true
    func soundEffect(_ soundType: SoundType, trigger: Bool) -> some View {
        modifier(SoundEffect(soundType: soundType, trigger: trigger))
    }
    
    /// Play a sound effect on tap
    func soundOnTap(_ soundType: SoundType) -> some View {
        self.onTapGesture {
            SoundManager.shared.playSound(soundType)
        }
    }
}
