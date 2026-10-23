import AVFoundation
import CryptoKit
import Foundation
import UIKit

enum VideoImportResult: Equatable {
    case added
    case duplicate
    case failed
}

/// Videos the user added from Photos or Files. Each file is copied into the app's own storage and played offline.
/// Nothing is uploaded and no network calls are made.
@MainActor
@Observable
final class ImportLibrary {
    private(set) var movies: [MediaSummary] = []
    private var records: [Record] = []
    private let directory: URL
    private let catalogURL: URL

    init() {
        let base = (try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? URL(fileURLWithPath: NSTemporaryDirectory())
        directory = base.appendingPathComponent("ImportedMovies", isDirectory: true)
        catalogURL = directory.appendingPathComponent("catalog.json")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        load()
    }

    /// Copies (or moves, for files already in the app's temporary storage) a video into the library.
    /// Security-scoped URLs from the Files picker are opened for the duration of the copy.
    func importVideo(from source: URL, title: String, movesSource: Bool) async -> VideoImportResult {
        let id = (records.map(\.id).max() ?? 0) + 1
        let known = Set(records.compactMap(\.digest))
        let directory = directory
        let outcome = await Task.detached(priority: .userInitiated) {
            VideoFileImporter.run(source: source, id: id, into: directory, known: known, movesSource: movesSource)
        }.value
        guard case .success(let item) = outcome else {
            if case .duplicate = outcome { return .duplicate }
            return .failed
        }
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        records.insert(
            Record(
                id: id,
                title: cleaned.isEmpty ? "Video \(id)" : cleaned,
                fileName: item.posterFileName,
                videoFileName: item.videoFileName,
                duration: item.duration,
                createdAt: .now,
                digest: item.digest
            ),
            at: 0
        )
        persist()
        rebuild()
        return .added
    }

    func summary(id: Int) -> MediaSummary? {
        movies.first { $0.id == id }
    }

    /// File URL of the imported video, or nil for titles without one or when the file is missing.
    func videoURL(id: Int) -> URL? {
        guard let name = records.first(where: { $0.id == id })?.videoFileName else { return nil }
        let url = directory.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func runtimeMinutes(id: Int) -> Int {
        Int(((records.first { $0.id == id }?.duration ?? 0) / 60).rounded())
    }

    private struct Record: Codable {
        var id: Int
        var title: String
        var fileName: String?
        var videoFileName: String?
        var duration: Double?
        var createdAt: Date
        var digest: String?
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
            let hasVideo = record.videoFileName.map {
                FileManager.default.fileExists(atPath: directory.appendingPathComponent($0).path)
            } ?? false
            let posterPath = record.fileName
                .map { directory.appendingPathComponent($0).path }
                .flatMap { FileManager.default.fileExists(atPath: $0) ? $0 : nil }
            guard hasVideo || posterPath != nil else { return nil }
            let rank = records.firstIndex { $0.id == record.id } ?? 0
            return MediaSummary(
                id: record.id,
                title: record.title,
                overview: hasVideo ? "Imported video." : "Imported from your photos.",
                posterPath: posterPath,
                backdropPath: posterPath,
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

/// Copy, verify and thumbnail work. Runs off the main actor.
private enum VideoFileImporter {
    struct Item {
        let videoFileName: String
        let posterFileName: String?
        let duration: Double
        let digest: String
    }

    enum Outcome {
        case success(Item)
        case duplicate
        case failure
    }

    static func run(source: URL, id: Int, into directory: URL, known: Set<String>, movesSource: Bool) -> Outcome {
        let scoped = source.startAccessingSecurityScopedResource()
        defer { if scoped { source.stopAccessingSecurityScopedResource() } }

        guard let digest = digest(of: source) else { return .failure }
        if known.contains(digest) {
            if movesSource { try? FileManager.default.removeItem(at: source) }
            return .duplicate
        }

        let ext = source.pathExtension.isEmpty ? "mov" : source.pathExtension.lowercased()
        let videoName = "\(id).\(ext)"
        var destination = directory.appendingPathComponent(videoName)
        try? FileManager.default.removeItem(at: destination)
        do {
            if movesSource {
                try FileManager.default.moveItem(at: source, to: destination)
            } else {
                try FileManager.default.copyItem(at: source, to: destination)
            }
        } catch {
            return .failure
        }
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? destination.setResourceValues(values)

        let asset = AVURLAsset(url: destination)
        let probe = blocking { () -> (Bool, Double) in
            let playable = (try? await asset.load(.isPlayable)) ?? false
            let seconds = (try? await asset.load(.duration).seconds) ?? 0
            return (playable, seconds.isFinite ? seconds : 0)
        }
        guard probe.0 else {
            try? FileManager.default.removeItem(at: destination)
            return .failure
        }

        var posterName: String?
        if let jpeg = blocking({ await poster(for: asset, duration: probe.1) }) {
            let name = "\(id).jpg"
            if (try? jpeg.write(to: directory.appendingPathComponent(name), options: .atomic)) != nil {
                posterName = name
            }
        }
        return .success(Item(videoFileName: videoName, posterFileName: posterName, duration: probe.1, digest: digest))
    }

    private static func digest(of url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try? handle.read(upToCount: 1 << 20), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private static func poster(for asset: AVURLAsset, duration: Double) async -> Data? {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 1280, height: 1280)
        let time = CMTime(seconds: min(1, duration / 2), preferredTimescale: 600)
        guard let image = try? await generator.image(at: time).image else { return nil }
        return UIImage(cgImage: image).jpegData(compressionQuality: 0.82)
    }

    /// Bridges async AVFoundation calls into this synchronous, already-detached worker.
    private static func blocking<T: Sendable>(_ work: @escaping @Sendable () async -> T) -> T {
        let box = ResultBox<T>()
        let semaphore = DispatchSemaphore(value: 0)
        Task.detached {
            box.value = await work()
            semaphore.signal()
        }
        semaphore.wait()
        return box.value!
    }

    private final class ResultBox<T>: @unchecked Sendable {
        var value: T?
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
        let minutes = await library.runtimeMinutes(id: id)
        return LocalDecode.value(MovieDetail.self, [
            "id": item.id,
            "title": item.title,
            "overview": item.overview,
            "poster_path": item.posterPath ?? "",
            "backdrop_path": item.backdropPath ?? "",
            "vote_average": 0,
            "vote_count": 0,
            "runtime": minutes,
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
