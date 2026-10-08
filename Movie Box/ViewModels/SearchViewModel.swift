import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    private let search: any SearchServiceProtocol
    var query = ""
    var scope: SearchScope = .all
    var filters = MediaFilters()
    var sort: SortOption = .popularity
    var hits: [SearchHit] = []
    var trending: [MediaSummary] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?
    private var page = 1
    private var totalPages = 1
    private var task: Task<Void, Never>?
    private var requestID = UUID()

    init(search: any SearchServiceProtocol) {
        self.search = search
    }

    var canLoadMore: Bool { page < totalPages && !isLoading && !isLoadingMore && !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    func loadTrendingIfNeeded() async {
        guard trending.isEmpty else { return }
        await reloadTrending()
    }

    func reloadTrending() async {
        trending = (try? await search.trendingTitles(page: 1)) ?? []
    }

    func updateQuery(_ text: String) {
        query = text
        task?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            hits = []
            isLoading = false
            errorMessage = nil
            page = 1
            totalPages = 1
            return
        }
        isLoading = true
        errorMessage = nil
        task = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await self.run(reset: true)
        }
    }

    func changeScope(_ scope: SearchScope) async {
        self.scope = scope
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        await run(reset: true)
    }

    func apply(filters: MediaFilters, sort: SortOption) async {
        self.filters = filters
        self.sort = sort
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        await run(reset: true)
    }

    func loadMore() async {
        guard canLoadMore else { return }
        await run(reset: false)
    }

    private func run(reset: Bool) async {
        let token = UUID()
        requestID = token
        if reset {
            isLoading = true
            page = 1
        } else {
            isLoadingMore = true
        }
        let nextPage = reset ? 1 : page + 1
        do {
            let result = try await search.search(query: query, scope: scope, page: nextPage)
            guard requestID == token else { return }
            let filtered = result.items.filter(matches).sorted(by: sorter)
            if reset {
                hits = filtered
            } else {
                let existing = Set(hits.map(\.id))
                hits.append(contentsOf: filtered.filter { !existing.contains($0.id) })
            }
            page = result.page
            totalPages = result.totalPages
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            guard requestID == token else { return }
            if reset { hits = [] }
            errorMessage = AppError.userMessage(for: error)
        }
        if requestID == token {
            isLoading = false
            isLoadingMore = false
        }
    }

    private func matches(_ hit: SearchHit) -> Bool {
        switch hit {
        case .person:
            return scope == .all || scope == .people
        case .media(let media):
            return filters.allows(media)
        }
    }

    private func sorter(_ lhs: SearchHit, _ rhs: SearchHit) -> Bool {
        switch (lhs, rhs) {
        case (.media(let a), .media(let b)):
            switch sort {
            case .popularity: return a.popularity > b.popularity
            case .rating: return a.voteAverage > b.voteAverage
            case .releaseDate: return a.releaseDate ?? "" > b.releaseDate ?? ""
            }
        default:
            return false
        }
    }
}
