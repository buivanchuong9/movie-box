import SwiftUI

struct MediaGrid: View {
    @Environment(AppEnvironment.self) private var env
    let items: [MediaSummary]
    var showsAds = false
    var onNearEnd: () -> Void = {}

    private func columns(for width: CGFloat) -> [GridItem] {
        let count = max(2, Int(width / 156))
        return Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: min(count, 6))
    }

    var body: some View {
        GeometryReader { proxy in
            let grid = columns(for: proxy.size.width)
            let cardWidth = max(120, (proxy.size.width - AppSpacing.page * 2 - AppSpacing.sm * CGFloat(grid.count - 1)) / CGFloat(grid.count))
            ScrollView {
                LazyVGrid(columns: grid, spacing: AppSpacing.lg) {
                    ForEach(Array(items.enumerated()), id: \.element.libraryKey) { index, media in
                        if showsAds && env.ads.showsGridItem(index: index) {
                            AdInlineCard()
                                .gridCellColumns(grid.count)
                        }
                        NavigationLink(value: AppRoute.media(media)) {
                            MovieCard(
                                media: media,
                                width: cardWidth,
                                showsGenre: false,
                                isFavorite: env.library.favoriteKeys.contains(media.libraryKey),
                                isWatchlisted: env.library.watchlistKeys.contains(media.libraryKey),
                                isWatched: env.library.watchedKeys.contains(media.libraryKey),
                                onToggleFavorite: { env.library.toggleFavorite(media) },
                                onToggleWatchlist: { env.library.toggleWatchlist(media) },
                                onToggleWatched: { env.library.toggleWatched(media) }
                            )
                        }
                        .buttonStyle(PressScaleStyle())
                        .simultaneousGesture(TapGesture().onEnded { MediaMemory.shared.store(media) })
                        .onAppear {
                            if index >= items.count - 4 { onNearEnd() }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .frame(maxWidth: 1080)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
