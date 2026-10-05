import SwiftUI

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case discover
    case search
    case library

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .discover: "Discover"
        case .search: "Search"
        case .library: "My List"
        }
    }

    func symbol(selected: Bool) -> String {
        switch self {
        case .home: selected ? "house.fill" : "house"
        case .discover: selected ? "safari.fill" : "safari"
        case .search: "magnifyingglass"
        case .library: selected ? "bookmark.fill" : "bookmark"
        }
    }
}
