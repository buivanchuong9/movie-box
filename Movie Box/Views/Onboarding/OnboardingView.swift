import SwiftUI

struct OnboardingView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var selected: Set<Int> = []

    private let pages: [(String, String, String)] = [
        ("sparkles", "Discover Movies You'll Love", "A cinematic home for what's trending, acclaimed, and about to arrive."),
        ("bookmark.fill", "Keep Your Watchlist Organized", "Save titles, mark what you've watched, and pick up episodes where you left off."),
        ("star.circle.fill", "Find What's Worth Watching", "Ratings stay honest. Recommendations follow the genres and titles you actually choose.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            if page < pages.count {
                intro
            } else {
                genres
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }

    private var intro: some View {
        let item = pages[page]
        return VStack(spacing: AppSpacing.xl) {
            HStack {
                Spacer()
                Button("Skip") { page = pages.count }
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(minHeight: AppSpacing.touch)
            }
            .padding(.horizontal, AppSpacing.page)
            Spacer()
            Image(systemName: item.0)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(AppColors.accent)
                .frame(width: 108, height: 108)
                .background(AppColors.elevated, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .accessibilityHidden(true)
            VStack(spacing: AppSpacing.sm) {
                Text(item.1)
                    .font(AppTypography.heroTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                Text(item.2)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppSpacing.xl)
            HStack(spacing: 6) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? AppColors.accent : AppColors.elevated)
                        .frame(width: index == page ? 18 : 6, height: 6)
                }
            }
            .accessibilityLabel("Page \(page + 1) of \(pages.count)")
            Spacer()
            PrimaryButton(title: page == pages.count - 1 ? "Choose Genres" : "Continue") {
                advance()
            }
            .padding(.horizontal, AppSpacing.page)
            .padding(.bottom, AppSpacing.lg)
        }
    }

    private var genres: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Select Your Favorite Genres")
                    .font(AppTypography.heroTitle)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Lumen uses these to shape For You. You can skip this and browse everything.")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.top, AppSpacing.xl)
            FlowLayout(spacing: AppSpacing.sm) {
                ForEach(GenreCatalog.featured) { genre in
                    GenreChip(title: genre.name, isSelected: selected.contains(genre.id)) {
                        if selected.contains(genre.id) {
                            selected.remove(genre.id)
                        } else {
                            selected.insert(genre.id)
                        }
                    }
                }
            }
            Spacer()
            PrimaryButton(title: "Start Watching") {
                env.library.completeOnboarding(genres: Array(selected))
            }
            Button("Not now") {
                env.library.completeOnboarding(genres: [])
            }
            .font(AppTypography.captionBold)
            .foregroundStyle(AppColors.textSecondary)
            .frame(maxWidth: .infinity, minHeight: AppSpacing.touch)
        }
        .padding(.horizontal, AppSpacing.page)
        .padding(.bottom, AppSpacing.lg)
    }

    private func advance() {
        if reduceMotion {
            page += 1
        } else {
            withAnimation(AppAnimation.standard) { page += 1 }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppEnvironment.preview)
        .preferredColorScheme(.dark)
}
