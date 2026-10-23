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
