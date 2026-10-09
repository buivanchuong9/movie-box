import SwiftUI

struct HomeView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showImporter = false

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
        .movieImporter(isPresented: $showImporter)
        .task {
            await env.home.loadIfNeeded(signals: signals)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image("AppLogo")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                VStack(alignment: .leading, spacing: 0) {
                    Text("Movie Box")
                        .font(AppTypography.wordmark)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("On this device")
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.accent)
                        .lineLimit(1)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Movie Box, stored on this device")
            .accessibilityAddTraits(.isHeader)

            Spacer(minLength: AppSpacing.sm)

            if env.home.hasContent {
                IconCircleButton(systemImage: "plus", label: "Import movies") {
                    showImporter = true
                }
            }
            IconCircleButton(systemImage: "magnifyingglass", label: "Search") {
                env.tabs.select(.search)
            }
            NavigationLink(value: AppRoute.settings) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: AppSpacing.touch, height: AppSpacing.touch)
                    .background(AppColors.surfaceElevated, in: Circle())
                    .overlay { Circle().strokeBorder(AppColors.border, lineWidth: 1) }
            }
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, AppSpacing.page)
        .padding(.vertical, AppSpacing.xs)
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
        } else if !env.home.hasContent {
            EmptyStateView(
                systemImage: "photo.on.rectangle.angled",
                title: "Start your movie collection",
                message: "Movie Box is a private library on this device. Import a poster from Photos or Files, and the title stays here.",
                actionTitle: "Import Movie Poster",
                action: { showImporter = true }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    if !env.network.isOnline {
                        OfflineView()
                    }
                    librarySummary
                    CinematicHero(items: env.home.heroItems)
                    if !env.home.popular.isEmpty {
                        PosterCarousel(title: "Recently Added", items: env.home.popular, seeAll: CatalogQuery(title: "Recently Added", source: .popular))
                    }
                    if !env.library.history.isEmpty {
                        PosterCarousel(title: "Recently Viewed", items: env.library.history.prefix(16).map(\.summary), seeAll: nil)
                    }
                    if !env.library.watched.isEmpty {
                        PosterCarousel(title: "Watched", items: env.library.watched.prefix(16).map(\.summary), seeAll: nil)
                    }
                    if !env.library.favorites.isEmpty {
                        PosterCarousel(title: "Favorites", items: env.library.favorites.prefix(16).map(\.summary), seeAll: nil)
                    }
                    if !env.library.watchlist.isEmpty {
                        PosterCarousel(title: "Watchlist", items: env.library.watchlist.prefix(16).map(\.summary), seeAll: nil)
                    }
                    if !env.home.forYou.isEmpty {
                        PosterCarousel(title: "For You", items: env.home.forYou, seeAll: CatalogQuery(title: "For You", source: .forYou, genreID: env.library.preferences.favoriteGenreIDs.first))
                    }
                    if env.ads.showsInline(sectionIndex: 3), env.home.hasContent {
                        AdInlineCard()
                    }
                    if !env.home.popularTV.isEmpty {
                        PosterCarousel(title: "Popular TV Shows", items: env.home.popularTV, seeAll: CatalogQuery(title: "Popular TV Shows", source: .popularTV))
                    }
                    if !env.home.nowPlaying.isEmpty {
                        PosterCarousel(title: "New Releases", items: env.home.nowPlaying, seeAll: CatalogQuery(title: "New Releases", source: .nowPlaying))
                    }
                    if !env.home.upcoming.isEmpty {
                        PosterCarousel(title: "Upcoming", items: env.home.upcoming, seeAll: CatalogQuery(title: "Upcoming", source: .upcoming))
                    }
                    if !env.home.topRated.isEmpty {
                        PosterCarousel(title: "Top Rated", items: env.home.topRated, seeAll: CatalogQuery(title: "Top Rated", source: .topRated))
                    }
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

    private var librarySummary: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(greeting)
                .font(AppTypography.section)
                .foregroundStyle(AppColors.textPrimary)
            Text(shelfLine)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.horizontal, AppSpacing.page)
        .accessibilityElement(children: .combine)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var shelfLine: String {
        let count = env.imports.movies.count
        switch count {
        case 0: return "Your private library, stored on this device"
        case 1: return "1 title, stored on this device"
        default: return "\(count) titles, stored on this device"
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
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, AppSpacing.md)
                                .frame(minHeight: AppSpacing.touch)
                                .background(AppColors.surface, in: Capsule())
                                .overlay { Capsule().strokeBorder(AppColors.border, lineWidth: 1) }
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
