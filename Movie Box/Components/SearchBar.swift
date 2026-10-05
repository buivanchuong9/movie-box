import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var prompt = "Search movies, shows, people"
    var onCancel: () -> Void
    var onSubmit: () -> Void = {}

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppColors.textTertiary)
                TextField(prompt, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .submitLabel(.search)
                    .onSubmit(onSubmit)
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColors.textTertiary)
                            .frame(width: AppSpacing.touch, height: AppSpacing.touch)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.leading, AppSpacing.sm)
            .frame(minHeight: AppSpacing.touch)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(AppColors.separator, lineWidth: 1)
            }

            Button("Cancel", action: onCancel)
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.accent)
                .frame(minHeight: AppSpacing.touch)
        }
    }
}

#Preview {
    SearchBar(text: .constant("Harbor"), onCancel: {})
        .padding()
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
