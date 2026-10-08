import SwiftUI

struct PrimaryButtonLabel: View {
    let title: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .font(AppTypography.button)
        .foregroundStyle(AppColors.onAccent)
        .frame(maxWidth: .infinity)
        .frame(minHeight: AppSpacing.touch)
        .padding(.horizontal, AppSpacing.md)
        .background(AppColors.accentFill)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .accessibilityLabel(title)
    }
}

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            PrimaryButtonLabel(title: title, systemImage: systemImage)
        }
        .buttonStyle(PressScaleStyle())
    }
}

struct SecondaryButtonLabel: View {
    let title: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .font(AppTypography.button)
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity)
        .frame(minHeight: AppSpacing.touch)
        .padding(.horizontal, AppSpacing.md)
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(AppColors.textTertiary.opacity(0.7), lineWidth: 1)
        }
        .accessibilityLabel(title)
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            SecondaryButtonLabel(title: title, systemImage: systemImage)
        }
        .buttonStyle(PressScaleStyle())
    }
}

struct FavoriteButton: View {
    var isFavorite: Bool
    var action: () -> Void
    @State private var burst = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            if !isFavorite {
                burst = true
            }
            action()
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isFavorite ? AppColors.accent : AppColors.textPrimary)
                .frame(width: AppSpacing.touch, height: AppSpacing.touch)
                .background(.ultraThinMaterial, in: Circle())
                .scaleEffect(!reduceMotion && burst ? 1.18 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
        .onChange(of: isFavorite) { _, favorite in
            guard favorite, !reduceMotion else { return }
            withAnimation(AppAnimation.quick) { burst = true }
            Task {
                try? await Task.sleep(for: .milliseconds(220))
                withAnimation(AppAnimation.quick) { burst = false }
            }
        }
    }
}

struct WatchlistButton: View {
    var isSaved: Bool
    var prominent = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            if prominent {
                SecondaryButtonLabel(
                    title: isSaved ? "In Your List" : "Add to Watchlist",
                    systemImage: isSaved ? "checkmark" : "plus"
                )
            } else {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSaved ? AppColors.accent : AppColors.textPrimary)
                    .frame(width: AppSpacing.touch, height: AppSpacing.touch)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(isSaved ? "Remove from watchlist" : "Add to watchlist")
    }
}

struct LibraryActions: View {
    @Environment(AppEnvironment.self) private var env
    let media: MediaSummary

    var body: some View {
        let key = media.libraryKey
        let listed = env.library.watchlistKeys.contains(key)
        let favorite = env.library.favoriteKeys.contains(key)
        let watched = env.library.watchedKeys.contains(key)
        HStack(spacing: AppSpacing.xs) {
            action(title: listed ? "In Watchlist" : "Watchlist", systemImage: listed ? "bookmark.fill" : "bookmark", selected: listed) {
                env.library.toggleWatchlist(media)
            }
            action(title: favorite ? "Favorited" : "Favorite", systemImage: favorite ? "heart.fill" : "heart", selected: favorite) {
                env.library.toggleFavorite(media)
            }
            action(title: "Watched", systemImage: watched ? "checkmark.circle.fill" : "checkmark.circle", selected: watched) {
                env.library.toggleWatched(media)
            }
        }
    }

    private func action(title: String, systemImage: String, selected: Bool, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            VStack(spacing: AppSpacing.xxs) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                Text(title)
                    .font(AppTypography.captionBold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(selected ? AppColors.accent : AppColors.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(selected ? AppColors.accent.opacity(0.7) : AppColors.separator, lineWidth: 1)
            }
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(title)
        .accessibilityValue(selected ? "On" : "Off")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct IconCircleButton: View {
    let systemImage: String
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: AppSpacing.touch, height: AppSpacing.touch)
                .background(AppColors.surface, in: Circle())
                .overlay { Circle().strokeBorder(AppColors.separator, lineWidth: 1) }
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(label)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "View Details", systemImage: "play.fill") {}
        SecondaryButton(title: "Add to List", systemImage: "plus") {}
        HStack {
            FavoriteButton(isFavorite: true) {}
            WatchlistButton(isSaved: false) {}
        }
    }
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
