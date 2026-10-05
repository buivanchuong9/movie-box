import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(AppColors.accent)
                .frame(width: 84, height: 84)
                .background(AppColors.elevated, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                .accessibilityHidden(true)
            Text(title)
                .font(AppTypography.section)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, action: action)
                    .padding(.top, AppSpacing.xs)
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity)
    }
}

struct NetworkErrorView: View {
    let message: String
    var retry: () -> Void

    var body: some View {
        EmptyStateView(
            systemImage: "wifi.exclamationmark",
            title: "Something went wrong",
            message: message,
            actionTitle: "Try Again",
            action: retry
        )
    }
}

struct OfflineView: View {
    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "wifi.slash")
            Text("You're offline")
                .lineLimit(2)
        }
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textPrimary)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.elevated)
        .accessibilityElement(children: .combine)
    }
}

struct ConfigurationNeededView: View {
    var openSettings: () -> Void

    var body: some View {
        EmptyStateView(
            systemImage: "key",
            title: "Connect movie data",
            message: "Movie data is unavailable right now.",
            actionTitle: "Open Settings",
            action: openSettings
        )
    }
}

#Preview {
    EmptyStateView(
        systemImage: "bookmark",
        title: "Your watchlist is empty",
        message: "Save movies and shows you want to come back to.",
        actionTitle: "Discover Movies",
        action: {}
    )
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
