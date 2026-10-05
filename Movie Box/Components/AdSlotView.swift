import SwiftUI

struct AdInlineCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("FROM LUMEN")
                .font(AppTypography.captionBold)
                .tracking(0.8)
                .foregroundStyle(AppColors.textTertiary)
            Text("Lumen Plus")
                .font(AppTypography.section)
                .foregroundStyle(AppColors.textPrimary)
            Text("A quieter app, finer filters, and recommendations that follow what you actually watch.")
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            NavigationLink(value: AppRoute.premium) {
                Text("See Lumen Plus")
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.onAccent)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 36)
                    .background(AppColors.accentFill, in: Capsule())
            }
            .buttonStyle(PressScaleStyle())
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(AppColors.separator, lineWidth: 1)
        }
        .padding(.horizontal, AppSpacing.page)
        .accessibilityElement(children: .combine)
    }
}

struct SponsorInterstitial: View {
    var onContinue: () -> Void
    var onUpgrade: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("FROM LUMEN")
                .font(AppTypography.captionBold)
                .tracking(0.8)
                .foregroundStyle(AppColors.textTertiary)
            Text("Keep browsing, or make it quieter.")
                .font(AppTypography.heroTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text("Lumen Plus removes these moments and unlocks advanced filters, recommendations, and statistics.")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
            PrimaryButton(title: "Continue browsing", action: onContinue)
            SecondaryButton(title: "View Lumen Plus", action: onUpgrade)
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(AppColors.background)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NavigationStack { AdInlineCard() }
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
