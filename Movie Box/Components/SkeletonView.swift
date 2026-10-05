import SwiftUI

struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -0.7

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.16), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(width: proxy.size.width * 0.55)
                        .rotationEffect(.degrees(18))
                        .offset(x: phase * proxy.size.width)
                    }
                    .clipped()
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
            .accessibilityHidden(true)
    }
}

struct SkeletonBone: View {
    var height: CGFloat
    var radius: CGFloat = AppRadius.sm

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(AppColors.elevated)
            .frame(height: height)
            .modifier(ShimmerModifier())
    }
}

struct MovieCardSkeleton: View {
    var width: CGFloat = AppSpacing.posterCard

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColors.elevated)
                .frame(width: width, height: width * 1.5)
                .modifier(ShimmerModifier())
            SkeletonBone(height: 14)
                .frame(width: width * 0.8)
            SkeletonBone(height: 12)
                .frame(width: width * 0.45)
        }
        .accessibilityLabel("Loading title")
    }
}

struct HeroSkeleton: View {
    var body: some View {
        RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous)
            .fill(AppColors.elevated)
            .frame(height: 460)
            .modifier(ShimmerModifier())
            .padding(.horizontal, AppSpacing.page)
            .accessibilityLabel("Loading featured title")
    }
}

struct DetailSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            RoundedRectangle(cornerRadius: 0)
                .fill(AppColors.elevated)
                .frame(height: 280)
                .modifier(ShimmerModifier())
            HStack(alignment: .bottom, spacing: AppSpacing.md) {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(AppColors.elevated)
                    .frame(width: 104, height: 156)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    SkeletonBone(height: 28)
                    SkeletonBone(height: 16)
                    SkeletonBone(height: 16).frame(width: 120)
                }
            }
            .padding(.horizontal, AppSpacing.page)
            SkeletonBone(height: 48).padding(.horizontal, AppSpacing.page)
            SkeletonBone(height: 90).padding(.horizontal, AppSpacing.page)
        }
        .accessibilityLabel("Loading details")
    }
}

struct ActorSkeleton: View {
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Circle().fill(AppColors.elevated).frame(width: 86, height: 86).modifier(ShimmerModifier())
            SkeletonBone(height: 12).frame(width: 72)
        }
        .accessibilityLabel("Loading cast")
    }
}

struct GridSkeleton: View {
    var columns: Int = 2

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: columns), spacing: AppSpacing.lg) {
            ForEach(0..<6, id: \.self) { _ in
                MovieCardSkeleton(width: 160)
            }
        }
        .padding(.horizontal, AppSpacing.page)
        .accessibilityLabel("Loading catalog")
    }
}

#Preview("Skeletons") {
    ScrollView {
        VStack(spacing: 24) {
            HeroSkeleton()
            HStack { MovieCardSkeleton(); MovieCardSkeleton() }
            DetailSkeleton()
        }
    }
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
