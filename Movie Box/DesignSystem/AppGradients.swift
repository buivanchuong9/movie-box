import SwiftUI

enum AppGradients {
    /// Primary actions. Both stops stay dark enough for white labels.
    static let primaryButton = LinearGradient(
        colors: [AppColors.accentFill, AppColors.accentDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func glow(opacity: Double) -> RadialGradient {
        RadialGradient(
            colors: [AppColors.accentBright.opacity(opacity), AppColors.accent.opacity(0)],
            center: .center,
            startRadius: 12,
            endRadius: 180
        )
    }
}
