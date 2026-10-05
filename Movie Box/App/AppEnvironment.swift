import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AppEnvironment {
    let client: APIClient
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
        if preview {
            movies = PreviewMovieService()
            tv = PreviewTVService()
            search = PreviewSearchService()
            people = PreviewPersonService()
        } else {
            movies = MovieService(client: client)
            tv = TVService(client: client)
            search = SearchService(client: client)
            people = PersonService(client: client)
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

    func applyLanguage() {
        client.contentLanguage = library.preferences.contentLanguage
    }
}
