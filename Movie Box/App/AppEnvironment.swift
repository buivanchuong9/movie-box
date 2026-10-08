import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AppEnvironment {
    let client: APIClient
    let imports: ImportLibrary
    let movies: any MovieServiceProtocol
    let tv: any TVServiceProtocol
    let search: any SearchServiceProtocol
    let people: any PersonServiceProtocol
    let images: ImageService
    let trailers: TrailerService
    let recommendations = RecommendationEngine()
    let container: ModelContainer
    let library: LibraryRepository
    let entitlements: EntitlementManager
    let store: StoreKitService
    let network: NetworkMonitor
    let ads: AdManager
    let tabs = TabRouter()
    let home: HomeViewModel
    let discover: DiscoverViewModel
    let searchModel: SearchViewModel

    @MainActor
    static let preview: AppEnvironment = {
        do { return try AppEnvironment(preview: true) }
        catch { fatalError("Preview environment failed: \(error)") }
    }()

    static func live() throws -> AppEnvironment {
        try AppEnvironment(preview: false)
    }

    private init(preview: Bool) throws {
        let schema = Schema([
            MovieBookmark.self,
            FavoriteMovie.self,
            WatchedMovie.self,
            EpisodeProgress.self,
            RecentSearch.self,
            RecentlyViewed.self,
            UserPreferences.self,
            CachedPayload.self
        ])
        container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: preview))
        library = LibraryRepository(context: container.mainContext)
        client = APIClient()
        client.contentLanguage = library.preferences.contentLanguage
        let imported = ImportLibrary()
        imports = imported
        if preview {
            movies = PreviewMovieService()
            tv = PreviewTVService()
            search = PreviewSearchService()
            people = PreviewPersonService()
        } else {
            movies = LocalMovieService(library: imported)
            tv = LocalTVService()
            search = LocalSearchService(library: imported)
            people = LocalPersonService()
        }
        images = ImageService()
        trailers = TrailerService()
        let entitlementManager = EntitlementManager()
        entitlements = entitlementManager
        let storeKit = StoreKitService(entitlements: entitlementManager)
        store = storeKit
        let monitor = NetworkMonitor()
        network = monitor
        monitor.start()
        ads = AdManager(entitlements: entitlementManager)
        home = HomeViewModel(movies: movies, television: tv, recommendations: recommendations)
        discover = DiscoverViewModel(movies: movies)
        searchModel = SearchViewModel(search: search)
        if !preview {
            storeKit.start()
        }
    }

    func importImages(_ images: [(title: String, data: Data)]) async {
        for image in images {
            imports.add(title: image.title, imageData: image.data)
        }
        await refreshImportedContent()
    }

    private func refreshImportedContent() async {
        let signals = library.signals(isPremium: entitlements.isPremium)
        await home.reload(signals: signals)
        await discover.reload()
        await searchModel.reloadTrending()
    }

    func applyLanguage() {
        client.contentLanguage = library.preferences.contentLanguage
    }
}
