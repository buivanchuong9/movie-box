import SwiftUI

enum PaywallMetrics {
    static let column: CGFloat = 640
    static let benefitMinimum: CGFloat = 250
}

enum PaywallColors {
    static var accentText: Color { AppColors.accent }
    static var ctaFill: Color { AppColors.accentFill }
    static let markGlyph = AppColors.dynamic(
        light: UIColor(red: 0.985, green: 0.965, blue: 0.930, alpha: 1),
        dark: UIColor(red: 0.102, green: 0.067, blue: 0.024, alpha: 1)
    )
    static var selectedSurface: Color { AppColors.selectedBackground }
    static var accentSoft: Color { AppColors.accentSoft }
    static let cardBorder = AppColors.dynamic(
        light: UIColor.black.withAlphaComponent(0.12),
        dark: UIColor.white.withAlphaComponent(0.14)
    )
    static let cardBorderStrong = AppColors.dynamic(
        light: UIColor.black.withAlphaComponent(0.28),
        dark: UIColor.white.withAlphaComponent(0.34)
    )
}

struct PaywallColumn<Content: View>: View {
    var padding: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, padding)
            .frame(maxWidth: PaywallMetrics.column)
            .frame(maxWidth: .infinity)
    }
}

struct PaywallHeader: View {
    var showsClose: Bool
    var onClose: () -> Void

    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .title3) private var logoSide: CGFloat = 28

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: logoSide, height: logoSide)
                    .clipShape(RoundedRectangle(cornerRadius: logoSide * 0.25, style: .continuous))
                    .accessibilityHidden(true)
                Text("Movie Box")
                    .font(AppTypography.wordmark)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Movie Box")
            .accessibilityAddTraits(.isHeader)

            Spacer(minLength: AppSpacing.xs)

            if showsClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(AppSpacing.xs)
                        .frame(minWidth: AppSpacing.touch, minHeight: AppSpacing.touch)
                        .background(AppColors.elevated, in: Circle())
                        .overlay {
                            Circle().strokeBorder(
                                contrast == .increased ? PaywallColors.cardBorderStrong : PaywallColors.cardBorder,
                                lineWidth: contrast == .increased ? 1.5 : 1
                            )
                        }
                }
                .buttonStyle(.plain)
                .layoutPriority(1)
                .accessibilityLabel("Close")
                .accessibilityInputLabels(["Close", "Dismiss"])
                .accessibilityIdentifier("paywall.close")
            }
        }
    }
}

struct PaywallHero: View {
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Lumen Plus")
                .font(AppTypography.captionBold)
                .textCase(.uppercase)
                .tracking(dynamicTypeSize.isAccessibilitySize ? 0 : 1)
                .foregroundStyle(PaywallColors.accentText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xxs + 1)
                .background(PaywallColors.accentSoft, in: Capsule())
                .accessibilityAddTraits(.isHeader)

            Text("Unlock the full Movie Box experience.")
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .lineSpacing(1)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text("Advanced tools, smarter discovery, and insights for your personal movie library.")
                .font(AppTypography.body)
                .foregroundStyle(secondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var secondary: Color {
        contrast == .increased ? AppColors.textPrimary : AppColors.textSecondary
    }
}

struct PaywallBenefits: View {
    @Environment(\.colorSchemeContrast) private var contrast

    private let benefits: [Benefit] = [
        Benefit(
            title: "Advanced filters",
            detail: "Refine your library with more powerful filtering options."
        ),
        Benefit(
            title: "Personalized recommendations",
            detail: "Discover titles based on the genres and preferences you choose."
        ),
        Benefit(
            title: "Viewing statistics",
            detail: "See insights into what you have watched."
        ),
        Benefit(
            title: "Premium library experience",
            detail: "Enjoy the full Movie Box experience with fewer promotional interruptions."
        )
    ]

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: PaywallMetrics.benefitMinimum), spacing: AppSpacing.lg, alignment: .top)]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: AppSpacing.md) {
            ForEach(benefits) { benefit in
                PaywallBenefitRow(title: benefit.title, detail: benefit.detail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(border, lineWidth: contrast == .increased ? 1.5 : 1)
        }
        .accessibilityElement(children: .contain)
    }

    private var border: Color {
        contrast == .increased ? PaywallColors.cardBorderStrong : PaywallColors.cardBorder
    }
}

private struct Benefit: Identifiable {
    let title: String
    let detail: String
    var id: String { title }
}

private struct PaywallBenefitRow: View {
    let title: String
    let detail: String

    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .body) private var iconSide: CGFloat = 22

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(PaywallColors.accentText)
                .frame(width: iconSide, height: iconSide)
                .background(PaywallColors.accentSoft, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(AppTypography.footnote)
                    .foregroundStyle(secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private var secondary: Color {
        contrast == .increased ? AppColors.textPrimary : AppColors.textSecondary
    }
}

struct PaywallPlanSelector: View {
    let plans: [PaywallPlan]
    let selectedKind: LumenPlanKind
    var isEnabled: Bool
    var unavailableMessage: String?
    let onSelect: (LumenPlanKind) -> Void

    var body: some View {
        if plans.isEmpty {
            Text(unavailableMessage ?? "Lumen Plus isn't available right now.")
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.lg)
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .strokeBorder(PaywallColors.cardBorder, lineWidth: 1)
                }
        } else {
            VStack(spacing: AppSpacing.xs) {
                ForEach(plans) { plan in
                    PaywallPlanRow(
                        plan: plan,
                        isSelected: plan.kind == selectedKind,
                        isEnabled: isEnabled,
                        onSelect: { onSelect(plan.kind) }
                    )
                }
            }
        }
    }
}

private struct PaywallPlanRow: View {
    let plan: PaywallPlan
    let isSelected: Bool
    var isEnabled: Bool
    let onSelect: () -> Void

    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .headline) private var minimumTextWidth: CGFloat = 128
    @ScaledMetric(relativeTo: .caption) private var markSize: CGFloat = 22

    var body: some View {
        Button(action: onSelect) {
            PaywallPlanLayout(spacing: AppSpacing.sm, minimumTextWidth: minimumTextWidth) {
                leading
                priceUnit
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm + 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? PaywallColors.selectedSurface : AppColors.surface, in: shape)
            .overlay {
                shape.strokeBorder(borderColor, lineWidth: borderWidth)
            }
            .contentShape(shape)
        }
        .buttonStyle(PressScaleStyle())
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityInputLabels([
            plan.kind.title,
            presentedName,
            "\(plan.kind.title) plan"
        ])
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("paywall.plan.\(plan.kind.rawValue)")
    }

    private var leading: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            mark
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                kickerRow
                Text(presentedName)
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var mark: some View {
        ZStack {
            Circle()
                .fill(isSelected ? PaywallColors.accentText : Color.clear)
            Circle()
                .strokeBorder(
                    isSelected ? Color.clear : AppColors.textSecondary,
                    lineWidth: contrast == .increased ? 2 : 1.5
                )
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: markSize * 0.46, weight: .bold))
                    .foregroundStyle(PaywallColors.markGlyph)
            }
        }
        .frame(width: markSize, height: markSize)
        .accessibilityHidden(true)
        .padding(.top, 1)
    }

    @ViewBuilder
    private var kickerRow: some View {
        if let recommendation {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: AppSpacing.xs) {
                    kicker
                    recommendationBadge(recommendation)
                }
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    kicker
                    recommendationBadge(recommendation)
                }
            }
        } else {
            kicker
        }
    }

    private var kicker: some View {
        Text(plan.kind.title)
            .font(AppTypography.captionBold)
            .textCase(.uppercase)
            .tracking(dynamicTypeSize.isAccessibilitySize ? 0 : 0.7)
            .foregroundStyle(isSelected ? PaywallColors.accentText : AppColors.textSecondary)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    private func recommendationBadge(_ text: String) -> some View {
        recommendationLabel(text)
            .font(AppTypography.captionBold)
            .textCase(.uppercase)
            .foregroundStyle(PaywallColors.accentText)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, AppSpacing.xxs)
            .background(PaywallColors.accentSoft, in: RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
            .accessibilityHidden(true)
    }

    /// Keeps the full recommendation visible. A single line is used when it fits; otherwise each phrase scales instead of truncating.
    @ViewBuilder
    private func recommendationLabel(_ text: String) -> some View {
        let parts = text.components(separatedBy: " · ")
        if parts.count == 2 {
            ViewThatFits(in: .horizontal) {
                Text(text)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                VStack(alignment: .leading, spacing: 1) {
                    Text(parts[0])
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text(parts[1])
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            Text(text)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// `displayPrice` stays one text run so a localized price cannot break into amount and currency.
    private var priceUnit: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(plan.displayPrice)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .allowsTightening(true)
                .multilineTextAlignment(.trailing)
            Text(plan.periodCaption)
                .font(AppTypography.footnote)
                .foregroundStyle(secondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityHidden(true)
    }

    private var presentedName: String {
        let trimmed = plan.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.compare(plan.kind.title, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
            return "Lumen Plus \(plan.kind.title)"
        }
        return trimmed
    }

    private var recommendation: String? {
        guard plan.kind == .annual else { return nil }
        if let savings = plan.savingsText, !savings.isEmpty {
            return "\(savings) · Recommended"
        }
        return "Best value"
    }

    private var spokenPeriod: String {
        if plan.kind == .lifetime {
            return "One-time purchase"
        }
        let raw = plan.periodCaption.hasPrefix("/") ? String(plan.periodCaption.dropFirst()) : plan.periodCaption
        return "per \(raw)"
    }

    private var accessibilityDescription: String {
        var parts = [presentedName, plan.displayPrice, spokenPeriod]
        if let recommendation {
            parts.append(recommendation)
        }
        return parts.joined(separator: ", ")
    }

    private var secondary: Color {
        contrast == .increased ? AppColors.textPrimary : AppColors.textSecondary
    }

    private var borderColor: Color {
        if isSelected { return PaywallColors.accentText }
        return contrast == .increased ? PaywallColors.cardBorderStrong : PaywallColors.cardBorder
    }

    private var borderWidth: CGFloat {
        if isSelected { return contrast == .increased ? 2 : 1.5 }
        return contrast == .increased ? 1.5 : 1
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
    }
}

struct PaywallCTA: View {
    let title: String
    var isBusy: Bool
    var isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if isBusy {
                    ProgressView()
                        .controlSize(.regular)
                        .tint(AppColors.onAccent)
                }
                Text(title)
                    .font(AppTypography.button)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(AppColors.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.md)
            .frame(minHeight: AppSpacing.touch)
            .background(PaywallColors.ctaFill, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
        .buttonStyle(PressScaleStyle())
        .disabled(!isEnabled)
        .accessibilityLabel(title)
        .accessibilityIdentifier("paywall.purchase")
    }
}

struct PaywallActionBar: View {
    let title: String
    var status: String?
    var statusColor: Color
    var isBusy: Bool
    var isEnabled: Bool
    var showsManage: Bool
    let onPrimary: () -> Void
    let onRestore: () -> Void
    let onManage: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.xxs) {
            if let status, !status.isEmpty {
                Text(status)
                    .font(AppTypography.callout)
                    .foregroundStyle(statusColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, AppSpacing.xxs)
                    .accessibilityAddTraits(.updatesFrequently)
            }

            PaywallCTA(title: title, isBusy: isBusy, isEnabled: isEnabled, action: onPrimary)

            Button("Restore Purchases", action: onRestore)
                .font(AppTypography.callout.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, minHeight: AppSpacing.touch)
                .disabled(isBusy)
                .accessibilityIdentifier("paywall.restore")

            if showsManage {
                Button("Manage Subscription", action: onManage)
                    .font(AppTypography.callout.weight(.semibold))
                    .foregroundStyle(PaywallColors.accentText)
                    .frame(maxWidth: .infinity, minHeight: AppSpacing.touch)
                    .disabled(isBusy)
                    .accessibilityIdentifier("paywall.manage")
            }
        }
    }
}

struct PaywallLegal: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.colorSchemeContrast) private var contrast

    private let disclosure = "Monthly and Annual renew automatically until you cancel in your Apple ID settings at least 24 hours before the period ends. Lifetime is a one-time purchase and does not renew. Payment is charged to your Apple ID."

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(disclosure)
                .font(.subheadline)
                .foregroundStyle(secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppSpacing.lg) {
                    legalLink("Terms of Use", url: LegalConfiguration.termsURL, document: .terms)
                    legalLink("Privacy Policy", url: LegalConfiguration.privacyURL, document: .privacy)
                }
                VStack(alignment: .leading, spacing: 0) {
                    legalLink("Terms of Use", url: LegalConfiguration.termsURL, document: .terms)
                    legalLink("Privacy Policy", url: LegalConfiguration.privacyURL, document: .privacy)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var secondary: Color {
        contrast == .increased ? AppColors.textPrimary : AppColors.textSecondary
    }

    @ViewBuilder
    private func legalLink(_ title: String, url: URL?, document: LegalDocument) -> some View {
        Group {
            if let url {
                Button(title) { openURL(url) }
                    .buttonStyle(.plain)
            } else {
                NavigationLink {
                    LegalView(document: document)
                } label: {
                    Text(title)
                }
                .buttonStyle(.plain)
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(PaywallColors.accentText)
        .underline()
        .frame(minHeight: AppSpacing.touch, alignment: .leading)
        .accessibilityIdentifier(document == .terms ? "paywall.terms" : "paywall.privacy")
    }
}

private struct PaywallPlanLayout: Layout {
    var spacing: CGFloat
    var minimumTextWidth: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrangement(width: proposal.width, subviews: subviews).total
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else {
            placeFallback(in: bounds, subviews: subviews)
            return
        }
        let plan = arrangement(width: bounds.width, subviews: subviews)
        if plan.stacked {
            subviews[0].place(
                at: CGPoint(x: bounds.minX, y: bounds.minY),
                proposal: ProposedViewSize(width: bounds.width, height: plan.lead.height)
            )
            subviews[1].place(
                at: CGPoint(x: bounds.maxX, y: bounds.minY + plan.lead.height + spacing),
                anchor: .topTrailing,
                proposal: ProposedViewSize(width: plan.price.width, height: plan.price.height)
            )
        } else {
            let leadWidth = max(0, bounds.width - plan.price.width - spacing)
            let leadY = bounds.minY + (plan.total.height - plan.lead.height) / 2
            subviews[0].place(
                at: CGPoint(x: bounds.minX, y: leadY),
                proposal: ProposedViewSize(width: leadWidth, height: plan.lead.height)
            )
            let priceY = bounds.minY + (plan.total.height - plan.price.height) / 2
            subviews[1].place(
                at: CGPoint(x: bounds.maxX, y: priceY),
                anchor: .topTrailing,
                proposal: ProposedViewSize(width: plan.price.width, height: plan.price.height)
            )
        }
    }

    private func arrangement(width: CGFloat?, subviews: Subviews) -> Arrangement {
        guard subviews.count == 2 else {
            let size = fallbackSize(width: width, subviews: subviews)
            return Arrangement(stacked: true, price: .zero, lead: size, total: size)
        }

        let priceIdeal = subviews[1].sizeThatFits(.unspecified)
        if width == nil {
            let lead = subviews[0].sizeThatFits(.unspecified)
            let total = CGSize(
                width: lead.width + spacing + priceIdeal.width,
                height: max(lead.height, priceIdeal.height)
            )
            return Arrangement(stacked: false, price: priceIdeal, lead: lead, total: total)
        }

        let available = width ?? 0
        let roomForText = available - priceIdeal.width - spacing
        let stacked = roomForText < minimumTextWidth || priceIdeal.width > available
        if stacked {
            let lead = subviews[0].sizeThatFits(ProposedViewSize(width: available, height: nil))
            let priceWidth = min(max(priceIdeal.width, 1), available)
            let price = subviews[1].sizeThatFits(ProposedViewSize(width: priceWidth, height: nil))
            let total = CGSize(width: available, height: lead.height + spacing + price.height)
            return Arrangement(stacked: true, price: CGSize(width: priceWidth, height: price.height), lead: lead, total: total)
        }

        let leadWidth = max(0, available - priceIdeal.width - spacing)
        let lead = subviews[0].sizeThatFits(ProposedViewSize(width: leadWidth, height: nil))
        let total = CGSize(width: available, height: max(lead.height, priceIdeal.height))
        return Arrangement(stacked: false, price: priceIdeal, lead: lead, total: total)
    }

    private func fallbackSize(width: CGFloat?, subviews: Subviews) -> CGSize {
        var height: CGFloat = 0
        var measuredWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
            height += size.height
            measuredWidth = max(measuredWidth, size.width)
        }
        if subviews.count > 1 {
            height += spacing * CGFloat(subviews.count - 1)
        }
        return CGSize(width: width ?? measuredWidth, height: height)
    }

    private func placeFallback(in bounds: CGRect, subviews: Subviews) {
        var y = bounds.minY
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            subview.place(
                at: CGPoint(x: bounds.minX, y: y),
                proposal: ProposedViewSize(width: bounds.width, height: size.height)
            )
            y += size.height + spacing
        }
    }

    private struct Arrangement {
        var stacked: Bool
        var price: CGSize
        var lead: CGSize
        var total: CGSize
    }
}
