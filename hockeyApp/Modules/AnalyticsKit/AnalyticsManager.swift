import Foundation
#if canImport(Mixpanel)
import Mixpanel
#endif
#if canImport(RevenueCat)
import RevenueCat
#endif
// Firebase Analytics + Crashlytics are optional
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif
#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

/// Centralized analytics manager for tracking events across the app
/// Supports Mixpanel, Firebase Analytics, and Firebase Crashlytics
public final class AnalyticsManager {
    public static let shared = AnalyticsManager()

    private init() {}

    // MARK: - Basic Event Tracking

    /// Track a generic event with optional properties
    public func track(eventName: String, properties: [String: Any]? = nil) {
        // Add environment context to all events
        var enrichedProperties = properties ?? [:]
        enrichedProperties["environment"] = AppEnvironment.current.analyticsProject
        enrichedProperties["build_type"] = AppEnvironment.current.displayName

        #if DEBUG
        print("[Analytics] [\(AppEnvironment.current.analyticsProject.uppercased())] \(eventName) -> \(enrichedProperties)")
        #endif

        // Send to Mixpanel
        #if canImport(Mixpanel)
        Mixpanel.mainInstance().track(event: eventName, properties: convertToMixpanelProps(enrichedProperties))
        Mixpanel.mainInstance().flush()
        #endif

        // Send to Firebase Analytics
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(eventName, parameters: convertToFirebaseParams(enrichedProperties))
        #endif
    }

    // MARK: - Initialization

    /// Initialize Mixpanel with the provided token
    public func initializeMixpanel(token: String) {
        guard !token.isEmpty else {
            print("[Analytics] Mixpanel token missing – skipping initialization")
            return
        }

        #if canImport(Mixpanel)
        Mixpanel.initialize(token: token, trackAutomaticEvents: true)
        print("[Analytics] ✅ Mixpanel initialized")
        #else
        print("[Analytics] Mixpanel framework not available – initialization skipped")
        #endif
    }

    // MARK: - User Identity Management

    /// Align Mixpanel distinctId to RevenueCat appUserID for consistent attribution.
    /// Call on launch, after RC configure, and whenever RC identity changes (login/logout).
    public func syncRevenueCatIdentity(appUserID: String? = nil) {
        let id: String

        #if canImport(RevenueCat)
        id = appUserID ?? Purchases.shared.appUserID
        #else
        id = appUserID ?? UUID().uuidString
        #endif

        #if canImport(Mixpanel)
        Mixpanel.mainInstance().identify(distinctId: id)
        #endif

        // Also set Firebase Analytics / Crashlytics user identifiers if available
        #if canImport(FirebaseAnalytics)
        Analytics.setUserID(id)
        #endif
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().setUserID(id)
        #endif

        #if DEBUG
        print("[Analytics] User identified: \(id)")
        #endif
    }

    /// Explicitly set a global user id across supported analytics providers.
    public func setGlobalUserID(_ id: String) {
        #if canImport(Mixpanel)
        Mixpanel.mainInstance().identify(distinctId: id)
        #endif
        #if canImport(FirebaseAnalytics)
        Analytics.setUserID(id)
        #endif
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().setUserID(id)
        #endif

        #if DEBUG
        print("[Analytics] Global user ID set: \(id)")
        #endif
    }

    /// Ensure pre-identity events (like `app_installed`) get merged with the
    /// authenticated/known user by creating a Mixpanel alias before identifying.
    /// Safe to call repeatedly; it no-ops once an alias has been created.
    public func aliasAndIdentifyIfNeeded(newDistinctId: String) {
        #if canImport(Mixpanel)
        let instance = Mixpanel.mainInstance()
        let currentId = instance.distinctId

        // Already using the desired id
        if currentId == newDistinctId {
            return
        }

        // Persist a guard so we only alias once per target id
        let aliasKey = "mixpanel_alias_done_\(newDistinctId)"
        if !UserDefaults.standard.bool(forKey: aliasKey) {
            // Merge the anonymous pre-login id with the known id
            instance.createAlias(newDistinctId, distinctId: currentId)
            UserDefaults.standard.set(true, forKey: aliasKey)
        }

        // Now identify as the stable id
        instance.identify(distinctId: newDistinctId)
        instance.flush()
        #endif
        
        // Keep other providers in sync
        #if canImport(FirebaseAnalytics)
        Analytics.setUserID(newDistinctId)
        #endif
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().setUserID(newDistinctId)
        #endif
    }

    // MARK: - Funnel Tracking (GoLive Pattern)

    /// Track a step in a user funnel (onboarding, conversion, etc.)
    /// This creates detailed funnel analytics in Mixpanel
    ///
    /// Example:
    /// ```
    /// trackFunnelStep(
    ///     funnel: "onboarding",
    ///     step: "welcome_screen",
    ///     stepNumber: 1,
    ///     totalSteps: 5
    /// )
    /// ```
    public func trackFunnelStep(
        funnel: String,
        step: String,
        stepNumber: Int,
        totalSteps: Int,
        metadata: [String: Any]? = nil
    ) {
        var properties = metadata ?? [:]
        properties["funnel"] = funnel
        properties["step"] = step
        properties["step_number"] = stepNumber
        properties["total_steps"] = totalSteps
        properties["progress_percentage"] = Double(stepNumber) / Double(totalSteps) * 100.0

        #if DEBUG
        print("[Analytics] Funnel: \(funnel) → Step \(stepNumber)/\(totalSteps): \(step)")
        #endif

        // Track the specific step name for funnel visualization
        #if canImport(Mixpanel)
        Mixpanel.mainInstance().track(event: "\(funnel)_\(step)", properties: convertToMixpanelProps(properties))
        Mixpanel.mainInstance().flush()
        #endif
    }

    /// Track funnel completion
    public func trackFunnelCompleted(
        funnel: String,
        totalSteps: Int,
        metadata: [String: Any]? = nil
    ) {
        var properties = metadata ?? [:]
        properties["funnel"] = funnel
        properties["total_steps"] = totalSteps
        properties["completed"] = true

        #if DEBUG
        print("[Analytics] ✅ Funnel completed: \(funnel)")
        #endif

        track(eventName: "\(funnel)_completed", properties: properties)
    }

    /// Track when user drops off from a funnel
    public func trackFunnelDropoff(
        funnel: String,
        step: String,
        stepNumber: Int,
        totalSteps: Int,
        reason: String = "unknown"
    ) {
        let properties: [String: Any] = [
            "funnel": funnel,
            "step": step,
            "step_number": stepNumber,
            "total_steps": totalSteps,
            "progress_percentage": Double(stepNumber) / Double(totalSteps) * 100.0,
            "reason": reason
        ]

        #if DEBUG
        print("[Analytics] ❌ Funnel dropout: \(funnel) at step \(stepNumber)")
        #endif

        track(eventName: "\(funnel)_dropout", properties: properties)
    }

    // MARK: - Screen Tracking

    /// Track when a screen is viewed
    public func trackScreenView(screenName: String, properties: [String: Any]? = nil) {
        var props = properties ?? [:]
        props["screen_name"] = screenName

        #if DEBUG
        print("[Analytics] Screen viewed: \(screenName)")
        #endif

        track(eventName: "screen_viewed", properties: props)
    }

    // MARK: - User Properties

    /// Set user profile properties (super properties in Mixpanel)
    /// These properties persist across all future events for this user
    public func setUserProperties(_ properties: [String: Any]) {
        #if DEBUG
        print("[Analytics] Setting user properties: \(properties)")
        #endif

        #if canImport(Mixpanel)
        if let mixpanelProps = convertToMixpanelProps(properties) {
            Mixpanel.mainInstance().people.set(properties: mixpanelProps)
        }
        #endif

        #if canImport(FirebaseAnalytics)
        for (key, value) in properties {
            let sanitizedKey = sanitizeFirebaseKey(key)
            if let stringValue = value as? String {
                Analytics.setUserProperty(stringValue, forName: sanitizedKey)
            } else if let numberValue = value as? NSNumber {
                Analytics.setUserProperty(numberValue.stringValue, forName: sanitizedKey)
            } else {
                Analytics.setUserProperty(String(describing: value), forName: sanitizedKey)
            }
        }
        #endif
    }

    /// Set a single user property
    public func setUserProperty(key: String, value: Any) {
        setUserProperties([key: value])
    }

    /// Reset Mixpanel to fresh state
    public func resetMixpanel() {
        #if canImport(Mixpanel)
        let instance = Mixpanel.mainInstance()

        // 1. Reset the instance (clears distinct ID, super properties, etc.)
        instance.reset()

        // 2. Clear all queued events
        instance.flush()

        // 3. Clear persistent storage (this is the key!)
        if let mixpanelDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Mixpanel") {
            try? FileManager.default.removeItem(at: mixpanelDirectory)
            print("[Analytics] ✅ Cleared Mixpanel persistent storage")
        }

        print("[Analytics] ✅ Mixpanel reset - fresh distinct ID will be generated")
        #endif
    }
}

// MARK: - Mixpanel Helpers
#if canImport(Mixpanel)
private extension AnalyticsManager {
    typealias MPProperties = Properties

    func convertToMixpanelProps(_ props: [String: Any]?) -> MPProperties? {
        guard let props = props else { return nil }
        var out: MPProperties = [:]
        for (k, v) in props {
            switch v {
            case let x as String: out[k] = x
            case let x as Int: out[k] = x
            case let x as Double: out[k] = x
            case let x as Float: out[k] = x
            case let x as Bool: out[k] = x
            case let x as Date: out[k] = x
            case let x as URL: out[k] = x
            default:
                out[k] = String(describing: v)
            }
        }
        return out
    }
}
#endif

// MARK: - Firebase Analytics Helpers
#if canImport(FirebaseAnalytics)
private extension AnalyticsManager {
    func convertToFirebaseParams(_ props: [String: Any]?) -> [String: Any]? {
        guard let props = props else { return nil }
        var out: [String: Any] = [:]
        for (k, v) in props {
            // Firebase Analytics has specific parameter naming rules
            // Replace invalid characters and ensure parameters are valid types
            let sanitizedKey = sanitizeFirebaseKey(k)

            switch v {
            case let x as String:
                out[sanitizedKey] = x
            case let x as Int:
                out[sanitizedKey] = x
            case let x as Double:
                out[sanitizedKey] = x
            case let x as Float:
                out[sanitizedKey] = Double(x)
            case let x as Bool:
                out[sanitizedKey] = x
            case let x as NSNumber:
                out[sanitizedKey] = x
            case is [Any]:
                // Firebase doesn't support arrays, convert to string
                out[sanitizedKey] = String(describing: v)
            default:
                out[sanitizedKey] = String(describing: v)
            }
        }
        return out
    }

    func sanitizeFirebaseKey(_ key: String) -> String {
        // Firebase Analytics parameter names must:
        // - Start with a letter
        // - Contain only alphanumeric characters and underscores
        // - Be no longer than 40 characters
        var sanitized = key
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .lowercased()

        // Remove any non-alphanumeric characters except underscores
        sanitized = sanitized.filter { $0.isLetter || $0.isNumber || $0 == "_" }

        // Ensure it starts with a letter
        if let first = sanitized.first, !first.isLetter {
            sanitized = "param_" + sanitized
        }

        // Truncate to 40 characters
        if sanitized.count > 40 {
            sanitized = String(sanitized.prefix(40))
        }

        return sanitized
    }
}
#endif
