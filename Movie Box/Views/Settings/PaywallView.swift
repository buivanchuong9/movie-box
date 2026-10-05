import SwiftUI

struct PaywallView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.openURL) private var openURL
    @State private var model: PaywallViewModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                if env.entitlements.isPremium {
                    activeBanner
                }
                if let model {
                    plans(model)
                    status(model)
                    purchaseButton(model)
                    restoreButton(model)
                    if model.showsManageSubscription {
                        Button("Manage Subscription") {
                            Task { await model.manageSubscription() }
                        }
                        .font(AppTypography.button)
                        .foregroundStyle(AppColors.accent)
                        .frame(maxWidth: .infinity, minHeight: AppSpacing.touch)
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 120)
                }
                legal
            }
            .padding(AppSpacing.page)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background)
        .navigationTitle("Lumen Plus")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if model == nil {
                model = PaywallViewModel(store: env.store, entitlements: env.entitlements)
            }
            if model?.phase == .loading || model?.plans.isEmpty == true {
                await model?.load()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Lumen Plus")
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text("Get more from your movie discovery experience.")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Home, search, details, and your lists stay free.")
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var activeBanner: some View {
        Text(activeText)
            .font(AppTypography.cardTitle)
            .foregroundStyle(AppColors.positive)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var activeText: String {
        switch env.entitlements.current {
        case .monthly: "Monthly Lumen Plus is active."
        case .annual: "Annual Lumen Plus is active."
        case .lifetime: "Lifetime Lumen Plus is active."
        case .notEntitled: ""
        }
    }

    @ViewBuilder
    private func plans(_ model: PaywallViewModel) -> some View {
        if model.phase == .loading && model.plans.isEmpty {
            ProgressView("Loading plans")
                .frame(maxWidth: .infinity, minHeight: 88)
        } else if model.plans.isEmpty {
            Text(model.statusText ?? "Lumen Plus isn't available right now.")
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            VStack(spacing: AppSpacing.sm) {
                ForEach(model.plans) { plan in
                    planCard(plan, model: model)
                }
            }
        }
    }

    private func planCard(_ plan: PaywallPlan, model: PaywallViewModel) -> some View {
        let selected = model.selectedKind == plan.kind
        return Button {
            model.select(plan.kind)
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(plan.kind.title.uppercased())
                        .font(AppTypography.captionBold)
                        .tracking(0.6)
                        .foregroundStyle(AppColors.accent)
                    Spacer(minLength: AppSpacing.sm)
                    if let savings = plan.savingsText {
                        Text(savings.uppercased())
                            .font(AppTypography.captionBold)
                            .foregroundStyle(AppColors.onAccent)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 4)
                            .background(AppColors.accent, in: Capsule())
                    }
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.accent)
                            .accessibilityHidden(true)
                    }
                }
                Text(plan.name)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(plan.priceLine)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(plan.billingNote)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(selected ? AppColors.accent : AppColors.separator, lineWidth: selected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(model.phase == .purchasing || model.phase == .restoring)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel("\(plan.name), \(plan.priceLine), \(plan.billingNote)")
    }

    @ViewBuilder
    private func status(_ model: PaywallViewModel) -> some View {
        if let status = model.statusText, !model.plans.isEmpty {
            Text(status)
                .font(AppTypography.callout)
                .foregroundStyle(statusColor(model.phase))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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

    @ViewBuilder
    private func purchaseButton(_ model: PaywallViewModel) -> some View {
        let busy = model.phase == .purchasing || model.phase == .loading || model.phase == .restoring
        if model.phase == .loading && model.plans.isEmpty {
            EmptyView()
        } else if model.plans.isEmpty {
            Button {
                Task { await model.load() }
            } label: {
                PrimaryButtonLabel(title: "Try Again")
            }
            .buttonStyle(PressScaleStyle())
            .disabled(model.phase == .loading)
        } else {
            Button {
                Task { await model.purchaseSelected() }
            } label: {
                PrimaryButtonLabel(title: busy ? "Please wait" : "Continue", systemImage: busy ? nil : "sparkles")
            }
            .buttonStyle(PressScaleStyle())
            .disabled(busy || model.selectedPlan == nil)
            .overlay {
                if model.phase == .purchasing {
                    ProgressView()
                        .tint(AppColors.onAccent)
                }
            }
        }
    }

    private func restoreButton(_ model: PaywallViewModel) -> some View {
        Button("Restore Purchases") {
            Task { await model.restore() }
        }
        .font(AppTypography.button)
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity, minHeight: AppSpacing.touch)
        .disabled(model.phase == .purchasing || model.phase == .restoring)
    }

    private var legal: some View {
        HStack(spacing: AppSpacing.lg) {
            legalLink("Terms of Use", url: LegalConfiguration.termsURL, document: .terms)
            legalLink("Privacy Policy", url: LegalConfiguration.privacyURL, document: .privacy)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func legalLink(_ title: String, url: URL?, document: LegalDocument) -> some View {
        if let url {
            Button(title) { openURL(url) }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        } else {
            NavigationLink(title) {
                LegalView(document: document)
            }
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
        }
    }
}

struct PremiumView: View {
    var body: some View {
        PaywallView()
    }
}
