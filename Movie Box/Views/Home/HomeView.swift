import SwiftUI

struct HomeView: View {
    @Environment(AppEnvironment.self) private var env

    private var signals: RecommendationSignals {
        env.library.signals(isPremium: env.entitlements.isPremium)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(AppColors.background)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await env.home.loadIfNeeded(signals: signals)
        }
    }

    private var header: some View {
        HStack(spacing: AppSpacing.sm) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(AppColors.accent)
                    .frame(width: 8, height: 18)
                Text("LUMEN")
                    .font(AppTypography.wordmark)
                    .tracking(2.4)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Lumen")
            .accessibilityAddTraits(.isHeader)

            Spacer()

            IconCircleButton(systemImage: "magnifyingglass", label: "Search") {
                env.tabs.select(.search)
            }
            NavigationLink(value: AppRoute.settings) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: AppSpacing.touch, height: AppSpacing.touch)
                    .background(AppColors.surface, in: Circle())
                    .overlay { Circle().strokeBorder(AppColors.separator, lineWidth: 1) }
            }
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, AppSpacing.page)
        .padding(.bottom, AppSpacing.xs)
    }

    @ViewBuilder
    private var content: some View {
        if env.home.isLoading && !env.home.hasContent {
            ScrollView {
                VStack(spacing: AppSpacing.section) {
                    HeroSkeleton()
                    railSkeleton
                    railSkeleton
                }
                .padding(.top, AppSpacing.sm)
            }
        } else if env.home.needsAPIKey {
            EmptyStateView(
                systemImage: "film",
                title: "Movie data is unavailable",
                message: "Movie data is unavailable right now.",
                actionTitle: "Try Again",
                action: { Task { await env.home.reload(signals: signals) } }
            )
        } else if let message = env.home.errorMessage, !env.home.hasContent {
            if !env.network.isOnline {
                EmptyStateView(
                    systemImage: "wifi.slash",
                    title: "You're offline",
                    message: "Saved lists are still available. Fresh movie data needs a connection.",
                    actionTitle: "Try Again",
                    action: { Task { await env.home.reload(signals: signals) } }
                )
            } else {
                NetworkErrorView(message: message) {
                    Task { await env.home.reload(signals: signals) }
                }
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    if !env.network.isOnline {
                        OfflineView()
                    }
                    CinematicHero(items: env.home.heroItems)
                    if !env.home.forYou.isEmpty {
                        PosterCarousel(title: "For You", items: env.home.forYou, seeAll: CatalogQuery(title: "For You", source: .forYou, genreID: env.library.preferences.favoriteGenreIDs.first))
                    }
                    PosterCarousel(title: "Trending Now", items: env.home.trending, seeAll: CatalogQuery(title: "Trending Now", source: .trending))
                    if !env.home.trendingForYou.isEmpty {
                        PosterCarousel(title: "Trending For You", items: env.home.trendingForYou, seeAll: nil)
                    }
                    PosterCarousel(title: "Popular Movies", items: env.home.popular, seeAll: CatalogQuery(title: "Popular Movies", source: .popular))
                    if env.ads.showsInline(sectionIndex: 3) {
                        AdInlineCard()
                    }
                    PosterCarousel(title: "Popular TV Shows", items: env.home.popularTV, seeAll: CatalogQuery(title: "Popular TV Shows", source: .popularTV))
                    PosterCarousel(title: "New Releases", items: env.home.nowPlaying, seeAll: CatalogQuery(title: "New Releases", source: .nowPlaying))
                    PosterCarousel(title: "Upcoming", items: env.home.upcoming, seeAll: CatalogQuery(title: "Upcoming", source: .upcoming))
                    PosterCarousel(title: "Top Rated", items: env.home.topRated, seeAll: CatalogQuery(title: "Top Rated", source: .topRated))
                    if env.entitlements.isPremium, !env.home.becauseYouWatched.isEmpty {
                        PosterCarousel(title: "Because You Watched \(env.home.becauseTitle)", items: env.home.becauseYouWatched, seeAll: nil)
                    }
                    if env.entitlements.isPremium, !env.home.youMayAlsoLike.isEmpty {
                        PosterCarousel(title: "You May Also Like", items: env.home.youMayAlsoLike, seeAll: nil)
                    }
                    genreRow
                }
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.lg)
            }
            .refreshable {
                await env.home.reload(signals: signals)
            }
        }
    }

    private var railSkeleton: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(0..<4, id: \.self) { _ in
                    MovieCardSkeleton()
                }
            }
            .padding(.horizontal, AppSpacing.page)
        }
    }

    private var genreRow: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "Genres")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(GenreCatalog.featured) { genre in
                        NavigationLink(value: AppRoute.catalog(CatalogQuery(title: genre.name, source: .popular, genreID: genre.id))) {
                            Text(genre.name)
                                .font(AppTypography.captionBold)
                                .foregroundStyle(AppColors.textPrimary)
                                .padding(.horizontal, 14)
                                .frame(minHeight: 36)
                                .background(AppColors.elevated, in: Capsule())
                                .overlay { Capsule().strokeBorder(AppColors.separator, lineWidth: 1) }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.page)
            }
        }
    }
}

#Preview {
    NavigationStack { HomeView() }
        .environment(AppEnvironment.preview)
        .preferredColorScheme(.dark)
}
