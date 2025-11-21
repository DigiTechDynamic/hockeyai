import Foundation

// MARK: - Profile Analytics
/// Centralized analytics tracking for profile features
class ProfileAnalytics {

    // MARK: - Singleton
    static let shared = ProfileAnalytics()
    private init() {}

    // MARK: - Private Properties
    private let analytics = AnalyticsManager.shared

    // MARK: - Profile View Tracking
    func trackProfileViewed() {
        analytics.track(eventName: "profile_viewed", properties: [:])
    }

    func trackProfileSaved() {
        analytics.track(eventName: "profile_saved", properties: [:])
    }

    // MARK: - Field Edit Tracking
    func trackFieldEdited(field: String, value: String) {
        analytics.track(eventName: "profile_field_edited", properties: [
            "field": field,
            "value": value
        ])
    }

    // MARK: - Photo Tracking
    func trackProfilePhotoUpdated() {
        analytics.track(eventName: "profile_photo_updated", properties: [:])
    }

    func trackProfilePhotoSourceSelected(source: String) {
        analytics.track(eventName: "profile_photo_source_selected", properties: [
            "source": source // "camera" or "library"
        ])
    }

    func trackProfilePhotoRemoved() {
        analytics.track(eventName: "profile_photo_removed", properties: [:])
    }

    // MARK: - Unit System Tracking
    func trackUnitChanged(to unit: String) {
        analytics.track(eventName: "profile_unit_changed", properties: [
            "unit_system": unit // "metric" or "imperial"
        ])
    }

    // MARK: - Settings Tracking
    func trackThemeChanged(to theme: String) {
        analytics.track(eventName: "profile_theme_changed", properties: [
            "theme": theme
        ])
    }

    func trackHapticsToggled(enabled: Bool) {
        analytics.track(eventName: "profile_haptics_toggled", properties: [
            "enabled": enabled
        ])
    }

    func trackSoundToggled(enabled: Bool) {
        analytics.track(eventName: "profile_sound_toggled", properties: [
            "enabled": enabled
        ])
    }

    func trackTeamSelected(team: String) {
        analytics.track(eventName: "profile_team_selected", properties: [
            "team": team
        ])
    }

    // MARK: - Account Actions
    func trackLogoutInitiated() {
        analytics.track(eventName: "profile_logout_initiated", properties: [:])
    }

    func trackAccountDeletionInitiated() {
        analytics.track(eventName: "profile_account_deletion_initiated", properties: [:])
    }

    // MARK: - Interaction Tracking
    func trackSectionExpanded(section: String) {
        analytics.track(eventName: "profile_section_expanded", properties: [
            "section": section
        ])
    }

    func trackPopupOpened(popup: String) {
        analytics.track(eventName: "profile_popup_opened", properties: [
            "popup": popup
        ])
    }

    func trackPopupClosed(popup: String, saved: Bool) {
        analytics.track(eventName: "profile_popup_closed", properties: [
            "popup": popup,
            "saved": saved
        ])
    }
}
