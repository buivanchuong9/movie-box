import SwiftUI

struct DiscoverView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showFilters = false
    @State private var showPremium = false
    @State private var draft = MediaFilters()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Discover")
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.page)
                .padding(.bottom, AppSpacing.sm)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(DiscoverMode.allCases) { mode in
                        GenreChip(title: mode.title, isSelected: env.discover.mode == mode && !env.discover.filters.isActive) {
                            Task { await env.discover.select(mode) }
                        }
                    }
                    GenreChip(title: "Filters", isSelected: env.discover.filters.isActive) {
                        draft = env.discover.filters
                        showFilters = true
                    }
                }
                .padding(.horizontal, AppSpacing.page)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(GenreCatalog.featured) { genre in
                        GenreChip(title: genre.name, isSelected: env.discover.filters.genreID == genre.id) {
                            var filters = env.discover.filters
                            filters.genreID = filters.genreID == genre.id ? nil : genre.id
                            Task { await env.discover.apply(filters) }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.vertical, AppSpacing.sm)
            }

            yearRow

            Group {
                if env.discover.isLoading && env.discover.items.isEmpty {
                    GridSkeleton()
                } else if let message = env.discover.errorMessage, env.discover.items.isEmpty {
                    if env.discover.needsAPIKey {
                        EmptyStateView(
                            systemImage: "film",
                            title: "Movie data is unavailable",
                            message: "Movie data is unavailable right now.",
                            actionTitle: "Try Again",
                            action: { Task { await env.discover.reload() } }
                        )
                    } else if !env.network.isOnline {
                        EmptyStateView(
                            systemImage: "wifi.slash",
                            title: "You're offline",
                            message: "This list isn't saved on this device yet.",
                            actionTitle: "Try Again",
                            action: { Task { await env.discover.reload() } }
                        )
                    } else {
                        NetworkErrorView(message: message) {
                            Task { await env.discover.reload() }
                        }
                    }
                } else if env.discover.items.isEmpty {
                    EmptyStateView(
                        systemImage: "film",
                        title: "No titles match",
                        message: "Try another genre, year, or sort."
                    )
                } else {
                    MediaGrid(items: env.discover.items, showsAds: true) {
                        Task { await env.discover.loadMore() }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppColors.background)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            if !env.network.isOnline, !env.discover.items.isEmpty {
                OfflineView()
            }
        }
        .refreshable { await env.discover.reload() }
        .task { await env.discover.loadIfNeeded() }
        .sheet(isPresented: $showFilters) {
            FilterSheet(
                filters: $draft,
                advancedLocked: !env.entitlements.isPremium,
                onLocked: { showFilters = false; showPremium = true },
                onApply: { filters in
                    Task { await env.discover.apply(filters) }
                }
            )
        }
        .sheet(isPresented: $showPremium) {
            NavigationStack { PremiumView() }
        }
    }

    private var yearRow: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Years")
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.page)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(YearCatalog.recent.prefix(12), id: \.self) { year in
                        GenreChip(title: String(year), isSelected: env.discover.filters.year == year) {
                            var filters = env.discover.filters
                            filters.year = filters.year == year ? nil : year
                            Task { await env.discover.apply(filters) }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.page)
            }
            countryRow
        }
        .padding(.bottom, AppSpacing.sm)
    }

    private var countryRow: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text("Countries")
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.textSecondary)
                if !env.entitlements.isPremium {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(AppColors.accent)
                }
            }
            .padding(.horizontal, AppSpacing.page)
            .padding(.top, AppSpacing.xs)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(CountryOption.common.prefix(10)) { country in
                        GenreChip(title: country.name, isSelected: env.discover.filters.country == country.code) {
                            guard env.entitlements.isPremium else {
                                showPremium = true
                                return
                            }
                            var filters = env.discover.filters
                            filters.country = filters.country == country.code ? nil : country.code
                            Task { await env.discover.apply(filters) }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.page)
            }
        }
    }
}

struct CatalogView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var model: CatalogViewModel?

    let query: CatalogQuery

    var body: some View {
        Group {
            if let model {
                if model.isLoading && model.items.isEmpty {
                    GridSkeleton()
                } else if let message = model.errorMessage, model.items.isEmpty {
                    NetworkErrorView(message: message) {
                        Task { await model.reload() }
                    }
                } else {
                    MediaGrid(items: model.items) {
                        Task { await model.loadMore() }
                    }
                }
            } else {
                GridSkeleton()
            }
        }
        .background(AppColors.background)
        .navigationTitle(query.title)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await model?.reload() }
        .task {
            if model == nil {
                model = CatalogViewModel(query: query, movies: env.movies, television: env.tv)
            }
            await model?.load()
        }
    }
}
