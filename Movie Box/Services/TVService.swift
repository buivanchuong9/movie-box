import Foundation

protocol TVServiceProtocol {
    func popular(page: Int) async throws -> PagedResult<MediaSummary>
    func topRated(page: Int) async throws -> PagedResult<MediaSummary>
    func trending(page: Int) async throws -> PagedResult<MediaSummary>
    func details(id: Int) async throws -> TVDetail
    func credits(id: Int) async throws -> CreditsResponse
    func videos(id: Int) async throws -> [MediaVideo]
    func reviews(id: Int, page: Int) async throws -> PagedResult<MovieReview>
    func similar(id: Int, page: Int) async throws -> PagedResult<MediaSummary>
    func season(id: Int, season: Int) async throws -> TVSeasonDetail
}

final class TVService: TVServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func popular(page: Int) async throws -> PagedResult<MediaSummary> {
        try await loadPage(.popularTV(page: page))
    }

    func topRated(page: Int) async throws -> PagedResult<MediaSummary> {
        try await loadPage(.topRatedTV(page: page))
    }

    func trending(page: Int) async throws -> PagedResult<MediaSummary> {
        try await loadPage(.trendingTV(page: page))
    }

    func details(id: Int) async throws -> TVDetail {
        try await client.get(.tv(id: id))
    }

    func credits(id: Int) async throws -> CreditsResponse {
        try await client.get(.tvCredits(id: id))
    }

    func videos(id: Int) async throws -> [MediaVideo] {
        let list: VideoList = try await client.get(.tvVideos(id: id))
        return list.results
    }

    func reviews(id: Int, page: Int) async throws -> PagedResult<MovieReview> {
        let list: ReviewList = try await client.get(.tvReviews(id: id, page: page))
        let items = list.results.filter { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return PagedResult(page: list.page, totalPages: max(list.totalPages, 1), totalResults: list.totalResults, items: items)
    }

    func similar(id: Int, page: Int) async throws -> PagedResult<MediaSummary> {
        try await loadPage(.tvSimilar(id: id, page: page))
    }

    func season(id: Int, season: Int) async throws -> TVSeasonDetail {
        try await client.get(.tvSeason(id: id, season: season))
    }

    private func loadPage(_ endpoint: APIEndpoint) async throws -> PagedResult<MediaSummary> {
        let payload: PagedPayload<MediaSummary> = try await client.get(endpoint)
        let items = payload.results.map { $0.setting(kind: .tv) }.filter { !$0.isAdult }
        return PagedResult(page: payload.page, totalPages: payload.totalPages, totalResults: payload.totalResults, items: items)
    }
}
