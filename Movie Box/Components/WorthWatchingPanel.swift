import SwiftUI

struct WorthWatchingPanel: View {
    let average: Double
    let voteCount: Int

    private var assessment: WorthWatchingAssessment {
        WorthWatchingCalculator.assess(average: average, voteCount: voteCount)
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(assessment.headline.uppercased())
                    .font(AppTypography.captionBold)
                    .tracking(0.6)
                    .foregroundStyle(AppColors.accent)
                if let percentage = assessment.percentage {
                    Text("\(percentage)%")
                        .font(AppTypography.ratingLarge)
                        .foregroundStyle(AppColors.textPrimary)
                        .accessibilityLabel("\(percentage) percent")
                }
            }
            .frame(minWidth: 92, alignment: .leading)

            Text(assessment.detail)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(AppColors.accent.opacity(0.35), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    WorthWatchingPanel(average: 8.4, voteCount: 5100)
        .padding()
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
