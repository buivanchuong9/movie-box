import Foundation
import UIKit

/// Movies the user added from the photo library or from image files. No network calls.
@MainActor
@Observable
final class ImportLibrary {
    private(set) var movies: [MediaSummary] = []
    private var records: [Record] = []
    private let directory: URL
    private let catalogURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        directory = base.appendingPathComponent("ImportedMovies", isDirectory: true)
        catalogURL = directory.appendingPathComponent("catalog.json")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        load()
    }

    func add(title: String, imageData: Data) {
        guard let image = UIImage(data: imageData), let jpeg = image.jpegData(compressionQuality: 0.88) else { return }
        let id = (records.map(\.id).max() ?? 0) + 1
        let fileName = "\(id).jpg"
        let url = directory.appendingPathComponent(fileName)
        do {
            try jpeg.write(to: url, options: .atomic)
        } catch {
            return
        }
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        records.insert(Record(id: id, title: cleaned.isEmpty ? "Movie \(id)" : cleaned, fileName: fileName, createdAt: .now), at: 0)
        persist()
        rebuild()
    }

    func summary(id: Int) -> MediaSummary? {
        movies.first { $0.id == id }
    }

    private struct Record: Codable {
        var id: Int
        var title: String
        var fileName: String
        var createdAt: Date
    }

    private func load() {
        guard let data = try? Data(contentsOf: catalogURL),
              let decoded = try? JSONDecoder().decode([Record].self, from: data) else {
            records = []
            movies = []
            return
        }
        records = decoded
        rebuild()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: catalogURL, options: .atomic)
    }

    private func rebuild() {
        movies = records.compactMap { record in
            let path = directory.appendingPathComponent(record.fileName).path
            guard FileManager.default.fileExists(atPath: path) else { return nil }
            let rank = records.firstIndex { $0.id == record.id } ?? 0
            return MediaSummary(
                id: record.id,
                title: record.title,
                overview: "Imported from your photos.",
                posterPath: path,
                backdropPath: path,
                voteAverage: 0,
                voteCount: 0,
                releaseDate: nil,
                genreIDs: [],
                mediaType: .movie,
                popularity: Double(records.count - rank),
                originalLanguage: nil,
                isAdult: false
            )
        }
    }
}

final class LocalMovieService: MovieServiceProtocol {
    private let library: ImportLibrary

    init(library: ImportLibrary) {
        self.library = library
    }

    func trending(page: Int) async throws -> PagedResult<MediaSummary> {
        paged(await library.movies)
    }
    func popular(page: Int) async throws -> PagedResult<MediaSummary> {
        paged(await library.movies)
    }
    func topRated(page: Int) async throws -> PagedResult<MediaSummary> { paged([]) }
    func nowPlaying(page: Int) async throws -> PagedResult<MediaSummary> { paged([]) }
    func upcoming(page: Int) async throws -> PagedResult<MediaSummary> { paged([]) }

    func details(id: Int) async throws -> MovieDetail {
        guard let item = await library.summary(id: id) else { throw AppError.notFound }
        return LocalDecode.value(MovieDetail.self, [
            "id": item.id,
            "title": item.title,
            "overview": item.overview,
            "poster_path": item.posterPath ?? "",
            "backdrop_path": item.backdropPath ?? "",
            "vote_average": 0,
            "vote_count": 0,
            "runtime": 0,
            "genres": [] as [[String: Any]],
            "tagline": "",
            "status": "Imported",
            "original_language": "en"
        ])
    }

    func credits(id: Int) async throws -> CreditsResponse {
        LocalDecode.value(CreditsResponse.self, ["cast": [] as [[String: Any]], "crew": [] as [[String: Any]]])
    }

    func videos(id: Int) async throws -> [MediaVideo] { [] }

    func reviews(id: Int, page: Int) async throws -> PagedResult<MovieReview> {
        PagedResult(page: 1, totalPages: 1, totalResults: 0, items: [])
    }

    func similar(id: Int, page: Int) async throws -> PagedResult<MediaSummary> {
        let others = await library.movies.filter { $0.id != id }
        return paged(others)
    }

    func discover(filters: MediaFilters, page: Int) async throws -> PagedResult<MediaSummary> {
        let items = await library.movies.filter { filters.allows($0) }
        return paged(items)
    }

    func genres() async throws -> [Genre] { GenreCatalog.featured }
}

final class LocalTVService: TVServiceProtocol {
    func popular(page: Int) async throws -> PagedResult<MediaSummary> { empty(page) }
    func topRated(page: Int) async throws -> PagedResult<MediaSummary> { empty(page) }
    func trending(page: Int) async throws -> PagedResult<MediaSummary> { empty(page) }
    func details(id: Int) async throws -> TVDetail { throw AppError.notFound }
    func credits(id: Int) async throws -> CreditsResponse {
        LocalDecode.value(CreditsResponse.self, ["cast": [] as [[String: Any]], "crew": [] as [[String: Any]]])
    }
    func videos(id: Int) async throws -> [MediaVideo] { [] }
    func reviews(id: Int, page: Int) async throws -> PagedResult<MovieReview> {
        PagedResult(page: 1, totalPages: 1, totalResults: 0, items: [])
    }
    func similar(id: Int, page: Int) async throws -> PagedResult<MediaSummary> { empty(page) }
    func season(id: Int, season: Int) async throws -> TVSeasonDetail { throw AppError.notFound }

    private func empty(_ page: Int) -> PagedResult<MediaSummary> {
        PagedResult(page: page, totalPages: 1, totalResults: 0, items: [])
    }
}

final class LocalSearchService: SearchServiceProtocol {
    private let library: ImportLibrary

    init(library: ImportLibrary) {
        self.library = library
    }

    func search(query: String, scope: SearchScope, page: Int) async throws -> PagedResult<SearchHit> {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty, scope != .people else {
            return PagedResult(page: 1, totalPages: 1, totalResults: 0, items: [])
        }
        let hits = await library.movies
            .filter { $0.title.lowercased().contains(needle) || $0.overview.lowercased().contains(needle) }
            .map { SearchHit.media($0) }
        return PagedResult(page: 1, totalPages: 1, totalResults: hits.count, items: hits)
    }

    func trendingTitles(page: Int) async throws -> [MediaSummary] {
        await library.movies
    }
}

final class LocalPersonService: PersonServiceProtocol {
    func details(id: Int) async throws -> PersonDetail { throw AppError.notFound }
}

private func paged(_ items: [MediaSummary]) -> PagedResult<MediaSummary> {
    PagedResult(page: 1, totalPages: 1, totalResults: items.count, items: items)
}

private enum LocalDecode {
    static func value<T: Decodable>(_ type: T.Type, _ object: Any) -> T {
        do {
            let data = try JSONSerialization.data(withJSONObject: object)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            preconditionFailure("Imported movie could not be read: \(error)")
        }
    }
}
