import Foundation

struct RecommendationSignals {
    var favoriteGenreIDs: [Int]
    var watched: [MediaSummary]
    var watchlist: [MediaSummary]
    var recentlyViewed: [MediaSummary]
    var isPremium: Bool
}

struct ScoredMedia: Identifiable, Hashable {
    let media: MediaSummary
    let score: Double
    let reason: String
    var id: String { media.libraryKey }
}

struct RecommendationEngine {
    func forYou(candidates: [MediaSummary], signals: RecommendationSignals) -> [MediaSummary] {
        let weights = genreWeights(signals)
        guard !weights.isEmpty else { return [] }
        return rank(candidates, weights: weights, signals: signals).map(\.media)
    }

    func trendingForYou(trending: [MediaSummary], signals: RecommendationSignals) -> [MediaSummary] {
        let weights = genreWeights(signals)
        guard !weights.isEmpty else { return [] }
        let ranked = rank(trending, weights: weights, signals: signals)
        let personalized = ranked.filter { $0.score > 0 }
        return personalized.isEmpty ? [] : personalized.map(\.media)
    }

    func becauseYouWatched(similar: [MediaSummary], source: MediaSummary, signals: RecommendationSignals) -> [ScoredMedia] {
        similar
            .filter { $0.libraryKey != source.libraryKey }
            .filter { !watchedKeys(signals).contains($0.libraryKey) }
            .map { ScoredMedia(media: $0, score: $0.voteAverage, reason: "Because you watched \(source.title)") }
    }

    private func rank(_ items: [MediaSummary], weights: [Int: Double], signals: RecommendationSignals) -> [ScoredMedia] {
        let seen = watchedKeys(signals)
        let listed = Set(signals.watchlist.map(\.libraryKey))
        return items
            .filter { !seen.contains($0.libraryKey) }
            .map { item in
                var score = item.voteAverage * 0.35 + min(item.popularity, 200) / 80
                var matched: [(Int, Double)] = []
                for genre in item.genreIDs {
                    if let weight = weights[genre] {
                        score += weight
                        matched.append((genre, weight))
                    }
                }
                if listed.contains(item.libraryKey) { score -= 0.4 }
                let top = matched.max { $0.1 < $1.1 }?.0
                let reason = top.flatMap { GenreCatalog.name(for: $0) }.map { "Because you like \($0)" } ?? "Matched to your taste"
                return ScoredMedia(media: item, score: score, reason: reason)
            }
            .sorted { $0.score > $1.score }
    }

    private func genreWeights(_ signals: RecommendationSignals) -> [Int: Double] {
        var weights: [Int: Double] = [:]
        for id in signals.favoriteGenreIDs {
            weights[id, default: 0] += 3
        }
        for item in signals.watchlist {
            for id in item.genreIDs { weights[id, default: 0] += 1.4 }
        }
        for item in signals.watched {
            for id in item.genreIDs { weights[id, default: 0] += signals.isPremium ? 1.6 : 0.8 }
        }
        for item in signals.recentlyViewed.prefix(8) {
            for id in item.genreIDs { weights[id, default: 0] += signals.isPremium ? 1.1 : 0.4 }
        }
        return weights
    }

    private func watchedKeys(_ signals: RecommendationSignals) -> Set<String> {
        Set(signals.watched.map(\.libraryKey))
    }
}
