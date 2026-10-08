import SwiftUI

struct MovieDetailView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.zoomNamespace) private var zoomNamespace
    let movieID: Int
    @State private var model: MovieDetailViewModel?
    @State private var shareText: SharePayload?

    var body: some View {
        Group {
            if let model {
                detail(model)
            } else {
                DetailSkeleton()
            }
        }
        .background(AppColors.background)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .matchedZoomDestination(id: "movie-\(movieID)", in: zoomNamespace)
        .task {
            if model == nil { model = MovieDetailViewModel(movieID: movieID) }
            await model?.load(env)
        }
    }

    @ViewBuilder
    private func detail(_ model: MovieDetailViewModel) -> some View {
        if model.isLoading && model.detail == nil {
            DetailSkeleton()
        } else if let message = model.errorMessage, model.detail == nil {
            EmptyStateView(
                systemImage: "wifi.exclamationmark",
                title: message == "You're offline" ? "You're offline" : "Something went wrong",
                message: message == "You're offline" ? "This movie isn't saved on this device yet." : message,
                actionTitle: "Try Again",
                action: {
                    Task {
                        model.isLoading = true
                        await model.load(env)
                    }
                }
            )
            .overlay(alignment: .topLeading) { backButton.padding() }
        } else if let movie = model.detail {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    if !env.network.isOnline {
                        OfflineView()
                    }
                    backdrop(movie)
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        actionRow(movie)
                        WorthWatchingPanel(average: movie.voteAverage, voteCount: movie.voteCount)
                        section("Overview") {
                            Text(movie.overview.isEmpty ? "No overview has been published." : movie.overview)
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        section("Rating") {
                            RatingView(average: movie.voteAverage, voteCount: movie.voteCount)
                        }
                        if let credits = model.credits, !credits.cast.isEmpty {
                            castRail(credits.cast)
                        }
                        if let credits = model.credits, !credits.directors.isEmpty || !credits.writers.isEmpty {
                            crewBlock(credits)
                        }
                        if model.trailer != nil {
                            trailerBlock(model.trailer, backdrop: movie.backdropPath, seed: movie.id)
                        }
                        reviewsBlock(model)
                        if !model.similar.isEmpty {
                            PosterCarousel(title: "Similar Movies", items: model.similar, seeAll: nil)
                                .padding(.horizontal, -AppSpacing.page)
                        }
                    }
                    .padding(.horizontal, AppSpacing.page)
                    .padding(.bottom, AppSpacing.xxl)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .ignoresSafeArea(edges: .top)
            .overlay(alignment: .top) { topBar(movie) }
            .sheet(item: $shareText) { ShareSheet(items: [$0.text]) }
        }
    }

    private func backdrop(_ movie: MovieDetail) -> some View {
        let url = ImageService().url(path: movie.backdropPath ?? movie.posterPath, size: .backdropLarge)
        return ZStack(alignment: .bottomLeading) {
            CachedAsyncImage(url: url, maxPixel: 1400, seed: movie.id, accessibilityLabel: "\(movie.title) backdrop")
                .frame(height: 340)
                .frame(maxWidth: .infinity)
                .clipped()
            LinearGradient(colors: [.clear, .clear, AppColors.background], startPoint: .top, endPoint: .bottom)
            HStack(alignment: .bottom, spacing: AppSpacing.md) {
                CachedAsyncImage(
                    url: ImageService().url(path: movie.posterPath, size: .large),
                    maxPixel: 600,
                    seed: movie.id,
                    accessibilityLabel: "\(movie.title) poster"
                )
                .frame(width: 112, height: 168)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .matchedZoomSource(id: "movie-\(movie.id)", in: zoomNamespace)

                VStack(alignment: .leading, spacing: 6) {
                    Text(movie.title)
                        .font(AppTypography.heroTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        RatingBadge(score: movie.voteAverage)
                        Text(movie.yearText)
                        Text(movie.runtimeText)
                    }
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.textSecondary)
                    if !movie.genreLine.isEmpty {
                        Text(movie.genreLine)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.page)
            .padding(.bottom, AppSpacing.sm)
        }
    }

    private func actionRow(_ movie: MovieDetail) -> some View {
        let summary = movie.summary
        return HStack(spacing: AppSpacing.sm) {
            if let url = model?.trailer?.youtubeURL {
                Button {
                    openURL(url)
                } label: {
                    PrimaryButtonLabel(title: "Watch Trailer", systemImage: "play.fill")
                }
                .buttonStyle(PressScaleStyle())
                .frame(maxWidth: .infinity)
                .accessibilityHint("Opens the official trailer")
            }

            WatchlistButton(isSaved: env.library.watchlistKeys.contains(summary.libraryKey), prominent: true) {
                env.library.toggleWatchlist(summary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func topBar(_ movie: MovieDetail) -> some View {
        HStack {
            backButton
            Spacer()
            Button {
                shareText = SharePayload(text: movie.summary.shareText)
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: AppSpacing.touch, height: AppSpacing.touch)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Share \(movie.title)")
            FavoriteButton(isFavorite: env.library.favoriteKeys.contains(movie.summary.libraryKey)) {
                env.library.toggleFavorite(movie.summary)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.top, 4)
    }

    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: AppSpacing.touch, height: AppSpacing.touch)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel("Back")
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppTypography.section)
                .foregroundStyle(AppColors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func castRail(_ cast: [CastMember]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Cast")
                .font(AppTypography.section)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.page)
                .accessibilityAddTraits(.isHeader)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: AppSpacing.md) {
                    ForEach(cast.prefix(18)) { person in
                        NavigationLink(value: AppRoute.person(id: person.id)) {
                            ActorCard(name: person.name, role: person.character, profilePath: person.profilePath, seed: person.id)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.page)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, -AppSpacing.page)
    }

    private func crewBlock(_ credits: CreditsResponse) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Crew")
                .font(AppTypography.section)
                .foregroundStyle(AppColors.textPrimary)
            if !credits.directors.isEmpty {
                labeledPeople("Director", people: credits.directors)
            }
            if !credits.writers.isEmpty {
                labeledPeople("Writers", people: credits.writers)
            }
        }
    }

    private func labeledPeople(_ title: String, people: [CrewMember]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textTertiary)
            ForEach(people, id: \.rowID) { person in
                NavigationLink(value: AppRoute.person(id: person.id)) {
                    HStack {
                        Text(person.name)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    .frame(minHeight: AppSpacing.touch)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func trailerBlock(_ trailer: MediaVideo?, backdrop: String?, seed: Int) -> some View {
        section("Trailer") {
            if let trailer, let url = trailer.youtubeURL {
                Button {
                    openURL(url)
                } label: {
                    ZStack {
                        CachedAsyncImage(
                            url: ImageService().url(path: backdrop, size: .backdrop),
                            maxPixel: 900,
                            seed: seed,
                            accessibilityLabel: trailer.name
                        )
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.white)
                            .shadow(radius: 8)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                }
                .buttonStyle(PressScaleStyle())
                .accessibilityLabel("Play \(trailer.name)")
            }
        }
    }

    @ViewBuilder
    private func reviewsBlock(_ model: MovieDetailViewModel) -> some View {
        section("Reviews") {
            Text("Individual audience reviews. Separate from the audience rating above.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
            if model.reviewsFailed && model.reviews.isEmpty {
                Text("Reviews are currently unavailable.")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                Button("Retry") {
                    Task { await model.retryReviews(env) }
                }
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.accent)
                .frame(minHeight: AppSpacing.touch, alignment: .leading)
            } else if model.reviews.isEmpty {
                Text("No reviews yet.")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(model.reviews) { review in
                        ReviewCard(review: review)
                    }
                    if model.canLoadMoreReviews {
                        Color.clear
                            .frame(height: 1)
                            .onAppear {
                                if let last = model.reviews.last?.id {
                                    Task { await model.loadMoreReviewsIfNeeded(currentID: last, env: env) }
                                }
                            }
                    }
                    if model.isLoadingMoreReviews {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
            }
        }
    }
}
