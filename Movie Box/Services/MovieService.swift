import Foundation

protocol MovieServiceProtocol {
    func trending(page: Int) async throws -> PagedResult<MediaSummary>
    func popular(page: Int) async throws -> PagedResult<MediaSummary>
    func topRated(page: Int) async throws -> PagedResult<MediaSummary>
    func nowPlaying(page: Int) async throws -> PagedResult<MediaSummary>
    func upcoming(page: Int) async throws -> PagedResult<MediaSummary>
    func details(id: Int) async throws -> MovieDetail
    func credits(id: Int) async throws -> CreditsResponse
    func videos(id: Int) async throws -> [MediaVideo]
    func reviews(id: Int, page: Int) async throws -> PagedResult<MovieReview>
    func similar(id: Int, page: Int) async throws -> PagedResult<MediaSummary>
    func discover(filters: MediaFilters, page: Int) async throws -> PagedResult<MediaSummary>
    func genres() async throws -> [Genre]
}

final class MovieService: MovieServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func trending(page: Int) async throws -> PagedResult<MediaSummary> {
        try await loadPage(.trendingMovies(page: page), kind: .movie)
    }

    func popular(page: Int) async throws -> PagedResult<MediaSummary> {
        try await loadPage(.popularMovies(page: page), kind: .movie)
    }

    func topRated(page: Int) async throws -> PagedResult<MediaSummary> {
        try await loadPage(.topRatedMovies(page: page), kind: .movie)
    }

    func nowPlaying(page: Int) async throws -> PagedResult<MediaSummary> {
        try await loadPage(.nowPlaying(page: page), kind: .movie)
    }

    func upcoming(page: Int) async throws -> PagedResult<MediaSummary> {
        try await loadPage(.upcoming(page: page), kind: .movie)
    }

    func details(id: Int) async throws -> MovieDetail {
        try await client.get(.movie(id: id))
    }

    func credits(id: Int) async throws -> CreditsResponse {
        try await client.get(.movieCredits(id: id))
    }

    func videos(id: Int) async throws -> [MediaVideo] {
        let list: VideoList = try await client.get(.movieVideos(id: id))
        return list.results
    }

    func reviews(id: Int, page: Int) async throws -> PagedResult<MovieReview> {
        let list: ReviewList = try await client.get(.movieReviews(id: id, page: page))
        let items = list.results.filter { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return PagedResult(page: list.page, totalPages: max(list.totalPages, 1), totalResults: list.totalResults, items: items)
    }

    func similar(id: Int, page: Int) async throws -> PagedResult<MediaSummary> {
        try await loadPage(.movieSimilar(id: id, page: page), kind: .movie)
    }

    func discover(filters: MediaFilters, page: Int) async throws -> PagedResult<MediaSummary> {
        try await loadPage(.discoverMovies(filters, page: page), kind: .movie)
    }

    func genres() async throws -> [Genre] {
        let list: GenreList = try await client.get(.movieGenres)
        return list.genres
    }

    private func loadPage(_ endpoint: APIEndpoint, kind: MediaKind) async throws -> PagedResult<MediaSummary> {
        let payload: PagedPayload<MediaSummary> = try await client.get(endpoint)
        let items = payload.results
            .map { $0.setting(kind: kind) }
            .filter { !$0.isAdult }
        return PagedResult(page: payload.page, totalPages: payload.totalPages, totalResults: payload.totalResults, items: items)
    }
}
