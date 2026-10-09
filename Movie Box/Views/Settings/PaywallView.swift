import SwiftUI

struct PaywallView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var embedded = false
    var required = false
    @State private var model: PaywallViewModel?

    init(embedded: Bool = false, required: Bool = false, model: PaywallViewModel? = nil) {
        self.embedded = embedded
        self.required = required
        _model = State(initialValue: model)
    }

    var body: some View {
        VStack(spacing: 0) {
            PaywallColumn(padding: horizontalPadding) {
                PaywallHeader(showsClose: !required, onClose: close)
                    .padding(.top, AppSpacing.xs)
                    .padding(.bottom, AppSpacing.xxs)
            }
            .layoutPriority(1)

            ScrollView {
                PaywallColumn(padding: horizontalPadding) {
                    scrollStack
                        .padding(.top, AppSpacing.sm)
                        .padding(.bottom, AppSpacing.lg)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(minHeight: 0, maxHeight: .infinity)

            Group {
                if pinsActions, let model, showsActions(model) {
                    PaywallColumn(padding: horizontalPadding) {
                        VStack(spacing: AppSpacing.sm) {
                            Rectangle()
                                .fill(PaywallColors.cardBorder)
                                .frame(height: 1)
                                .accessibilityHidden(true)
                            actionBar(model)
                        }
                        .padding(.top, AppSpacing.xs)
                        .padding(.bottom, AppSpacing.md)
                    }
                    .background(AppColors.background)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Lumen Plus")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(embedded ? .automatic : .hidden, for: .navigationBar)
        .interactiveDismissDisabled(required)
        .task { await prepare() }
    }

    private var scrollStack: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            PaywallHero()

            if env.entitlements.isPremium, !activeText.isEmpty {
                Text(activeText)
                    .font(AppTypography.callout.weight(.semibold))
                    .foregroundStyle(AppColors.positive)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PaywallBenefits()
            plansSection

            if let model, !pinsActions, showsActions(model) {
                actionBar(model)
            }

            PaywallLegal()
        }
    }

    @ViewBuilder
    private var plansSection: some View {
        if let model {
            if model.phase == .loading && model.plans.isEmpty {
                ProgressView("Loading plans")
                    .tint(PaywallColors.accentText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl)
            } else {
                PaywallPlanSelector(
                    plans: model.plans,
                    selectedKind: model.selectedKind,
                    isEnabled: !isBusy(model),
                    unavailableMessage: model.statusText,
                    onSelect: { select($0, model: model) }
                )
            }
        } else {
            ProgressView("Loading plans")
                .tint(PaywallColors.accentText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xl)
        }
    }

    private func actionBar(_ model: PaywallViewModel) -> some View {
        PaywallActionBar(
            title: primaryTitle(model),
            status: statusText(model),
            statusColor: statusColor(model.phase),
            isBusy: isBusy(model),
            isEnabled: primaryEnabled(model),
            showsManage: model.showsManageSubscription,
            onPrimary: { performPrimary(model) },
            onRestore: { restore(model) },
            onManage: { manage(model) }
        )
    }

    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? AppSpacing.xl : AppSpacing.lg
    }

    private var sectionSpacing: CGFloat {
        verticalSizeClass == .compact ? AppSpacing.md : AppSpacing.xl
    }

    private var pinsActions: Bool {
        !dynamicTypeSize.isAccessibilitySize
    }

    private var activeText: String {
        switch env.entitlements.current {
        case .monthly: "Monthly Lumen Plus is active."
        case .annual: "Annual Lumen Plus is active."
        case .lifetime: "Lifetime Lumen Plus is active."
        case .notEntitled: ""
        }
    }

    private func showsActions(_ model: PaywallViewModel) -> Bool {
        !(model.plans.isEmpty && model.phase == .loading)
    }

    private func isBusy(_ model: PaywallViewModel) -> Bool {
        switch model.phase {
        case .purchasing, .restoring, .loading:
            true
        default:
            false
        }
    }

    private func primaryEnabled(_ model: PaywallViewModel) -> Bool {
        if isBusy(model) { return false }
        if model.plans.isEmpty { return true }
        return model.selectedPlan != nil
    }

    private func primaryTitle(_ model: PaywallViewModel) -> String {
        if model.plans.isEmpty { return "Try Again" }
        switch model.phase {
        case .purchasing, .restoring, .loading:
            return "Please wait"
        default:
            if let name = model.selectedPlan?.kind.title {
                return "Continue with \(name)"
            }
            return "Continue"
        }
    }

    private func statusText(_ model: PaywallViewModel) -> String? {
        guard !model.plans.isEmpty else { return nil }
        return model.statusText
    }

    private func statusColor(_ phase: PaywallPhase) -> Color {
        switch phase {
        case .success, .restored, .alreadyPurchased:
            AppColors.positive
        case .failed, .network, .unavailable:
            AppColors.textPrimary
        default:
            AppColors.textSecondary
        }
    }

    private func close() {
        dismiss()
    }

    private func select(_ kind: LumenPlanKind, model: PaywallViewModel) {
        Haptics.selection()
        if reduceMotion {
            model.select(kind)
        } else {
            withAnimation(AppAnimation.quick) {
                model.select(kind)
            }
        }
    }

    private func performPrimary(_ model: PaywallViewModel) {
        Task {
            if model.plans.isEmpty {
                await model.load()
            } else {
                await model.purchaseSelected()
            }
        }
    }

    private func restore(_ model: PaywallViewModel) {
        Task { await model.restore() }
    }

    private func manage(_ model: PaywallViewModel) {
        Task { await model.manageSubscription() }
    }

    private func prepare() async {
        if model == nil {
            model = PaywallViewModel(store: env.store, entitlements: env.entitlements)
        }
        guard let model else { return }
        if model.phase == .loading || model.plans.isEmpty {
            await model.load()
        }
    }
}

struct PremiumView: View {
    var body: some View {
        PaywallView(embedded: true)
    }
}

#if DEBUG
#Preview("Dark · Annual") {
    PaywallView(model: .layoutPreview(selected: .annual))
        .environment(AppEnvironment.preview)
        .preferredColorScheme(.dark)
}

#Preview("Light · Monthly") {
    PaywallView(model: .layoutPreview(selected: .monthly))
        .environment(AppEnvironment.preview)
        .preferredColorScheme(.light)
}

#Preview("Lifetime · Light") {
    PaywallView(model: .layoutPreview(selected: .lifetime))
        .environment(AppEnvironment.preview)
        .preferredColorScheme(.light)
}

#Preview("Long prices") {
    PaywallView(model: .layoutPreview(
        selected: .annual,
        prices: ("24,99 US$", "1.249.000 ₫", "¥12,800")
    ))
    .environment(AppEnvironment.preview)
    .preferredColorScheme(.dark)
}

#Preview("Narrow") {
    PaywallView(model: .layoutPreview(
        selected: .annual,
        prices: ("24,99 US$", "1.249.000 ₫", "¥12,800")
    ))
    .environment(AppEnvironment.preview)
    .frame(width: 320, height: 700)
    .preferredColorScheme(.dark)
}

#Preview("Large text") {
    PaywallView(model: .layoutPreview(selected: .annual))
        .environment(AppEnvironment.preview)
        .environment(\.dynamicTypeSize, .accessibility2)
        .preferredColorScheme(.light)
}
#endif
