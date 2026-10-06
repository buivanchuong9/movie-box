import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showPremium = false

    var body: some View {
        Group {
            if !env.library.preferences.hasCompletedOnboarding {
                OnboardingView()
            } else if !env.entitlements.isPremium {
                PaywallView()
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

    var body: some View {
        ZStack {
            tab(.home) { HomeRoot() }
            tab(.discover) { DiscoverRoot() }
            tab(.search) { SearchRoot() }
            tab(.library) { LibraryRoot() }
        }
        .background(AppColors.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CinematicTabBar()
        }
        .onChange(of: env.tabs.selection) { _, tab in
            env.tabs.loaded.insert(tab)
        }
    }

    @ViewBuilder
    private func tab<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        if env.tabs.loaded.contains(tab) {
            content()
                .opacity(env.tabs.selection == tab ? 1 : 0)
                .allowsHitTesting(env.tabs.selection == tab)
                .accessibilityHidden(env.tabs.selection != tab)
                .zIndex(env.tabs.selection == tab ? 1 : 0)
        }
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
