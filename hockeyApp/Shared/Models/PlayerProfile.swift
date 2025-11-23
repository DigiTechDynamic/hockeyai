import Foundation

// MARK: - Player Profile Model
struct PlayerProfile: Codable {
    var name: String? // Player's name
    var height: Double? // in inches
    var weight: Double? // in pounds
    var age: Int?
    var gender: Gender?
    var position: Position?
    var handedness: Handedness?
    var playStyle: PlayStyle?
    var customPlayStyle: String?
    var jerseyNumber: String? // Player's jersey number
    
    // Computed properties for display
    var heightInFeetAndInches: String {
        guard let height = height else { return "" }
        let feet = Int(height) / 12
        let inches = Int(height) % 12
        return "\(feet)'\(inches)\""
    }

    var totalHeightInInches: Double? {
        return height
    }

    var isComplete: Bool {
        return height != nil &&
               weight != nil &&
               age != nil &&
               gender != nil &&
               position != nil &&
               handedness != nil &&
               (playStyle != nil || !customPlayStyle.isNilOrEmpty)
    }
}

// MARK: - Enums
enum Gender: String, CaseIterable, Codable {
    case male = "Male"
    case female = "Female"
    
    var icon: String {
        switch self {
        case .male: return "person.fill"
        case .female: return "person.fill"
        }
    }
}

enum Position: String, CaseIterable, Codable {
    case center = "Center"
    case leftWing = "Left Wing"
    case rightWing = "Right Wing"
    case leftDefense = "Left Defense"
    case rightDefense = "Right Defense"
    case goalie = "Goalie"
    
    var abbreviation: String {
        switch self {
        case .center: return "C"
        case .leftWing: return "LW"
        case .rightWing: return "RW"
        case .leftDefense: return "LD"
        case .rightDefense: return "RD"
        case .goalie: return "G"
        }
    }
    
    var icon: String {
        switch self {
        case .center, .leftWing, .rightWing:
            return "sportscourt.fill"
        case .leftDefense, .rightDefense:
            return "shield.fill"
        case .goalie:
            return "hockey.puck"
        }
    }
    
    var isForward: Bool {
        switch self {
        case .center, .leftWing, .rightWing:
            return true
        default:
            return false
        }
    }
    
    var isDefense: Bool {
        switch self {
        case .leftDefense, .rightDefense:
            return true
        default:
            return false
        }
    }
}

enum Handedness: String, CaseIterable, Codable {
    case left = "Left"
    case right = "Right"
    
    var icon: String {
        switch self {
        case .left: return "arrow.left.circle.fill"
        case .right: return "arrow.right.circle.fill"
        }
    }
}

enum PlayStyle: String, CaseIterable, Codable {
    // Forward styles
    case playmaker = "Playmaker"
    case sniper = "Sniper"
    case powerForward = "Power Forward"
    case twoWayForward = "Two-Way Forward"
    case grinder = "Grinder"
    case speedster = "Speedster"
    case dangler = "Dangler"
    case netFrontPresence = "Net-Front Presence"
    
    // Defense styles
    case offensiveDefenseman = "Offensive Defenseman"
    case stayAtHomeDefenseman = "Stay-at-home Defenseman"
    case twoWayDefenseman = "Two-Way Defenseman"
    case physicalDefenseman = "Physical Defenseman"
    case pokecheckSpecialist = "Poke-Check Specialist"
    
    // Goalie styles
    case butterfly = "Butterfly"
    case hybrid = "Hybrid"
    case standup = "Stand-up"
    case aggressive = "Aggressive"
    case positional = "Positional"
    
    var description: String {
        switch self {
        // Forward descriptions
        case .playmaker:
            return "Sets up teammates with great passes"
        case .sniper:
            return "Elite shooting and scoring ability"
        case .powerForward:
            return "Physical presence with scoring touch"
        case .twoWayForward:
            return "Strong offensive and defensive play"
        case .grinder:
            return "Hard-working, physical forechecking"
        case .speedster:
            return "Uses exceptional speed to create chances"
        case .dangler:
            return "Skilled stick-handler who dekes defenders"
        case .netFrontPresence:
            return "Excels at screens, tips, and rebounds"
            
        // Defense descriptions
        case .offensiveDefenseman:
            return "Contributes offensively from the blue line"
        case .stayAtHomeDefenseman:
            return "Focuses on defensive responsibilities"
        case .twoWayDefenseman:
            return "Balanced offensive and defensive skills"
        case .physicalDefenseman:
            return "Intimidating presence, big hits"
        case .pokecheckSpecialist:
            return "Expert at stick checks and takeaways"
            
        // Goalie descriptions
        case .butterfly:
            return "Goes down early, covers low areas"
        case .hybrid:
            return "Mix of butterfly and stand-up styles"
        case .standup:
            return "Stays on feet, relies on positioning"
        case .aggressive:
            return "Challenges shooters, plays the puck"
        case .positional:
            return "Relies on angles and positioning"
        }
    }
    
    static func stylesForPosition(_ position: Position?) -> [PlayStyle] {
        guard let position = position else { return [] }
        
        switch position {
        case .center, .leftWing, .rightWing:
            return [.playmaker, .sniper, .powerForward, .twoWayForward, .grinder, .speedster, .dangler, .netFrontPresence]
        case .leftDefense, .rightDefense:
            return [.offensiveDefenseman, .stayAtHomeDefenseman, .twoWayDefenseman, .physicalDefenseman, .pokecheckSpecialist]
        case .goalie:
            return [.butterfly, .hybrid, .standup, .aggressive, .positional]
        }
    }
}