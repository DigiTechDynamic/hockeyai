import Foundation
import SwiftUI

struct AIDebugLog: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let request: AIDebugRequest
    var response: AIDebugResponse?
    var duration: TimeInterval?
    var error: Error?
    var status: RequestStatus
    
    init(timestamp: Date, request: AIDebugRequest, response: AIDebugResponse? = nil, duration: TimeInterval? = nil, error: Error? = nil, status: RequestStatus = .pending) {
        self.id = request.id
        self.timestamp = timestamp
        self.request = request
        self.response = response
        self.duration = duration
        self.error = error
        self.status = status
    }
    
    enum RequestStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case success = "Success"
        case failed = "Failed"
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .success: return .green
            case .failed: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .pending: return "clock.fill"
            case .success: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp, request, response, duration, status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        request = try container.decode(AIDebugRequest.self, forKey: .request)
        response = try container.decodeIfPresent(AIDebugResponse.self, forKey: .response)
        duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
        status = try container.decode(RequestStatus.self, forKey: .status)
        error = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(request, forKey: .request)
        try container.encodeIfPresent(response, forKey: .response)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encode(status, forKey: .status)
    }
}

struct AIDebugRequest: Codable {
    let id: UUID
    let prompt: String
    let systemPrompt: String?
    let model: String
    let parameters: [String: String]
    let media: [AIDebugMedia]?
    let tokenEstimate: Int?
    let temperature: Double?
    let maxTokens: Int?
    let topP: Double?
    let topK: Int?
    let responseSchema: String?  // JSON schema if provided
    let fullGenerationConfig: String?  // Full generation config as JSON
    let playerProfile: String?  // Player profile data if included
    let fullRequestBody: String?  // Complete request body as JSON
    
    init(
        prompt: String,
        systemPrompt: String? = nil,
        model: String,
        parameters: [String: String] = [:],
        media: [AIDebugMedia]? = nil,
        tokenEstimate: Int? = nil,
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        topP: Double? = nil,
        topK: Int? = nil,
        responseSchema: String? = nil,
        fullGenerationConfig: String? = nil,
        playerProfile: String? = nil,
        fullRequestBody: String? = nil
    ) {
        self.id = UUID()
        self.prompt = prompt
        self.systemPrompt = systemPrompt
        self.model = model
        self.parameters = parameters
        self.media = media
        self.tokenEstimate = tokenEstimate
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.topK = topK
        self.responseSchema = responseSchema
        self.fullGenerationConfig = fullGenerationConfig
        self.playerProfile = playerProfile
        self.fullRequestBody = fullRequestBody
    }
    
    var fullPrompt: String {
        if let systemPrompt = systemPrompt {
            return "System: \(systemPrompt)\n\nUser: \(prompt)"
        }
        return prompt
    }
    
    var mediaSummary: String {
        guard let media = media, !media.isEmpty else { return "No media" }
        
        let counts = Dictionary(grouping: media, by: { $0.type })
            .mapValues { $0.count }
        
        return counts.map { "\($1) \($0)\($1 > 1 ? "s" : "")" }.joined(separator: ", ")
    }
}

struct AIDebugMedia: Codable {
    let type: String
    let sizeBytes: Int
    let encoding: String
    let dimensions: CGSize?
    let thumbnailData: Data?
    let mimeType: String?
    let fps: Int?
    let duration: TimeInterval?
    let base64Data: String?  // Store the actual base64 video/image data
    
    init(
        type: String,
        sizeBytes: Int,
        encoding: String = "base64",
        dimensions: CGSize? = nil,
        thumbnailData: Data? = nil,
        mimeType: String? = nil,
        fps: Int? = nil,
        duration: TimeInterval? = nil,
        base64Data: String? = nil
    ) {
        self.type = type
        self.sizeBytes = sizeBytes
        self.encoding = encoding
        self.dimensions = dimensions
        self.thumbnailData = thumbnailData
        self.mimeType = mimeType
        self.fps = fps
        self.duration = duration
        self.base64Data = base64Data
    }
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(sizeBytes))
    }
    
    var formattedDimensions: String? {
        guard let dimensions = dimensions else { return nil }
        return "\(Int(dimensions.width)) × \(Int(dimensions.height))"
    }
    
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct AIDebugResponse: Codable {
    let text: String
    let tokenUsage: TokenUsage
    let finishReason: String?
    let modelVersion: String?
    let processingTime: TimeInterval?
    
    init(
        text: String,
        tokenUsage: TokenUsage,
        finishReason: String? = nil,
        modelVersion: String? = nil,
        processingTime: TimeInterval? = nil
    ) {
        self.text = text
        self.tokenUsage = tokenUsage
        self.finishReason = finishReason
        self.modelVersion = modelVersion
        self.processingTime = processingTime
    }
}

struct TokenUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    init(promptTokens: Int, completionTokens: Int) {
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = promptTokens + completionTokens
    }
    
    var estimatedCost: String {
        let promptCost = Double(promptTokens) * 0.00001
        let completionCost = Double(completionTokens) * 0.00003
        let total = promptCost + completionCost
        return String(format: "$%.6f", total)
    }
}

enum AIDebugFilter: String, CaseIterable {
    case all = "All"
    case success = "Success"
    case failed = "Failed"
    case pending = "Pending"
    case withMedia = "With Media"
    case withoutMedia = "Without Media"
    
    func matches(_ log: AIDebugLog) -> Bool {
        switch self {
        case .all:
            return true
        case .success:
            return log.status == .success
        case .failed:
            return log.status == .failed
        case .pending:
            return log.status == .pending
        case .withMedia:
            return log.request.media != nil && !log.request.media!.isEmpty
        case .withoutMedia:
            return log.request.media == nil || log.request.media!.isEmpty
        }
    }
}

enum AIDebugSortOption: String, CaseIterable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    case longestDuration = "Longest Duration"
    case shortestDuration = "Shortest Duration"
    case mostTokens = "Most Tokens"
    case leastTokens = "Least Tokens"
    
    func sort(_ logs: [AIDebugLog]) -> [AIDebugLog] {
        switch self {
        case .newest:
            return logs.sorted { $0.timestamp > $1.timestamp }
        case .oldest:
            return logs.sorted { $0.timestamp < $1.timestamp }
        case .longestDuration:
            return logs.sorted { ($0.duration ?? 0) > ($1.duration ?? 0) }
        case .shortestDuration:
            return logs.sorted { ($0.duration ?? 0) < ($1.duration ?? 0) }
        case .mostTokens:
            return logs.sorted { ($0.response?.tokenUsage.totalTokens ?? 0) > ($1.response?.tokenUsage.totalTokens ?? 0) }
        case .leastTokens:
            return logs.sorted { ($0.response?.tokenUsage.totalTokens ?? 0) < ($1.response?.tokenUsage.totalTokens ?? 0) }
        }
    }
}