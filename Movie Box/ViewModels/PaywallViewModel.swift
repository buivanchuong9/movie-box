import Foundation
import Observation
import StoreKit

struct PaywallPlan: Identifiable, Equatable {
    let id: String
    let kind: LumenPlanKind
    let name: String
    let displayPrice: String
    let priceLine: String
    let billingNote: String
    let savingsText: String?
}

enum PaywallPhase: Equatable {
    case loading
    case ready
    case purchasing
    case success
    case cancelled
    case pending
    case failed
    case alreadyPurchased
    case restoring
    case restored
    case nothingToRestore
    case unavailable
    case network
}

@MainActor
@Observable
final class PaywallViewModel {
    private let store: StoreKitService
    private let entitlements: EntitlementManager

    var plans: [PaywallPlan] = []
    var selectedKind: LumenPlanKind = .annual
    var phase: PaywallPhase = .loading
    var statusText: String?

    init(store: StoreKitService, entitlements: EntitlementManager) {
        self.store = store
        self.entitlements = entitlements
    }

    var selectedPlan: PaywallPlan? {
        plans.first { $0.kind == selectedKind } ?? plans.first
    }

    var showsManageSubscription: Bool {
        entitlements.current.canManageSubscription
    }

    func load() async {
        phase = .loading
        statusText = nil
        let outcome = await store.loadProducts()
        rebuildPlans()
        switch outcome {
        case .loaded:
            phase = .ready
            if selectedPlan == nil, let first = plans.first {
                selectedKind = first.kind
            }
            if !plans.contains(where: { $0.kind == selectedKind }), let first = plans.first {
                selectedKind = first.kind
            }
        case .empty:
            phase = .unavailable
            statusText = "Lumen Plus isn't available right now."
        case .network:
            phase = .network
            statusText = "Purchases couldn't be reached. Check your connection and try again."
        case .failed:
            phase = .failed
            statusText = "Purchases couldn't be loaded. Please try again."
        }
    }

    func select(_ kind: LumenPlanKind) {
        selectedKind = kind
        if phase != .purchasing && phase != .restoring {
            phase = plans.isEmpty ? phase : .ready
            statusText = nil
        }
    }

    func purchaseSelected() async {
        guard let plan = selectedPlan, let product = store.product(for: plan.kind) else { return }
        if entitlements.alreadyIncludes(plan.kind) {
            phase = .alreadyPurchased
            statusText = "Lumen Plus is already active on this Apple ID."
            return
        }
        phase = .purchasing
        statusText = nil
        switch await store.purchase(product) {
        case .success:
            phase = .success
            statusText = "Lumen Plus is active."
        case .cancelled:
            phase = .cancelled
            statusText = "Purchase cancelled."
        case .pending:
            phase = .pending
            statusText = "Your purchase is waiting for approval."
        case .network:
            phase = .network
            statusText = "Purchases couldn't be reached. Check your connection and try again."
        case .failed, .unverified:
            phase = .failed
            statusText = "The purchase couldn't be completed. Please try again."
        }
    }

    func restore() async {
        phase = .restoring
        statusText = nil
        switch await store.restore() {
        case .restored:
            phase = .restored
            statusText = "Purchases restored"
        case .nothingFound:
            phase = .nothingToRestore
            statusText = "No previous purchases found."
        case .network:
            phase = .network
            statusText = "Purchases couldn't be reached. Check your connection and try again."
        case .failed:
            phase = .failed
            statusText = "Purchases couldn't be restored. Please try again."
        }
    }

    func manageSubscription() async {
        await store.showManageSubscriptions()
    }

    private func rebuildPlans() {
        let monthly = store.product(for: .monthly)
        let annual = store.product(for: .annual)
        let savings = monthly.flatMap { month in
            annual.flatMap { year in PlanPricing.annualSavingsPercent(monthly: month, annual: year) }
        }
        plans = store.orderedProducts().map { product in
            let kind = LumenProductID.kind(for: product.id) ?? .monthly
            let suffix = PlanPricing.periodSuffix(for: product)
            let priceLine = suffix.map { "\(product.displayPrice) / \($0)" } ?? product.displayPrice
            let billingNote: String
            switch kind {
            case .monthly:
                billingNote = "Billed monthly"
            case .annual:
                billingNote = "Billed yearly"
            case .lifetime:
                billingNote = "One time"
            }
            let savingsText = kind == .annual ? savings.map { "Save \($0)%" } : nil
            return PaywallPlan(
                id: product.id,
                kind: kind,
                name: product.displayName,
                displayPrice: product.displayPrice,
                priceLine: priceLine,
                billingNote: billingNote,
                savingsText: savingsText
            )
        }
    }
}
