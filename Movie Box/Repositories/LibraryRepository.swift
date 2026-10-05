import Foundation
import SwiftData

struct PreferenceSnapshot: Equatable {
    var favoriteGenreIDs: [Int]
    var hasCompletedOnboarding: Bool
    var appearance: AppearancePreference
    var contentLanguage: String
    var notificationsEnabled: Bool

    static let initial = PreferenceSnapshot(
        favoriteGenreIDs: [],
        hasCompletedOnboarding: false,
        appearance: .dark,
        contentLanguage: "en-US",
        notificationsEnabled: false
    )

}

@MainActor
@Observable
final class LibraryRepository {
    private let context: ModelContext
    private(set) var watchlist: [MovieBookmark] = []
    private(set) var favorites: [FavoriteMovie] = []
    private(set) var watched: [WatchedMovie] = []
    private(set) var searches: [RecentSearch] = []
    private(set) var history: [RecentlyViewed] = []
    private(set) var episodeKeys: Set<String> = []
    private(set) var preferences: PreferenceSnapshot = .initial

    var watchlistKeys: Set<String> { Set(watchlist.map(\.libraryKey)) }
    var favoriteKeys: Set<String> { Set(favorites.map(\.libraryKey)) }
    var watchedKeys: Set<String> { Set(watched.map(\.libraryKey)) }

    init(context: ModelContext) {
        self.context = context
        let existing = (try? context.fetch(FetchDescriptor<UserPreferences>())) ?? []
        if existing.isEmpty {
            context.insert(UserPreferences())
            try? context.save()
        }
        reload()
    }

    func completeOnboarding(genres: [Int]) {
        updatePreferences { model in
            model.favoriteGenreIDs = genres
            model.hasCompletedOnboarding = true
        }
    }

    func setAppearance(_ appearance: AppearancePreference) {
        updatePreferences { $0.appearanceRaw = appearance.rawValue }
    }

    func setLanguage(_ code: String) {
        updatePreferences { $0.contentLanguage = code }
    }

    func setNotifications(_ enabled: Bool) {
        updatePreferences { $0.notificationsEnabled = enabled }
    }

    func reload() {
        watchlist = fetch(SortDescriptor(\.addedAt, order: .reverse))
        favorites = fetch(SortDescriptor(\.addedAt, order: .reverse))
        watched = fetch(SortDescriptor(\.addedAt, order: .reverse))
        searches = fetch(SortDescriptor(\.searchedAt, order: .reverse))
        history = fetch(SortDescriptor(\.viewedAt, order: .reverse))
        let episodes: [EpisodeProgress] = fetch(SortDescriptor(\.updatedAt, order: .reverse))
        episodeKeys = Set(episodes.filter(\.isWatched).map(\.key))
        if let stored: UserPreferences = fetch(SortDescriptor(\.key)).first {
            preferences = PreferenceSnapshot(
                favoriteGenreIDs: stored.favoriteGenreIDs,
                hasCompletedOnboarding: stored.hasCompletedOnboarding,
                appearance: AppearancePreference(rawValue: stored.appearanceRaw) ?? .dark,
                contentLanguage: stored.contentLanguage,
                notificationsEnabled: stored.notificationsEnabled
            )
        }
    }

    func containsWatchlist(_ media: MediaSummary) -> Bool { watchlistKeys.contains(media.libraryKey) }
    func containsFavorite(_ media: MediaSummary) -> Bool { favoriteKeys.contains(media.libraryKey) }
    func containsWatched(_ media: MediaSummary) -> Bool { watchedKeys.contains(media.libraryKey) }

    func toggleWatchlist(_ media: MediaSummary) {
        toggle(media, existing: watchlist.first { $0.libraryKey == media.libraryKey }, make: { MovieBookmark(media: media) })
        Haptics.impact(.medium)
    }

    func toggleFavorite(_ media: MediaSummary) {
        toggle(media, existing: favorites.first { $0.libraryKey == media.libraryKey }, make: { FavoriteMovie(media: media) })
        Haptics.success()
    }

    func toggleWatched(_ media: MediaSummary) {
        toggle(media, existing: watched.first { $0.libraryKey == media.libraryKey }, make: { WatchedMovie(media: media) })
        Haptics.impact(.light)
    }

    func isEpisodeWatched(showID: Int, season: Int, episode: Int) -> Bool {
        episodeKeys.contains(EpisodeProgress.makeKey(showID: showID, season: season, episode: episode))
    }

    func toggleEpisode(showID: Int, season: Int, episode: Int) {
        let key = EpisodeProgress.makeKey(showID: showID, season: season, episode: episode)
        let descriptor = FetchDescriptor<EpisodeProgress>(predicate: #Predicate { $0.key == key })
        if let existing = try? context.fetch(descriptor).first {
            existing.isWatched.toggle()
            existing.updatedAt = .now
        } else {
            context.insert(EpisodeProgress(showID: showID, seasonNumber: season, episodeNumber: episode, isWatched: true))
        }
        persist()
        Haptics.selection()
    }

    func addSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        let lowered = trimmed.lowercased()
        if let existing = searches.first(where: { $0.query.lowercased() == lowered }) {
            context.delete(existing)
        }
        context.insert(RecentSearch(query: trimmed))
        persist()
        let overflow = searches.dropFirst(12)
        overflow.forEach { context.delete($0) }
        if !overflow.isEmpty { persist() }
    }

    func clearSearches() {
        searches.forEach { context.delete($0) }
        persist()
    }

    func recordView(_ media: MediaSummary, directorID: Int? = nil, castIDs: [Int] = []) {
        if let existing = history.first(where: { $0.libraryKey == media.libraryKey }) {
            context.delete(existing)
        }
        context.insert(RecentlyViewed(media: media, directorID: directorID, castIDs: castIDs))
        persist()
        let overflow = history.dropFirst(30)
        overflow.forEach { context.delete($0) }
        if !overflow.isEmpty { persist() }
    }

    func signals(isPremium: Bool) -> RecommendationSignals {
        RecommendationSignals(
            favoriteGenreIDs: preferences.favoriteGenreIDs,
            watched: watched.map(\.summary),
            watchlist: watchlist.map(\.summary),
            recentlyViewed: history.map(\.summary),
            isPremium: isPremium
        )
    }

    func storePayload<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        let lookup = key
        let descriptor = FetchDescriptor<CachedPayload>(predicate: #Predicate { $0.key == lookup })
        if let existing = try? context.fetch(descriptor).first {
            existing.data = data
            existing.savedAt = .now
        } else {
            context.insert(CachedPayload(key: key, data: data))
        }
        try? context.save()
    }

    func loadPayload<T: Decodable>(_ type: T.Type, key: String) -> T? {
        let lookup = key
        let descriptor = FetchDescriptor<CachedPayload>(predicate: #Predicate { $0.key == lookup })
        guard let data = try? context.fetch(descriptor).first?.data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func toggle<Model: PersistentModel>(_ media: MediaSummary, existing: Model?, make: () -> Model) {
        if let existing {
            context.delete(existing)
        } else {
            context.insert(make())
        }
        persist()
    }

    private func updatePreferences(_ change: (UserPreferences) -> Void) {
        let descriptor = FetchDescriptor<UserPreferences>()
        guard let model = try? context.fetch(descriptor).first else { return }
        change(model)
        persist()
    }

    private func persist() {
        try? context.save()
        reload()
    }

    private func fetch<Model: PersistentModel>(_ sort: SortDescriptor<Model>) -> [Model] {
        let descriptor = FetchDescriptor<Model>(sortBy: [sort])
        return (try? context.fetch(descriptor)) ?? []
    }
}
