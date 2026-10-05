import Foundation

protocol SearchServiceProtocol {
    func search(query: String, scope: SearchScope, page: Int) async throws -> PagedResult<SearchHit>
    func trendingTitles(page: Int) async throws -> [MediaSummary]
}

final class SearchService: SearchServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func search(query: String, scope: SearchScope, page: Int) async throws -> PagedResult<SearchHit> {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return PagedResult(page: 1, totalPages: 1, totalResults: 0, items: [])
        }
        switch scope {
        case .all:
            return try await hits(.searchMulti(query: trimmed, page: page))
        case .movies:
            return try await mediaHits(.searchMovies(query: trimmed, page: page), kind: .movie)
        case .tv:
            return try await mediaHits(.searchTV(query: trimmed, page: page), kind: .tv)
        case .people:
            return try await people(.searchPeople(query: trimmed, page: page))
        }
    }

    func trendingTitles(page: Int) async throws -> [MediaSummary] {
        let payload: PagedPayload<MediaSummary> = try await client.get(.trendingMovies(page: page))
        return payload.results.map { $0.setting(kind: .movie) }.filter { !$0.isAdult }
    }

    private func hits(_ endpoint: APIEndpoint) async throws -> PagedResult<SearchHit> {
        let payload: PagedPayload<MultiSearchItem> = try await client.get(endpoint)
        let items = payload.results.compactMap { $0.searchHit() }.filter { hit in
            if case .media(let media) = hit { return !media.isAdult }
            return true
        }
        return PagedResult(page: payload.page, totalPages: payload.totalPages, totalResults: payload.totalResults, items: items)
    }

    private func mediaHits(_ endpoint: APIEndpoint, kind: MediaKind) async throws -> PagedResult<SearchHit> {
        let payload: PagedPayload<MediaSummary> = try await client.get(endpoint)
        let items = payload.results
            .map { $0.setting(kind: kind) }
            .filter { !$0.isAdult }
            .map { SearchHit.media($0) }
        return PagedResult(page: payload.page, totalPages: payload.totalPages, totalResults: payload.totalResults, items: items)
    }

    private func people(_ endpoint: APIEndpoint) async throws -> PagedResult<SearchHit> {
        let payload: PagedPayload<PersonSearchDTO> = try await client.get(endpoint)
        let items = payload.results.map { SearchHit.person($0.summary) }
        return PagedResult(page: payload.page, totalPages: payload.totalPages, totalResults: payload.totalResults, items: items)
    }
}

private struct PersonSearchDTO: Decodable {
    let id: Int
    let name: String
    let profilePath: String?
    let knownForDepartment: String?
    let knownFor: [MultiSearchItem.KnownForTitle]

    var summary: PersonSummary {
        PersonSummary(
            id: id,
            name: name,
            profilePath: profilePath,
            knownForDepartment: knownForDepartment,
            knownFor: knownFor.compactMap { $0.title ?? $0.name }.prefix(2).joined(separator: " · ")
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, name
        case profilePath = "profile_path"
        case knownForDepartment = "known_for_department"
        case knownFor = "known_for"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown"
        profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
        knownForDepartment = try container.decodeIfPresent(String.self, forKey: .knownForDepartment)
        knownFor = try container.decodeIfPresent([MultiSearchItem.KnownForTitle].self, forKey: .knownFor) ?? []
    }
}
