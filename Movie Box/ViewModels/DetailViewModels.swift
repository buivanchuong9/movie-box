import Foundation
import Observation

@MainActor
@Observable
final class MovieDetailViewModel {
    let movieID: Int
    var detail: MovieDetail?
    var credits: CreditsResponse?
    var trailer: MediaVideo?
    var reviews: [MovieReview] = []
    var reviewPage = 0
    var reviewTotalPages = 1
    var reviewsFailed = false
    var isLoadingMoreReviews = false
    var similar: [MediaSummary] = []
    var isLoading = true
    var errorMessage: String?
    private var hasLoaded = false
    private let reviewPageLimit = 5

    init(movieID: Int) {
        self.movieID = movieID
    }

    var canLoadMoreReviews: Bool {
        reviewPage > 0 && reviewPage < reviewTotalPages && reviewPage < reviewPageLimit && !isLoadingMoreReviews && !reviewsFailed
    }

    func load(_ env: AppEnvironment) async {
        guard !hasLoaded else { return }
        hasLoaded = true
        isLoading = detail == nil
        hydrate(env)
        if await loadDetail(env) == false {
            hasLoaded = false
            isLoading = false
            return
        }
        if Task.isCancelled { hasLoaded = false; isLoading = false; return }
        await loadCredits(env)
        if Task.isCancelled { hasLoaded = false; isLoading = false; return }
        await loadVideos(env)
        if Task.isCancelled { hasLoaded = false; isLoading = false; return }
        await loadReviews(env, reset: true)
        if Task.isCancelled { hasLoaded = false; isLoading = false; return }
        await loadSimilar(env)
        isLoading = false
        if detail == nil {
            hasLoaded = false
        }
        if let detail {
            let director = credits?.directors.first?.id
            let cast = credits?.cast.prefix(8).map(\.id) ?? []
            env.library.recordView(detail.summary, directorID: director, castIDs: Array(cast))
            env.ads.registerDetailVisit()
        }
    }

    func retryReviews(_ env: AppEnvironment) async {
        reviewsFailed = false
        await loadReviews(env, reset: true)
    }

    func loadMoreReviewsIfNeeded(currentID: String, env: AppEnvironment) async {
        guard canLoadMoreReviews, reviews.last?.id == currentID else { return }
        await loadReviews(env, reset: false)
    }

    private func hydrate(_ env: AppEnvironment) {
        if detail == nil, let cached: MovieDetail = env.library.loadPayload(MovieDetail.self, key: "movie-\(movieID)") {
            detail = cached
        }
        if reviews.isEmpty, let cached: CachedReviews = env.library.loadPayload(CachedReviews.self, key: "movie-reviews-\(movieID)") {
            reviews = cached.reviews
            reviewPage = cached.page
            reviewTotalPages = cached.totalPages
        }
        if similar.isEmpty, let cached: [MediaSummary] = env.library.loadPayload([MediaSummary].self, key: "movie-similar-\(movieID)") {
            similar = cached
        }
    }

    private func loadDetail(_ env: AppEnvironment) async -> Bool {
        do {
            let loaded = try await env.movies.details(id: movieID)
            detail = loaded
            env.library.storePayload(loaded, key: "movie-\(loaded.id)")
            errorMessage = nil
            return true
        } catch is CancellationError {
            return false
        } catch let error as AppError where error == .cancelled {
            return false
        } catch {
            if detail == nil {
                errorMessage = (error as? AppError) == .offline || !env.network.isOnline
                    ? "You're offline"
                    : error.localizedDescription
            }
            return true
        }
    }

    private func loadCredits(_ env: AppEnvironment) async {
        credits = try? await env.movies.credits(id: movieID)
    }

    private func loadVideos(_ env: AppEnvironment) async {
        let videos = (try? await env.movies.videos(id: movieID)) ?? []
        trailer = env.trailers.bestTrailer(from: videos)
    }

    private func loadReviews(_ env: AppEnvironment, reset: Bool) async {
        if reset {
            reviewsFailed = false
        } else {
            isLoadingMoreReviews = true
        }
        defer { isLoadingMoreReviews = false }
        let page = reset ? 1 : reviewPage + 1
        do {
            let result = try await env.movies.reviews(id: movieID, page: page)
            if reset {
                reviews = result.items
            } else {
                let existing = Set(reviews.map(\.id))
                reviews.append(contentsOf: result.items.filter { !existing.contains($0.id) })
            }
            reviewPage = result.page
            reviewTotalPages = result.totalPages
            reviewsFailed = false
            env.library.storePayload(
                CachedReviews(reviews: reviews, page: reviewPage, totalPages: reviewTotalPages),
                key: "movie-reviews-\(movieID)"
            )
        } catch is CancellationError {
            return
        } catch let error as AppError where error == .cancelled {
            return
        } catch {
            if reviews.isEmpty {
                reviewsFailed = true
            }
        }
    }

    private func loadSimilar(_ env: AppEnvironment) async {
        if let result = try? await env.movies.similar(id: movieID, page: 1) {
            similar = result.items
            env.library.storePayload(result.items, key: "movie-similar-\(movieID)")
        }
    }
}

@MainActor
@Observable
final class TVDetailViewModel {
    let showID: Int
    var detail: TVDetail?
    var credits: CreditsResponse?
    var trailer: MediaVideo?
    var reviews: [MovieReview] = []
    var similar: [MediaSummary] = []
    var episodes: [Episode] = []
    var selectedSeason = 1
    var isLoading = true
    var isLoadingEpisodes = false
    var errorMessage: String?
    private var hasLoaded = false

    init(showID: Int) {
        self.showID = showID
    }

    func load(_ env: AppEnvironment) async {
        guard !hasLoaded else { return }
        hasLoaded = true
        if detail == nil, let cached: TVDetail = env.library.loadPayload(TVDetail.self, key: "tv-\(showID)") {
            detail = cached
        }
        do {
            let loaded = try await env.tv.details(id: showID)
            detail = loaded
            env.library.storePayload(loaded, key: "tv-\(loaded.id)")
            credits = try? await env.tv.credits(id: showID)
            trailer = env.trailers.bestTrailer(from: (try? await env.tv.videos(id: showID)) ?? [])
            reviews = (try? await env.tv.reviews(id: showID, page: 1))?.items ?? []
            similar = (try? await env.tv.similar(id: showID, page: 1))?.items ?? []
            let director = credits?.directors.first?.id
            let cast = Array((credits?.cast.prefix(8).map(\.id)) ?? [])
            env.library.recordView(loaded.summary, directorID: director, castIDs: cast)
            env.ads.registerDetailVisit()
            if let first = loaded.orderedSeasons.first(where: { $0.seasonNumber > 0 }) ?? loaded.orderedSeasons.first {
                selectedSeason = first.seasonNumber
                await loadSeason(env)
            }
            errorMessage = nil
        } catch is CancellationError {
            hasLoaded = false
        } catch {
            if detail == nil {
                errorMessage = error.localizedDescription
                hasLoaded = false
            }
        }
        isLoading = false
    }

    func selectSeason(_ season: Int, env: AppEnvironment) async {
        guard selectedSeason != season || episodes.isEmpty else { return }
        selectedSeason = season
        await loadSeason(env)
    }

    private func loadSeason(_ env: AppEnvironment) async {
        isLoadingEpisodes = true
        episodes = (try? await env.tv.season(id: showID, season: selectedSeason).episodes) ?? []
        isLoadingEpisodes = false
    }
}

@MainActor
@Observable
final class PersonDetailViewModel {
    let personID: Int
    var person: PersonDetail?
    var isLoading = true
    var errorMessage: String?
    private var hasLoaded = false

    init(personID: Int) {
        self.personID = personID
    }

    func load(_ env: AppEnvironment) async {
        guard !hasLoaded else { return }
        hasLoaded = true
        do {
            person = try await env.people.details(id: personID)
            errorMessage = nil
        } catch is CancellationError {
            hasLoaded = false
        } catch {
            errorMessage = error.localizedDescription
            hasLoaded = false
        }
        isLoading = false
    }
}
