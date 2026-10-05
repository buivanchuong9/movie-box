import SwiftUI

private struct ZoomNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var zoomNamespace: Namespace.ID? {
        get { self[ZoomNamespaceKey.self] }
        set { self[ZoomNamespaceKey.self] = newValue }
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String = "See All"
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppTypography.section)
                .foregroundStyle(AppColors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: AppSpacing.sm)
            if let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.accent)
                        .frame(minHeight: AppSpacing.touch)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(actionTitle), \(title)")
            }
        }
        .padding(.horizontal, AppSpacing.page)
    }
}

struct GenreChip: View {
    let title: String
    var isSelected = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.captionBold)
                .foregroundStyle(isSelected ? AppColors.onAccent : AppColors.textPrimary)
                .padding(.horizontal, 14)
                .frame(minHeight: 36)
                .background(isSelected ? AppColors.accentFill : AppColors.elevated, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(isSelected ? Color.clear : AppColors.separator, lineWidth: 1)
                }
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        let rows = rows(for: subviews, maxWidth: width)
        var height: CGFloat = 0
        for row in rows {
            height += rowHeight(row)
        }
        if rows.count > 1 {
            height += CGFloat(rows.count - 1) * spacing
        }
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = rows(for: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let height = rowHeight(row)
            for view in row {
                let size = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: size.width, height: size.height))
                x += size.width + spacing
            }
            y += height + spacing
        }
    }

    private func rowHeight(_ row: [LayoutSubview]) -> CGFloat {
        var height: CGFloat = 0
        for view in row {
            height = Swift.max(height, view.sizeThatFits(.unspecified).height)
        }
        return height
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var width: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if width + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([view])
                width = size.width + spacing
            } else {
                rows[rows.count - 1].append(view)
                width += size.width + spacing
            }
        }
        return rows
    }
}

#Preview {
    VStack(alignment: .leading) {
        SectionHeader(title: "Trending Now") {}
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                GenreChip(title: "Drama", isSelected: true) {}
                GenreChip(title: "Thriller") {}
            }
            .padding(.horizontal, 18)
        }
    }
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
