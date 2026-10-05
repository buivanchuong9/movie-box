import Foundation
import SwiftData

@Model
final class MovieBookmark {
    @Attribute(.unique) var libraryKey: String
    var mediaID: Int
    var mediaTypeRaw: String
    var title: String
    var overview: String
    var posterPath: String?
    var backdropPath: String?
    var voteAverage: Double
    var voteCount: Int
    var releaseDate: String?
    var genreIDs: [Int]
    var originalLanguage: String?
    var addedAt: Date

    init(media: MediaSummary, addedAt: Date = .now) {
        libraryKey = media.libraryKey
        mediaID = media.id
        mediaTypeRaw = media.mediaType.rawValue
        title = media.title
        overview = media.overview
        posterPath = media.posterPath
        backdropPath = media.backdropPath
        voteAverage = media.voteAverage
        voteCount = media.voteCount
        releaseDate = media.releaseDate
        genreIDs = media.genreIDs
        originalLanguage = media.originalLanguage
        self.addedAt = addedAt
    }

    var summary: MediaSummary { MediaRecord.summary(from: self) }
}

@Model
final class FavoriteMovie {
    @Attribute(.unique) var libraryKey: String
    var mediaID: Int
    var mediaTypeRaw: String
    var title: String
    var overview: String
    var posterPath: String?
    var backdropPath: String?
    var voteAverage: Double
    var voteCount: Int
    var releaseDate: String?
    var genreIDs: [Int]
    var originalLanguage: String?
    var addedAt: Date

    init(media: MediaSummary, addedAt: Date = .now) {
        libraryKey = media.libraryKey
        mediaID = media.id
        mediaTypeRaw = media.mediaType.rawValue
        title = media.title
        overview = media.overview
        posterPath = media.posterPath
        backdropPath = media.backdropPath
        voteAverage = media.voteAverage
        voteCount = media.voteCount
        releaseDate = media.releaseDate
        genreIDs = media.genreIDs
        originalLanguage = media.originalLanguage
        self.addedAt = addedAt
    }

    var summary: MediaSummary { MediaRecord.summary(from: self) }
}

@Model
final class WatchedMovie {
    @Attribute(.unique) var libraryKey: String
    var mediaID: Int
    var mediaTypeRaw: String
    var title: String
    var overview: String
    var posterPath: String?
    var backdropPath: String?
    var voteAverage: Double
    var voteCount: Int
    var releaseDate: String?
    var genreIDs: [Int]
    var originalLanguage: String?
    var addedAt: Date

    init(media: MediaSummary, addedAt: Date = .now) {
        libraryKey = media.libraryKey
        mediaID = media.id
        mediaTypeRaw = media.mediaType.rawValue
        title = media.title
        overview = media.overview
        posterPath = media.posterPath
        backdropPath = media.backdropPath
        voteAverage = media.voteAverage
        voteCount = media.voteCount
        releaseDate = media.releaseDate
        genreIDs = media.genreIDs
        originalLanguage = media.originalLanguage
        self.addedAt = addedAt
    }

    var summary: MediaSummary { MediaRecord.summary(from: self) }
}

@Model
final class EpisodeProgress {
    @Attribute(.unique) var key: String
    var showID: Int
    var seasonNumber: Int
    var episodeNumber: Int
    var isWatched: Bool
    var updatedAt: Date

    init(showID: Int, seasonNumber: Int, episodeNumber: Int, isWatched: Bool, updatedAt: Date = .now) {
        self.key = EpisodeProgress.makeKey(showID: showID, season: seasonNumber, episode: episodeNumber)
        self.showID = showID
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.isWatched = isWatched
        self.updatedAt = updatedAt
    }

    static func makeKey(showID: Int, season: Int, episode: Int) -> String {
        "tv-\(showID)-s\(season)e\(episode)"
    }
}

@Model
final class RecentSearch {
    @Attribute(.unique) var query: String
    var searchedAt: Date

    init(query: String, searchedAt: Date = .now) {
        self.query = query
        self.searchedAt = searchedAt
    }
}

@Model
final class RecentlyViewed {
    @Attribute(.unique) var libraryKey: String
    var mediaID: Int
    var mediaTypeRaw: String
    var title: String
    var overview: String
    var posterPath: String?
    var backdropPath: String?
    var voteAverage: Double
    var voteCount: Int
    var releaseDate: String?
    var genreIDs: [Int]
    var originalLanguage: String?
    var directorID: Int?
    var castIDs: [Int]
    var viewedAt: Date

    init(media: MediaSummary, directorID: Int? = nil, castIDs: [Int] = [], viewedAt: Date = .now) {
        libraryKey = media.libraryKey
        mediaID = media.id
        mediaTypeRaw = media.mediaType.rawValue
        title = media.title
        overview = media.overview
        posterPath = media.posterPath
        backdropPath = media.backdropPath
        voteAverage = media.voteAverage
        voteCount = media.voteCount
        releaseDate = media.releaseDate
        genreIDs = media.genreIDs
        originalLanguage = media.originalLanguage
        self.directorID = directorID
        self.castIDs = castIDs
        self.viewedAt = viewedAt
    }

    var summary: MediaSummary { MediaRecord.summary(from: self) }
}

@Model
final class UserPreferences {
    @Attribute(.unique) var key: String
    var favoriteGenreIDs: [Int]
    var hasCompletedOnboarding: Bool
    var appearanceRaw: String
    var contentLanguage: String
    var notificationsEnabled: Bool

    init(
        key: String = "primary",
        favoriteGenreIDs: [Int] = [],
        hasCompletedOnboarding: Bool = false,
        appearanceRaw: String = AppearancePreference.dark.rawValue,
        contentLanguage: String = "en-US",
        notificationsEnabled: Bool = false
    ) {
        self.key = key
        self.favoriteGenreIDs = favoriteGenreIDs
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.appearanceRaw = appearanceRaw
        self.contentLanguage = contentLanguage
        self.notificationsEnabled = notificationsEnabled
    }
}

@Model
final class CachedPayload {
    @Attribute(.unique) var key: String
    var data: Data
    var savedAt: Date

    init(key: String, data: Data, savedAt: Date = .now) {
        self.key = key
        self.data = data
        self.savedAt = savedAt
    }
}

enum MediaRecord {
    static func summary(
        libraryKey: String,
        mediaID: Int,
        mediaTypeRaw: String,
        title: String,
        overview: String,
        posterPath: String?,
        backdropPath: String?,
        voteAverage: Double,
        voteCount: Int,
        releaseDate: String?,
        genreIDs: [Int],
        originalLanguage: String?
    ) -> MediaSummary {
        MediaSummary(
            id: mediaID,
            title: title,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            voteAverage: voteAverage,
            voteCount: voteCount,
            releaseDate: releaseDate,
            genreIDs: genreIDs,
            mediaType: MediaKind(rawValue: mediaTypeRaw) ?? .movie,
            popularity: 0,
            originalLanguage: originalLanguage,
            isAdult: false
        )
    }

    static func summary(from item: MovieBookmark) -> MediaSummary {
        summary(libraryKey: item.libraryKey, mediaID: item.mediaID, mediaTypeRaw: item.mediaTypeRaw, title: item.title, overview: item.overview, posterPath: item.posterPath, backdropPath: item.backdropPath, voteAverage: item.voteAverage, voteCount: item.voteCount, releaseDate: item.releaseDate, genreIDs: item.genreIDs, originalLanguage: item.originalLanguage)
    }

    static func summary(from item: FavoriteMovie) -> MediaSummary {
        summary(libraryKey: item.libraryKey, mediaID: item.mediaID, mediaTypeRaw: item.mediaTypeRaw, title: item.title, overview: item.overview, posterPath: item.posterPath, backdropPath: item.backdropPath, voteAverage: item.voteAverage, voteCount: item.voteCount, releaseDate: item.releaseDate, genreIDs: item.genreIDs, originalLanguage: item.originalLanguage)
    }

    static func summary(from item: WatchedMovie) -> MediaSummary {
        summary(libraryKey: item.libraryKey, mediaID: item.mediaID, mediaTypeRaw: item.mediaTypeRaw, title: item.title, overview: item.overview, posterPath: item.posterPath, backdropPath: item.backdropPath, voteAverage: item.voteAverage, voteCount: item.voteCount, releaseDate: item.releaseDate, genreIDs: item.genreIDs, originalLanguage: item.originalLanguage)
    }

    static func summary(from item: RecentlyViewed) -> MediaSummary {
        summary(libraryKey: item.libraryKey, mediaID: item.mediaID, mediaTypeRaw: item.mediaTypeRaw, title: item.title, overview: item.overview, posterPath: item.posterPath, backdropPath: item.backdropPath, voteAverage: item.voteAverage, voteCount: item.voteCount, releaseDate: item.releaseDate, genreIDs: item.genreIDs, originalLanguage: item.originalLanguage)
    }
}
