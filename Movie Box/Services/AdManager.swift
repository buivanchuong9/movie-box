import Foundation
import Observation

/// Decides when a placement may appear. The creative is replaceable:
/// a future ad SDK should conform to the same frequency rules and never
/// block navigation, cover artwork, or appear at launch.
@MainActor
@Observable
final class AdManager {
    private let entitlements: EntitlementManager
    private let sessionStart = Date()
    private var detailVisits = 0
    private var lastInterstitial: Date?
    var isPresentingInterstitial = false

    init(entitlements: EntitlementManager) {
        self.entitlements = entitlements
    }

    var adsEnabled: Bool { !entitlements.isPremium }

    func showsInline(sectionIndex: Int) -> Bool {
        adsEnabled && sectionIndex == 3
    }

    func showsGridItem(index: Int) -> Bool {
        adsEnabled && index > 0 && index % 12 == 0
    }

    func registerDetailVisit() {
        guard adsEnabled else { return }
        guard Date().timeIntervalSince(sessionStart) > 45 else { return }
        detailVisits += 1
        guard detailVisits >= 6 else { return }
        if let lastInterstitial, Date().timeIntervalSince(lastInterstitial) < 180 { return }
        isPresentingInterstitial = true
    }

    func dismissInterstitial() {
        isPresentingInterstitial = false
        lastInterstitial = Date()
        detailVisits = 0
    }
}
