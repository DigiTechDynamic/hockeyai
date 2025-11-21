import Foundation
import SwiftUI

// MARK: - Physical Attributes Model
/// Centralized model for height, weight, and age with automatic metric/imperial conversion
/// All internal storage uses imperial (inches/pounds) for consistency with existing PlayerProfile
struct PhysicalAttributes: Codable, Equatable, Hashable {

    // MARK: - Storage (Imperial base for compatibility)
    private(set) var heightInches: Int
    private(set) var weightPounds: Double
    private(set) var age: Int

    // MARK: - User Preference
    var useMetric: Bool

    // MARK: - Validation Ranges
    enum Constraints {
        static let heightInches = 47...98     // ~4'0" to ~8'2" (120cm to 250cm)
        static let heightCm = 120...250
        static let weightPounds = 66...441    // ~30kg to ~200kg
        static let weightKg = 30.0...200.0
        static let age = 5...100
    }

    // MARK: - Initializers
    init(heightInches: Int = 70, weightPounds: Double = 180, age: Int = 18, useMetric: Bool = false) {
        self.heightInches = heightInches.clamped(to: Constraints.heightInches)
        self.weightPounds = weightPounds.clamped(to: Constraints.weightPounds)
        self.age = age.clamped(to: Constraints.age)
        self.useMetric = useMetric
    }

    init(heightCm: Int, weightKg: Double, age: Int, useMetric: Bool = true) {
        self.heightInches = Self.cmToInches(heightCm)
        self.weightPounds = Self.kgToPounds(weightKg)
        self.age = age.clamped(to: Constraints.age)
        self.useMetric = useMetric
    }

    init(heightFeet: Int, heightInches: Int, weightPounds: Double, age: Int, useMetric: Bool = false) {
        self.heightInches = (heightFeet * 12 + heightInches).clamped(to: Constraints.heightInches)
        self.weightPounds = weightPounds.clamped(to: Constraints.weightPounds)
        self.age = age.clamped(to: Constraints.age)
        self.useMetric = useMetric
    }

    // MARK: - Height Properties
    var heightFeet: Int {
        heightInches / 12
    }

    var heightRemainingInches: Int {
        heightInches % 12
    }

    var heightCm: Int {
        Self.inchesToCm(heightInches)
    }

    // MARK: - Weight Properties
    var weightKg: Double {
        Self.poundsToKg(weightPounds)
    }

    var weightLbs: Int {
        Int(weightPounds.rounded())
    }

    // MARK: - Display Strings
    var heightDisplay: String {
        useMetric ? heightDisplayMetric : heightDisplayImperial
    }

    var heightDisplayMetric: String {
        "\(heightCm) cm"
    }

    var heightDisplayImperial: String {
        "\(heightFeet)'\(heightRemainingInches)\""
    }

    var heightDisplayCompact: String {
        useMetric ? "\(heightCm)" : "\(heightFeet)'\(heightRemainingInches)\""
    }

    var weightDisplay: String {
        useMetric ? weightDisplayMetric : weightDisplayImperial
    }

    var weightDisplayMetric: String {
        "\(Int(weightKg.rounded())) kg"
    }

    var weightDisplayImperial: String {
        "\(weightLbs) lbs"
    }

    var weightDisplayCompact: String {
        useMetric ? "\(Int(weightKg.rounded()))" : "\(weightLbs)"
    }

    var ageDisplay: String {
        "\(age)"
    }

    var ageDisplayWithUnit: String {
        "\(age) years"
    }

    // MARK: - Setters (Height)
    mutating func setHeight(feet: Int, inches: Int) {
        let totalInches = (feet * 12 + inches).clamped(to: Constraints.heightInches)
        self.heightInches = totalInches
    }

    mutating func setHeight(totalInches: Int) {
        self.heightInches = totalInches.clamped(to: Constraints.heightInches)
    }

    mutating func setHeight(cm: Int) {
        let inches = Self.cmToInches(cm)
        self.heightInches = inches.clamped(to: Constraints.heightInches)
    }

    // MARK: - Setters (Weight)
    mutating func setWeight(pounds: Double) {
        self.weightPounds = pounds.clamped(to: Constraints.weightPounds)
    }

    mutating func setWeight(kg: Double) {
        let pounds = Self.kgToPounds(kg)
        self.weightPounds = pounds.clamped(to: Constraints.weightPounds)
    }

    // MARK: - Setters (Age)
    mutating func setAge(_ newAge: Int) {
        self.age = newAge.clamped(to: Constraints.age)
    }

    // MARK: - Unit Conversion
    mutating func toggleUnits() {
        useMetric.toggle()
    }

    mutating func setUseMetric(_ metric: Bool) {
        useMetric = metric
    }

    // MARK: - Validation
    enum ValidationError: Error, LocalizedError {
        case heightOutOfRange
        case weightOutOfRange
        case ageOutOfRange

        var errorDescription: String? {
            switch self {
            case .heightOutOfRange:
                return "Height must be between 4'0\" and 8'2\" (120-250 cm)"
            case .weightOutOfRange:
                return "Weight must be between 66-441 lbs (30-200 kg)"
            case .ageOutOfRange:
                return "Age must be between 5-100 years"
            }
        }
    }

    func validate() -> [ValidationError] {
        var errors: [ValidationError] = []

        if !Constraints.heightInches.contains(heightInches) {
            errors.append(.heightOutOfRange)
        }

        if !Constraints.weightPounds.contains(Int(weightPounds)) {
            errors.append(.weightOutOfRange)
        }

        if !Constraints.age.contains(age) {
            errors.append(.ageOutOfRange)
        }

        return errors
    }

    var isValid: Bool {
        validate().isEmpty
    }

    // MARK: - Conversion Utilities (Static)
    static func inchesToCm(_ inches: Int) -> Int {
        Int((Double(inches) * 2.54).rounded())
    }

    static func cmToInches(_ cm: Int) -> Int {
        Int((Double(cm) / 2.54).rounded())
    }

    static func poundsToKg(_ pounds: Double) -> Double {
        pounds * 0.453592
    }

    static func kgToPounds(_ kg: Double) -> Double {
        kg * 2.20462
    }

    // MARK: - PlayerProfile Integration
    /// Create from existing PlayerProfile
    static func from(_ profile: PlayerProfile, useMetric: Bool) -> PhysicalAttributes? {
        guard let height = profile.height,
              let weight = profile.weight,
              let age = profile.age else {
            return nil
        }

        return PhysicalAttributes(
            heightInches: Int(height),
            weightPounds: weight,
            age: age,
            useMetric: useMetric
        )
    }

    /// Update PlayerProfile with current values
    func updateProfile(_ profile: inout PlayerProfile) {
        profile.height = Double(heightInches)
        profile.weight = weightPounds
        profile.age = age
    }
}

// MARK: - Comparable Extensions
fileprivate extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

fileprivate extension Double {
    func clamped(to range: ClosedRange<Int>) -> Double {
        Swift.min(Swift.max(self, Double(range.lowerBound)), Double(range.upperBound))
    }

    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - SwiftUI Binding Extensions
extension PhysicalAttributes {
    /// Binding for height in feet (imperial)
    static func heightFeetBinding(for attributes: Binding<PhysicalAttributes>) -> Binding<Int> {
        Binding(
            get: { attributes.wrappedValue.heightFeet },
            set: { newFeet in
                attributes.wrappedValue.setHeight(
                    feet: newFeet,
                    inches: attributes.wrappedValue.heightRemainingInches
                )
            }
        )
    }

    /// Binding for height in inches (imperial remainder)
    static func heightInchesBinding(for attributes: Binding<PhysicalAttributes>) -> Binding<Int> {
        Binding(
            get: { attributes.wrappedValue.heightRemainingInches },
            set: { newInches in
                attributes.wrappedValue.setHeight(
                    feet: attributes.wrappedValue.heightFeet,
                    inches: newInches
                )
            }
        )
    }

    /// Binding for height in cm (metric)
    static func heightCmBinding(for attributes: Binding<PhysicalAttributes>) -> Binding<Int> {
        Binding(
            get: { attributes.wrappedValue.heightCm },
            set: { newCm in
                attributes.wrappedValue.setHeight(cm: newCm)
            }
        )
    }

    /// Binding for weight in pounds
    static func weightLbsBinding(for attributes: Binding<PhysicalAttributes>) -> Binding<Int> {
        Binding(
            get: { attributes.wrappedValue.weightLbs },
            set: { newLbs in
                attributes.wrappedValue.setWeight(pounds: Double(newLbs))
            }
        )
    }

    /// Binding for weight in kg
    static func weightKgBinding(for attributes: Binding<PhysicalAttributes>) -> Binding<Int> {
        Binding(
            get: { Int(attributes.wrappedValue.weightKg.rounded()) },
            set: { newKg in
                attributes.wrappedValue.setWeight(kg: Double(newKg))
            }
        )
    }

    /// Binding for age
    static func ageBinding(for attributes: Binding<PhysicalAttributes>) -> Binding<Int> {
        Binding(
            get: { attributes.wrappedValue.age },
            set: { newAge in
                attributes.wrappedValue.setAge(newAge)
            }
        )
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension PhysicalAttributes {
    static let preview = PhysicalAttributes(
        heightInches: 70,
        weightPounds: 180,
        age: 23,
        useMetric: false
    )

    static let previewMetric = PhysicalAttributes(
        heightCm: 178,
        weightKg: 82,
        age: 23,
        useMetric: true
    )
}
#endif
