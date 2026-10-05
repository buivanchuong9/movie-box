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
                .minimumScaleFactor(0.8)
        }
        .font(AppTypography.button)
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity)
        .frame(minHeight: AppSpacing.touch)
        .padding(.horizontal, AppSpacing.md)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(AppColors.separator, lineWidth: 1)
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
