import Foundation
import UIKit
import Combine

// MARK: - Model
struct GeneratedCard: Codable, Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let fileName: String
    let width: Int
    let height: Int
}

// MARK: - Store
/// Minimal, robust local persistence for generated cards.
/// - Saves each image to Documents/GeneratedCards as JPEG.
/// - Maintains an index.json for quick listing.
final class GeneratedCardsStore: ObservableObject {
    static let shared = GeneratedCardsStore()

    @Published private(set) var cards: [GeneratedCard] = []

    private let fileManager = FileManager.default
    private let workQueue = DispatchQueue(label: "GeneratedCardsStore.work")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let directoryURL: URL
    private let indexURL: URL

    private init() {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.directoryURL = documents.appendingPathComponent("GeneratedCards", isDirectory: true)
        self.indexURL = directoryURL.appendingPathComponent("index.json")

        // Ensure directory exists
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        // Load index if present
        if let data = try? Data(contentsOf: indexURL),
           let saved = try? decoder.decode([GeneratedCard].self, from: data) {
            self.cards = saved
        } else {
            self.cards = []
        }
    }

    // MARK: - Public API
    func save(image: UIImage) {
        workQueue.async { [weak self] in
            guard let self = self else { return }

            let id = UUID()
            let fileName = "\(id.uuidString).jpg"
            let url = self.directoryURL.appendingPathComponent(fileName)

            // Prefer JPEG for smaller disk footprint; fall back to PNG if needed
            let imageData = image.jpegData(compressionQuality: 0.9) ?? image.pngData()
            guard let data = imageData else { return }

            do {
                try data.write(to: url, options: [.atomic])
                let size = image.size
                let card = GeneratedCard(
                    id: id,
                    createdAt: Date(),
                    fileName: fileName,
                    width: Int(size.width.rounded()),
                    height: Int(size.height.rounded())
                )

                // Update memory + persist index
                var updated = self.cards
                updated.append(card)
                self.persistIndex(updated)
                DispatchQueue.main.async {
                    self.cards = updated
                }
            } catch {
                // Non-fatal: skip persistence if write fails
                // (Intentionally no user-facing alert for robustness)
            }
        }
    }

    func delete(_ card: GeneratedCard) {
        workQueue.async { [weak self] in
            guard let self = self else { return }
            let url = self.directoryURL.appendingPathComponent(card.fileName)
            try? self.fileManager.removeItem(at: url)
            let updated = self.cards.filter { $0.id != card.id }
            self.persistIndex(updated)
            DispatchQueue.main.async { self.cards = updated }
        }
    }

    var cardsSortedNewestFirst: [GeneratedCard] {
        cards.sorted { $0.createdAt > $1.createdAt }
    }

    func imageURL(for card: GeneratedCard) -> URL {
        directoryURL.appendingPathComponent(card.fileName)
    }

    func loadImage(for card: GeneratedCard) -> UIImage? {
        let url = imageURL(for: card)
        return UIImage(contentsOfFile: url.path)
    }

    // MARK: - Persistence
    private func persistIndex(_ cards: [GeneratedCard]) {
        do {
            let data = try encoder.encode(cards)
            // Write atomically via temp file to avoid corruption
            let tmp = directoryURL.appendingPathComponent("index.tmp")
            try data.write(to: tmp, options: [.atomic])
            // Replace
            if fileManager.fileExists(atPath: indexURL.path) {
                try? fileManager.removeItem(at: indexURL)
            }
            try? fileManager.moveItem(at: tmp, to: indexURL)
        } catch {
            // Ignore index write errors to remain robust
        }
    }
}

