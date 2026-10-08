import SwiftUI

struct RatingBadge: View {
    let score: Double

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: 9, weight: .bold))
            Text(Formatters.rating(score))
                .font(AppTypography.captionBold)
        }
        .foregroundStyle(score > 0 ? AppColors.onAccent : AppColors.textSecondary)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(score > 0 ? AppColors.rating : AppColors.elevated, in: Capsule())
        .accessibilityLabel(score > 0 ? "Rated \(Formatters.rating(score)) out of 10" : "No rating")
    }
}

struct RatingView: View {
    let average: Double
    let voteCount: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .stroke(AppColors.elevated, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: revealed ? min(CGFloat(average / 10), 1) : 0)
                    .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text(Formatters.rating(average))
                        .font(AppTypography.ratingLarge)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("/ 10")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .frame(width: 112, height: 112)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Audience rating \(Formatters.rating(average)) out of 10, \(voteCount) votes")

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Audience rating")
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                Text("\(Formatters.count(voteCount)) votes")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                Text("Audience average from published votes. This is not a critic score.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            if reduceMotion {
                revealed = true
            } else {
                withAnimation(AppAnimation.standard) { revealed = true }
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 24) {
        RatingBadge(score: 8.2)
        RatingView(average: 8.2, voteCount: 12400)
    }
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
