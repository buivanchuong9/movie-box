import Foundation
import Observation
import StoreKit
import UIKit

enum LumenPlanKind: String, CaseIterable, Identifiable {
    case monthly
    case annual
    case lifetime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly: "Monthly"
        case .annual: "Annual"
        case .lifetime: "Lifetime"
        }
    }
}

enum LumenProductID {
    static let monthly = "com.lumen.discovery.plus.monthly"
    static let annual = "com.lumen.discovery.plus.annual"
    static let lifetime = "com.lumen.discovery.plus.lifetime"
    static let all = [monthly, annual, lifetime]

    static func kind(for productID: String) -> LumenPlanKind? {
        switch productID {
        case monthly: .monthly
        case annual: .annual
        case lifetime: .lifetime
        default: nil
        }
    }

    static func id(for kind: LumenPlanKind) -> String {
        switch kind {
        case .monthly: monthly
        case .annual: annual
        case .lifetime: lifetime
        }
    }
}

enum LumenPlusEntitlement: Equatable {
    case notEntitled
    case monthly
    case annual
    case lifetime

    var isPremium: Bool { self != .notEntitled }

    var canManageSubscription: Bool {
        switch self {
        case .monthly, .annual: true
        default: false
        }
    }
}

enum StorePurchaseOutcome: Equatable {
    case success
    case cancelled
    case pending
    case failed
    case network
    case unverified
}

enum StoreRestoreOutcome: Equatable {
    case restored
    case nothingFound
    case failed
    case network
}

enum StoreLoadOutcome: Equatable {
    case loaded
    case empty
    case network
    case failed
}

@MainActor
@Observable
final class StoreKitService {
    private let entitlements: EntitlementManager
    private var updates: Task<Void, Never>?
    private(set) var products: [Product] = []
    private(set) var isLoadingProducts = false

    init(entitlements: EntitlementManager) {
        self.entitlements = entitlements
    }

    func start() {
        updates?.cancel()
        updates = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                await self.handle(update)
            }
        }
        Task { await loadProducts() }
    }

    func stop() {
        updates?.cancel()
        updates = nil
    }

    func orderedProducts() -> [Product] {
        LumenPlanKind.allCases.compactMap { kind in
            products.first { $0.id == LumenProductID.id(for: kind) }
        }
    }

    func product(for kind: LumenPlanKind) -> Product? {
        products.first { $0.id == LumenProductID.id(for: kind) }
    }

    func loadProducts() async -> StoreLoadOutcome {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let fetched = try await Product.products(for: LumenProductID.all)
            products = LumenPlanKind.allCases.compactMap { kind in
                fetched.first { $0.id == LumenProductID.id(for: kind) }
            }
            await refreshEntitlements()
            return products.isEmpty ? .empty : .loaded
        } catch {
            await refreshEntitlements()
            return Self.classify(error) == .network ? .network : .failed
        }
    }

    func purchase(_ product: Product) async -> StorePurchaseOutcome {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard let transaction = verified(verification) else { return .unverified }
                await transaction.finish()
                await refreshEntitlements()
                return entitlements.isPremium ? .success : .failed
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed
            }
        } catch {
            return Self.classify(error)
        }
    }

    func restore() async -> StoreRestoreOutcome {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            return entitlements.isPremium ? .restored : .nothingFound
        } catch {
            return Self.classify(error) == .network ? .network : .failed
        }
    }

    func showManageSubscriptions() async {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return }
        try? await AppStore.showManageSubscriptions(in: scene)
    }

    func refreshEntitlements() async {
        var active: [LumenPlanKind] = []
        for await result in Transaction.currentEntitlements {
            guard let transaction = verified(result) else { continue }
            guard LumenProductID.all.contains(transaction.productID) else { continue }
            guard transaction.revocationDate == nil else { continue }
            if let expiration = transaction.expirationDate, expiration < Date() { continue }
            if let kind = LumenProductID.kind(for: transaction.productID) {
                active.append(kind)
            }
            await transaction.finish()
        }
        entitlements.apply(Self.preferred(active))
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard let transaction = verified(result) else { return }
        await transaction.finish()
        await refreshEntitlements()
    }

    private func verified(_ result: VerificationResult<Transaction>) -> Transaction? {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified:
            return nil
        }
    }

    private static func preferred(_ kinds: [LumenPlanKind]) -> LumenPlusEntitlement {
        if kinds.contains(.lifetime) { return .lifetime }
        if kinds.contains(.annual) { return .annual }
        if kinds.contains(.monthly) { return .monthly }
        return .notEntitled
    }

    private static func classify(_ error: Error) -> StorePurchaseOutcome {
        if error is CancellationError { return .cancelled }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cancelled:
                return .cancelled
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return .network
            default:
                return .failed
            }
        }
        if let storeError = error as? StoreKitError {
            switch storeError {
            case .networkError:
                return .network
            case .userCancelled:
                return .cancelled
            default:
                return .failed
            }
        }
        return .failed
    }
}

enum PlanPricing {
    static func annualSavingsPercent(monthly: Product, annual: Product) -> Int? {
        let yearly = monthly.price * 12
        guard yearly > 0, annual.price < yearly else { return nil }
        let percent = (yearly - annual.price) / yearly * 100
        var rounded = Decimal()
        var source = percent
        NSDecimalRound(&rounded, &source, 0, .plain)
        let value = NSDecimalNumber(decimal: rounded).intValue
        guard value > 0, value < 100 else { return nil }
        return value
    }

    static func periodSuffix(for product: Product) -> String? {
        guard let period = product.subscription?.subscriptionPeriod else { return nil }
        let count = period.value
        switch period.unit {
        case .day:
            return count == 1 ? "day" : "\(count) days"
        case .week:
            return count == 1 ? "week" : "\(count) weeks"
        case .month:
            return count == 1 ? "month" : "\(count) months"
        case .year:
            return count == 1 ? "year" : "\(count) years"
        @unknown default:
            return nil
        }
    }
}
