import SwiftUI

struct LibraryView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var segment: LibrarySegment = .watchlist

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("My List")
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.page)
                .accessibilityAddTraits(.isHeader)

            if !env.network.isOnline {
                OfflineView()
            }

            HStack(spacing: AppSpacing.xs) {
                ForEach(LibrarySegment.allCases) { item in
                    Button {
                        withAnimation(AppAnimation.quick) { segment = item }
                    } label: {
                        Text(item.title)
                            .font(AppTypography.captionBold)
                            .foregroundStyle(segment == item ? AppColors.onAccent : AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: AppSpacing.touch)
                            .background(segment == item ? AppColors.accentFill : AppColors.elevated, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(segment == item ? .isSelected : [])
                }
            }
            .padding(.horizontal, AppSpacing.page)

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
        case .watchlist: "Save movies and shows you want to come back to."
        case .favorites: "Tap the heart on a title to keep it close."
        case .watched: "Mark something watched and it will live here."
        }
    }
}
