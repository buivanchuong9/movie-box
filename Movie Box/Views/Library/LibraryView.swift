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

            CollectionPicker(segment: $segment)
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
        case .watched: "No watched movies yet"
        }
    }

    private var emptyMessage: String {
        switch segment {
        case .watchlist: "Save movies you want to come back to."
        case .favorites: "Save movies you want to keep close."
        case .watched: "Mark a movie as watched to see it here."
        }
    }
}

private struct CollectionPicker: View {
    @Binding var segment: LibrarySegment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            ForEach(LibrarySegment.allCases) { item in
                let selected = segment == item
                Button {
                    if reduceMotion {
                        segment = item
                    } else {
                        withAnimation(AppAnimation.quick) { segment = item }
                    }
                    Haptics.selection()
                } label: {
                    Text(item.title)
                        .font(AppTypography.captionBold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(selected ? AppColors.onAccent : AppColors.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .padding(.horizontal, AppSpacing.xs)
                        .background(selected ? AppColors.accentFill : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(AppSpacing.xxs)
        .background(AppColors.surface, in: Capsule())
        .overlay {
            Capsule().strokeBorder(AppColors.border, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Collection")
    }
}
