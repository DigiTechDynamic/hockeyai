import SwiftUI

struct AIDebugLogsView: View {
    @StateObject private var logger = AIDebugLogger.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    @State private var searchText = ""
    @State private var selectedFilter: AIDebugFilter = .all
    @State private var selectedSort: AIDebugSortOption = .newest
    @State private var showingExportSheet = false
    @State private var exportData: Data?
    @State private var selectedLog: AIDebugLog?
    
    private var filteredLogs: [AIDebugLog] {
        let filtered = logger.searchLogs(query: searchText)
            .filter { selectedFilter.matches($0) }
        return selectedSort.sort(filtered)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Clear All Logs Button
                    if !filteredLogs.isEmpty {
                        HStack {
                            Spacer()
                            Button(action: {
                                logger.clearLogs()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash")
                                    Text("Clear All Logs")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    
                    if filteredLogs.isEmpty {
                        emptyState
                    } else {
                        logsList
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { exportLogs() }) {
                            Label("Export Logs", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: { logger.clearLogs() }) {
                            Label("Clear All Logs", systemImage: "trash")
                        }
                        .foregroundColor(.red)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                if let data = exportData {
                    ShareSheet(items: [data])
                }
            }
            .sheet(item: $selectedLog) { log in
                AIDebugLogDetailView(log: log)
            }
        }
    }
    
    private var headerStats: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                AIDebugStatCard(
                    title: "Total",
                    value: "\(logger.totalRequests)",
                    icon: "number.circle.fill",
                    color: theme.primary
                )
                
                AIDebugStatCard(
                    title: "Success",
                    value: "\(logger.successfulRequests)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                AIDebugStatCard(
                    title: "Failed",
                    value: "\(logger.failedRequests)",
                    icon: "xmark.circle.fill",
                    color: .red
                )
                
                AIDebugStatCard(
                    title: "Avg Time",
                    value: String(format: "%.2fs", logger.averageResponseTime),
                    icon: "clock.fill",
                    color: .orange
                )
                
                AIDebugStatCard(
                    title: "Tokens",
                    value: "\(logger.totalTokensUsed)",
                    icon: "text.word.spacing",
                    color: .purple
                )
            }
            .padding()
        }
        .background(theme.surface)
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Menu {
                    ForEach(AIDebugFilter.allCases, id: \.self) { filter in
                        Button(action: { selectedFilter = filter }) {
                            Label(filter.rawValue, systemImage: selectedFilter == filter ? "checkmark" : "")
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                        Text(selectedFilter.rawValue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.surface)
                    .cornerRadius(8)
                }
                
                Menu {
                    ForEach(AIDebugSortOption.allCases, id: \.self) { sort in
                        Button(action: { selectedSort = sort }) {
                            Label(sort.rawValue, systemImage: selectedSort == sort ? "checkmark" : "")
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(selectedSort.rawValue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.surface)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private var logsList: some View {
        List {
            ForEach(filteredLogs) { log in
                LogRowView(log: log)
                    .listRowBackground(theme.surface)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .onTapGesture {
                        selectedLog = log
                    }
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(theme.textSecondary.opacity(0.5))
            
            Text("No AI Debug Logs")
                .font(.title2)
                .foregroundColor(theme.text)
            
            Text("AI requests will appear here when debug logging is enabled")
                .font(.body)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func exportLogs() {
        exportData = logger.exportLogs()
        if exportData != nil {
            showingExportSheet = true
        }
    }
}

struct LogRowView: View {
    let log: AIDebugLog
    @Environment(\.theme) private var theme
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: log.status.icon)
                    .foregroundColor(log.status.color)
                
                Text(log.request.model)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                
                Spacer()
                
                Text(timeFormatter.string(from: log.timestamp))
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
            
            Text(log.request.prompt)
                .lineLimit(2)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(theme.text)
            
            HStack {
                if let media = log.request.media, !media.isEmpty {
                    Label(log.request.mediaSummary, systemImage: "photo")
                        .font(.caption)
                        .foregroundColor(theme.primary)
                }
                
                if let duration = log.duration {
                    Label(String(format: "%.2fs", duration), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                if let tokens = log.response?.tokenUsage.totalTokens {
                    Label("\(tokens) tokens", systemImage: "text.word.spacing")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
                
                if let error = log.error {
                    Label("Error", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(theme.surface)
        .cornerRadius(12)
    }
}

struct AIDebugStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
            
            Text(value)
                .font(.title3.bold())
                .foregroundColor(theme.text)
        }
        .padding(12)
        .background(theme.background)
        .cornerRadius(8)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}