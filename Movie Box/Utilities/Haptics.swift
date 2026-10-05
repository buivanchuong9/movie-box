import UIKit

@MainActor
enum Haptics {
    enum Impact {
        case light
        case medium
        case heavy
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func impact(_ style: Impact = .light) {
        let feedback: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case .light: feedback = .light
        case .medium: feedback = .medium
        case .heavy: feedback = .heavy
        }
        UIImpactFeedbackGenerator(style: feedback).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
