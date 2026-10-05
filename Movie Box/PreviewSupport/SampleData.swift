import Foundation

enum SampleData {
    static let movies: [MediaSummary] = [
        item(1, "Glass Harbor", "A cartographer returns to a flooded city and finds the streets have learned her name.", "2024-04-12", 8.1, 2400, [18, 53], .movie),
        item(2, "Ember Line", "Two rivals share a night train that never quite reaches morning.", "2023-11-02", 7.4, 1800, [28, 53], .movie),
        item(3, "Paper Moons", "A quiet comedian inherits a planetarium and the lies kept inside it.", "2022-06-18", 7.9, 960, [35, 18], .movie),
        item(4, "Night Orchard", "Harvest season brings something patient between the rows.", "2025-01-09", 6.8, 640, [27, 14], .movie),
        item(5, "Salt and Violet", "A coastal chef cooks a last menu for the town that raised her.", "2021-09-30", 8.4, 5100, [18, 10749], .movie),
        item(6, "Kingdom of Quiet", "An archivist opens a sealed wing and wakes a forgotten court.", "2020-02-14", 7.2, 3200, [14, 12], .movie),
        item(7, "Red Lantern Mile", "Street racers map a city by the lights they refuse to pass.", "2024-08-22", 6.5, 870, [28, 80], .movie),
        item(8, "A Small Eclipse", "Scientists on a glacier have twelve hours of borrowed daylight.", "2023-03-03", 8.0, 4100, [878, 18], .movie)
    ]

    static let shows: [MediaSummary] = [
        item(21, "North Station", "Dispatchers at the edge of a winter city keep the last trains moving.", "2022-01-11", 8.3, 1900, [18, 80], .tv),
        item(22, "The Violet Hour", "A late-night studio interviews guests who are not entirely alive.", "2024-10-04", 7.6, 720, [9648, 18], .tv),
        item(23, "Low Tide Club", "Four friends open a bar that only exists when the water is out.", "2019-05-20", 7.1, 1100, [35, 18], .tv)
    ]

    static let people: [PersonSummary] = [
        PersonSummary(id: 101, name: "Mara Ellison", profilePath: nil, knownForDepartment: "Acting", knownFor: "Glass Harbor · Salt and Violet"),
        PersonSummary(id: 102, name: "Jonah Voss", profilePath: nil, knownForDepartment: "Directing", knownFor: "Ember Line")
    ]

    static func item(
        _ id: Int,
        _ title: String,
        _ overview: String,
        _ date: String,
        _ rating: Double,
        _ votes: Int,
        _ genres: [Int],
        _ kind: MediaKind
    ) -> MediaSummary {
        MediaSummary(
            id: id,
            title: title,
            overview: overview,
            posterPath: nil,
            backdropPath: nil,
            voteAverage: rating,
            voteCount: votes,
            releaseDate: date,
            genreIDs: genres,
            mediaType: kind,
            popularity: Double(votes),
            originalLanguage: "en",
            isAdult: false
        )
    }
}
