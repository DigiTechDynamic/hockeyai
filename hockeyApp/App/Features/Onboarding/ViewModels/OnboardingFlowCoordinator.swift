import SwiftUI
import Combine

// MARK: - Onboarding Flow Coordinator
@MainActor
class OnboardingFlowCoordinator: ObservableObject {
    @Published var currentPageIndex: Int = 0
    @Published var isNavigating: Bool = false

    private var pages: [AnyOnboardingPage]
    private var autoNavTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    var onComplete: (() -> Void)?

    init(pages: [AnyOnboardingPage]) {
        self.pages = pages
    }

    // MARK: - Current Page Access
    var currentPage: AnyOnboardingPage {
        pages[currentPageIndex]
    }

    var isFirstPage: Bool {
        currentPageIndex == 0
    }

    var isLastPage: Bool {
        currentPageIndex == pages.count - 1
    }

    // MARK: - Navigation Permissions
    func canGoBack() -> Bool {
        guard !isFirstPage else { return false }
        return currentPage.canNavigateBack()
    }

    func canSkip() -> Bool {
        currentPage.navigationRules.showsSkipButton
    }

    func showsBackButton() -> Bool {
        currentPage.navigationRules.showsBackButton && canGoBack()
    }

    func showsProgressBar() -> Bool {
        currentPage.navigationRules.showsProgressBar
    }

    var progress: Double {
        Double(currentPageIndex + 1) / Double(pages.count)
    }

    // MARK: - Page Lifecycle
    func pageDidAppear() {
        currentPage.onAppear()
        startAutoNavigationIfNeeded()
    }

    func pageWillDisappear() {
        stopAutoNavigation()
        currentPage.onDisappear()
    }

    // MARK: - Navigation Actions
    func navigateForward() {
        guard !isNavigating else { return }
        guard currentPage.canNavigateForward() else { return }

        isNavigating = true

        currentPage.onNavigateForward { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .proceed:
                self.advanceToNextPage()

            case .cancel:
                self.isNavigating = false

            case .waitForModal:
                // Navigation will be triggered when modal dismisses
                // Don't set isNavigating = false here
                break
            }
        }
    }

    func navigateBack() {
        guard !isNavigating else { return }
        guard canGoBack() else { return }

        isNavigating = true

        currentPage.onNavigateBack { [weak self] result in
            guard let self = self else { return }

            if case .proceed = result {
                self.moveToPreviousPage()
            } else {
                self.isNavigating = false
            }
        }
    }

    func skip() {
        // Skip moves to next page, not complete onboarding
        // This allows users to skip optional screens while still seeing remaining screens
        guard !isNavigating else { return }
        isNavigating = true
        advanceToNextPage()
    }

    // Jump forward by skipping the next page (useful for conditional flows)
    func skipNextPage() {
        guard !isNavigating else { return }

        isNavigating = true

        pageWillDisappear()

        let targetIndex = currentPageIndex + 2
        if targetIndex >= pages.count {
            completeOnboarding()
        } else {
            withAnimation(.easeInOut(duration: currentPage.navigationRules.transitionDuration)) {
                currentPageIndex = targetIndex
            }
            isNavigating = false
            pageDidAppear()
        }
    }

    // MARK: - Internal Navigation
    private func advanceToNextPage() {
        pageWillDisappear()

        if isLastPage {
            completeOnboarding()
        } else {
            withAnimation(.easeInOut(duration: currentPage.navigationRules.transitionDuration)) {
                currentPageIndex += 1
            }

            isNavigating = false
            pageDidAppear()
        }
    }

    private func moveToPreviousPage() {
        pageWillDisappear()

        withAnimation(.easeInOut(duration: 0.3)) {
            currentPageIndex -= 1
        }

        isNavigating = false
        pageDidAppear()
    }

    private func completeOnboarding() {
        onComplete?()
    }

    // MARK: - Auto Navigation
    private func startAutoNavigationIfNeeded() {
        guard let config = currentPage.autoNavigationConfig else { return }

        autoNavTimer = Timer.scheduledTimer(withTimeInterval: config.delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            // Check condition if provided
            if let condition = config.condition, !condition() {
                return
            }

            self.navigateForward()
        }
    }

    nonisolated private func stopAutoNavigation() {
        Task { @MainActor in
            autoNavTimer?.invalidate()
            autoNavTimer = nil
        }
    }

    // MARK: - Public method to complete navigation after modal
    func completeModalNavigation() {
        isNavigating = false
        advanceToNextPage()
    }

    // MARK: - Cleanup
    deinit {
        stopAutoNavigation()
    }
}
