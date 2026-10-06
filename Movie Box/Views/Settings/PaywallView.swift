import SwiftUI

enum LaunchOffer {
    private static let key = "lumen.launchOffer.dismissed"

    static var isDismissed: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

struct PaywallView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.openURL) private var openURL
    var allowsDismiss = false
    var onDismiss: () -> Void = {}
    @State private var model: PaywallViewModel?

    var body: some View {
        ZStack(alignment: .top) {
            background
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        header
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
        .toolbar(allowsDismiss ? .hidden : .automatic, for: .navigationBar)
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
        ZStack {
            AppColors.background
            Circle()
                .fill(AppColors.accent.opacity(0.22))
                .frame(width: 280, height: 280)
                .blur(radius: 40)
                .offset(y: -220)
            Circle()
                .fill(AppColors.accent.opacity(0.08))
                .frame(width: 180, height: 180)
                .blur(radius: 30)
                .offset(x: 120, y: -80)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(AppColors.accent)
                    .frame(width: 8, height: 18)
                Text("LUMEN")
                    .font(AppTypography.wordmark)
                    .tracking(2.4)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Lumen")
            Spacer()
            if allowsDismiss {
                Button("Not now") { onDismiss() }
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(minHeight: AppSpacing.touch)
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
            Text("Get more from your movie discovery experience.")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, AppSpacing.sm)
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
                            .foregroundStyle(featured ? AppColors.onAccent : AppColors.accent)
                        if let savings = plan.savingsText {
                            Text(savings.uppercased())
                                .font(AppTypography.captionBold)
                                .foregroundStyle(AppColors.onAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppColors.accentFill, in: Capsule())
                        }
                    }
                    Text(plan.name)
                        .font(featured ? AppTypography.section : AppTypography.cardTitle)
                        .foregroundStyle(featured && selected ? AppColors.onAccent : AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(plan.billingNote)
                        .font(AppTypography.caption)
                        .foregroundStyle(featured && selected ? AppColors.onAccent.opacity(0.75) : AppColors.textSecondary)
                }
                Spacer(minLength: AppSpacing.sm)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(plan.displayPrice)
                        .font(featured ? AppTypography.ratingLarge : AppTypography.section)
                        .foregroundStyle(featured && selected ? AppColors.onAccent : AppColors.textPrimary)
                        .multilineTextAlignment(.trailing)
                        .minimumScaleFactor(0.7)
                    if let period = periodLabel(for: plan) {
                        Text(period)
                            .font(AppTypography.captionBold)
                            .foregroundStyle(featured && selected ? AppColors.onAccent.opacity(0.8) : AppColors.textTertiary)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, featured ? AppSpacing.lg : AppSpacing.md)
            .frame(maxWidth: .infinity, minHeight: featured ? 108 : 88, alignment: .leading)
            .background(cardBackground(featured: featured, selected: selected))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous)
                    .strokeBorder(cardStroke(featured: featured, selected: selected), lineWidth: selected ? 2 : 1)
            }
            .shadow(color: selected ? AppColors.accent.opacity(0.28) : .clear, radius: 16, y: 8)
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

    private func cardBackground(featured: Bool, selected: Bool) -> some ShapeStyle {
        if featured && selected {
            AnyShapeStyle(LinearGradient(
                colors: [AppColors.accentFill, AppColors.accent.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        } else if selected {
            AnyShapeStyle(AppColors.elevated)
        } else {
            AnyShapeStyle(AppColors.surface)
        }
    }

    private func cardStroke(featured: Bool, selected: Bool) -> Color {
        if selected { return AppColors.accent }
        if featured { return AppColors.accent.opacity(0.55) }
        return AppColors.separator
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
        let finished = model.phase == .success || model.phase == .restored || model.phase == .alreadyPurchased
        let busy = model.phase == .purchasing || model.phase == .loading || model.phase == .restoring
        if model.phase == .loading && model.plans.isEmpty {
            EmptyView()
        } else if finished && allowsDismiss {
            Button(action: onDismiss) {
                PrimaryButtonLabel(title: "Continue", systemImage: "checkmark")
            }
            .buttonStyle(PressScaleStyle())
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

struct PremiumView: View {
    var body: some View {
        PaywallView()
    }
}
