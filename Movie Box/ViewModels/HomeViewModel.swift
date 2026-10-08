import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private let movies: any MovieServiceProtocol
    private let television: any TVServiceProtocol
    private let recommendations: RecommendationEngine

    var trending: [MediaSummary] = []
    var popular: [MediaSummary] = []
    var popularTV: [MediaSummary] = []
    var nowPlaying: [MediaSummary] = []
    var upcoming: [MediaSummary] = []
    var topRated: [MediaSummary] = []
    var forYou: [MediaSummary] = []
    var trendingForYou: [MediaSummary] = []
    var becauseYouWatched: [MediaSummary] = []
    var becauseTitle = ""
    var youMayAlsoLike: [MediaSummary] = []
    var isLoading = false
    var errorMessage: String?
    var needsAPIKey = false
    private var hasLoaded = false
    private var recommendationTask: Task<Void, Never>?

    init(movies: any MovieServiceProtocol, television: any TVServiceProtocol, recommendations: RecommendationEngine) {
        self.movies = movies
        self.television = television
        self.recommendations = recommendations
    }

    var heroItems: [MediaSummary] {
        let featured = trending.filter { $0.backdropPath != nil }
        let source = featured.isEmpty ? trending : featured
        return Array(source.prefix(6))
    }

    var hasContent: Bool {
        !trending.isEmpty || !popular.isEmpty || !popularTV.isEmpty
    }

    func loadIfNeeded(signals: RecommendationSignals) async {
        guard !hasLoaded else {
            await applyRecommendations(signals)
            return
        }
        await reloadNow(signals: signals)
    }

    func reload(signals: RecommendationSignals) async {
        await RequestCache.$bypassFreshness.withValue(true) {
            await self.reloadNow(signals: signals)
        }
    }

    private func reloadNow(signals: RecommendationSignals) async {
        if trending.isEmpty { isLoading = true }
        errorMessage = nil
        needsAPIKey = false

        let results = await (
            outcome { try await self.movies.trending(page: 1) },
            outcome { try await self.movies.popular(page: 1) },
            outcome { try await self.television.popular(page: 1) },
            outcome { try await self.movies.nowPlaying(page: 1) },
            outcome { try await self.movies.upcoming(page: 1) },
            outcome { try await self.movies.topRated(page: 1) }
        )
        if Task.isCancelled { return }

        trending = results.0.value?.items ?? trending
        popular = results.1.value?.items ?? popular
        popularTV = results.2.value?.items ?? popularTV
        nowPlaying = results.3.value?.items ?? nowPlaying
        upcoming = results.4.value?.items ?? upcoming
        topRated = results.5.value?.items ?? topRated

        let failures = [results.0, results.1, results.2, results.3, results.4, results.5].compactMap(\.error)
        if !hasContent, let failure = failures.first {
            needsAPIKey = (failure as? AppError) == .missingAPIKey
            errorMessage = AppError.userMessage(for: failure)
        } else if !failures.isEmpty && !hasContent {
            errorMessage = AppError.offline.localizedDescription
        }
        hasLoaded = hasContent || errorMessage != nil
        isLoading = false
        await applyRecommendations(signals)
    }

    func applyRecommendations(_ signals: RecommendationSignals) async {
        recommendationTask?.cancel()
        let task = Task { await self.score(signals) }
        recommendationTask = task
        await task.value
    }

    private func score(_ signals: RecommendationSignals) async {
        let pool = trending + popular + topRated + nowPlaying + upcoming
        var seen = Set<String>()
        let unique = pool.filter { seen.insert($0.libraryKey).inserted }
        forYou = recommendations.forYou(candidates: unique, signals: signals)
        trendingForYou = recommendations.trendingForYou(trending: trending, signals: signals)

        guard signals.isPremium, !Task.isCancelled else {
            becauseYouWatched = []
            becauseTitle = ""
            youMayAlsoLike = []
            return
        }

        if let source = signals.recentlyViewed.first ?? signals.watched.first {
            becauseTitle = source.title
            if let similar = try? await similar(to: source) {
                becauseYouWatched = recommendations.becauseYouWatched(similar: similar, source: source, signals: signals).map(\.media)
            }
        } else {
            becauseYouWatched = []
            becauseTitle = ""
        }

        if let second = signals.watchlist.first ?? signals.recentlyViewed.dropFirst().first {
            youMayAlsoLike = (try? await similar(to: second)) ?? []
        } else {
            youMayAlsoLike = []
        }
    }

    private func similar(to media: MediaSummary) async throws -> [MediaSummary] {
        if media.mediaType == .tv {
            return try await television.similar(id: media.id, page: 1).items
        }
        return try await movies.similar(id: media.id, page: 1).items
    }

    private func outcome<T>(_ work: () async throws -> T) async -> (value: T?, error: Error?) {
        do {
            return (try await work(), nil)
        } catch is CancellationError {
            return (nil, nil)
        } catch {
            return (nil, error)
        }
    }
}
