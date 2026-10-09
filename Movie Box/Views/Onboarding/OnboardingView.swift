import SwiftUI

struct OnboardingView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let visualPageCount = 4

    var body: some View {
        visualIntro
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var visualIntro: some View {
        ZStack {
            LinearGradient(colors: [AppColors.background, AppColors.surfaceElevated.opacity(0.65), AppColors.background], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            Group {
                switch page {
                case 0: genrePage
                case 1: discoverPage
                case 2: actorsPage
                default: detailPage
                }
            }
            .padding(.bottom, 92)

            VStack {
                HStack {
                    Spacer()
                    Button("Skip") { finish() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(minHeight: 44)
                }
                .padding(.horizontal, 22)
                Spacer()
            }

            VStack(spacing: 14) {
                Spacer()
                HStack(spacing: 7) {
                    ForEach(0..<visualPageCount, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? AppColors.accent : AppColors.textTertiary)
                            .frame(width: index == page ? 18 : 6, height: 6)
                    }
                }
                .accessibilityLabel("Page \(page + 1) of \(visualPageCount)")
                Button(action: advance) {
                    Text(page == visualPageCount - 1 ? "See Plans" : "Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColors.onAccent)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: AppSpacing.touch)
                        .background(AppColors.accentFill, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
        }
    }

    private var genrePage: some View {
        ZStack {
            posterCollage
            VStack(spacing: 0) {
                VStack(spacing: -2) {
                    Text("Movies For")
                        .font(.system(size: 42, weight: .bold, design: .serif))
                    Text("Every Genre")
                        .font(.system(size: 36, weight: .bold, design: .serif))
                }
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, 72)
                Spacer()
                HStack(alignment: .bottom) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 54, weight: .light))
                        .foregroundStyle(AppColors.accent)
                        .accessibilityHidden(true)
                    Spacer()
                    VStack(alignment: .trailing, spacing: -4) {
                        Text("1000+")
                            .font(.system(size: 44, weight: .bold, design: .serif))
                        Text("Movies")
                            .font(.system(size: 26, weight: .semibold, design: .serif))
                    }
                    .foregroundStyle(AppColors.textPrimary)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 8)
            }
        }
    }

    private var posterCollage: some View {
        let spots: [(CGFloat, CGFloat, Double)] = [
            (-118, -250, -8), (118, -236, 7),
            (-132, -40, 6), (132, -28, -6),
            (-110, 150, -4), (116, 164, 8),
            (-36, 250, 3), (48, -120, -2)
        ]
        return ZStack {
            ForEach(Array(ReviewImages.collage.enumerated()), id: \.offset) { index, name in
                let spot = spots[index]
                ReviewPhoto(folder: "posters", name: name)
                    .frame(width: 92, height: 138)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .rotationEffect(.degrees(spot.2))
                    .offset(x: spot.0, y: spot.1)
                    .opacity(0.92)
            }
        }
        .accessibilityHidden(true)
    }

    private var discoverPage: some View {
        VStack(spacing: 16) {
            phoneMock
                .frame(maxWidth: 280)
                .frame(maxHeight: 430)
                .padding(.top, 36)
            Text("Discover\nTrending Movies")
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 28)
    }

    private var phoneMock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Movie Box")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                Image(systemName: "magnifyingglass")
            }
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.top, 14)
            HStack(spacing: 16) {
                Text("Movies").font(.system(size: 13, weight: .bold)).foregroundStyle(AppColors.accent)
                Text("TV Shows").font(.system(size: 13, weight: .semibold)).foregroundStyle(AppColors.textTertiary)
                Spacer()
            }
            .padding(.horizontal, 12)
            phoneRow("Upcoming", ReviewImages.upcoming, titles: ["Dune: Part Two", "Civil War", "Challengers"])
            phoneRow("Most Popular", ReviewImages.popular, titles: ["The Dark Knight", "The Godfather", "The Matrix"])
            phoneRow("New Releases", ReviewImages.fresh, titles: ["Dune", "Oppenheimer", "Spider-Man"])
            Spacer(minLength: 0)
        }
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(AppColors.border, lineWidth: 1)
        }
    }

    private func phoneRow(_ title: String, _ names: [String], titles: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, 12)
            HStack(spacing: 8) {
                ForEach(Array(names.enumerated()), id: \.offset) { index, name in
                    VStack(alignment: .leading, spacing: 3) {
                        ReviewPhoto(folder: "posters", name: name)
                            .frame(height: 72)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Text(titles[index])
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 12)
        }
    }

    private var actorsPage: some View {
        VStack(spacing: 18) {
            Text("All Your\nFavorite Actors")
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, 64)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 16) {
                ForEach(ReviewImages.actors, id: \.file) { actor in
                    VStack(spacing: 6) {
                        ReviewPhoto(folder: "actors", name: actor.file)
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                        Text(actor.name)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(height: 24)
                    }
                }
            }
            .padding(.horizontal, 22)
            Spacer(minLength: 0)
        }
    }

    private var detailPage: some View {
        VStack(spacing: 14) {
            Text("Explore\nMovie Details")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, 56)
            VStack(alignment: .leading, spacing: 10) {
                ReviewPhoto(folder: "backdrops", name: "backdrop-dune")
                    .frame(height: 148)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text("Dune")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                Text("A gifted heir travels to a desert planet and finds that survival, prophecy, and empire are the same fight.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(3)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    detailFact("Status", "Released")
                    detailFact("Language", "English")
                    detailFact("Year", "2021")
                    detailFact("Runtime", "2h 35m")
                }
            }
            .padding(14)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(.horizontal, 22)
            Spacer(minLength: 0)
        }
    }

    private func detailFact(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppColors.textTertiary)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppColors.surfaceElevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func advance() {
        guard page < visualPageCount - 1 else {
            finish()
            return
        }
        if reduceMotion {
            page += 1
        } else {
            withAnimation(AppAnimation.standard) { page += 1 }
        }
    }

    private func finish() {
        env.library.completeOnboarding(genres: [])
    }
}

private struct ReviewPhoto: View {
    let folder: String
    let name: String

    var body: some View {
        Group {
            if let image = ReviewImages.image(folder: folder, name: name) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                AppColors.elevated
            }
        }
        .clipped()
    }
}

#Preview {
    OnboardingView()
        .environment(AppEnvironment.preview)
        .preferredColorScheme(.dark)
}
