import Foundation

// MARK: - Drill Category
enum DrillCategory: String, Codable, CaseIterable {
    case stickhandling = "Stickhandling"
    case skating = "Skating"
    case shooting = "Shooting"
    case passing = "Passing"
    case agility = "Agility"
    case conditioning = "Conditioning"
    case skillDevelopment = "Skill Development"

    var icon: String {
        switch self {
        case .stickhandling: return "🏒"
        case .skating: return "⛸️"
        case .shooting: return "🎯"
        case .passing: return "🔄"
        case .agility: return "⚡"
        case .conditioning: return "💪"
        case .skillDevelopment: return "🧠"
        }
    }

    var description: String {
        switch self {
        case .stickhandling: return "Figure-8s, toe drags, one-handed control"
        case .skating: return "Edge work, crossovers, backward skating"
        case .shooting: return "Wrist shots, slapshots, one-timers, backhand"
        case .passing: return "Forehand/backhand, sauce passes, one-touch"
        case .agility: return "Cone weaves, quick feet, lateral movement"
        case .conditioning: return "Off-ice strength, cardio, explosive power"
        case .skillDevelopment: return "Combined drills, game situations"
        }
    }

    var imageName: String {
        switch self {
        case .stickhandling: return "PlaceholderDrills"
        case .skating: return "PlaceholderDrills"
        case .shooting: return "PlaceholderDrills"
        case .passing: return "PlaceholderDrills"
        case .agility: return "PlaceholderDrills"
        case .conditioning: return "PlaceholderDrills"
        case .skillDevelopment: return "PlaceholderDrills"
        }
    }

    // MARK: - Rest Time Defaults (Based on Hockey Training Research)

    /// Default rest time between sets for this drill category
    /// Based on typical hockey training patterns
    var defaultRestBetweenSets: TimeInterval {
        switch self {
        case .stickhandling, .skillDevelopment:
            return 0  // Continuous skill work, no rest between sets
        case .shooting, .passing:
            return 30  // Quick recovery, maintain rhythm
        case .skating, .agility:
            return 45  // Moderate recovery for explosive movements
        case .conditioning:
            return 90  // Longer recovery for high-intensity work
        }
    }

    /// Default rest time after completing this drill before next exercise
    /// Allows for transitions and brief recovery
    var defaultRestAfterExercise: TimeInterval {
        switch self {
        case .stickhandling, .skillDevelopment:
            return 30  // Quick transition between skill drills
        case .shooting, .passing, .agility:
            return 45  // Standard transition time
        case .skating:
            return 60  // Slightly longer for skating recovery
        case .conditioning:
            return 120  // Longer recovery after high-intensity work
        }
    }
}

// MARK: - Exercise Type Enum
enum ExerciseType: String, Codable {
    case timeBased
    case repsOnly
    case countBased
    case weightRepsSets
    case distance
    case repsSets
    case timeSets
}

// MARK: - Exercise Configuration
enum ExerciseConfig: Codable, Equatable, Hashable {
    case timeBased(duration: TimeInterval) // seconds
    case repsOnly(reps: Int)
    case countBased(targetCount: Int)
    case weightRepsSets(weight: Double, reps: Int, sets: Int, unit: WeightUnit)
    case distance(distance: Double, unit: DistanceUnit)
    case repsSets(reps: Int, sets: Int)
    case timeSets(duration: TimeInterval, sets: Int, restTime: TimeInterval?)

    var type: ExerciseType {
        switch self {
        case .timeBased: return .timeBased
        case .repsOnly: return .repsOnly
        case .countBased: return .countBased
        case .weightRepsSets: return .weightRepsSets
        case .distance: return .distance
        case .repsSets: return .repsSets
        case .timeSets: return .timeSets
        }
    }

    var displaySummary: String {
        switch self {
        case .timeBased(let duration):
            return formatDuration(duration)
        case .repsOnly(let reps):
            return "\(reps) reps"
        case .countBased(let count):
            return "\(count) count"
        case .weightRepsSets(let weight, let reps, let sets, let unit):
            return "\(Int(weight)) \(unit.rawValue) • \(sets)×\(reps)"
        case .distance(let distance, let unit):
            return "\(Int(distance)) \(unit.rawValue)"
        case .repsSets(let reps, let sets):
            return "\(sets)×\(reps)"
        case .timeSets(let duration, let sets, let restTime):
            if let rest = restTime {
                return "\(formatDuration(duration)) • \(sets) sets • \(formatDuration(rest)) rest"
            } else {
                return "\(formatDuration(duration)) • \(sets) sets"
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if minutes > 0 {
            return secs > 0 ? "\(minutes)m \(secs)s" : "\(minutes)m"
        } else {
            return "\(secs)s"
        }
    }
}

// MARK: - Units
enum WeightUnit: String, Codable {
    case lbs
    case kg
}

enum DistanceUnit: String, Codable {
    case meters = "m"
    case yards = "yd"
    case feet = "ft"
    case laps
}

// MARK: - Equipment
enum Equipment: String, Codable, CaseIterable {
    case pucks = "Pucks"
    case cones = "Cones"
    case barbell = "Barbell"
    case dumbbells = "Dumbbells"
    case bench = "Bench"
    case stick = "Stick"
    case net = "Net"
    case box = "Box"
    case resistanceBand = "Resistance Band"
    case none = "None"

    var icon: String {
        switch self {
        case .pucks: return "hockey.puck"
        case .cones: return "cone"
        case .barbell: return "figure.strengthtraining.traditional"
        case .dumbbells: return "dumbbell"
        case .bench: return "square.split.bottomrightquarter"
        case .stick: return "hockey.puck"
        case .net: return "rectangle.portrait.and.arrow.forward"
        case .box: return "cube.box"
        case .resistanceBand: return "arrow.left.and.right"
        case .none: return "checkmark"
        }
    }
}

// MARK: - Exercise Model
struct Exercise: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var category: DrillCategory
    var config: ExerciseConfig
    var equipment: [Equipment]
    var instructions: String?
    var tips: String?
    var benefits: String?
    var videoFileName: String?  // e.g., "SlapShotFromBehind.MOV"

    // MARK: - Rest Configuration
    /// Rest time between sets (for exercises with multiple sets)
    /// If nil, uses category-based default
    var restBetweenSets: TimeInterval?

    /// Rest time after completing this exercise before next exercise
    /// If nil, uses category-based default
    var restAfterExercise: TimeInterval?

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: DrillCategory,
        config: ExerciseConfig,
        equipment: [Equipment],
        instructions: String? = nil,
        tips: String? = nil,
        benefits: String? = nil,
        videoFileName: String? = nil,
        restBetweenSets: TimeInterval? = nil,
        restAfterExercise: TimeInterval? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.config = config
        self.equipment = equipment
        self.instructions = instructions
        self.tips = tips
        self.benefits = benefits
        self.videoFileName = videoFileName
        self.restBetweenSets = restBetweenSets
        self.restAfterExercise = restAfterExercise
    }

    // MARK: - Computed Properties for Rest Times

    /// Effective rest time between sets (uses explicit value or category default)
    var effectiveRestBetweenSets: TimeInterval {
        // Priority: 1) Explicit value 2) timeSets.restTime 3) Category default
        if let explicitRest = restBetweenSets {
            return explicitRest
        }

        // Check if timeSets has rest defined
        if case let .timeSets(_, _, restTime) = config, let rest = restTime {
            return rest
        }

        // Fall back to category default
        return category.defaultRestBetweenSets
    }

    /// Effective rest time after exercise (uses explicit value or category default)
    var effectiveRestAfterExercise: TimeInterval {
        return restAfterExercise ?? category.defaultRestAfterExercise
    }

    /// Whether this exercise has multiple sets (needs rest between sets)
    var hasSets: Bool {
        switch config {
        case .repsSets, .weightRepsSets, .timeSets:
            return true
        default:
            return false
        }
    }
}

// MARK: - Workout Model
struct Workout: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var exercises: [Exercise]
    var estimatedTimeMinutes: Int

    init(
        id: UUID = UUID(),
        name: String,
        exercises: [Exercise] = [],
        estimatedTimeMinutes: Int = 0
    ) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.estimatedTimeMinutes = estimatedTimeMinutes
    }

    var exerciseCount: Int {
        exercises.count
    }

    var allEquipment: [Equipment] {
        Array(Set(exercises.flatMap { $0.equipment }))
            .filter { $0 != .none }
            .sorted { $0.rawValue < $1.rawValue }
    }

    var allCategories: [DrillCategory] {
        Array(Set(exercises.map { $0.category }))
            .sorted { $0.rawValue < $1.rawValue }
    }
}