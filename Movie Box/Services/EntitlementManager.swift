import Foundation
import Observation

@MainActor
@Observable
final class EntitlementManager {
    private(set) var current: LumenPlusEntitlement = .notEntitled

    var isPremium: Bool { current.isPremium }

    func apply(_ entitlement: LumenPlusEntitlement) {
        current = entitlement
    }

    func alreadyIncludes(_ kind: LumenPlanKind) -> Bool {
        switch (current, kind) {
        case (.lifetime, _):
            true
        case (.annual, .annual), (.annual, .monthly):
            true
        case (.monthly, .monthly):
            true
        default:
            false
        }
    }
}
