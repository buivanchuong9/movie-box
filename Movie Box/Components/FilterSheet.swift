import SwiftUI

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: MediaFilters
    var advancedLocked: Bool
    var onLocked: () -> Void
    var onApply: (MediaFilters) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    filterGroup("Genre") {
                        chip("Any", selected: filters.genreID == nil) { filters.genreID = nil }
                        ForEach(GenreCatalog.featured) { genre in
                            chip(genre.name, selected: filters.genreID == genre.id) {
                                filters.genreID = genre.id
                            }
                        }
                    }
                    filterGroup("Year") {
                        chip("Any", selected: filters.year == nil) { filters.year = nil }
                        ForEach(YearCatalog.recent.prefix(16), id: \.self) { year in
                            chip(String(year), selected: filters.year == year) { filters.year = year }
                        }
                    }
                    lockedGroup("Minimum rating", locked: advancedLocked) {
                        chip("Any", selected: filters.minimumRating == nil) { filters.minimumRating = nil }
                        ForEach([6.0, 7.0, 8.0], id: \.self) { rating in
                            chip(String(format: "%.0f+", rating), selected: filters.minimumRating == rating) {
                                filters.minimumRating = rating
                            }
                        }
                    }
                    lockedGroup("Language", locked: advancedLocked) {
                        chip("Any", selected: filters.language == nil) { filters.language = nil }
                        ForEach(LanguageOption.originals) { language in
                            chip(language.name, selected: filters.language == language.code) {
                                filters.language = language.code
                            }
                        }
                    }
                    lockedGroup("Country", locked: advancedLocked) {
                        chip("Any", selected: filters.country == nil) { filters.country = nil }
                        ForEach(CountryOption.common) { country in
                            chip(country.name, selected: filters.country == country.code) {
                                filters.country = country.code
                            }
                        }
                    }
                }
                .padding(AppSpacing.page)
            }
            .background(AppColors.background)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") { filters = MediaFilters(sort: filters.sort) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(filters)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func filterGroup(_ title: String, @ViewBuilder chips: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) { chips() }
            }
        }
    }

    private func lockedGroup(_ title: String, locked: Bool, @ViewBuilder chips: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text(title)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(AppColors.accent)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) { chips() }
            }
            .allowsHitTesting(!locked)
            .opacity(locked ? 0.45 : 1)
            .overlay {
                if locked {
                    Button(action: onLocked) {
                        Color.clear
                            .frame(maxWidth: .infinity, minHeight: AppSpacing.touch)
                    }
                    .accessibilityLabel("\(title) is part of Lumen Plus")
                }
            }
        }
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        GenreChip(title: title, isSelected: selected, action: action)
    }
}

struct SortSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var sort: SortOption
    var onApply: (SortOption) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.sm) {
                ForEach(SortOption.allCases) { option in
                    Button {
                        sort = option
                        onApply(option)
                        dismiss()
                    } label: {
                        HStack {
                            Text(option.title)
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer()
                            if sort == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppColors.accent)
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .frame(minHeight: 52)
                        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(AppSpacing.page)
            .background(AppColors.background)
            .navigationTitle("Sort")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}
