import SwiftUI

struct CinematicHero: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let items: [MediaSummary]
    @State private var index = 0

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            if items.isEmpty {
                HeroSkeleton()
            } else {
                TabView(selection: $index) {
                    ForEach(Array(items.enumerated()), id: \.element.libraryKey) { offset, media in
                        heroPage(media)
                            .tag(offset)
                            .padding(.horizontal, AppSpacing.page)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 500)
                .task(id: index) {
                    guard items.count > 1, !reduceMotion else { return }
                    try? await Task.sleep(for: .seconds(5.5))
                    guard !Task.isCancelled else { return }
                    withAnimation(AppAnimation.hero) {
                        index = (index + 1) % items.count
                    }
                }

                HStack(spacing: 6) {
                    ForEach(items.indices, id: \.self) { item in
                        Capsule()
                            .fill(item == index ? AppColors.accent : AppColors.textTertiary.opacity(0.45))
                            .frame(width: item == index ? 18 : 6, height: 6)
                            .accessibilityLabel("Featured title \(item + 1) of \(items.count)")
                            .accessibilityAddTraits(item == index ? .isSelected : [])
                    }
                }
                .animation(reduceMotion ? nil : AppAnimation.quick, value: index)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func heroPage(_ media: MediaSummary) -> some View {
        let backdrop = ImageService().url(path: media.backdropPath ?? media.posterPath, size: .backdrop)
        let saved = env.library.watchlistKeys.contains(media.libraryKey)
        return ZStack(alignment: .bottomLeading) {
            CachedAsyncImage(
                url: backdrop,
                maxPixel: 1200,
                seed: media.id,
                accessibilityLabel: "\(media.title) backdrop"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            LinearGradient(
                colors: [.black.opacity(0.05), .black.opacity(0.15), .black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(media.title)
                    .font(AppTypography.heroTitle)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                HStack(spacing: AppSpacing.xs) {
                    RatingBadge(score: media.voteAverage)
                    metaPill(media.yearText)
                    if media.mediaType == .tv {
                        metaPill("Series")
                    }
                }
                if !media.genreLine.isEmpty {
                    Text(media.genreLine)
                        .font(AppTypography.captionBold)
                        .foregroundStyle(Color.white.opacity(0.86))
                }
                Text(media.overview)
                    .font(AppTypography.callout)
                    .foregroundStyle(Color.white.opacity(0.88))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: AppSpacing.sm) {
                    NavigationLink(value: AppRoute.media(media)) {
                        PrimaryButtonLabel(title: "View Details", systemImage: "play.fill")
                    }
                    .simultaneousGesture(TapGesture().onEnded { MediaMemory.shared.store(media) })
                    .buttonStyle(PressScaleStyle())

                    WatchlistButton(isSaved: saved, prominent: true) {
                        env.library.toggleWatchlist(media)
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private func metaPill(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.captionBold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.16), in: Capsule())
    }
}

#Preview {
    CinematicHero(items: SampleData.movies)
        .environment(AppEnvironment.preview)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
