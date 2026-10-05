import Foundation

final class PreviewMovieService: MovieServiceProtocol {
    func trending(page: Int) async throws -> PagedResult<MediaSummary> { samplePage(SampleData.movies) }
    func popular(page: Int) async throws -> PagedResult<MediaSummary> { samplePage(SampleData.movies) }
    func topRated(page: Int) async throws -> PagedResult<MediaSummary> { samplePage(SampleData.movies.reversed()) }
    func nowPlaying(page: Int) async throws -> PagedResult<MediaSummary> { samplePage(Array(SampleData.movies.prefix(4))) }
    func upcoming(page: Int) async throws -> PagedResult<MediaSummary> { samplePage(Array(SampleData.movies.suffix(4))) }
    func details(id: Int) async throws -> MovieDetail {
        let title = SampleData.movies.first { $0.id == id }?.title ?? "Glass Harbor"
        let json = """
        {"id":\(id),"title":"\(title)","overview":"A preview synopsis for layout only.","vote_average":8.1,"vote_count":2400,"release_date":"2024-04-12","runtime":118,"genres":[{"id":18,"name":"Drama"},{"id":53,"name":"Thriller"}],"tagline":"Light finds the harbor."}
        """
        return try JSONDecoder().decode(MovieDetail.self, from: Data(json.utf8))
    }
    func credits(id: Int) async throws -> CreditsResponse { CreditsResponse(cast: [], crew: []) }
    func videos(id: Int) async throws -> [MediaVideo] { [] }
    func reviews(id: Int, page: Int) async throws -> PagedResult<MovieReview> {
        PagedResult(page: 1, totalPages: 1, totalResults: 0, items: [])
    }
    func similar(id: Int, page: Int) async throws -> PagedResult<MediaSummary> { samplePage(SampleData.movies) }
    func discover(filters: MediaFilters, page: Int) async throws -> PagedResult<MediaSummary> { samplePage(SampleData.movies) }
    func genres() async throws -> [Genre] { GenreCatalog.featured }
    private func samplePage(_ items: [MediaSummary]) -> PagedResult<MediaSummary> {
        PagedResult(page: 1, totalPages: 1, totalResults: items.count, items: items)
    }
}

final class PreviewTVService: TVServiceProtocol {
    func popular(page: Int) async throws -> PagedResult<MediaSummary> { samplePage(SampleData.shows) }
    func topRated(page: Int) async throws -> PagedResult<MediaSummary> { samplePage(SampleData.shows) }
    func trending(page: Int) async throws -> PagedResult<MediaSummary> { samplePage(SampleData.shows) }
    func details(id: Int) async throws -> TVDetail {
        let json = """
        {"id":\(id),"name":"North Station","overview":"Dispatchers keep the last trains moving.","vote_average":8.3,"vote_count":1900,"first_air_date":"2022-01-11","genres":[{"id":18,"name":"Drama"}],"seasons":[{"id":1,"name":"Season 1","season_number":1,"episode_count":2}],"episode_run_time":[48],"number_of_seasons":1}
        """
        return try JSONDecoder().decode(TVDetail.self, from: Data(json.utf8))
    }
    func credits(id: Int) async throws -> CreditsResponse { CreditsResponse(cast: [], crew: []) }
    func videos(id: Int) async throws -> [MediaVideo] { [] }
    func reviews(id: Int, page: Int) async throws -> PagedResult<MovieReview> {
        PagedResult(page: 1, totalPages: 1, totalResults: 0, items: [])
    }
    func similar(id: Int, page: Int) async throws -> PagedResult<MediaSummary> { samplePage(SampleData.shows) }
    func season(id: Int, season: Int) async throws -> TVSeasonDetail {
        let json = """
        {"season_number":\(season),"name":"Season \(season)","episodes":[{"id":1,"episode_number":1,"name":"Arrival","overview":"The first storm of the year.","air_date":"2022-01-11","runtime":48,"vote_average":8.0}]}
        """
        return try JSONDecoder().decode(TVSeasonDetail.self, from: Data(json.utf8))
    }
    private func samplePage(_ items: [MediaSummary]) -> PagedResult<MediaSummary> {
        PagedResult(page: 1, totalPages: 1, totalResults: items.count, items: items)
    }
}

final class PreviewSearchService: SearchServiceProtocol {
    func search(query: String, scope: SearchScope, page: Int) async throws -> PagedResult<SearchHit> {
        let media = SampleData.movies.map { SearchHit.media($0) }
        let people = SampleData.people.map { SearchHit.person($0) }
        let items: [SearchHit]
        switch scope {
        case .people: items = people
        case .tv: items = SampleData.shows.map { SearchHit.media($0) }
        case .movies: items = media
        case .all: items = media + people
        }
        return PagedResult(page: 1, totalPages: 1, totalResults: items.count, items: items)
    }
    func trendingTitles(page: Int) async throws -> [MediaSummary] { SampleData.movies }
}

final class PreviewPersonService: PersonServiceProtocol {
    func details(id: Int) async throws -> PersonDetail {
        PersonDetail(
            id: id,
            name: "Mara Ellison",
            biography: "Mara Ellison is a fictional performer used to preview Lumen layouts.",
            profilePath: nil,
            knownForDepartment: "Acting",
            birthday: "1988-05-02",
            placeOfBirth: "Lisbon",
            movieCredits: SampleData.movies,
            televisionCredits: SampleData.shows
        )
    }
}
