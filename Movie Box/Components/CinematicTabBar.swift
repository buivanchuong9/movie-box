import Observation

@MainActor
@Observable
final class TabRouter {
    var selection: AppTab = .home
    var loaded: Set<AppTab> = [.home]

    func select(_ tab: AppTab) {
        loaded.insert(tab)
        selection = tab
    }
}
