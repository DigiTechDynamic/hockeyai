import Foundation
import UIKit

// MARK: - Player Rating Model
struct PlayerRating: Codable, Identifiable {
    let id: UUID
    let overallScore: Int
    let archetype: String
    let archetypeEmoji: String
    let photoData: Data?
    let createdAt: Date

    // AI-generated fields
    let aiComment: String?
    let visualObservations: [String]?
    let gearComponents: [String]?
    let description: String?

    // Premium intangibles (optional - only if person detected)
    let premiumIntangibles: PremiumIntangibles?

    init(
        id: UUID = UUID(),
        overallScore: Int,
        archetype: String,
        archetypeEmoji: String,
        photo: UIImage?,
        createdAt: Date = Date(),
        aiComment: String? = nil,
        visualObservations: [String]? = nil,
        gearComponents: [String]? = nil,
        description: String? = nil,
        premiumIntangibles: PremiumIntangibles? = nil
    ) {
        self.id = id
        self.overallScore = overallScore
        self.archetype = archetype
        self.archetypeEmoji = archetypeEmoji
        self.photoData = photo?.jpegData(compressionQuality: 0.9)  // Increased from 0.8 for better quality
        self.createdAt = createdAt
        self.aiComment = aiComment
        self.visualObservations = visualObservations
        self.gearComponents = gearComponents
        self.description = description
        self.premiumIntangibles = premiumIntangibles
    }

    var photo: UIImage? {
        guard let data = photoData else { return nil }
        return UIImage(data: data)
    }
}
