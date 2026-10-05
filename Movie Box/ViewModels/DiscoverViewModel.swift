import Foundation
import Observation

enum DiscoverMode: String, CaseIterable, Identifiable {
    case trending
    case popular
    case topRated
    case nowPlaying
    case upcoming

    var id: String { rawValue }

    var title: String {
        switch self {
        case .trending: "Trending"
        case .popular: "Popular"
        case .topRated: "Top Rated"
        case .nowPlaying: "Now Playing"
        case .upcoming: "Upcoming"
        }
    }

    var source: CatalogSource {
        switch self {
        case .trending: .trending
        case .popular: .popular
        case .topRated: .topRated
        case .nowPlaying: .nowPlaying
        case .upcoming: .upcoming
        }
    }
}

@MainActor
@Observable
final class DiscoverViewModel {
    private let movies: any MovieServiceProtocol
    var mode: DiscoverMode = .trending
    var filters = MediaFilters()
    var items: [MediaSummary] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?
    var needsAPIKey = false
    private var page = 1
    private var totalPages = 1
    private var requestID = UUID()

    init(movies: any MovieServiceProtocol) {
        self.movies = movies
    }

    var canLoadMore: Bool { page < totalPages && !isLoadingMore && !isLoading }

    func loadIfNeeded() async {
        guard items.isEmpty, !isLoading else { return }
        await reloadNow()
    }

    func reload() async {
        await RequestCache.$bypassFreshness.withValue(true) {
            await self.reloadNow()
        }
    }

    private func reloadNow() async {
        let token = UUID()
        requestID = token
        isLoading = true
        errorMessage = nil
        needsAPIKey = false
        page = 1
        do {
            let result = try await fetch(page: 1)
            guard requestID == token else { return }
            items = result.items
            totalPages = result.totalPages
            page = result.page
        } catch is CancellationError {
            return
        } catch {
            guard requestID == token else { return }
            items = []
            needsAPIKey = (error as? AppError) == .missingAPIKey
            errorMessage = error.localizedDescription
        }
        if requestID == token { isLoading = false }
    }

    func loadMore() async {
        guard canLoadMore else { return }
        isLoadingMore = true
        let next = page + 1
        let token = requestID
        do {
            let result = try await fetch(page: next)
            guard requestID == token else { return }
            let existing = Set(items.map(\.libraryKey))
            items.append(contentsOf: result.items.filter { !existing.contains($0.libraryKey) })
            page = result.page
            totalPages = result.totalPages
        } catch {
            guard requestID == token else { return }
        }
        if requestID == token { isLoadingMore = false }
    }

    func select(_ mode: DiscoverMode) async {
        guard self.mode != mode else { return }
        self.mode = mode
        await reload()
    }

    func apply(_ filters: MediaFilters) async {
        self.filters = filters
        await reload()
    }

    private func fetch(page: Int) async throws -> PagedResult<MediaSummary> {
        if filters.genreID != nil || filters.year != nil || filters.minimumRating != nil || filters.language != nil || filters.country != nil || filters.sort != .popularity {
            return try await movies.discover(filters: filters, page: page)
        }
        switch mode {
        case .trending: return try await movies.trending(page: page)
        case .popular: return try await movies.popular(page: page)
        case .topRated: return try await movies.topRated(page: page)
        case .nowPlaying: return try await movies.nowPlaying(page: page)
        case .upcoming: return try await movies.upcoming(page: page)
        }
    }
}

@MainActor
@Observable
final class CatalogViewModel {
    private let movies: any MovieServiceProtocol
    private let television: any TVServiceProtocol
    let query: CatalogQuery
    var items: [MediaSummary] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?
    private var page = 1
    private var totalPages = 1

    init(query: CatalogQuery, movies: any MovieServiceProtocol, television: any TVServiceProtocol) {
        self.query = query
        self.movies = movies
        self.television = television
    }

    var canLoadMore: Bool { page < totalPages && !isLoading && !isLoadingMore }

    func load() async {
        guard items.isEmpty else { return }
        await reload()
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await fetch(page: 1)
            items = result.items
            page = result.page
            totalPages = result.totalPages
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard canLoadMore else { return }
        isLoadingMore = true
        do {
            let result = try await fetch(page: page + 1)
            let existing = Set(items.map(\.libraryKey))
            items.append(contentsOf: result.items.filter { !existing.contains($0.libraryKey) })
            page = result.page
            totalPages = result.totalPages
        } catch {}
        isLoadingMore = false
    }

    private func fetch(page: Int) async throws -> PagedResult<MediaSummary> {
        if let genreID = query.genreID {
            var filters = MediaFilters()
            filters.genreID = genreID
            filters.year = query.year
            return try await movies.discover(filters: filters, page: page)
        }
        switch query.source {
        case .trending: return try await movies.trending(page: page)
        case .popular: return try await movies.popular(page: page)
        case .topRated: return try await movies.topRated(page: page)
        case .nowPlaying: return try await movies.nowPlaying(page: page)
        case .upcoming: return try await movies.upcoming(page: page)
        case .popularTV: return try await television.popular(page: page)
        case .topRatedTV: return try await television.topRated(page: page)
        case .forYou:
            var filters = MediaFilters()
            filters.sort = .popularity
            return try await movies.discover(filters: filters, page: page)
        }
    }
}
