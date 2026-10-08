import SwiftUI

struct PaywallView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    var embedded = false
    var required = false
    @State private var model: PaywallViewModel?

    var body: some View {
        ZStack(alignment: .top) {
            background
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        header
                        benefits
                        if env.entitlements.isPremium {
                            activeBanner
                        }
                        if let model {
                            plans(model)
                            status(model)
                        } else {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 160)
                        }
                        legal
                    }
                    .padding(.horizontal, AppSpacing.page)
                    .padding(.bottom, AppSpacing.xl)
                    .lumenColumn(maxWidth: 640)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let model {
                footer(model)
            }
        }
        .background(AppColors.background)
        .navigationTitle("Lumen Plus")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(embedded ? .automatic : .hidden, for: .navigationBar)
        .interactiveDismissDisabled(required)
        .task {
            if model == nil {
                model = PaywallViewModel(store: env.store, entitlements: env.entitlements)
            }
            if model?.phase == .loading || model?.plans.isEmpty == true {
                await model?.load()
            }
        }
    }

    private var background: some View {
        AppColors.background
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image("AppLogo")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                Text("Movie Box")
                    .font(AppTypography.wordmark)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Movie Box")
            Spacer()
            if !required {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: AppSpacing.touch, height: AppSpacing.touch)
                        .background(AppColors.surface, in: Circle())
                        .overlay { Circle().strokeBorder(AppColors.separator, lineWidth: 1) }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
        }
        .padding(.horizontal, AppSpacing.page)
        .padding(.top, AppSpacing.sm)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Lumen Plus")
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text(required ? "Choose a plan to use Movie Box." : "A quieter way to keep your movie library.")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, AppSpacing.xs)
        .accessibilityElement(children: .combine)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            benefit("Advanced filters")
            benefit("Personalized recommendations")
            benefit("Viewing statistics")
            benefit("A premium library experience")
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(AppColors.separator, lineWidth: 1)
        }
    }

    private func benefit(_ title: String) -> some View {
        Label(title, systemImage: "checkmark")
            .font(AppTypography.callout)
            .foregroundStyle(AppColors.textPrimary)
            .labelStyle(BenefitLabelStyle())
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
                .frame(maxWidth: .infinity, minHeight: 180)
        } else if model.plans.isEmpty {
            Text(model.statusText ?? "Lumen Plus isn't available right now.")
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.lg)
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous))
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
        let featured = plan.kind == .annual
        return Button {
            model.select(plan.kind)
        } label: {
            HStack(alignment: .center, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: AppSpacing.xs) {
                        Text(plan.kind.title.uppercased())
                            .font(AppTypography.captionBold)
                            .tracking(1.1)
                            .foregroundStyle(selected ? AppColors.onAccent : AppColors.accent)
                        if let savings = plan.savingsText {
                            Text(savings.uppercased())
                                .font(AppTypography.captionBold)
                                .foregroundStyle(selected ? AppColors.onAccent : AppColors.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(selected ? AppColors.onAccent.opacity(0.16) : AppColors.accent.opacity(0.16), in: Capsule())
                        }
                    }
                    Text(plan.name)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(selected ? AppColors.onAccent : AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(plan.billingNote)
                        .font(AppTypography.caption)
                        .foregroundStyle(selected ? AppColors.onAccent.opacity(0.75) : AppColors.textSecondary)
                }
                Spacer(minLength: AppSpacing.sm)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(plan.displayPrice)
                        .font(AppTypography.ratingLarge)
                        .foregroundStyle(selected ? AppColors.onAccent : AppColors.textPrimary)
                        .multilineTextAlignment(.trailing)
                        .minimumScaleFactor(0.7)
                    if let period = periodLabel(for: plan) {
                        Text(period)
                            .font(AppTypography.captionBold)
                            .foregroundStyle(selected ? AppColors.onAccent.opacity(0.8) : AppColors.textTertiary)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .background(selected ? AppColors.accentFill : AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(selected ? AppColors.accentFill : (featured ? AppColors.accent.opacity(0.45) : AppColors.separator), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(model.phase == .purchasing || model.phase == .restoring)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel("\(plan.name), \(plan.priceLine), \(plan.billingNote)")
    }

    private func periodLabel(for plan: PaywallPlan) -> String? {
        guard plan.priceLine.contains(" / "), let suffix = plan.priceLine.split(separator: "/").last else { return nil }
        let period = suffix.trimmingCharacters(in: .whitespaces)
        guard !period.isEmpty else { return nil }
        return "/ \(period)"
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

    private func footer(_ model: PaywallViewModel) -> some View {
        VStack(spacing: AppSpacing.xs) {
            purchaseButton(model)
            HStack(spacing: AppSpacing.lg) {
                restoreButton(model)
                if model.showsManageSubscription {
                    Button("Manage Subscription") {
                        Task { await model.manageSubscription() }
                    }
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.accent)
                    .frame(minHeight: AppSpacing.touch)
                }
            }
        }
        .padding(.horizontal, AppSpacing.page)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.md)
        .background(
            LinearGradient(
                colors: [AppColors.background.opacity(0), AppColors.background, AppColors.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        )
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
                PrimaryButtonLabel(
                    title: purchaseTitle(model),
                    systemImage: busy ? nil : "sparkles"
                )
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

    private func purchaseTitle(_ model: PaywallViewModel) -> String {
        switch model.phase {
        case .purchasing, .restoring, .loading:
            "Please wait"
        default:
            if let name = model.selectedPlan?.kind.title {
                "Continue with \(name)"
            } else {
                "Continue"
            }
        }
    }

    private func restoreButton(_ model: PaywallViewModel) -> some View {
        Button("Restore Purchases") {
            Task { await model.restore() }
        }
        .font(AppTypography.captionBold)
        .foregroundStyle(AppColors.textSecondary)
        .frame(minHeight: AppSpacing.touch)
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

private struct BenefitLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: AppSpacing.sm) {
            configuration.icon
                .font(.caption.weight(.bold))
                .foregroundStyle(AppColors.accent)
                .frame(width: 22, height: 22)
                .background(AppColors.accent.opacity(0.16), in: Circle())
            configuration.title
        }
    }
}

struct PremiumView: View {
    var body: some View {
        PaywallView(embedded: true)
    }
}
