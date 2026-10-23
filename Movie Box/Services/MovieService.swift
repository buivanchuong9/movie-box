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
