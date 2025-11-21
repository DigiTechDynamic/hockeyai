import Foundation
import SwiftUI
import UIKit

// MARK: - Safe Manager Access
/// Provides safe access to managers that might not be initialized
/// Prevents crashes when managers are accessed before initialization
struct SafeManagers {
    // MARK: - Settings
    // Use SoundManager as the single source of truth for SFX enablement
    private static var areUISoundsEnabled: Bool {
        SoundManager.shared.areSoundsEnabled()
    }
    
    // MARK: - Haptic Feedback
    static func playHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1.0) {
        // Import HapticManager only if available
        #if canImport(SharedServices)
        HapticManager.shared.playImpact(style: style, intensity: intensity)
        #endif
    }
    
    static func playSelectionHaptic() {
        #if canImport(SharedServices)
        HapticManager.shared.playSelection()
        #endif
    }
    
    static func playNotificationHaptic(type: UINotificationFeedbackGenerator.FeedbackType) {
        #if canImport(SharedServices)
        HapticManager.shared.playNotification(type: type)
        #endif
    }
    
    // MARK: - Sound Effects
    static func playSound(_ sound: String, volume: Float = 1.0) {
        // Respect UI sound setting; default is off for chrome sounds
        guard areUISoundsEnabled else { return }
        // Map string to our unified SoundType and delegate to SoundManager
        let normalized = sound.lowercased()
        if let mapped = mapStringToSoundType(normalized) {
            SoundManager.shared.playSound(mapped)
        } else {
            // Fallback to a safe default UI press sound
            SoundManager.shared.playSound(.uiPress)
        }
    }
    
    static func playSoundWithHaptic(_ sound: String, hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        playSound(sound)
        playHaptic(style: hapticStyle)
    }
    
    static func playFeedback(sound: String, haptic: UIImpactFeedbackGenerator.FeedbackStyle) {
        playSound(sound)
        playHaptic(style: haptic)
    }
    
    // MARK: - System Sound Fallbacks
    private static func mapStringToSoundType(_ sound: String) -> SoundType? {
        switch sound {
        case "uipress", "ui_press", "uitap", "ui_tap":
            return .uiPress
        case "confirmchime", "confirm_chime", "confirm":
            return .confirmChime
        case "error", "error_buzz":
            return .error
        case "success", "success_bell":
            return .success
        case "warning", "warning_tone":
            return .warning
        case "toggle", "toggle_click", "selection", "item_select":
            return .toggle
        case "slider_tick", "scroll_tick":
            return .sliderTick
        case "page_swoosh", "nav_forward", "pageTransition":
            return .pageTransition
        default:
            return nil
        }
    }
}

// MARK: - View Extensions
extension View {
    /// Safe haptic feedback modifier
    func safeHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle, trigger: Bool) -> some View {
        self.onChange(of: trigger) { newValue in
            if newValue {
                SafeManagers.playHaptic(style: style)
            }
        }
    }
    
    /// Safe sound effect modifier
    func safeSoundEffect(_ soundName: String, trigger: Bool) -> some View {
        self.onChange(of: trigger) { newValue in
            if newValue {
                SafeManagers.playSound(soundName)
            }
        }
    }
}
