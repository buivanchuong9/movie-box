import SwiftUI

struct PosterCarousel: View {
    @Environment(AppEnvironment.self) private var env
    let title: String
    let items: [MediaSummary]
    var seeAll: CatalogQuery?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: title)
                .overlay(alignment: .trailing) {
                if let seeAll {
                    NavigationLink(value: AppRoute.catalog(seeAll)) {
                        Text("See All")
                            .font(AppTypography.captionBold)
                            .foregroundStyle(AppColors.accent)
                            .frame(minHeight: AppSpacing.touch)
                            .padding(.trailing, AppSpacing.page)
                    }
                    .accessibilityLabel("See all \(title)")
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: AppSpacing.sm) {
                    ForEach(items) { media in
                        NavigationLink(value: AppRoute.media(media)) {
                            MovieCard(
                                media: media,
                                isFavorite: env.library.favoriteKeys.contains(media.libraryKey),
                                isWatchlisted: env.library.watchlistKeys.contains(media.libraryKey),
                                isWatched: env.library.watchedKeys.contains(media.libraryKey),
                                onToggleFavorite: { env.library.toggleFavorite(media) },
                                onToggleWatchlist: { env.library.toggleWatchlist(media) },
                                onToggleWatched: { env.library.toggleWatched(media) }
                            )
                        }
                        .buttonStyle(PressScaleStyle())
                        .simultaneousGesture(TapGesture().onEnded {
                            MediaMemory.shared.store(media)
                        })
                    }
                }
                .padding(.horizontal, AppSpacing.page)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        PosterCarousel(
            title: "Trending Now",
            items: SampleData.movies,
            seeAll: CatalogQuery(title: "Trending Now", source: .trending)
        )
    }
    .environment(AppEnvironment.preview)
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
