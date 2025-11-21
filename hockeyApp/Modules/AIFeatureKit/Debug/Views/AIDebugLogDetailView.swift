import SwiftUI
import AVKit

struct AIDebugLogDetailView: View {
    let log: AIDebugLog
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var selectedTab = 0
    @State private var showingShareSheet = false
    @State private var shareData: Data?
    @State private var videoPlayers: [Int: AVPlayer] = [:]
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        Picker("View", selection: $selectedTab) {
                            Text("Request").tag(0)
                            Text("Response").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        contentSection
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Log Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: shareLog) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let data = shareData {
                    ShareSheet(items: [data])
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: log.status.icon)
                    .font(.title)
                    .foregroundColor(log.status.color)
                
                Text(log.status.rawValue)
                    .font(.title2.bold())
                    .foregroundColor(theme.text)
            }
            
            Text(dateFormatter.string(from: log.timestamp))
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            
            HStack(spacing: 20) {
                if let duration = log.duration {
                    VStack {
                        Text(String(format: "%.3f", duration))
                            .font(.headline)
                            .foregroundColor(theme.text)
                        Text("seconds")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                
                if let tokens = log.response?.tokenUsage {
                    VStack {
                        Text("\(tokens.totalTokens)")
                            .font(.headline)
                            .foregroundColor(theme.text)
                        Text("tokens")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    VStack {
                        Text(tokens.estimatedCost)
                            .font(.headline)
                            .foregroundColor(theme.text)
                        Text("estimated")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(theme.surface)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var contentSection: some View {
        switch selectedTab {
        case 0:
            requestView
        case 1:
            responseView
        default:
            requestView
        }
    }
    
    private var requestView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let systemPrompt = log.request.systemPrompt {
                sectionCard(title: "System Prompt") {
                    ScrollView {
                        Text(systemPrompt)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(theme.text)
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
                    .frame(height: 200)
                }
            }
            
            sectionCard(title: "User Prompt") {
                ScrollView {
                    Text(log.request.prompt)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(theme.text)
                        .textSelection(.enabled)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.black.opacity(0.3))
                .cornerRadius(6)
                .frame(height: 200)
            }
            
            if let responseSchema = log.request.responseSchema {
                sectionCard(title: "Response Schema", titleColor: .blue) {
                    ScrollView {
                        Text(responseSchema)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(theme.text)
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
                    .frame(height: 200)
                }
            }
            
            if let fullConfig = log.request.fullGenerationConfig {
                sectionCard(title: "Generation Config", titleColor: .orange) {
                    ScrollView {
                        Text(fullConfig)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(theme.text)
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
                    .frame(height: 200)
                }
            }
            
            // Add Media Content and Metadata to Request view
            if let media = log.request.media, !media.isEmpty {
                mediaContentSection(media: media)
            }
            
            metadataSection
            
            if let playerProfile = log.request.playerProfile {
                sectionCard(title: "Player Profile", titleColor: .purple) {
                    Text(playerProfile)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(theme.text)
                        .textSelection(.enabled)
                }
            }
            
            if !log.request.parameters.isEmpty {
                sectionCard(title: "Parameters") {
                    ForEach(Array(log.request.parameters.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.caption.bold())
                                .foregroundColor(theme.textSecondary)
                            Spacer()
                            Text(log.request.parameters[key] ?? "")
                                .font(.caption)
                                .foregroundColor(theme.text)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var responseView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let response = log.response {
                sectionCard(title: "Response Text") {
                    Text(response.text)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(theme.text)
                        .textSelection(.enabled)
                }
                
                sectionCard(title: "Token Usage") {
                    VStack(alignment: .leading, spacing: 8) {
                        tokenRow("Prompt Tokens", value: response.tokenUsage.promptTokens)
                        tokenRow("Completion Tokens", value: response.tokenUsage.completionTokens)
                        Divider()
                        tokenRow("Total Tokens", value: response.tokenUsage.totalTokens, bold: true)
                        tokenRow("Estimated Cost", text: response.tokenUsage.estimatedCost, bold: true)
                    }
                }
            } else if let error = log.error {
                sectionCard(title: "Error", titleColor: .red) {
                    Text(error.localizedDescription)
                        .font(.body)
                        .foregroundColor(.red)
                }
            } else {
                sectionCard(title: "Response") {
                    Text("No response received")
                        .font(.body)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var mediaView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let media = log.request.media, !media.isEmpty {
                ForEach(Array(media.enumerated()), id: \.offset) { index, item in
                    sectionCard(title: "Media #\(index + 1)") {
                        VStack(alignment: .leading, spacing: 8) {
                            mediaRow("Type", value: item.type)
                            mediaRow("Size", value: item.formattedSize)
                            mediaRow("Encoding", value: item.encoding)
                            
                            if let dimensions = item.formattedDimensions {
                                mediaRow("Dimensions", value: dimensions)
                            }
                            
                            if let mimeType = item.mimeType {
                                mediaRow("MIME Type", value: mimeType)
                            }
                            
                            if let fps = item.fps {
                                mediaRow("FPS", value: "\(fps)")
                            }
                            
                            if let duration = item.formattedDuration {
                                mediaRow("Duration", value: duration)
                            }
                            
                            // Show thumbnail and provide way to view/play media
                            if let thumbnailData = item.thumbnailData,
                               let uiImage = UIImage(data: thumbnailData) {
                                VStack(spacing: 8) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 200)
                                        .cornerRadius(8)
                                    
                                    if item.type.lowercased().contains("video") {
                                        if let player = createVideoPlayer(for: item, index: index) {
                                            VideoPlayer(player: player)
                                                .frame(height: 250)
                                                .cornerRadius(8)
                                                .onAppear {
                                                    videoPlayers[index] = player
                                                }
                                                .onDisappear {
                                                    player.pause()
                                                }
                                        } else {
                                            Text("Unable to load video")
                                                .foregroundColor(theme.textSecondary)
                                                .font(.caption)
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                }
            } else {
                sectionCard(title: "Media") {
                    Text("No media attached")
                        .font(.body)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var metadataView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionCard(title: "Request Info") {
                VStack(alignment: .leading, spacing: 8) {
                    metadataRow("Request ID", value: log.id.uuidString)
                    metadataRow("Model", value: log.request.model)
                    if let endpoint = log.request.parameters["endpoint"] {
                        metadataRow("API Endpoint", value: endpoint)
                    }
                    metadataRow("Timestamp", value: dateFormatter.string(from: log.timestamp))
                    
                    if let temp = log.request.temperature {
                        metadataRow("Temperature", value: String(format: "%.2f", temp))
                    }
                    
                    if let maxTokens = log.request.maxTokens {
                        metadataRow("Max Tokens", value: "\(maxTokens)")
                    }
                    
                    if let topP = log.request.topP {
                        metadataRow("Top P", value: String(format: "%.2f", topP))
                    }
                    
                    if let topK = log.request.topK {
                        metadataRow("Top K", value: "\(topK)")
                    }
                }
            }
            
            if let response = log.response {
                sectionCard(title: "Response Info") {
                    VStack(alignment: .leading, spacing: 8) {
                        if let finishReason = response.finishReason {
                            metadataRow("Finish Reason", value: finishReason)
                        }
                        
                        if let modelVersion = response.modelVersion {
                            metadataRow("Model Version", value: modelVersion)
                        }
                        
                        if let processingTime = response.processingTime {
                            metadataRow("Processing Time", value: String(format: "%.3fs", processingTime))
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func sectionCard<Content: View>(
        title: String,
        titleColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(titleColor ?? theme.text)
            
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(theme.surface)
        .cornerRadius(12)
    }
    
    private func tokenRow(_ label: String, value: Int, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(bold ? .body.bold() : .body)
                .foregroundColor(theme.textSecondary)
            Spacer()
            Text("\(value)")
                .font(bold ? .body.bold() : .body)
                .foregroundColor(theme.text)
        }
    }
    
    private func tokenRow(_ label: String, text: String, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(bold ? .body.bold() : .body)
                .foregroundColor(theme.textSecondary)
            Spacer()
            Text(text)
                .font(bold ? .body.bold() : .body)
                .foregroundColor(theme.text)
        }
    }
    
    private func mediaRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(theme.text)
        }
    }
    
    private func metadataRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.caption.monospaced())
                .foregroundColor(theme.text)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
    
    private func processRequestBodyForDisplay(_ requestBody: String) -> String {
        var processedBody = requestBody
        
        // More aggressive pattern to find base64 data regardless of structure
        // This handles both "data": "base64..." and other base64 strings
        let base64Pattern = "\"[A-Za-z0-9+/]{100,}={0,2}\""
        if let regex = try? NSRegularExpression(pattern: base64Pattern, options: []) {
            let matches = regex.matches(in: processedBody, options: [], range: NSRange(location: 0, length: processedBody.count))
            
            var mediaCount = 0
            for match in matches.reversed() {
                let matchRange = match.range
                if let range = Range(matchRange, in: processedBody) {
                    let originalData = String(processedBody[range])
                    let dataLength = originalData.count - 2 // Subtract quotes
                    
                    // Only replace if it's large base64 data (likely media)
                    if dataLength > 1000 {
                        let sizeInKB = dataLength / 1024
                        let sizeInMB = Double(sizeInKB) / 1024.0
                        
                        mediaCount += 1
                        let replacement = String(format: "\"📹 [MEDIA_DATA_%d: %.1fMB base64 data - See Media tab for details]\"", mediaCount, sizeInMB)
                        processedBody.replaceSubrange(range, with: replacement)
                        
                        print("🔧 [AIDebugLogDetailView] Replaced base64 data: \(dataLength) chars -> \(sizeInMB)MB")
                    }
                }
            }
            
            if mediaCount > 0 {
                print("🔧 [AIDebugLogDetailView] Processed \(mediaCount) media items")
            }
        }
        
        // Also check for very long quoted strings that might be encoded content
        let longStringPattern = "\"[^\"]{5000,}\""
        if let regex = try? NSRegularExpression(pattern: longStringPattern, options: []) {
            let matches = regex.matches(in: processedBody, options: [], range: NSRange(location: 0, length: processedBody.count))
            
            for match in matches.reversed() {
                let matchRange = match.range
                if let range = Range(matchRange, in: processedBody) {
                    let originalString = String(processedBody[range])
                    
                    // Skip if it's already been replaced
                    if originalString.contains("MEDIA_DATA") || originalString.contains("[") {
                        continue
                    }
                    
                    let contentLength = originalString.count - 2 // Subtract quotes
                    let sizeInKB = contentLength / 1024
                    
                    let replacement = String(format: "\"📄 [LARGE_CONTENT: %dKB text content - Truncated for display]\"", sizeInKB)
                    processedBody.replaceSubrange(range, with: replacement)
                    
                    print("🔧 [AIDebugLogDetailView] Replaced large text: \(contentLength) chars")
                }
            }
        }
        
        return processedBody
    }
    
    private func createVideoPlayer(for item: AIDebugMedia, index: Int) -> AVPlayer? {
        guard let base64Data = item.base64Data,
              let videoData = Data(base64Encoded: base64Data) else {
            print("❌ [AIDebugLogDetailView] Failed to decode base64 video data for player")
            return nil
        }
        
        do {
            // Create temporary file for video playback
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "debug_video_\(index)_\(UUID().uuidString).mp4"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try videoData.write(to: fileURL)
            print("✅ [AIDebugLogDetailView] Created temp video file for player: \(fileURL)")
            
            let player = AVPlayer(url: fileURL)
            return player
        } catch {
            print("❌ [AIDebugLogDetailView] Failed to create video player: \(error)")
            return nil
        }
    }
    
    private func mediaContentSection(media: [AIDebugMedia]) -> some View {
        sectionCard(title: "Media Content", titleColor: .red) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(media.enumerated()), id: \.offset) { index, item in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(item.type.capitalized) #\(index + 1)")
                            .font(.headline)
                            .foregroundColor(theme.text)
                        
                        mediaRow("Size", value: item.formattedSize)
                        mediaRow("Encoding", value: item.encoding)
                        
                        if let mimeType = item.mimeType {
                            mediaRow("MIME Type", value: mimeType)
                        }
                        
                        if let fps = item.fps {
                            mediaRow("FPS", value: "\(fps)")
                        }
                        
                        if item.type.lowercased().contains("video") {
                            if let player = createVideoPlayer(for: item, index: index) {
                                VideoPlayer(player: player)
                                    .frame(height: 200)
                                    .cornerRadius(8)
                                    .onAppear {
                                        videoPlayers[index] = player
                                    }
                                    .onDisappear {
                                        player.pause()
                                    }
                            } else {
                                Text("Unable to load video")
                                    .foregroundColor(theme.textSecondary)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if index < media.count - 1 {
                        Divider()
                            .background(theme.textSecondary.opacity(0.3))
                    }
                }
            }
        }
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionCard(title: "Request Info") {
                VStack(alignment: .leading, spacing: 8) {
                    metadataRow("Request ID", value: log.id.uuidString)
                    metadataRow("Model", value: log.request.model)
                    if let endpoint = log.request.parameters["endpoint"] {
                        metadataRow("API Endpoint", value: endpoint)
                    }
                    metadataRow("Timestamp", value: dateFormatter.string(from: log.timestamp))
                    
                    if let temp = log.request.temperature {
                        metadataRow("Temperature", value: String(format: "%.2f", temp))
                    }
                    
                    if let maxTokens = log.request.maxTokens {
                        metadataRow("Max Tokens", value: "\(maxTokens)")
                    }
                    
                    if let topP = log.request.topP {
                        metadataRow("Top P", value: String(format: "%.2f", topP))
                    }
                    
                    if let topK = log.request.topK {
                        metadataRow("Top K", value: "\(topK)")
                    }
                }
            }
            
            if let response = log.response {
                sectionCard(title: "Response Info") {
                    VStack(alignment: .leading, spacing: 8) {
                        metadataRow("Finish Reason", value: response.finishReason ?? "N/A")
                        
                        if let modelVersion = response.modelVersion {
                            metadataRow("Model Version", value: modelVersion)
                        }
                        
                        if let processingTime = response.processingTime {
                            metadataRow("Processing Time", value: String(format: "%.3f seconds", processingTime))
                        }
                        
                        if let duration = log.duration {
                            metadataRow("Total Duration", value: String(format: "%.3f seconds", duration))
                        }
                    }
                }
            }
        }
    }
    
    private func shareLog() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode([log]) {
            shareData = data
            showingShareSheet = true
        }
    }
}