import SwiftUI

struct MovieCard: View {
    @Environment(\.zoomNamespace) private var zoomNamespace
    let media: MediaSummary
    var width: CGFloat = AppSpacing.posterCard
    var showsGenre = true
    var isFavorite = false
    var isWatchlisted = false
    var isWatched = false
    var onToggleFavorite: () -> Void = {}
    var onToggleWatchlist: () -> Void = {}
    var onToggleWatched: () -> Void = {}
    @State private var shareText: SharePayload?
    @State private var heartBurst = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var imageURL: URL? {
        ImageService().url(path: media.posterPath, size: .medium)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ZStack {
                CachedAsyncImage(
                    url: imageURL,
                    maxPixel: width * 3,
                    seed: media.id,
                    accessibilityLabel: "\(media.title) poster"
                )
                .frame(width: width, height: width * 1.5)
                .clipped()

                if heartBurst && !reduceMotion {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(AppColors.accent)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityHidden(true)
                }
            }
            .frame(width: width, height: width * 1.5)
            .overlay(alignment: .topLeading) {
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isFavorite ? AppColors.onAccent : .white)
                        .frame(width: 28, height: 28)
                        .background(isFavorite ? AppColors.accentFill : Color.black.opacity(0.45), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(8)
                .accessibilityLabel(isFavorite ? "Remove \(media.title) from favorites" : "Favorite \(media.title)")
            }
            .overlay(alignment: .topTrailing) {
                RatingBadge(score: media.voteAverage)
                    .padding(8)
            }
            .overlay(alignment: .bottomLeading) {
                if isWatched {
                    Text("Watched")
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.onAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(AppColors.accentFill, in: Capsule())
                        .padding(8)
                }
            }
            .frame(width: width, height: width * 1.5)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(AppColors.separator, lineWidth: 1)
            }
            .matchedZoomSource(id: media.libraryKey, in: zoomNamespace)

            Text(media.title)
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
                .frame(width: width, alignment: .leading)
            Text(metaLine)
                .font(AppTypography.meta)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)
                .frame(width: width, alignment: .leading)
        }
        .frame(width: width, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onToggleWatchlist()
            } label: {
                Label(isWatchlisted ? "Remove from Watchlist" : "Add to Watchlist", systemImage: "bookmark")
            }
            Button {
                onToggleWatched()
            } label: {
                Label(isWatched ? "Unmark Watched" : "Mark Watched", systemImage: "checkmark.circle")
            }
            Button {
                shareText = SharePayload(text: media.shareText)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: isWatchlisted ? "Remove from Watchlist" : "Add to Watchlist", onToggleWatchlist)
        .accessibilityAction(named: isWatched ? "Unmark Watched" : "Mark Watched", onToggleWatched)
        .sheet(item: $shareText) { payload in
            ShareSheet(items: [payload.text])
        }
        .onChange(of: isFavorite) { _, favorite in
            guard favorite else { return }
            guard !reduceMotion else { return }
            withAnimation(AppAnimation.quick) { heartBurst = true }
            Task {
                try? await Task.sleep(for: .milliseconds(420))
                withAnimation(AppAnimation.quick) { heartBurst = false }
            }
        }
    }

    private var metaLine: String {
        if showsGenre && !media.genreLine.isEmpty {
            return "\(media.yearText) · \(media.genreLine)"
        }
        return media.yearText
    }
}

struct CompactMovieCard: View {
    let media: MediaSummary

    private var imageURL: URL? {
        ImageService().url(path: media.posterPath, size: .small)
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            CachedAsyncImage(
                url: imageURL,
                maxPixel: 240,
                seed: media.id,
                accessibilityLabel: "\(media.title) poster"
            )
            .frame(width: 64, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(media.title)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)
                Text(media.yearText)
                    .font(AppTypography.meta)
                    .foregroundStyle(AppColors.textSecondary)
                RatingBadge(score: media.voteAverage)
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.xs)
        .frame(maxWidth: .infinity, minHeight: AppSpacing.touch, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(media.accessibilitySummary)
    }
}

struct SharePayload: Identifiable {
    let id = UUID()
    let text: String
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ScrollView(.horizontal) {
        HStack {
            MovieCard(media: SampleData.movies[0], isFavorite: true)
            CompactMovieCard(media: SampleData.movies[1])
                .frame(width: 280)
        }
        .padding()
    }
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
