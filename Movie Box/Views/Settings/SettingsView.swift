import StoreKit
import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.openURL) private var openURL
    #if DEBUG
    #endif
    @State private var notifyMessage: String?
    @State private var restoreMessage: String?

    var body: some View {
        List {
            Section("Library") {
                Picker("Language", selection: languageBinding) {
                    ForEach(LanguageOption.content) { language in
                        Text(language.name).tag(language.code)
                    }
                }
                .listRowBackground(AppColors.surface)
                NavigationLink(value: AppRoute.statistics) { Text("Statistics") }
                    .listRowBackground(AppColors.surface)
            }

            Section("Appearance") {
                Picker("Appearance", selection: appearanceBinding) {
                    ForEach(AppearancePreference.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(AppColors.surface)
            }

            Section {
                Toggle("Notifications", isOn: notificationBinding)
                    .listRowBackground(AppColors.surface)
                if let notifyMessage {
                    Text(notifyMessage)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .listRowBackground(AppColors.surface)
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text("This preference stays on your device. Movie Box does not send a digest from a server.")
            }

            Section("Lumen Plus") {
                NavigationLink(value: AppRoute.premium) {
                    HStack {
                        Text("Lumen Plus")
                        Spacer(minLength: AppSpacing.sm)
                        if env.entitlements.isPremium {
                            Text("Active")
                                .font(AppTypography.captionBold)
                                .foregroundStyle(AppColors.accent)
                        }
                    }
                }
                .listRowBackground(AppColors.surface)
                Button("Restore Purchases") {
                    Task { restoreMessage = await restorePurchases() }
                }
                .listRowBackground(AppColors.surface)
                if let restoreMessage {
                    Text(restoreMessage)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .listRowBackground(AppColors.surface)
                }
                if env.entitlements.current.canManageSubscription {
                    Button("Manage Subscription") {
                        Task { await env.store.showManageSubscriptions() }
                    }
                    .listRowBackground(AppColors.surface)
                }
            }

            Section("Privacy") {
                legalRow("Privacy", url: LegalConfiguration.privacyURL, document: .privacy)
                legalRow("Terms", url: LegalConfiguration.termsURL, document: .terms)
            }

            Section("Support") {
                NavigationLink(value: AppRoute.legal(.about)) { Text("About") }
                    .listRowBackground(AppColors.surface)
                Button("Rate Movie Box") { rateApp() }
                    .listRowBackground(AppColors.surface)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .lumenColumn(maxWidth: 720)
        .background(AppColors.background)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppColors.accent)
    }

    @ViewBuilder
    private func legalRow(_ title: String, url: URL?, document: LegalDocument) -> some View {
        if let url {
            Button(title) { openURL(url) }
                .listRowBackground(AppColors.surface)
        } else {
            NavigationLink(value: AppRoute.legal(document)) { Text(title) }
                .listRowBackground(AppColors.surface)
        }
    }

    private var appearanceBinding: Binding<AppearancePreference> {
        Binding(
            get: { env.library.preferences.appearance },
            set: { env.library.setAppearance($0) }
        )
    }

    private var languageBinding: Binding<String> {
        Binding(
            get: { env.library.preferences.contentLanguage },
            set: { env.library.setLanguage($0) }
        )
    }

    private var notificationBinding: Binding<Bool> {
        Binding(
            get: { env.library.preferences.notificationsEnabled },
            set: { enabled in
                env.library.setNotifications(enabled)
                guard enabled else { return }
                Task { await requestNotifications() }
            }
        )
    }

    private func restorePurchases() async -> String {
        switch await env.store.restore() {
        case .restored:
            "Purchases restored"
        case .nothingFound:
            "No previous purchases found."
        case .network:
            "Purchases couldn't be reached. Check your connection and try again."
        case .failed:
            "Purchases couldn't be restored. Please try again."
        }
    }

    private func rateApp() {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }

    private func requestNotifications() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            notifyMessage = granted ? "Notifications are allowed." : "Notifications stay off until iOS allows them."
            if !granted { env.library.setNotifications(false) }
        } catch {
            notifyMessage = "Notifications could not be requested."
            env.library.setNotifications(false)
        }
    }
}

struct StatisticsView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        Group {
            if env.entitlements.isPremium {
                stats
            } else {
                VStack(spacing: AppSpacing.lg) {
                    EmptyStateView(
                        systemImage: "chart.bar",
                        title: "Statistics are part of Lumen Plus",
                        message: "See how many titles you've saved, finished, and which genres you return to."
                    )
                    NavigationLink(value: AppRoute.premium) {
                        PrimaryButtonLabel(title: "View Lumen Plus")
                    }
                    .buttonStyle(PressScaleStyle())
                    .padding(.horizontal, AppSpacing.xl)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var stats: some View {
        let watched = env.library.watched.map(\.summary)
        let average = watched.isEmpty ? 0 : watched.map(\.voteAverage).reduce(0, +) / Double(watched.count)
        let genreCounts = Dictionary(grouping: watched.flatMap(\.genreIDs), by: { $0 }).mapValues(\.count)
        let top = genreCounts.sorted { $0.value > $1.value }.prefix(4)
        return ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                stat("Watchlist", value: "\(env.library.watchlist.count)")
                stat("Favorites", value: "\(env.library.favorites.count)")
                stat("Watched", value: "\(watched.count)")
                stat("Episodes watched", value: "\(env.library.episodeKeys.count)")
                stat("Average rating", value: watched.isEmpty ? "—" : Formatters.rating(average))
                if !top.isEmpty {
                    Text("Genres you finish")
                        .font(AppTypography.section)
                        .foregroundStyle(AppColors.textPrimary)
                    ForEach(Array(top), id: \.key) { genreID, count in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(GenreCatalog.name(for: genreID) ?? "Other")
                                .font(AppTypography.captionBold)
                                .foregroundStyle(AppColors.textSecondary)
                            Capsule()
                                .fill(AppColors.accent)
                                .frame(width: barWidth(count, highest: top.first?.value ?? 1), height: 8)
                        }
                    }
                }
            }
            .padding(AppSpacing.page)
        }
    }

    private func stat(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.section)
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }

    private func barWidth(_ count: Int, highest: Int) -> CGFloat {
        let ratio = CGFloat(count) / CGFloat(Swift.max(highest, 1))
        return Swift.max(24, ratio * 220)
    }
}

struct LegalView: View {
    let document: LegalDocument

    var body: some View {
        ScrollView {
            Text(bodyText)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.page)
        }
        .background(AppColors.background)
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var bodyText: String {
        switch document {
        case .privacy:
            """
            Lumen stores your watchlist, favorites, watched titles, episode progress, recent searches, and genre preferences on this device with SwiftData. Videos you import are copied into the app's own storage on this device and play offline.

            Lumen does not run its own account system. Lumen makes no network requests to load movie information and uploads none of your videos or data.

            Lumen Plus purchases are processed by Apple. Lumen does not sell personal information. The occasional Lumen Plus placement is our own message, not a third-party tracker.
            """
        case .terms:
            """
            Lumen is a discovery app. It does not host, stream, or download movies or television episodes. Videos play from files you import into the app.

            Your lists can be removed by deleting the app. Subscriptions, if offered, are billed by Apple and can be managed in your Apple ID settings.
            """
        case .about:
            """
            Lumen is an independent movie and television discovery app.

            Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")

            Videos and images you import stay on this device. You are responsible for having the right to use them.
            """
        }
    }
}
