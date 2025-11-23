import SwiftUI

struct CardHistoryView: View {
    @ObservedObject private var store = GeneratedCardsStore.shared
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    @State private var selected: GeneratedCard? = nil
    @State private var showingDeleteAlert = false

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]

    var body: some View {
        NavigationView {
            Group {
                if store.cards.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(store.cardsSortedNewestFirst) { card in
                                thumbnail(for: card)
                                    .onTapGesture { selected = card }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Previous Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { closeButton } }
        }
        .sheet(item: $selected) { card in
            CardDetailView(card: card)
        }
    }

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(8)
                .background(Circle().fill(theme.surface.opacity(0.5)))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(theme.primary)
            Text("No previous cards yet")
                .font(theme.fonts.title)
                .foregroundColor(.white)
            Text("Generate a card and it will appear here.")
                .font(theme.fonts.body)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background.ignoresSafeArea())
    }

    private func thumbnail(for card: GeneratedCard) -> some View {
        let url = store.imageURL(for: card)
        let image = UIImage(contentsOfFile: url.path)

        return ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.2)
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(height: 160)
        .clipped()
        .background(theme.surface.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(theme.primary.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Detail
private struct CardDetailView: View {
    let card: GeneratedCard
    @ObservedObject private var store = GeneratedCardsStore.shared
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().fill(theme.surface.opacity(0.5)))
                }

                Spacer()

                Text("Card")
                    .font(.system(size: 20, weight: .black))
                    .glowingHeaderText()

                Spacer()

                // Placeholder
                Color.clear.frame(width: 34, height: 34)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Image
            ScrollView {
                if let image = store.loadImage(for: card) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(16)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.orange)
                        Text("Couldn’t load image from disk.")
                            .font(theme.fonts.body)
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(32)
                }
            }

            // Actions
            VStack(spacing: 12) {
                Button(action: saveToPhotos) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save to Photos")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(theme.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(theme.surface.opacity(0.5))
                    .cornerRadius(26)
                    .overlay(RoundedRectangle(cornerRadius: 26).stroke(theme.primary.opacity(0.5), lineWidth: 1))
                }

                Button(role: .destructive, action: deleteCard) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete from History")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.red.opacity(0.15))
                    .foregroundColor(.red)
                    .cornerRadius(24)
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 16)
            .background(
                LinearGradient(colors: [theme.background.opacity(0), theme.background], startPoint: .top, endPoint: .bottom)
                    .frame(height: 100)
                    .offset(y: 20)
            )
        }
        .background(theme.background.ignoresSafeArea())
    }

    private func saveToPhotos() {
        if let image = store.loadImage(for: card) {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            HapticManager.shared.playNotification(type: .success)
        }
    }

    private func deleteCard() {
        store.delete(card)
        HapticManager.shared.playNotification(type: .success)
        dismiss()
    }
}

