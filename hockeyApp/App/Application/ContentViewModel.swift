import SwiftUI
import Combine

/// ViewModel for ContentView - manages app state and navigation logic
class ContentViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            // Persist onboarding state
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: onboardingKey)
        }
    }
    
    @Published var isLoadingAuth: Bool = true
    @Published var isAuthenticated: Bool = false
    
    // MARK: - Dependencies

    private let authManager = AuthenticationManager.shared

    // MARK: - Private Properties
    
    private let onboardingKey = "hasCompletedOnboarding"
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Load onboarding state from UserDefaults
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)

        // Setup auth state observation
        setupAuthObservation()

        // Auto-sign in anonymously if no user exists
        Task {
            if !authManager.isAuthenticated {
                try? await authManager.signInAnonymously()
            }
        }

        // Listen for app state reset notification (used in debug builds)
        NotificationCenter.default.publisher(for: NSNotification.Name("AppStateReset"))
            .sink { [weak self] _ in
                guard let self = self else { return }
                // Reload onboarding state after reset
                DispatchQueue.main.async {
                    self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: self.onboardingKey)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    private func setupAuthObservation() {
        // Observe auth manager loading state
        authManager.$isLoading
            .sink { [weak self] isLoading in
                self?.isLoadingAuth = isLoading
            }
            .store(in: &cancellables)

        // Observe authentication state
        authManager.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                guard let self = self else { return }
                self.isAuthenticated = isAuthenticated

                // Always reload onboarding state from UserDefaults when auth state changes
                // This ensures we pick up any changes made during sign out
                DispatchQueue.main.async {
                    self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: self.onboardingKey)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Completes the onboarding process
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    /// Resets onboarding state (typically called on sign out)
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
    
    /// Force refresh auth state (useful for testing)
    func refreshAuthState() {
        // Auth state is automatically managed by AuthenticationManager's listener
        // No manual refresh needed
    }

    /// Force reload onboarding state from UserDefaults
    func reloadOnboardingState() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
    }
    
    // MARK: - Computed Properties
    
    /// Determines which view should be shown based on current state
    var currentViewState: ViewState {
        if isLoadingAuth {
            return .loading
        } else if !hasCompletedOnboarding {
            return .onboarding
        } else {
            return .main
        }
    }
    
    // MARK: - ViewState Enum
    
    enum ViewState {
        case loading
        case authentication
        case onboarding
        case main
    }
}

// MARK: - Preview Helpers

extension ContentViewModel {
    /// Creates a mock view model for previews
    static var preview: ContentViewModel {
        let viewModel = ContentViewModel()
        viewModel.isLoadingAuth = false
        viewModel.isAuthenticated = true
        viewModel.hasCompletedOnboarding = true
        return viewModel
    }
    
    /// Creates a mock view model showing onboarding
    static var previewOnboarding: ContentViewModel {
        let viewModel = ContentViewModel()
        viewModel.isLoadingAuth = false
        viewModel.isAuthenticated = true
        viewModel.hasCompletedOnboarding = false
        return viewModel
    }
    
    /// Creates a mock view model showing authentication
    static var previewAuth: ContentViewModel {
        let viewModel = ContentViewModel()
        viewModel.isLoadingAuth = false
        viewModel.isAuthenticated = false
        return viewModel
    }
}