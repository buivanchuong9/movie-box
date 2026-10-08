import SwiftUI

struct SearchView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showImporter = false
    @State private var showFilters = false
    @State private var showSort = false
    @State private var showPremium = false
    @State private var draft = MediaFilters()
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Search")
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.page)
                .accessibilityAddTraits(.isHeader)

            SearchBar(text: queryBinding, onCancel: cancel, onSubmit: {
                env.library.addSearch(env.searchModel.query)
                focused = false
            })
            .padding(.horizontal, AppSpacing.page)
            .focused($focused)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(SearchScope.allCases) { scope in
                        GenreChip(title: scope.title, isSelected: env.searchModel.scope == scope) {
                            Task { await env.searchModel.changeScope(scope) }
                        }
                    }
                    GenreChip(title: "Filter", isSelected: env.searchModel.filters.isActive) {
                        draft = env.searchModel.filters
                        showFilters = true
                    }
                    GenreChip(title: env.searchModel.sort.title, isSelected: env.searchModel.sort != .popularity) {
                        showSort = true
                    }
                }
                .padding(.horizontal, AppSpacing.page)
            }

            Group {
                if env.searchModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    suggestions
                } else if env.searchModel.isLoading && env.searchModel.hits.isEmpty {
                    searchSkeleton
                } else if let message = env.searchModel.errorMessage, env.searchModel.hits.isEmpty {
                    NetworkErrorView(message: message) {
                        env.searchModel.updateQuery(env.searchModel.query)
                    }
                } else if env.searchModel.hits.isEmpty {
                    EmptyStateView(
                        systemImage: "magnifyingglass",
                        title: "No matches",
                        message: "Try another title from the movies you imported."
                    )
                } else {
                    results
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppColors.background)
        .toolbar(.hidden, for: .navigationBar)
        .scrollDismissesKeyboard(.immediately)
        .movieImporter(isPresented: $showImporter)
        .task { await env.searchModel.loadTrendingIfNeeded() }
        .sheet(isPresented: $showFilters) {
            FilterSheet(
                filters: $draft,
                advancedLocked: !env.entitlements.isPremium,
                onLocked: { showFilters = false; showPremium = true },
                onApply: { filters in
                    Task { await env.searchModel.apply(filters: filters, sort: env.searchModel.sort) }
                }
            )
        }
        .sheet(isPresented: $showSort) {
            SortSheet(sort: sortBinding) { sort in
                Task { await env.searchModel.apply(filters: env.searchModel.filters, sort: sort) }
            }
        }
        .sheet(isPresented: $showPremium) {
            NavigationStack { PremiumView() }
        }
    }

    private var queryBinding: Binding<String> {
        Binding(
            get: { env.searchModel.query },
            set: { env.searchModel.updateQuery($0) }
        )
    }

    private var sortBinding: Binding<SortOption> {
        Binding(
            get: { env.searchModel.sort },
            set: { env.searchModel.sort = $0 }
        )
    }

    private func cancel() {
        env.searchModel.updateQuery("")
        focused = false
    }

    private var suggestions: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                if !env.library.searches.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("Recent")
                                .font(AppTypography.section)
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer()
                            Button("Clear") { env.library.clearSearches() }
                                .font(AppTypography.captionBold)
                                .foregroundStyle(AppColors.accent)
                                .frame(minHeight: AppSpacing.touch)
                        }
                        ForEach(env.library.searches) { search in
                            Button {
                                env.searchModel.updateQuery(search.query)
                                env.library.addSearch(search.query)
                            } label: {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundStyle(AppColors.textTertiary)
                                    Text(search.query)
                                        .foregroundStyle(AppColors.textPrimary)
                                    Spacer()
                                }
                                .frame(minHeight: AppSpacing.touch)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if env.searchModel.trending.isEmpty {
                    EmptyStateView(
                        systemImage: "photo.on.rectangle.angled",
                        title: "Add your movies",
                        message: "Import posters from your photo library or from image files.",
                        actionTitle: "Import",
                        action: { showImporter = true }
                    )
                } else {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Your Movies")
                            .font(AppTypography.section)
                            .foregroundStyle(AppColors.textPrimary)
                        FlowLayout(spacing: AppSpacing.xs) {
                            ForEach(env.searchModel.trending.prefix(8)) { media in
                                GenreChip(title: media.title) {
                                    env.searchModel.updateQuery(media.title)
                                    env.library.addSearch(media.title)
                                }
                            }
                        }
                    }
                }
            }
            .padding(AppSpacing.page)
        }
    }

    private var searchSkeleton: some View {
        ScrollView {
            VStack(spacing: AppSpacing.sm) {
                ForEach(0..<6, id: \.self) { _ in
                    HStack(spacing: AppSpacing.sm) {
                        RoundedRectangle(cornerRadius: AppRadius.sm).fill(AppColors.elevated).frame(width: 64, height: 96).modifier(ShimmerModifier())
                        VStack(alignment: .leading, spacing: 8) {
                            SkeletonBone(height: 14)
                            SkeletonBone(height: 12).frame(width: 80)
                        }
                    }
                }
            }
            .padding(AppSpacing.page)
        }
        .accessibilityLabel("Loading search results")
    }

    private var results: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.sm) {
                if !env.network.isOnline {
                    OfflineView()
                }
                ForEach(env.searchModel.hits) { hit in
                    switch hit {
                    case .media(let media):
                        NavigationLink(value: AppRoute.media(media)) {
                            CompactMovieCard(media: media)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded {
                            MediaMemory.shared.store(media)
                            env.library.addSearch(env.searchModel.query)
                        })
                    case .person(let person):
                        NavigationLink(value: AppRoute.person(id: person.id)) {
                            personRow(person)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if env.searchModel.canLoadMore {
                    ProgressView()
                        .tint(AppColors.accent)
                        .frame(maxWidth: .infinity, minHeight: AppSpacing.touch)
                        .onAppear { Task { await env.searchModel.loadMore() } }
                }
            }
            .padding(.horizontal, AppSpacing.page)
            .padding(.bottom, AppSpacing.lg)
        }
    }

    private func personRow(_ person: PersonSummary) -> some View {
        HStack(spacing: AppSpacing.sm) {
            CachedAsyncImage(
                url: ImageService().url(path: person.profilePath, size: .profile),
                maxPixel: 200,
                seed: person.id,
                accessibilityLabel: "\(person.name) profile"
            )
            .frame(width: 54, height: 54)
            .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                Text(person.knownForDepartment ?? "Person")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                if !person.knownFor.isEmpty {
                    Text(person.knownFor)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .frame(minHeight: AppSpacing.touch)
        .accessibilityElement(children: .combine)
    }
}
