import SwiftUI

struct TVDetailView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    let showID: Int
    @State private var model: TVDetailViewModel?
    @State private var shareText: SharePayload?

    var body: some View {
        Group {
            if let model { content(model) } else { DetailSkeleton() }
        }
        .background(AppColors.background)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task {
            if model == nil { model = TVDetailViewModel(showID: showID) }
            await model?.load(env)
        }
    }

    @ViewBuilder
    private func content(_ model: TVDetailViewModel) -> some View {
        if model.isLoading && model.detail == nil {
            DetailSkeleton()
        } else if let message = model.errorMessage, model.detail == nil {
            NetworkErrorView(message: message) {
                Task { await model.load(env) }
            }
        } else if let show = model.detail {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    if !env.network.isOnline {
                        OfflineView()
                    }
                    header(show)
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        HStack(spacing: AppSpacing.sm) {
                            if let url = model.trailer?.youtubeURL {
                                Button {
                                    openURL(url)
                                } label: {
                                    PrimaryButtonLabel(title: "Watch Trailer", systemImage: "play.fill")
                                }
                                .buttonStyle(PressScaleStyle())
                            }
                            WatchlistButton(isSaved: env.library.watchlistKeys.contains(show.summary.libraryKey), prominent: true) {
                                env.library.toggleWatchlist(show.summary)
                            }
                        }
                        WorthWatchingPanel(average: show.voteAverage, voteCount: show.voteCount)
                        Text(show.overview.isEmpty ? "No overview has been published." : show.overview)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textSecondary)
                        if let credits = model.credits, !credits.cast.isEmpty {
                            Text("Cast")
                                .font(AppTypography.section)
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: AppSpacing.md) {
                                    ForEach(credits.cast.prefix(16)) { person in
                                        NavigationLink(value: AppRoute.person(id: person.id)) {
                                            ActorCard(name: person.name, role: person.character, profilePath: person.profilePath, seed: person.id)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        seasons(model, show: show)
                        if !model.similar.isEmpty {
                            PosterCarousel(title: "Similar Shows", items: model.similar)
                                .padding(.horizontal, -AppSpacing.page)
                        }
                    }
                    .padding(.horizontal, AppSpacing.page)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .ignoresSafeArea(edges: .top)
            .overlay(alignment: .top) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Back")
                    Spacer()
                    FavoriteButton(isFavorite: env.library.favoriteKeys.contains(show.summary.libraryKey)) {
                        env.library.toggleFavorite(show.summary)
                    }
                }
                .padding(.horizontal, AppSpacing.sm)
            }
            .sheet(item: $shareText) { ShareSheet(items: [$0.text]) }
        }
    }

    private func header(_ show: TVDetail) -> some View {
        ZStack(alignment: .bottomLeading) {
            CachedAsyncImage(
                url: ImageService().url(path: show.backdropPath ?? show.posterPath, size: .backdropLarge),
                maxPixel: 1400,
                seed: show.id,
                accessibilityLabel: "\(show.name) backdrop"
            )
            .frame(height: 320)
            .frame(maxWidth: .infinity)
            .clipped()
            LinearGradient(colors: [.clear, AppColors.background], startPoint: .top, endPoint: .bottom)
            HStack(alignment: .bottom, spacing: AppSpacing.md) {
                CachedAsyncImage(
                    url: ImageService().url(path: show.posterPath, size: .large),
                    maxPixel: 500,
                    seed: show.id,
                    accessibilityLabel: "\(show.name) poster"
                )
                .frame(width: 104, height: 156)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                VStack(alignment: .leading, spacing: 6) {
                    Text(show.name)
                        .font(AppTypography.heroTitle)
                        .foregroundStyle(AppColors.textPrimary)
                    HStack {
                        RatingBadge(score: show.voteAverage)
                        Text(Formatters.mediumDate(show.firstAirDate))
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Text(show.genreLine)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, AppSpacing.page)
        }
    }

    private func seasons(_ model: TVDetailViewModel, show: TVDetail) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Seasons")
                .font(AppTypography.section)
                .foregroundStyle(AppColors.textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(show.orderedSeasons) { season in
                        GenreChip(title: season.displayName, isSelected: model.selectedSeason == season.seasonNumber) {
                            Task { await model.selectSeason(season.seasonNumber, env: env) }
                        }
                    }
                }
            }
            if model.isLoadingEpisodes && model.episodes.isEmpty {
                SkeletonBone(height: 72)
            } else if model.episodes.isEmpty {
                Text("No episodes are listed for this season.")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(model.episodes) { episode in
                        episodeRow(episode, model: model)
                    }
                }
            }
        }
    }

    private func episodeRow(_ episode: Episode, model: TVDetailViewModel) -> some View {
        let watched = env.library.isEpisodeWatched(showID: showID, season: model.selectedSeason, episode: episode.episodeNumber)
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Episode \(episode.episodeNumber)")
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.accent)
                    Text(episode.name)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.textPrimary)
                    HStack(spacing: AppSpacing.xs) {
                        Text(Formatters.mediumDate(episode.airDate))
                        Text(Formatters.runtime(episode.runtime))
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                Button {
                    env.library.toggleEpisode(showID: showID, season: model.selectedSeason, episode: episode.episodeNumber)
                } label: {
                    Image(systemName: watched ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(watched ? AppColors.positive : AppColors.textSecondary)
                        .frame(width: AppSpacing.touch, height: AppSpacing.touch)
                }
                .accessibilityLabel(watched ? "Mark episode unwatched" : "Mark episode watched")
            }
            if !episode.overview.isEmpty {
                Text(episode.overview)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(4)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }
}
