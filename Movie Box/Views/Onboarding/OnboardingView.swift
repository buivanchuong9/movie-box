import SwiftUI

struct OnboardingView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var page = 0

    private let pages = IntroPage.pages

    var body: some View {
        ZStack {
            backdrop
            VStack(spacing: 0) {
                header
                stage
                footer
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var backdrop: some View {
        ZStack {
            AppColors.background
            Circle()
                .fill(AppGradients.glow(opacity: colorScheme == .dark ? 0.34 : 0.18))
                .frame(width: 420, height: 420)
                .blur(radius: 8)
                .offset(y: glowOffset)
                .accessibilityHidden(true)
        }
        .ignoresSafeArea()
        .animation(reduceMotion ? nil : AppAnimation.hero, value: page)
    }

    private var glowOffset: CGFloat {
        switch page {
        case 0: -120
        case 1: -80
        case 2: -40
        default: -100
        }
    }

    private var header: some View {
        HStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Image("AppLogo")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                Text("Movie Box")
                    .font(AppTypography.wordmark)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: AppSpacing.sm)

            Button(action: finish) {
                Text("Skip")
                    .font(AppTypography.button)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(minWidth: AppSpacing.touch, minHeight: AppSpacing.touch)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Leaves the introduction")
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.xs)
    }

    private var stage: some View {
        ZStack(alignment: .top) {
            ForEach(pages) { item in
                if item.index == page {
                    IntroPageView(page: item, compactArt: dynamicTypeSize.isAccessibilitySize)
                        .transition(pageTransition)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var pageTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 16))
    }

    private var footer: some View {
        VStack(spacing: AppSpacing.md) {
            OnboardingProgressIndicator(count: pages.count, page: page)
            Button(action: advance) {
                HStack(spacing: AppSpacing.xs) {
                    Text(page == pages.count - 1 ? "See Plans" : "Continue")
                    Image(systemName: "arrow.right")
                        .accessibilityHidden(true)
                }
                .font(AppTypography.button)
                .foregroundStyle(AppColors.onAccent)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(AppGradients.primaryButton, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                }
                .shadow(color: AppColors.accentDeep.opacity(colorScheme == .dark ? 0.45 : 0.28), radius: 16, y: 8)
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityHint(page == pages.count - 1 ? "Continues to subscription plans" : "Shows the next introduction screen")
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.md)
        .background(footerFade)
    }

    private var footerFade: some View {
        LinearGradient(
            colors: [AppColors.background.opacity(0), AppColors.background],
            startPoint: .top,
            endPoint: .init(x: 0.5, y: 0.35)
        )
        .ignoresSafeArea(edges: .bottom)
        .accessibilityHidden(true)
    }

    private func advance() {
        guard page < pages.count - 1 else {
            finish()
            return
        }
        Haptics.selection()
        if reduceMotion {
            page += 1
        } else {
            withAnimation(AppAnimation.standard) { page += 1 }
        }
    }

    private func finish() {
        Haptics.selection()
        env.library.completeOnboarding(genres: [])
    }
}

private struct IntroPage: Identifiable {
    let index: Int
    let title: String
    let message: String
    let highlights: [IntroHighlight]

    var id: Int { index }

    static let pages: [IntroPage] = [
        IntroPage(
            index: 0,
            title: "Your Movies, Your Way",
            message: "Movie Box keeps a private library on this device, with details and lists you can use to decide what to watch.",
            highlights: []
        ),
        IntroPage(
            index: 1,
            title: "Build Your Library",
            message: "Import posters from Photos or Files. They stay on this device with your watchlist, favorites, and watched titles.",
            highlights: [
                IntroHighlight(symbol: "photo.on.rectangle", title: "Photos"),
                IntroHighlight(symbol: "folder", title: "Files"),
                IntroHighlight(symbol: "bookmark", title: "Lists")
            ]
        ),
        IntroPage(
            index: 2,
            title: "Open the Details",
            message: "Read the overview, check the audience rating and cast, and open a trailer when one is available.",
            highlights: [
                IntroHighlight(symbol: "star", title: "Rating"),
                IntroHighlight(symbol: "person.2", title: "Cast"),
                IntroHighlight(symbol: "play.rectangle", title: "Trailer")
            ]
        ),
        IntroPage(
            index: 3,
            title: "Ready to Begin?",
            message: "Continue to choose a plan, then start saving the movies you want to keep.",
            highlights: []
        )
    ]
}

private struct IntroHighlight: Identifiable {
    let symbol: String
    let title: String
    var id: String { symbol }
}

private struct IntroPageView: View {
    let page: IntroPage
    var compactArt: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                Text("Step \(page.index + 1) of \(IntroPage.pages.count)")
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.accent)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 6)
                    .background(AppColors.accentSoft, in: Capsule())

                illustration
                    .accessibilityHidden(true)

                VStack(spacing: AppSpacing.sm) {
                    Text(page.title)
                        .font(AppTypography.display)
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(page.message)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: 460)

                if !page.highlights.isEmpty {
                    highlightRow
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.lg)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    @ViewBuilder
    private var illustration: some View {
        if compactArt {
            Image(systemName: compactSymbol)
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(AppColors.accent)
                .frame(maxWidth: .infinity)
                .frame(height: 88)
        } else {
            switch page.index {
            case 0: WelcomeIllustration()
            case 1: LibraryIllustration()
            case 2: DetailIllustration()
            default: ReadyIllustration()
            }
        }
    }

    private var compactSymbol: String {
        switch page.index {
        case 0: "play.circle.fill"
        case 1: "folder.fill"
        case 2: "text.below.photo"
        default: "sparkles"
        }
    }

    private var highlightRow: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(page.highlights) { item in
                VStack(spacing: AppSpacing.xs) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.accent)
                        .frame(width: 40, height: 40)
                        .background(AppColors.accentSoft, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    Text(item.title)
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: AppSpacing.touch)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.top, AppSpacing.xxs)
    }
}

struct OnboardingProgressIndicator: View {
    let count: Int
    let page: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == page ? AppColors.accent : AppColors.textTertiary.opacity(0.45))
                    .frame(width: index == page ? 22 : 6, height: 6)
            }
        }
        .animation(reduceMotion ? nil : AppAnimation.quick, value: page)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(page + 1) of \(count)")
    }
}

private struct WelcomeIllustration: View {
    var body: some View {
        ZStack {
            FilmStrip()
                .rotationEffect(.degrees(-8))
                .offset(y: 28)
            AnimatedPlaySymbol(diameter: 112)
            floating("photo", x: -104, y: -78)
            floating("bookmark", x: 108, y: -46)
            floating("film", x: -96, y: 92)
            floating("sparkle", x: 102, y: 86)
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
    }

    private func floating(_ symbol: String, x: CGFloat, y: CGFloat) -> some View {
        DriftIcon(systemName: symbol)
            .offset(x: x, y: y)
    }
}

struct AnimatedPlaySymbol: View {
    var diameter: CGFloat = 112
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(AppColors.accent.opacity(0.28), lineWidth: 1)
                .frame(width: diameter * 1.72, height: diameter * 1.72)
            Circle()
                .strokeBorder(AppColors.accentBright.opacity(0.55), lineWidth: 1.5)
                .frame(width: diameter * 1.34, height: diameter * 1.34)
            playCore
        }
    }

    private var playCore: some View {
        ZStack {
            Circle()
                .fill(AppGradients.primaryButton)
                .frame(width: diameter, height: diameter)
                .shadow(color: AppColors.accentFill.opacity(0.4), radius: 22, y: 10)
            Image(systemName: "play.fill")
                .font(.system(size: diameter * 0.36, weight: .bold))
                .foregroundStyle(AppColors.onAccent)
                .offset(x: diameter * 0.03)
                .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion)
        }
    }
}

private struct FilmStrip: View {
    var body: some View {
        HStack(spacing: 0) {
            sprockets
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(LinearGradient(colors: AppColors.posterWash(seed: index + 3), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(AppColors.onAccent.opacity(0.92))
                        }
                        .frame(width: 48, height: 68)
                }
            }
            .padding(.horizontal, 8)
            sprockets
        }
        .padding(.vertical, 8)
        .background(AppColors.elevated, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(AppColors.accent.opacity(0.35), lineWidth: 1)
        }
    }

    private var sprockets: some View {
        VStack(spacing: 7) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(AppColors.background.opacity(0.9))
                    .frame(width: 8, height: 6)
            }
        }
        .padding(.horizontal, 5)
    }
}

private struct LibraryIllustration: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let art = ZStack {
            mediaCard(seed: 1, width: 142)
                .rotationEffect(.degrees(-9))
                .offset(x: -42, y: 18)
            mediaCard(seed: 6, width: 142)
                .rotationEffect(.degrees(8))
                .offset(x: 44, y: 10)
            mediaCard(seed: 11, width: 154)
                .offset(y: -8)
            folderBadge
                .offset(x: 102, y: 92)
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)

        if reduceMotion {
            art
        } else {
            art.phaseAnimator([CGFloat(0), 7, 0]) { content, y in
                content.offset(y: y)
            } animation: { _ in
                .easeInOut(duration: 3.4)
            }
        }
    }

    private func mediaCard(seed: Int, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                LinearGradient(colors: AppColors.posterWash(seed: seed), startPoint: .top, endPoint: .bottom)
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.onAccent.opacity(0.9))
            }
            .frame(width: width - 20, height: 92)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Capsule()
                .fill(AppColors.textTertiary.opacity(0.45))
                .frame(width: width * 0.55, height: 7)
            Capsule()
                .fill(AppColors.textTertiary.opacity(0.28))
                .frame(width: width * 0.34, height: 6)
        }
        .padding(10)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(AppColors.border, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 16, y: 8)
    }

    private var folderBadge: some View {
        Image(systemName: "folder.fill")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(AppColors.accent)
            .frame(width: 48, height: 48)
            .background(AppColors.surface, in: Circle())
            .overlay { Circle().strokeBorder(AppColors.accent.opacity(0.4), lineWidth: 1) }
    }
}

private struct DetailIllustration: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: AppColors.posterWash(seed: 4), startPoint: .topLeading, endPoint: .bottomTrailing)
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(AppColors.onAccent.opacity(0.22))
                            .frame(width: 18, height: 28)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppColors.onAccent)
                    .padding(12)
            }
            .frame(height: 112)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

            HStack(spacing: AppSpacing.sm) {
                ratingRing
                VStack(alignment: .leading, spacing: 6) {
                    Capsule().fill(AppColors.textTertiary.opacity(0.4)).frame(width: 120, height: 8)
                    Capsule().fill(AppColors.textTertiary.opacity(0.25)).frame(width: 84, height: 6)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: AppSpacing.xs) {
                detailChip("star.fill", "Rating")
                detailChip("person.2.fill", "Cast")
                detailChip("play.rectangle.fill", "Trailer")
            }
        }
        .padding(AppSpacing.sm)
        .frame(maxWidth: 320)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous)
                .strokeBorder(AppColors.border, lineWidth: 1)
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
    }

    private var ratingRing: some View {
        ZStack {
            Circle()
                .stroke(AppColors.accentSoft, lineWidth: 4)
            Circle()
                .trim(from: 0, to: 0.78)
                .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: "star.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColors.accent)
        }
        .frame(width: 36, height: 36)
    }

    private func detailChip(_ symbol: String, _ title: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
            Text(title)
                .lineLimit(1)
        }
        .font(AppTypography.captionBold)
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AppColors.elevated, in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
    }
}

private struct ReadyIllustration: View {
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .strokeBorder(AppColors.accent.opacity(0.18 + Double(index) * 0.08), lineWidth: 1)
                    .frame(width: 140 + CGFloat(index) * 52, height: 140 + CGFloat(index) * 52)
            }
            AnimatedPlaySymbol(diameter: 108)
            DriftDot(size: 7, travel: 10).offset(x: -120, y: -70)
            DriftDot(size: 5, travel: 14).offset(x: 128, y: -36)
            DriftDot(size: 6, travel: 8).offset(x: 96, y: 96)
            DriftDot(size: 4, travel: 12).offset(x: -100, y: 88)
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
    }
}

private struct DriftIcon: View {
    let systemName: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let icon = Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AppColors.accent)
            .frame(width: 40, height: 40)
            .background(AppColors.surface.opacity(0.94), in: Circle())
            .overlay { Circle().strokeBorder(AppColors.accent.opacity(0.35), lineWidth: 1) }

        if reduceMotion {
            icon
        } else {
            icon.phaseAnimator([CGFloat(0), -7, 0, 5]) { content, y in
                content.offset(y: y)
            } animation: { _ in
                .easeInOut(duration: 2.8)
            }
        }
    }
}

private struct DriftDot: View {
    var size: CGFloat
    var travel: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let dot = Circle()
            .fill(AppColors.accentBright)
            .frame(width: size, height: size)
            .shadow(color: AppColors.accentBright.opacity(0.8), radius: 6)

        if reduceMotion {
            dot
        } else {
            dot.phaseAnimator([CGFloat(0), -travel, 0]) { content, y in
                content.offset(y: y)
            } animation: { _ in
                .easeInOut(duration: 2.6)
            }
        }
    }
}

#Preview("Dark") {
    OnboardingView()
        .environment(AppEnvironment.preview)
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    OnboardingView()
        .environment(AppEnvironment.preview)
        .preferredColorScheme(.light)
}
