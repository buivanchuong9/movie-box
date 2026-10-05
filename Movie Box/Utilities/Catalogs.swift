import Foundation

enum GenreCatalog {
    static let featured: [Genre] = [
        Genre(id: 28, name: "Action"),
        Genre(id: 12, name: "Adventure"),
        Genre(id: 16, name: "Animation"),
        Genre(id: 35, name: "Comedy"),
        Genre(id: 80, name: "Crime"),
        Genre(id: 18, name: "Drama"),
        Genre(id: 14, name: "Fantasy"),
        Genre(id: 27, name: "Horror"),
        Genre(id: 10749, name: "Romance"),
        Genre(id: 878, name: "Sci-Fi"),
        Genre(id: 53, name: "Thriller"),
        Genre(id: 99, name: "Documentary")
    ]

    static func name(for id: Int) -> String? {
        featured.first { $0.id == id }?.name
    }
}

struct CountryOption: Identifiable, Hashable {
    let code: String
    let name: String
    var id: String { code }

    static let common: [CountryOption] = [
        .init(code: "US", name: "United States"),
        .init(code: "GB", name: "United Kingdom"),
        .init(code: "KR", name: "South Korea"),
        .init(code: "JP", name: "Japan"),
        .init(code: "FR", name: "France"),
        .init(code: "IN", name: "India"),
        .init(code: "DE", name: "Germany"),
        .init(code: "ES", name: "Spain"),
        .init(code: "IT", name: "Italy"),
        .init(code: "BR", name: "Brazil"),
        .init(code: "CN", name: "China"),
        .init(code: "CA", name: "Canada"),
        .init(code: "AU", name: "Australia"),
        .init(code: "MX", name: "Mexico"),
        .init(code: "SE", name: "Sweden"),
        .init(code: "VN", name: "Vietnam")
    ]
}

struct LanguageOption: Identifiable, Hashable {
    let code: String
    let name: String
    var id: String { code }

    static let content: [LanguageOption] = [
        .init(code: "en-US", name: "English"),
        .init(code: "es-ES", name: "Spanish"),
        .init(code: "fr-FR", name: "French"),
        .init(code: "de-DE", name: "German"),
        .init(code: "pt-BR", name: "Portuguese"),
        .init(code: "ja-JP", name: "Japanese"),
        .init(code: "ko-KR", name: "Korean"),
        .init(code: "zh-CN", name: "Chinese"),
        .init(code: "vi-VN", name: "Vietnamese"),
        .init(code: "hi-IN", name: "Hindi"),
        .init(code: "it-IT", name: "Italian")
    ]

    static let originals: [LanguageOption] = [
        .init(code: "en", name: "English"),
        .init(code: "es", name: "Spanish"),
        .init(code: "fr", name: "French"),
        .init(code: "de", name: "German"),
        .init(code: "ko", name: "Korean"),
        .init(code: "ja", name: "Japanese"),
        .init(code: "zh", name: "Chinese"),
        .init(code: "hi", name: "Hindi"),
        .init(code: "pt", name: "Portuguese"),
        .init(code: "it", name: "Italian"),
        .init(code: "vi", name: "Vietnamese")
    ]
}

enum YearCatalog {
    static var recent: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 30)...current).reversed()
    }
}
