import SwiftUI

struct ActorCard: View {
    let name: String
    let role: String
    let profilePath: String?
    var seed: Int = 0

    private var url: URL? { ImageService().url(path: profilePath, size: .profile) }

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            CachedAsyncImage(url: url, maxPixel: 280, seed: seed, accessibilityLabel: "\(name) profile")
                .frame(width: 86, height: 86)
                .clipShape(Circle())
                .overlay { Circle().strokeBorder(AppColors.separator, lineWidth: 1) }
            Text(name)
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            Text(role)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 96)
        .accessibilityElement(children: .combine)
    }
}

struct ReviewCard: View {
    let review: MovieReview
    @Environment(\.openURL) private var openURL
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .center, spacing: AppSpacing.sm) {
                avatar
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.displayName)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let created = review.createdAt {
                        Text(Formatters.mediumDate(created))
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
                Spacer(minLength: AppSpacing.sm)
                if let rating = review.rating, rating > 0 {
                    RatingBadge(score: rating)
                        .accessibilityLabel("Review rating \(Formatters.rating(rating)) out of 10")
                }
            }
            Text(review.content)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(expanded ? nil : 6)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: AppSpacing.md) {
                if review.content.count > 220 {
                    Button(expanded ? "Show less" : "Read More") {
                        withAnimation(AppAnimation.quick) { expanded.toggle() }
                    }
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.accent)
                    .frame(minHeight: 32)
                }
                if let source = review.sourceURL {
                    Button("Read Original") { openURL(source) }
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.accent)
                        .frame(minHeight: 32)
                }
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lumenCard()
    }

    private var avatar: some View {
        CachedAsyncImage(url: review.avatarURL, maxPixel: 120, seed: review.id.hashValue, accessibilityLabel: "\(review.displayName) avatar")
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .overlay { Circle().strokeBorder(AppColors.separator, lineWidth: 1) }
            .accessibilityHidden(true)
    }
}

#Preview {
    ActorCard(name: "Mara Ellison", role: "Elena Voss", profilePath: nil, seed: 3)
        .padding()
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
