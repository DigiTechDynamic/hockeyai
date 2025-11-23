import SwiftUI
import Combine

// MARK: - Profile View Model
/// Central business logic for profile management
/// Handles state, validation, persistence, and analytics
class ProfileViewModel: ObservableObject {

    // MARK: - Published State

    // Profile image
    @Published var profileImage: UIImage?
    @Published var showingPhotoOptions = false
    @Published var showingCustomCamera = false
    @Published var showingMediaPicker = false
    @Published var mediaSourceType: UIImagePickerController.SourceType = .photoLibrary

    // Personal information
    @Published var displayName: String = ""
    @Published var email: String = ""

    // Physical attributes
    @Published var heightFeet: Int = 0
    @Published var heightInches: Int = 0
    @Published var weight: String = ""
    @Published var weightInKg: String = ""
    @Published var age: String = ""
    @Published var selectedGender: Gender? = nil
    @Published var useMetric = false
    @Published var previousUseMetric = false

    // Hockey profile
    @Published var selectedPosition: Position? = nil
    @Published var selectedHandedness: Handedness? = nil
    @Published var selectedPlayStyle: PlayStyle?
    @Published var jerseyNumber: String = ""
    @Published var showingTeamSelector = false

    // MARK: - Dependencies
    private let authManager: AuthenticationManager
    private let analytics = ProfileAnalytics.shared
    private let imageService = ProfileImageService.shared

    // MARK: - Private State
    private var saveTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(authManager: AuthenticationManager = AuthenticationManager.shared) {
        self.authManager = authManager
        loadUserData()
        loadProfileImage()
        setupAutoSave()

        analytics.trackProfileViewed()
    }

    // MARK: - Auto-Save Setup
    private func setupAutoSave() {
        // Auto-save when any profile field changes
        Publishers.CombineLatest4(
            $heightFeet,
            $heightInches,
            $weight,
            $age
        )
        .dropFirst() // Skip initial value
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.saveProfile()
        }
        .store(in: &cancellables)

        Publishers.CombineLatest4(
            $selectedGender,
            $selectedPosition,
            $selectedHandedness,
            $selectedPlayStyle
        )
        .dropFirst()
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.saveProfile()
        }
        .store(in: &cancellables)

        // Auto-save when jersey number changes
        $jerseyNumber
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveProfile()
            }
            .store(in: &cancellables)

        // Auto-save when display name changes
        $displayName
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveProfile()
            }
            .store(in: &cancellables)

        // Refresh when PlayerProfile is updated elsewhere (e.g., AI Analyzer flow)
        NotificationCenter.default.publisher(for: Notification.Name("PlayerProfileUpdated"))
            .sink { [weak self] _ in
                self?.loadUserData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading
    func loadUserData() {
        print("🔵 [ProfileViewModel] loadUserData() called")

        // Load email from current user (email always comes from auth)
        if let user = authManager.currentUser {
            email = user.email ?? ""
        }

        // Load metric preferences FIRST (needed for weight conversion)
        let generalMetric = UserDefaults.standard.bool(forKey: "useMetricUnits")
        useMetric = UserDefaults.standard.object(forKey: "useMetricHeightUnits") != nil ?
                    UserDefaults.standard.bool(forKey: "useMetricHeightUnits") : generalMetric
        previousUseMetric = useMetric

        // Load profile data from UserDefaults
        if let profileData = UserDefaults.standard.data(forKey: "playerProfile"),
           let profile = try? JSONDecoder().decode(PlayerProfile.self, from: profileData) {
            print("✅ [ProfileViewModel] Found existing profile in UserDefaults")
            print("🔵 [ProfileViewModel] profile.name: '\(profile.name ?? "nil")'")
            print("🔵 [ProfileViewModel] authManager.currentUser?.displayName: '\(authManager.currentUser?.displayName ?? "nil")'")

            // Load name from profile first, fallback to auth manager
            if let profileName = profile.name, !profileName.isEmpty {
                displayName = profileName
                print("✅ [ProfileViewModel] Loaded name from profile: '\(profileName)'")
            } else if let authName = authManager.currentUser?.displayName {
                displayName = authName
                print("✅ [ProfileViewModel] Loaded name from auth manager: '\(authName)'")
            } else {
                print("⚠️ [ProfileViewModel] No name found in profile or auth manager")
            }
            // Physical attributes
            if let profileHeight = profile.height {
                let totalInches = Int(profileHeight)
                heightFeet = totalInches / 12
                heightInches = totalInches % 12
            }

            // Weight is ALWAYS stored in lbs - convert to kg if using metric
            if let profileWeight = profile.weight {
                if useMetric {
                    // Convert lbs to kg for display
                    let kgValue = profileWeight * 0.453592
                    weight = String(format: "%.0f", kgValue)
                } else {
                    weight = String(Int(profileWeight))
                }
            }

            if let profileAge = profile.age {
                age = String(profileAge)
            }
            selectedGender = profile.gender

            // Hockey profile
            if let position = profile.position {
                selectedPosition = position
            }
            if let handedness = profile.handedness {
                selectedHandedness = handedness
            }
            if let playStyle = profile.playStyle {
                selectedPlayStyle = playStyle
            }
            if let number = profile.jerseyNumber {
                jerseyNumber = number
            }
        } else {
            // No profile exists, load name from auth manager as fallback
            if let authName = authManager.currentUser?.displayName {
                displayName = authName
            }
        }
    }

    func loadProfileImage() {
        profileImage = imageService.loadImage()
    }

    // MARK: - Data Persistence
    func saveProfile() {
        print("🔵 [ProfileViewModel] saveProfile() called")
        print("🔵 [ProfileViewModel] displayName: '\(displayName)'")

        // Create updated profile
        var profile = PlayerProfile()
        profile.name = displayName.isEmpty ? nil : displayName  // Save name to profile
        profile.height = Double(heightFeet * 12 + heightInches)

        // Validate and save weight
        if !weight.isEmpty {
            let weightValue: Double
            if useMetric {
                if let kg = Double(weight), kg > 0 {
                    weightValue = kg * 2.20462 // Convert kg to lbs for storage
                    profile.weight = weightValue
                }
            } else {
                if let lbs = Double(weight), lbs > 0 {
                    profile.weight = lbs
                }
            }
        }

        // Validate and save age
        if !age.isEmpty {
            if let ageValue = Int(age), ageValue > 0 {
                profile.age = ageValue
            }
        }

        profile.gender = selectedGender
        profile.position = selectedPosition
        profile.handedness = selectedHandedness
        profile.playStyle = selectedPlayStyle
        profile.jerseyNumber = jerseyNumber.isEmpty ? nil : jerseyNumber

        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "playerProfile")
            print("✅ [ProfileViewModel] Saved profile: \(displayName), #\(jerseyNumber), \(selectedPosition?.rawValue ?? "N/A")")

            // Notify other parts of app that profile was updated
            NotificationCenter.default.post(name: Notification.Name("PlayerProfileUpdated"), object: nil)
        }

        // Save metric preference
        UserDefaults.standard.set(useMetric, forKey: "useMetricHeightUnits")

        // Update display name if changed
        Task {
            if displayName != authManager.currentUser?.displayName && !displayName.isEmpty {
                try? await authManager.updateProfile(displayName: displayName, photoURL: nil)
            }
        }

        analytics.trackProfileSaved()
    }

    func saveProfileImage() {
        guard let image = profileImage else { return }
        imageService.saveImage(image)
        analytics.trackProfilePhotoUpdated()
    }

    // MARK: - Unit Conversion
    func convertWeightToMetric() {
        // Convert from lbs to kg
        if !weight.isEmpty, let lbsValue = Double(weight) {
            let kgValue = lbsValue * 0.453592
            weight = String(format: "%.0f", kgValue)
        }
        analytics.trackUnitChanged(to: "metric")
    }

    func convertWeightToImperial() {
        // Convert from kg to lbs
        if !weight.isEmpty, let kgValue = Double(weight) {
            let lbsValue = kgValue * 2.20462
            weight = String(format: "%.0f", lbsValue)
        }
        analytics.trackUnitChanged(to: "imperial")
    }

    // MARK: - Computed Properties
    func getPositionAndPlayStyle() -> String {
        let position = selectedPosition?.rawValue ?? "--"
        let playStyle = selectedPlayStyle?.rawValue ?? "All-around"
        return "\(position) • \(playStyle)"
    }

    func getHeightDisplay() -> String {
        if useMetric {
            let cm = Double(heightFeet * 12 + heightInches) * 2.54
            return String(format: "%.0f cm", cm)
        } else {
            return "\(heightFeet)'\(heightInches)\""
        }
    }

    func getWeightDisplay() -> String {
        if weight.isEmpty {
            return "--"
        }
        return "\(weight) \(useMetric ? "kg" : "lbs")"
    }

    func getAgeDisplay() -> String {
        if age.isEmpty {
            return "--"
        }
        return "\(age) years"
    }

    // MARK: - Field Updates (with analytics)
    func updateHeight(feet: Int, inches: Int) {
        heightFeet = feet
        heightInches = inches
        analytics.trackFieldEdited(field: "height", value: "\(feet)'\(inches)\"")
    }

    func updateWeight(_ value: String) {
        weight = value
        analytics.trackFieldEdited(field: "weight", value: value)
    }

    func updateAge(_ value: String) {
        age = value
        analytics.trackFieldEdited(field: "age", value: value)
    }

    func updateGender(_ gender: Gender) {
        selectedGender = gender
        analytics.trackFieldEdited(field: "gender", value: gender.rawValue)
    }

    func updatePosition(_ position: Position) {
        selectedPosition = position
        selectedPlayStyle = nil // Reset play style when position changes
        analytics.trackFieldEdited(field: "position", value: position.rawValue)
    }

    func updateHandedness(_ handedness: Handedness) {
        selectedHandedness = handedness
        analytics.trackFieldEdited(field: "handedness", value: handedness.rawValue)
    }

    func updatePlayStyle(_ playStyle: PlayStyle?) {
        selectedPlayStyle = playStyle
        if let style = playStyle {
            analytics.trackFieldEdited(field: "play_style", value: style.rawValue)
        }
    }

    func updateJerseyNumber(_ number: String) {
        jerseyNumber = number
        analytics.trackFieldEdited(field: "jersey_number", value: number)
    }

    func getJerseyNumberDisplay() -> String {
        if jerseyNumber.isEmpty {
            return "--"
        }
        return "#\(jerseyNumber)"
    }

    func updateUseMetric(_ value: Bool) {
        // Handle unit conversion when toggling
        if value != previousUseMetric {
            if value && !previousUseMetric {
                convertWeightToMetric()
            } else if !value && previousUseMetric {
                convertWeightToImperial()
            }
        }
        useMetric = value
        previousUseMetric = value
        UserDefaults.standard.set(value, forKey: "useMetricHeightUnits")
    }

    // MARK: - Validation
    func isValidWeight() -> Bool {
        guard !weight.isEmpty, let value = Double(weight) else { return false }
        return value > 0 && value < 500 // Reasonable weight range
    }

    func isValidAge() -> Bool {
        guard !age.isEmpty, let value = Int(age) else { return false }
        return value > 0 && value < 120 // Reasonable age range
    }

    // MARK: - Cleanup
    deinit {
        saveTimer?.invalidate()
        cancellables.removeAll()
    }
}
