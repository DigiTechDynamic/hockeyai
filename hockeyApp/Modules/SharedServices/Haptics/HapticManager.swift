import UIKit
import CoreHaptics

// MARK: - Haptic Sound Types
enum HapticSoundType: String {
    case uiTap = "ui_tap"
    case navigationForward = "nav_forward" 
    case scrollTick = "scroll_tick"
    case selection = "item_select"
    case confirmChime = "confirm"
    case error = "error_buzz"
}

// MARK: - Haptic Manager
final class HapticManager {
    
    // MARK: - Constants
    private enum Constants {
        static let hapticsEnabledKey = "hapticsEnabled"
    }
    
    // MARK: - Singleton
    static let shared = HapticManager()
    
    // MARK: - Properties
    private var isHapticsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: UserDefaults.moduleKey(Constants.hapticsEnabledKey)) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaults.moduleKey(Constants.hapticsEnabledKey)) }
    }
    
    // Sound enablement is owned by SoundManager (single source of truth)
    
    // Feedback generators (kept alive for better performance)
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    // Core Haptics engine for advanced patterns
    private var hapticEngine: CHHapticEngine?
    private var supportsHaptics: Bool = false
    
    // MARK: - Initialization
    private init() {
        // Enable haptics by default
        if UserDefaults.standard.object(forKey: Constants.hapticsEnabledKey) == nil {
            isHapticsEnabled = true
        }
        
        // Sound defaults and migrations are handled by SoundManager
        
        // Check haptic support
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        
        // Prepare generators
        prepareHaptics()
        
        // Setup Core Haptics if supported
        if supportsHaptics {
            setupHapticEngine()
        }
    }
    
    // MARK: - Setup
    private func setupHapticEngine() {
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            
            // Handle engine reset
            hapticEngine?.resetHandler = { [weak self] in
                self?.startHapticEngine()
            }
            
            // Handle engine stopped
            hapticEngine?.stoppedHandler = { [weak self] _ in
                self?.startHapticEngine()
            }
        } catch {
            // Failed to setup haptic engine
        }
    }
    
    private func startHapticEngine() {
        do {
            try hapticEngine?.start()
        } catch {
            // Failed to start haptic engine
        }
    }
    
    // MARK: - Prepare Haptics
    func prepareHaptics() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    // MARK: - Impact Feedback
    func playImpact(style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1.0) {
        guard isHapticsEnabled else { return }
        
        switch style {
        case .light:
            impactLight.impactOccurred(intensity: intensity)
        case .medium:
            impactMedium.impactOccurred(intensity: intensity)
        case .heavy:
            impactHeavy.impactOccurred(intensity: intensity)
        default:
            break
        }
    }
    
    // MARK: - Selection Feedback
    func playSelection() {
        guard isHapticsEnabled else { return }
        selectionGenerator.selectionChanged()
    }
    
    // MARK: - Notification Feedback
    func playNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsEnabled else { return }
        notificationGenerator.notificationOccurred(type)
    }
    
    // MARK: - Custom Haptic Patterns
    func playCustomPattern(_ pattern: HapticPattern) {
        guard isHapticsEnabled, supportsHaptics, let engine = hapticEngine else { return }
        
        do {
            let pattern = try pattern.createCHHapticPattern()
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Failed to play custom haptic pattern
        }
    }
    
    // MARK: - Convenience Methods
    func playSuccess() {
        playNotification(type: .success)
    }
    
    func playError() {
        playNotification(type: .error)
    }
    
    func playWarning() {
        playNotification(type: .warning)
    }
    
    // MARK: - Sound Playback (delegates to SoundManager)
    private func mapToSoundManagerType(_ sound: HapticSoundType) -> SoundType {
        switch sound {
        case .uiTap:
            return .uiPress
        case .navigationForward:
            return .pageTransition
        case .scrollTick:
            return .sliderTick
        case .selection:
            return .toggle
        case .confirmChime:
            return .confirmChime
        case .error:
            return .error
        }
    }

    func playSound(_ sound: HapticSoundType, volume: Float = 1.0) {
        // Delegate gating to SoundManager
        SoundManager.shared.playSound(mapToSoundManagerType(sound))
    }
    
    // MARK: - Combined Feedback
    func playFeedback(_ sound: HapticSoundType, haptic: UIImpactFeedbackGenerator.FeedbackStyle? = nil) {
        playSound(sound)
        if let haptic = haptic {
            playImpact(style: haptic)
        }
    }
    
    func playSelectionFeedback(sound: HapticSoundType = .selection) {
        playSound(sound)
        playSelection()
    }
    
    // MARK: - Settings
    func setHapticsEnabled(_ enabled: Bool) {
        isHapticsEnabled = enabled
    }
    
    func areHapticsEnabled() -> Bool {
        return isHapticsEnabled
    }
    
    func setSoundsEnabled(_ enabled: Bool) {
        SoundManager.shared.setSoundEnabled(enabled)
    }
    
    func areSoundsEnabled() -> Bool {
        return SoundManager.shared.areSoundsEnabled()
    }
    
    // MARK: - Static Convenience Methods (for backward compatibility)
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        shared.playImpact(style: style)
    }
    
    static func selection() {
        shared.playSelection()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        shared.playNotification(type: type)
    }
    
    static func success() {
        shared.playSuccess()
    }
    
    static func error() {
        shared.playError()
    }
    
    static func warning() {
        shared.playWarning()
    }
    
    // MARK: - Sound Convenience Methods
    static func playSound(_ sound: HapticSoundType, volume: Float = 1.0) {
        shared.playSound(sound, volume: volume)
    }
    
    static func playFeedback(_ sound: HapticSoundType, haptic: UIImpactFeedbackGenerator.FeedbackStyle? = nil) {
        shared.playFeedback(sound, haptic: haptic)
    }
    
    static func playSelectionFeedback(sound: HapticSoundType = .selection) {
        shared.playSelectionFeedback(sound: sound)
    }
}

// MARK: - Haptic Pattern
struct HapticPattern {
    let events: [CHHapticEvent]
    
    static let buttonPress = HapticPattern(events: [
        CHHapticEvent(eventType: .hapticTransient, 
                      parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                                  CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)],
                      relativeTime: 0)
    ])
    
    static let buttonRelease = HapticPattern(events: [
        CHHapticEvent(eventType: .hapticTransient,
                      parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                                  CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)],
                      relativeTime: 0)
    ])
    
    static let longPress = HapticPattern(events: [
        CHHapticEvent(eventType: .hapticContinuous,
                      parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                                  CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)],
                      relativeTime: 0,
                      duration: 0.5)
    ])
    
    func createCHHapticPattern() throws -> CHHapticPattern {
        return try CHHapticPattern(events: events, parameters: [])
    }
}

// MARK: - SwiftUI Integration
import SwiftUI

struct HapticModifier: ViewModifier {
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { newValue in
                if newValue {
                    HapticManager.shared.playImpact(style: style)
                }
            }
    }
}

extension View {
    /// Trigger haptic feedback when a condition changes to true
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle, trigger: Bool) -> some View {
        modifier(HapticModifier(style: style, trigger: trigger))
    }
    
    /// Trigger haptic feedback on tap
    func hapticOnTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onTapGesture {
            HapticManager.shared.playImpact(style: style)
        }
    }
}
