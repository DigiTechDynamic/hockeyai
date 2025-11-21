import Foundation

final class AIDebugStorage {
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let logsFileName = "ai_debug_logs.json"
    private let maxFileSize: Int = 50 * 1024 * 1024  // 50MB for debug logs with large request bodies
    
    private var logsFileURL: URL {
        documentsDirectory.appendingPathComponent(logsFileName)
    }
    
    init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("AIDebugLogs", isDirectory: true)
        
        createDirectoryIfNeeded()
    }
    
    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: documentsDirectory.path) {
            try? fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    func saveLogs(_ logs: [AIDebugLog]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(logs)
            
            if data.count > maxFileSize {
                let trimmedLogs = Array(logs.suffix(logs.count / 2))
                let trimmedData = try encoder.encode(trimmedLogs)
                try trimmedData.write(to: logsFileURL)
                print("[AIDebugStorage] Logs trimmed and saved (exceeded max size) - kept \(trimmedLogs.count) most recent logs")
            } else {
                try data.write(to: logsFileURL)
            }
        } catch {
            print("[AIDebugStorage] Failed to save logs: \(error)")
        }
    }
    
    func loadLogs() -> [AIDebugLog] {
        guard fileManager.fileExists(atPath: logsFileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: logsFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let logs = try decoder.decode([AIDebugLog].self, from: data)
            print("[AIDebugStorage] Loaded \(logs.count) logs from storage")
            
            // Debug: Check if logs have full request body data
            for (index, log) in logs.enumerated() {
                let hasFullBody = log.request.fullRequestBody != nil && !log.request.fullRequestBody!.isEmpty
                let bodyLength = log.request.fullRequestBody?.count ?? 0
                print("[AIDebugStorage] Log \(index): hasFullBody=\(hasFullBody), bodyLength=\(bodyLength)")
            }
            
            return logs
        } catch {
            print("[AIDebugStorage] Failed to load logs: \(error)")
            return []
        }
    }
    
    func clearLogs() {
        do {
            if fileManager.fileExists(atPath: logsFileURL.path) {
                try fileManager.removeItem(at: logsFileURL)
                print("[AIDebugStorage] Logs file deleted")
            }
        } catch {
            print("[AIDebugStorage] Failed to clear logs: \(error)")
        }
    }
    
    func exportLogsAsFile() -> URL? {
        guard fileManager.fileExists(atPath: logsFileURL.path) else {
            return nil
        }
        
        let exportFileName = "ai_debug_logs_\(Date().timeIntervalSince1970).json"
        let exportURL = documentsDirectory.appendingPathComponent(exportFileName)
        
        do {
            try fileManager.copyItem(at: logsFileURL, to: exportURL)
            return exportURL
        } catch {
            print("[AIDebugStorage] Failed to export logs: \(error)")
            return nil
        }
    }
    
    func getStorageSize() -> Int64 {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: logsFileURL.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    func getFormattedStorageSize() -> String {
        let size = getStorageSize()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}