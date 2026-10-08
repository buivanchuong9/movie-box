import SwiftUI

struct DiscoverView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showImporter = false
    @State private var showFilters = false
    @State private var showPremium = false
    @State private var draft = MediaFilters()

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Discover")
                    .font(AppTypography.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text("Browse your film library by mood, year, and origin.")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, AppSpacing.page)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(DiscoverMode.allCases) { mode in
                        GenreChip(title: mode.title, isSelected: env.discover.mode == mode && !env.discover.filters.isActive) {
                            Task { await env.discover.select(mode) }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.page)
            }

            filterControl
                .padding(.horizontal, AppSpacing.page)

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
                    discoverEmpty
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
        .movieImporter(isPresented: $showImporter)
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

    private var filterControl: some View {
        let count = env.discover.filters.activeCount
        return Button {
            draft = env.discover.filters
            showFilters = true
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "line.3.horizontal.decrease")
                Text(count == 0 ? "Filters" : "Filters · \(count)")
                    .lineLimit(1)
            }
            .font(AppTypography.captionBold)
            .foregroundStyle(count == 0 ? AppColors.textPrimary : AppColors.onAccent)
            .padding(.horizontal, AppSpacing.md)
            .frame(minHeight: AppSpacing.touch)
            .background(count == 0 ? AppColors.surface : AppColors.accentFill, in: Capsule())
            .overlay {
                Capsule().strokeBorder(count == 0 ? AppColors.separator : Color.clear, lineWidth: 1)
            }
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(count == 0 ? "Filters" : "Filters, \(count) active")
    }

    @ViewBuilder
    private var discoverEmpty: some View {
        if env.discover.filters.isActive {
            EmptyStateView(
                systemImage: "line.3.horizontal.decrease",
                title: "No matching titles",
                message: "Nothing in your library fits these filters.",
                actionTitle: "Reset Filters",
                action: {
                    Task { await env.discover.apply(MediaFilters()) }
                }
            )
        } else if env.imports.movies.isEmpty {
            EmptyStateView(
                systemImage: "film.stack",
                title: "Nothing to discover yet",
                message: "Import a few posters and your film library will show up here.",
                actionTitle: "Import Movies",
                action: { showImporter = true }
            )
        } else {
            EmptyStateView(
                systemImage: "film",
                title: "Nothing in \(env.discover.mode.title)",
                message: "Try another category, or import another title."
            )
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
