import SwiftUI

struct PersonDetailView: View {
    @Environment(AppEnvironment.self) private var env
    let personID: Int
    @State private var model: PersonDetailViewModel?

    var body: some View {
        Group {
            if let model {
                if model.isLoading && model.person == nil {
                    VStack(spacing: AppSpacing.lg) {
                        ActorSkeleton()
                        SkeletonBone(height: 80).padding(.horizontal, AppSpacing.page)
                    }
                } else if let message = model.errorMessage, model.person == nil {
                    NetworkErrorView(message: message) { Task { await model.load(env) } }
                } else if let person = model.person {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppSpacing.xl) {
                            VStack(spacing: AppSpacing.sm) {
                                CachedAsyncImage(
                                    url: ImageService().url(path: person.profilePath, size: .large),
                                    maxPixel: 600,
                                    seed: person.id,
                                    accessibilityLabel: "\(person.name) profile"
                                )
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                                Text(person.name)
                                    .font(AppTypography.heroTitle)
                                    .foregroundStyle(AppColors.textPrimary)
                                    .multilineTextAlignment(.center)
                                if let department = person.knownForDepartment {
                                    Text(department)
                                        .font(AppTypography.callout)
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                if !person.knownForLine.isEmpty {
                                    Text(person.knownForLine)
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColors.textTertiary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, AppSpacing.lg)

                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Biography")
                                    .font(AppTypography.section)
                                    .foregroundStyle(AppColors.textPrimary)
                                Text(person.biography.isEmpty ? "No biography is available." : person.biography)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            if !person.movieCredits.isEmpty {
                                PosterCarousel(title: "Movies", items: person.movieCredits)
                                    .padding(.horizontal, -AppSpacing.page)
                            }
                            if !person.televisionCredits.isEmpty {
                                PosterCarousel(title: "TV Shows", items: person.televisionCredits)
                                    .padding(.horizontal, -AppSpacing.page)
                            }
                        }
                        .padding(.horizontal, AppSpacing.page)
                        .padding(.bottom, AppSpacing.xxl)
                    }
                }
            } else {
                ActorSkeleton()
            }
        }
        .background(AppColors.background)
        .navigationTitle(model?.person?.name ?? "Person")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if model == nil { model = PersonDetailViewModel(personID: personID) }
            await model?.load(env)
        }
    }
}
