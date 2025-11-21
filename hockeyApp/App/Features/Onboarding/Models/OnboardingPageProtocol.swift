import SwiftUI

// MARK: - Navigation Result
enum NavigationResult {
    case proceed                        // Advance to next page immediately
    case cancel                         // Don't advance
    case waitForModal                   // Wait for modal to complete
}

// MARK: - Navigation Rules
struct NavigationRules {
    let allowsSwipeBack: Bool
    let allowsSwipeForward: Bool
    let showsBackButton: Bool
    let showsSkipButton: Bool
    let showsProgressBar: Bool
    let transitionDuration: TimeInterval

    // Common presets
    static let standard = NavigationRules(
        allowsSwipeBack: false,
        allowsSwipeForward: false,
        showsBackButton: true,
        showsSkipButton: false,
        showsProgressBar: true,
        transitionDuration: 0.3
    )

    static let firstPage = NavigationRules(
        allowsSwipeBack: false,
        allowsSwipeForward: false,
        showsBackButton: false,
        showsSkipButton: false,
        showsProgressBar: false,
        transitionDuration: 0.3
    )

    static let locked = NavigationRules(
        allowsSwipeBack: false,
        allowsSwipeForward: false,
        showsBackButton: false,
        showsSkipButton: true,
        showsProgressBar: true,
        transitionDuration: 0.3
    )

    static let finalPage = NavigationRules(
        allowsSwipeBack: false,
        allowsSwipeForward: false,
        showsBackButton: false,
        showsSkipButton: true,
        showsProgressBar: true,
        transitionDuration: 0.3
    )
}

// MARK: - Auto Navigation Config
struct AutoNavigationConfig {
    let delay: TimeInterval
    let condition: (() -> Bool)?

    static func after(seconds: TimeInterval) -> AutoNavigationConfig {
        AutoNavigationConfig(delay: seconds, condition: nil)
    }
}

// MARK: - Onboarding Page Protocol
protocol OnboardingPageProtocol {
    var pageID: String { get }
    var navigationRules: NavigationRules { get }
    var autoNavigationConfig: AutoNavigationConfig? { get }

    func onAppear()
    func onDisappear()
    func canNavigateForward() -> Bool
    func canNavigateBack() -> Bool
    func onNavigateForward(completion: @escaping (NavigationResult) -> Void)
    func onNavigateBack(completion: @escaping (NavigationResult) -> Void)
}

// Default implementations
extension OnboardingPageProtocol {
    func onAppear() {}
    func onDisappear() {}
    func canNavigateForward() -> Bool { true }
    func canNavigateBack() -> Bool { navigationRules.showsBackButton }
    func onNavigateBack(completion: @escaping (NavigationResult) -> Void) {
        completion(.proceed)
    }
    var autoNavigationConfig: AutoNavigationConfig? { nil }
}

// MARK: - Type-Erased Wrapper
struct AnyOnboardingPage: OnboardingPageProtocol {
    private let _pageID: () -> String
    private let _navigationRules: () -> NavigationRules
    private let _onAppear: () -> Void
    private let _onDisappear: () -> Void
    private let _canNavigateForward: () -> Bool
    private let _canNavigateBack: () -> Bool
    private let _onNavigateForward: (@escaping (NavigationResult) -> Void) -> Void
    private let _onNavigateBack: (@escaping (NavigationResult) -> Void) -> Void
    private let _autoNavigationConfig: () -> AutoNavigationConfig?

    init<P: OnboardingPageProtocol>(_ page: P) {
        _pageID = { page.pageID }
        _navigationRules = { page.navigationRules }
        _onAppear = page.onAppear
        _onDisappear = page.onDisappear
        _canNavigateForward = page.canNavigateForward
        _canNavigateBack = page.canNavigateBack
        _onNavigateForward = page.onNavigateForward
        _onNavigateBack = page.onNavigateBack
        _autoNavigationConfig = { page.autoNavigationConfig }
    }

    var pageID: String { _pageID() }
    var navigationRules: NavigationRules { _navigationRules() }
    var autoNavigationConfig: AutoNavigationConfig? { _autoNavigationConfig() }

    func onAppear() { _onAppear() }
    func onDisappear() { _onDisappear() }
    func canNavigateForward() -> Bool { _canNavigateForward() }
    func canNavigateBack() -> Bool { _canNavigateBack() }

    func onNavigateForward(completion: @escaping (NavigationResult) -> Void) {
        _onNavigateForward(completion)
    }

    func onNavigateBack(completion: @escaping (NavigationResult) -> Void) {
        _onNavigateBack(completion)
    }
}
