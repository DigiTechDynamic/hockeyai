import Foundation

// MARK: - Skill Check Context
/// User-provided context about the skill video for better AI analysis
struct SkillCheckContext: Codable {
    /// Free-form user request describing what they want feedback on
    let userRequest: String

    // MARK: - Initializers
    init(userRequest: String) {
        self.userRequest = userRequest
    }

    // MARK: - Default
    static var `default`: SkillCheckContext {
        SkillCheckContext(userRequest: "")
    }

    // MARK: - Prompt Addition
    /// Returns context string to append to AI prompt
    var promptContext: String {
        guard !userRequest.isEmpty else { return "" }
        return """

        USER'S SPECIFIC REQUEST:
        "\(userRequest)"

        Focus your analysis and feedback on what the user asked about. Address their specific request directly in your response.
        """
    }
}
