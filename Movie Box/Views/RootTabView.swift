import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showPremium = false

    var body: some View {
        Group {
            if !env.library.preferences.hasCompletedOnboarding {
                OnboardingView()
            } else if !env.entitlements.isPremium {
                PaywallView(required: true)
            } else {
                RootTabView()
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .preferredColorScheme(env.library.preferences.appearance.scheme)
        .sheet(isPresented: interstitialBinding) {
            SponsorInterstitial(
                onContinue: { env.ads.dismissInterstitial() },
                onUpgrade: {
                    env.ads.dismissInterstitial()
                    showPremium = true
                }
            )
        }
        .sheet(isPresented: $showPremium) {
            NavigationStack { PremiumView() }
        }
        .onChange(of: env.library.preferences.contentLanguage) { _, _ in
            env.applyLanguage()
        }
    }

    private var interstitialBinding: Binding<Bool> {
        Binding(
            get: { env.ads.isPresentingInterstitial },
            set: { if !$0 { env.ads.dismissInterstitial() } }
        )
    }
}

struct RootTabView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var usesSidebar: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    var body: some View {
        if usesSidebar {
            NavigationSplitView {
                List(selection: sidebarSelection) {
                    ForEach(AppTab.allCases) { tab in
                        Label(tab.title, systemImage: tab.symbol(selected: env.tabs.selection == tab))
                            .tag(tab)
                    }
                }
                .navigationTitle("Movie Box")
                .listStyle(.sidebar)
            } detail: {
                keptTabs
            }
            .navigationSplitViewStyle(.balanced)
            .tint(AppColors.accent)
        } else {
            TabView(selection: selection) {
                HomeRoot()
                    .tabItem { Label(AppTab.home.title, systemImage: "house") }
                    .tag(AppTab.home)
                DiscoverRoot()
                    .tabItem { Label(AppTab.discover.title, systemImage: "safari") }
                    .tag(AppTab.discover)
                SearchRoot()
                    .tabItem { Label(AppTab.search.title, systemImage: "magnifyingglass") }
                    .tag(AppTab.search)
                LibraryRoot()
                    .tabItem { Label(AppTab.library.title, systemImage: "bookmark") }
                    .tag(AppTab.library)
            }
            .tint(AppColors.accent)
            .toolbarBackground(AppColors.background, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        }
    }

    private var keptTabs: some View {
        ZStack {
            kept(HomeRoot(), tab: .home)
            kept(DiscoverRoot(), tab: .discover)
            kept(SearchRoot(), tab: .search)
            kept(LibraryRoot(), tab: .library)
        }
        .background(AppColors.background)
    }

    private func kept<Content: View>(_ content: Content, tab: AppTab) -> some View {
        let selected = env.tabs.selection == tab
        return content
            .opacity(selected ? 1 : 0)
            .allowsHitTesting(selected)
            .accessibilityHidden(!selected)
            .zIndex(selected ? 1 : 0)
    }

    private var sidebarSelection: Binding<AppTab?> {
        Binding(
            get: { env.tabs.selection },
            set: { tab in
                guard let tab, env.tabs.selection != tab else { return }
                Haptics.selection()
                env.tabs.select(tab)
            }
        )
    }

    private var selection: Binding<AppTab> {
        Binding(
            get: { env.tabs.selection },
            set: { tab in
                guard env.tabs.selection != tab else { return }
                Haptics.selection()
                env.tabs.select(tab)
            }
        )
    }
}

struct HomeRoot: View {
    @Namespace private var zoom

    var body: some View {
        NavigationStack {
            HomeView()
                .environment(\.zoomNamespace, zoom)
                .navigationDestination(for: AppRoute.self) { route in
                    AppDestination(route: route)
                        .environment(\.zoomNamespace, zoom)
                }
        }
    }
}

struct DiscoverRoot: View {
    @Namespace private var zoom

    var body: some View {
        NavigationStack {
            DiscoverView()
                .environment(\.zoomNamespace, zoom)
                .navigationDestination(for: AppRoute.self) { route in
                    AppDestination(route: route)
                        .environment(\.zoomNamespace, zoom)
                }
        }
    }
}

struct SearchRoot: View {
    @Namespace private var zoom

    var body: some View {
        NavigationStack {
            SearchView()
                .environment(\.zoomNamespace, zoom)
                .navigationDestination(for: AppRoute.self) { route in
                    AppDestination(route: route)
                        .environment(\.zoomNamespace, zoom)
                }
        }
    }
}

struct LibraryRoot: View {
    @Namespace private var zoom

    var body: some View {
        NavigationStack {
            LibraryView()
                .environment(\.zoomNamespace, zoom)
                .navigationDestination(for: AppRoute.self) { route in
                    AppDestination(route: route)
                        .environment(\.zoomNamespace, zoom)
                }
        }
    }
}

struct AppDestination: View {
    let route: AppRoute

    var body: some View {
        switch route {
        case .movie(let id):
            MovieDetailView(movieID: id)
        case .television(let id):
            TVDetailView(showID: id)
        case .person(let id):
            PersonDetailView(personID: id)
        case .catalog(let query):
            CatalogView(query: query)
        case .settings:
            SettingsView()
        case .premium:
            PremiumView()
        case .statistics:
            StatisticsView()
        case .legal(let document):
            LegalView(document: document)
        }
    }
}
