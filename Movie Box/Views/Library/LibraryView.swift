import SwiftUI

struct LibraryView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var segment: LibrarySegment = .watchlist

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("My List")
                    .font(AppTypography.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text("Watchlist, favorites, and the movies you've watched.")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, AppSpacing.page)

            if !env.network.isOnline {
                OfflineView()
            }

            Picker("Collection", selection: $segment) {
                ForEach(LibrarySegment.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppSpacing.page)
            .accessibilityLabel("Collection")

            let items = currentItems
            if items.isEmpty {
                Spacer()
                EmptyStateView(
                    systemImage: emptySymbol,
                    title: emptyTitle,
                    message: emptyMessage,
                    actionTitle: "Discover Movies",
                    action: { env.tabs.select(.discover) }
                )
                Spacer()
            } else {
                MediaGrid(items: items)
            }
        }
        .background(AppColors.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var currentItems: [MediaSummary] {
        switch segment {
        case .watchlist: env.library.watchlist.map(\.summary)
        case .favorites: env.library.favorites.map(\.summary)
        case .watched: env.library.watched.map(\.summary)
        }
    }

    private var emptySymbol: String {
        switch segment {
        case .watchlist: "bookmark"
        case .favorites: "heart"
        case .watched: "checkmark.circle"
        }
    }

    private var emptyTitle: String {
        switch segment {
        case .watchlist: "Your watchlist is empty"
        case .favorites: "No favorites yet"
        case .watched: "Nothing marked watched"
        }
    }

    private var emptyMessage: String {
        switch segment {
        case .watchlist: "Save titles you want to come back to."
        case .favorites: "Heart a movie to keep it in this collection."
        case .watched: "Mark a title watched and it stays here."
        }
    }
}
