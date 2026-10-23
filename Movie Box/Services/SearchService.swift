import Foundation

protocol SearchServiceProtocol {
    func search(query: String, scope: SearchScope, page: Int) async throws -> PagedResult<SearchHit>
    func trendingTitles(page: Int) async throws -> [MediaSummary]
}
