import SwiftUI

// MARK: - NHL Team Data
// Official colors for all 32 NHL teams with accessibility adaptations

struct NHLTeam: Equatable {
    let id: String
    let name: String
    let city: String
    let abbreviation: String
    let conference: Conference
    let division: Division
    let primaryColor: Color
    let secondaryColor: Color
    let accentColor: Color?
    let logoSymbol: String // SF Symbol fallback

    enum Conference: String, CaseIterable {
        case eastern = "Eastern"
        case western = "Western"
    }

    enum Division: String, CaseIterable {
        case atlantic = "Atlantic"
        case metropolitan = "Metropolitan"
        case central = "Central"
        case pacific = "Pacific"
    }

    static func == (lhs: NHLTeam, rhs: NHLTeam) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - NHL Teams Database
struct NHLTeams {
    
    // MARK: - Atlantic Division
    static let bruins = NHLTeam(
        id: "bruins",
        name: "Bruins",
        city: "Boston",
        abbreviation: "BOS",
        conference: .eastern,
        division: .atlantic,
        primaryColor: Color(hex: "#FFB81C"),  // Gold
        secondaryColor: Color(hex: "#000000"), // Black
        accentColor: nil,
        logoSymbol: "b.circle.fill"
    )
    
    static let sabres = NHLTeam(
        id: "sabres",
        name: "Sabres",
        city: "Buffalo",
        abbreviation: "BUF",
        conference: .eastern,
        division: .atlantic,
        primaryColor: Color(hex: "#002654"),  // Navy Blue
        secondaryColor: Color(hex: "#FCB514"), // Gold
        accentColor: Color(hex: "#ADAFAA"),   // Silver
        logoSymbol: "shield.fill"
    )
    
    static let redWings = NHLTeam(
        id: "redwings",
        name: "Red Wings",
        city: "Detroit",
        abbreviation: "DET",
        conference: .eastern,
        division: .atlantic,
        primaryColor: Color(hex: "#CE1126"),  // Red
        secondaryColor: Color(hex: "#FFFFFF"), // White
        accentColor: nil,
        logoSymbol: "w.circle.fill"
    )
    
    static let panthers = NHLTeam(
        id: "panthers",
        name: "Panthers",
        city: "Florida",
        abbreviation: "FLA",
        conference: .eastern,
        division: .atlantic,
        primaryColor: Color(hex: "#041E42"),  // Navy
        secondaryColor: Color(hex: "#C8102E"), // Red
        accentColor: Color(hex: "#B9975B"),   // Gold
        logoSymbol: "pawprint.fill"
    )
    
    static let canadiens = NHLTeam(
        id: "canadiens",
        name: "Canadiens",
        city: "Montreal",
        abbreviation: "MTL",
        conference: .eastern,
        division: .atlantic,
        primaryColor: Color(hex: "#AF1E2D"),  // Red
        secondaryColor: Color(hex: "#192168"), // Blue
        accentColor: Color(hex: "#FFFFFF"),   // White
        logoSymbol: "h.circle.fill"
    )
    
    static let senators = NHLTeam(
        id: "senators",
        name: "Senators",
        city: "Ottawa",
        abbreviation: "OTT",
        conference: .eastern,
        division: .atlantic,
        primaryColor: Color(hex: "#DA020E"),  // Red
        secondaryColor: Color(hex: "#000000"), // Black
        accentColor: Color(hex: "#C69214"),   // Gold
        logoSymbol: "o.circle.fill"
    )
    
    static let lightning = NHLTeam(
        id: "lightning",
        name: "Lightning",
        city: "Tampa Bay",
        abbreviation: "TB",
        conference: .eastern,
        division: .atlantic,
        primaryColor: Color(hex: "#002868"),  // Blue
        secondaryColor: Color(hex: "#FFFFFF"), // White
        accentColor: nil,
        logoSymbol: "bolt.fill"
    )
    
    static let mapleLeafs = NHLTeam(
        id: "mapleleafs",
        name: "Maple Leafs",
        city: "Toronto",
        abbreviation: "TOR",
        conference: .eastern,
        division: .atlantic,
        primaryColor: Color(hex: "#00205B"),  // Blue
        secondaryColor: Color(hex: "#FFFFFF"), // White
        accentColor: nil,
        logoSymbol: "leaf.fill"
    )
    
    // MARK: - Metropolitan Division
    static let hurricanes = NHLTeam(
        id: "hurricanes",
        name: "Hurricanes",
        city: "Carolina",
        abbreviation: "CAR",
        conference: .eastern,
        division: .metropolitan,
        primaryColor: Color(hex: "#CE1126"),  // Red
        secondaryColor: Color(hex: "#000000"), // Black
        accentColor: Color(hex: "#A2AAAD"),   // Silver
        logoSymbol: "hurricane"
    )
    
    static let blueJackets = NHLTeam(
        id: "bluejackets",
        name: "Blue Jackets",
        city: "Columbus",
        abbreviation: "CBJ",
        conference: .eastern,
        division: .metropolitan,
        primaryColor: Color(hex: "#002654"),  // Navy Blue
        secondaryColor: Color(hex: "#CE1126"), // Red
        accentColor: Color(hex: "#A4A9AD"),   // Silver
        logoSymbol: "star.fill"
    )
    
    static let devils = NHLTeam(
        id: "devils",
        name: "Devils",
        city: "New Jersey",
        abbreviation: "NJ",
        conference: .eastern,
        division: .metropolitan,
        primaryColor: Color(hex: "#CE1126"),  // Red
        secondaryColor: Color(hex: "#000000"), // Black
        accentColor: Color(hex: "#FFFFFF"),   // White
        logoSymbol: "flame.fill"
    )
    
    static let islanders = NHLTeam(
        id: "islanders",
        name: "Islanders",
        city: "New York",
        abbreviation: "NYI",
        conference: .eastern,
        division: .metropolitan,
        primaryColor: Color(hex: "#00539B"),  // Blue
        secondaryColor: Color(hex: "#F47D30"), // Orange
        accentColor: Color(hex: "#FFFFFF"),   // White
        logoSymbol: "map.fill"
    )
    
    static let rangers = NHLTeam(
        id: "rangers",
        name: "Rangers",
        city: "New York",
        abbreviation: "NYR",
        conference: .eastern,
        division: .metropolitan,
        primaryColor: Color(hex: "#0038A8"),  // Blue
        secondaryColor: Color(hex: "#CE1126"), // Red
        accentColor: Color(hex: "#FFFFFF"),   // White
        logoSymbol: "r.circle.fill"
    )
    
    static let flyers = NHLTeam(
        id: "flyers",
        name: "Flyers",
        city: "Philadelphia",
        abbreviation: "PHI",
        conference: .eastern,
        division: .metropolitan,
        primaryColor: Color(hex: "#F74902"),  // Orange
        secondaryColor: Color(hex: "#000000"), // Black
        accentColor: Color(hex: "#FFFFFF"),   // White
        logoSymbol: "p.circle.fill"
    )
    
    static let penguins = NHLTeam(
        id: "penguins",
        name: "Penguins",
        city: "Pittsburgh",
        abbreviation: "PIT",
        conference: .eastern,
        division: .metropolitan,
        primaryColor: Color(hex: "#000000"),  // Black
        secondaryColor: Color(hex: "#FCB514"), // Gold
        accentColor: Color(hex: "#FFFFFF"),   // White
        logoSymbol: "bird.fill"
    )
    
    static let capitals = NHLTeam(
        id: "capitals",
        name: "Capitals",
        city: "Washington",
        abbreviation: "WSH",
        conference: .eastern,
        division: .metropolitan,
        primaryColor: Color(hex: "#041E42"),  // Navy
        secondaryColor: Color(hex: "#C8102E"), // Red
        accentColor: Color(hex: "#FFFFFF"),   // White
        logoSymbol: "w.circle.fill"
    )
    
    // MARK: - Central Division
    static let coyotes = NHLTeam(
        id: "coyotes",
        name: "Coyotes",
        city: "Arizona",
        abbreviation: "ARI",
        conference: .western,
        division: .central,
        primaryColor: Color(hex: "#8C2633"),  // Sedona Red
        secondaryColor: Color(hex: "#E2D6B5"), // Desert Sand
        accentColor: Color(hex: "#111111"),   // Black
        logoSymbol: "a.circle.fill"
    )
    
    static let blackhawks = NHLTeam(
        id: "blackhawks",
        name: "Blackhawks",
        city: "Chicago",
        abbreviation: "CHI",
        conference: .western,
        division: .central,
        primaryColor: Color(hex: "#CF0A2C"),  // Red
        secondaryColor: Color(hex: "#000000"), // Black
        accentColor: Color(hex: "#FFFFFF"),   // White
        logoSymbol: "c.circle.fill"
    )
    
    static let avalanche = NHLTeam(
        id: "avalanche",
        name: "Avalanche",
        city: "Colorado",
        abbreviation: "COL",
        conference: .western,
        division: .central,
        primaryColor: Color(hex: "#6F263D"),  // Burgundy
        secondaryColor: Color(hex: "#236192"), // Blue
        accentColor: Color(hex: "#A2AAAD"),   // Silver
        logoSymbol: "mountain.2.fill"
    )
    
    static let stars = NHLTeam(
        id: "stars",
        name: "Stars",
        city: "Dallas",
        abbreviation: "DAL",
        conference: .western,
        division: .central,
        primaryColor: Color(hex: "#006847"),  // Victory Green
        secondaryColor: Color(hex: "#8F8F8C"), // Silver
        accentColor: Color(hex: "#111111"),   // Black
        logoSymbol: "star.fill"
    )
    
    static let wild = NHLTeam(
        id: "wild",
        name: "Wild",
        city: "Minnesota",
        abbreviation: "MIN",
        conference: .western,
        division: .central,
        primaryColor: Color(hex: "#154734"),  // Forest Green
        secondaryColor: Color(hex: "#A6192E"), // Iron Range Red
        accentColor: Color(hex: "#EAAA00"),   // Wheat
        logoSymbol: "leaf.arrow.circlepath"
    )
    
    static let predators = NHLTeam(
        id: "predators",
        name: "Predators",
        city: "Nashville",
        abbreviation: "NSH",
        conference: .western,
        division: .central,
        primaryColor: Color(hex: "#FFB81C"),  // Gold
        secondaryColor: Color(hex: "#041E42"), // Navy
        accentColor: Color(hex: "#FFFFFF"),   // White
        logoSymbol: "n.circle.fill"
    )
    
    static let blues = NHLTeam(
        id: "blues",
        name: "Blues",
        city: "St. Louis",
        abbreviation: "STL",
        conference: .western,
        division: .central,
        primaryColor: Color(hex: "#002F87"),  // Blue
        secondaryColor: Color(hex: "#FCB514"), // Gold
        accentColor: Color(hex: "#041E42"),   // Navy
        logoSymbol: "music.note"
    )
    
    static let jets = NHLTeam(
        id: "jets",
        name: "Jets",
        city: "Winnipeg",
        abbreviation: "WPG",
        conference: .western,
        division: .central,
        primaryColor: Color(hex: "#041E42"),  // Navy
        secondaryColor: Color(hex: "#004C97"), // Blue
        accentColor: Color(hex: "#8E9090"),   // Silver
        logoSymbol: "airplane"
    )
    
    // MARK: - Pacific Division
    static let ducks = NHLTeam(
        id: "ducks",
        name: "Ducks",
        city: "Anaheim",
        abbreviation: "ANA",
        conference: .western,
        division: .pacific,
        primaryColor: Color(hex: "#000000"),  // Black
        secondaryColor: Color(hex: "#F47A38"), // Orange
        accentColor: Color(hex: "#B09862"),   // Gold
        logoSymbol: "d.circle.fill"
    )
    
    static let flames = NHLTeam(
        id: "flames",
        name: "Flames",
        city: "Calgary",
        abbreviation: "CGY",
        conference: .western,
        division: .pacific,
        primaryColor: Color(hex: "#C8102E"),  // Red
        secondaryColor: Color(hex: "#F1BE48"), // Yellow
        accentColor: Color(hex: "#111111"),   // Black
        logoSymbol: "flame.fill"
    )
    
    static let oilers = NHLTeam(
        id: "oilers",
        name: "Oilers",
        city: "Edmonton",
        abbreviation: "EDM",
        conference: .western,
        division: .pacific,
        primaryColor: Color(hex: "#FF4C00"),  // Orange
        secondaryColor: Color(hex: "#041E42"), // Navy
        accentColor: Color(hex: "#FFFFFF"),   // White
        logoSymbol: "drop.fill"
    )
    
    static let kings = NHLTeam(
        id: "kings",
        name: "Kings",
        city: "Los Angeles",
        abbreviation: "LA",
        conference: .western,
        division: .pacific,
        primaryColor: Color(hex: "#111111"),  // Black
        secondaryColor: Color(hex: "#A2AAAD"), // Silver
        accentColor: Color(hex: "#FFFFFF"),   // White
        logoSymbol: "crown.fill"
    )
    
    static let sharks = NHLTeam(
        id: "sharks",
        name: "Sharks",
        city: "San Jose",
        abbreviation: "SJ",
        conference: .western,
        division: .pacific,
        primaryColor: Color(hex: "#006D75"),  // Teal
        secondaryColor: Color(hex: "#EA7200"), // Orange
        accentColor: Color(hex: "#000000"),   // Black
        logoSymbol: "s.circle.fill"
    )
    
    static let kraken = NHLTeam(
        id: "kraken",
        name: "Kraken",
        city: "Seattle",
        abbreviation: "SEA",
        conference: .western,
        division: .pacific,
        primaryColor: Color(hex: "#001628"),  // Deep Sea Blue
        secondaryColor: Color(hex: "#99D9D9"), // Ice Blue
        accentColor: Color(hex: "#E55A00"),   // Boundless Blue
        logoSymbol: "s.circle.fill"
    )
    
    static let canucks = NHLTeam(
        id: "canucks",
        name: "Canucks",
        city: "Vancouver",
        abbreviation: "VAN",
        conference: .western,
        division: .pacific,
        primaryColor: Color(hex: "#00205B"),  // Blue
        secondaryColor: Color(hex: "#00843D"), // Green
        accentColor: Color(hex: "#FFFFFF"),   // White
        logoSymbol: "v.circle.fill"
    )
    
    static let goldenKnights = NHLTeam(
        id: "goldenknights",
        name: "Golden Knights",
        city: "Vegas",
        abbreviation: "VGK",
        conference: .western,
        division: .pacific,
        primaryColor: Color(hex: "#B4975A"),  // Gold
        secondaryColor: Color(hex: "#333F42"), // Steel Gray
        accentColor: Color(hex: "#C8102E"),   // Red
        logoSymbol: "shield.fill"
    )
    
    // MARK: - All Teams Array
    static let allTeams: [NHLTeam] = [
        // Atlantic
        bruins, sabres, redWings, panthers, canadiens, senators, lightning, mapleLeafs,
        // Metropolitan
        hurricanes, blueJackets, devils, islanders, rangers, flyers, penguins, capitals,
        // Central
        coyotes, blackhawks, avalanche, stars, wild, predators, blues, jets,
        // Pacific
        ducks, flames, oilers, kings, sharks, kraken, canucks, goldenKnights
    ]
    
    // MARK: - Helper Methods
    static func teamsByDivision(_ division: NHLTeam.Division) -> [NHLTeam] {
        allTeams.filter { $0.division == division }
    }
    
    static func teamsByConference(_ conference: NHLTeam.Conference) -> [NHLTeam] {
        allTeams.filter { $0.conference == conference }
    }
    
    static func team(byId id: String) -> NHLTeam? {
        allTeams.first { $0.id == id }
    }
    
    static func team(byAbbreviation abbr: String) -> NHLTeam? {
        allTeams.first { $0.abbreviation == abbr }
    }
}