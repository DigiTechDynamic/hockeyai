import Foundation
import SwiftUI

final class AIDebugLogger: ObservableObject {
    static let shared = AIDebugLogger()
    
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "AIDebugLoggingEnabled")
            if !isEnabled {
                print("[AIDebugLogger] Debug logging disabled")
            } else {
                print("[AIDebugLogger] Debug logging enabled")
            }
        }
    }
    
    @Published private(set) var logs: [AIDebugLog] = []
    
    private let maxLogs = 100
    private let storage = AIDebugStorage()
    private let dateFormatter: DateFormatter
    private let queue = DispatchQueue(label: "com.hockeyapp.aidebuglogger", attributes: .concurrent)
    
    var totalRequests: Int { logs.count }
    var successfulRequests: Int { logs.filter { $0.error == nil }.count }
    var failedRequests: Int { logs.filter { $0.error != nil }.count }
    var averageResponseTime: TimeInterval {
        let times = logs.compactMap { $0.duration }
        guard !times.isEmpty else { return 0 }
        return times.reduce(0, +) / Double(times.count)
    }
    var totalTokensUsed: Int {
        logs.reduce(0) { $0 + ($1.response?.tokenUsage.totalTokens ?? 0) }
    }
    
    private init() {
        #if DEBUG
        // Automatically enable debug logging in debug builds
        self.isEnabled = true
        UserDefaults.standard.set(true, forKey: "AIDebugLoggingEnabled")
        #else
        self.isEnabled = UserDefaults.standard.bool(forKey: "AIDebugLoggingEnabled")
        #endif
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateStyle = .short
        self.dateFormatter.timeStyle = .medium
        
        loadLogs()
        
        #if DEBUG
        if isEnabled {
            print("[AIDebugLogger] Debug logging automatically enabled for DEBUG build")
        }
        #endif
    }
    
    func logRequest(_ request: AIDebugRequest) {
        guard isEnabled else { return }
        
        print("[AIDebugLogger] Logging request - has full body: \(request.fullRequestBody != nil ? "YES (\(request.fullRequestBody!.count) chars)" : "NO")")
        
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let log = AIDebugLog(
                timestamp: Date(),
                request: request,
                response: nil,
                duration: nil,
                error: nil,
                status: .pending
            )
            
            DispatchQueue.main.async {
                self.logs.insert(log, at: 0)
                self.trimLogsIfNeeded()
                
                // Save immediately to persist full request body data
                self.storage.saveLogs(self.logs)
            }
            
            print("[AIDebugLogger] Request logged: \(request.model) - \(request.prompt.prefix(100))...")
        }
    }
    
    func updateLogWithResponse(_ requestId: UUID, response: AIDebugResponse, duration: TimeInterval) {
        guard isEnabled else { return }
        
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let index = self.logs.firstIndex(where: { $0.id == requestId }) {
                    var updatedLog = self.logs[index]
                    updatedLog.response = response
                    updatedLog.duration = duration
                    updatedLog.status = .success
                    self.logs[index] = updatedLog
                    
                    print("[AIDebugLogger] Response logged: \(duration)s - \(response.tokenUsage.totalTokens) tokens")
                }
            }
            
            self.storage.saveLogs(self.logs)
        }
    }
    
    func updateLogWithError(_ requestId: UUID, error: Error, duration: TimeInterval) {
        guard isEnabled else { return }
        
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let index = self.logs.firstIndex(where: { $0.id == requestId }) {
                    var updatedLog = self.logs[index]
                    updatedLog.error = error
                    updatedLog.duration = duration
                    updatedLog.status = .failed
                    self.logs[index] = updatedLog
                    
                    print("[AIDebugLogger] Error logged: \(error.localizedDescription)")
                }
            }
            
            self.storage.saveLogs(self.logs)
        }
    }
    
    func clearLogs() {
        queue.async(flags: .barrier) { [weak self] in
            DispatchQueue.main.async {
                self?.logs.removeAll()
            }
            self?.storage.clearLogs()
            print("[AIDebugLogger] All logs cleared")
        }
    }
    
    func exportLogs() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let exportData = logs.map { log in
                AIDebugLogExport(
                    timestamp: log.timestamp,
                    requestId: log.id,
                    model: log.request.model,
                    prompt: log.request.prompt,
                    systemPrompt: log.request.systemPrompt,
                    parameters: log.request.parameters,
                    mediaCount: log.request.media?.count ?? 0,
                    mediaDetails: log.request.media?.map { media in
                        AIDebugMediaExport(
                            type: media.type,
                            sizeBytes: media.sizeBytes,
                            encoding: media.encoding,
                            dimensions: media.dimensions
                        )
                    },
                    responseText: log.response?.text,
                    tokenUsage: log.response?.tokenUsage,
                    duration: log.duration,
                    error: log.error?.localizedDescription,
                    status: log.status.rawValue
                )
            }
            
            return try encoder.encode(exportData)
        } catch {
            print("[AIDebugLogger] Failed to export logs: \(error)")
            return nil
        }
    }
    
    func searchLogs(query: String) -> [AIDebugLog] {
        guard !query.isEmpty else { return logs }
        
        let lowercasedQuery = query.lowercased()
        return logs.filter { log in
            log.request.prompt.lowercased().contains(lowercasedQuery) ||
            log.response?.text.lowercased().contains(lowercasedQuery) ?? false ||
            log.request.model.lowercased().contains(lowercasedQuery) ||
            log.error?.localizedDescription.lowercased().contains(lowercasedQuery) ?? false
        }
    }
    
    func logsForDateRange(from startDate: Date, to endDate: Date) -> [AIDebugLog] {
        logs.filter { log in
            log.timestamp >= startDate && log.timestamp <= endDate
        }
    }
    
    private func loadLogs() {
        queue.async { [weak self] in
            let loadedLogs = self?.storage.loadLogs() ?? []
            DispatchQueue.main.async {
                self?.logs = loadedLogs
            }
        }
    }
    
    private func trimLogsIfNeeded() {
        if logs.count > maxLogs {
            logs = Array(logs.prefix(maxLogs))
            storage.saveLogs(logs)
        }
    }
}

struct AIDebugLogExport: Codable {
    let timestamp: Date
    let requestId: UUID
    let model: String
    let prompt: String
    let systemPrompt: String?
    let parameters: [String: String]
    let mediaCount: Int
    let mediaDetails: [AIDebugMediaExport]?
    let responseText: String?
    let tokenUsage: TokenUsage?
    let duration: TimeInterval?
    let error: String?
    let status: String
}

struct AIDebugMediaExport: Codable {
    let type: String
    let sizeBytes: Int
    let encoding: String
    let dimensions: CGSize?
}