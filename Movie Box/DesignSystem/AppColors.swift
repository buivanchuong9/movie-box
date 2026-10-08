import SwiftUI
import UIKit

enum AppColors {
    static let background = dynamic(
        light: UIColor(red: 0.957, green: 0.941, blue: 0.914, alpha: 1),
        dark: UIColor(red: 0.055, green: 0.051, blue: 0.047, alpha: 1)
    )
    static let surface = dynamic(
        light: UIColor(red: 0.996, green: 0.988, blue: 0.973, alpha: 1),
        dark: UIColor(red: 0.102, green: 0.094, blue: 0.086, alpha: 1)
    )
    static let elevated = dynamic(
        light: UIColor(red: 0.922, green: 0.894, blue: 0.855, alpha: 1),
        dark: UIColor(red: 0.165, green: 0.149, blue: 0.133, alpha: 1)
    )
    static let accent = dynamic(
        light: UIColor(red: 0.690, green: 0.420, blue: 0.145, alpha: 1),
        dark: UIColor(red: 0.910, green: 0.659, blue: 0.365, alpha: 1)
    )
    static let accentFill = Color(red: 0.910, green: 0.682, blue: 0.400)
    static let onAccent = Color(red: 0.110, green: 0.082, blue: 0.051)
    static let secondary = dynamic(
        light: UIColor(red: 0.420, green: 0.380, blue: 0.330, alpha: 1),
        dark: UIColor(red: 0.545, green: 0.510, blue: 0.463, alpha: 1)
    )
    static let textPrimary = dynamic(
        light: UIColor(red: 0.110, green: 0.094, blue: 0.078, alpha: 1),
        dark: UIColor(red: 0.965, green: 0.945, blue: 0.914, alpha: 1)
    )
    static let textSecondary = dynamic(
        light: UIColor(red: 0.345, green: 0.310, blue: 0.267, alpha: 1),
        dark: UIColor(red: 0.690, green: 0.655, blue: 0.608, alpha: 1)
    )
    static let textTertiary = dynamic(
        light: UIColor(red: 0.490, green: 0.447, blue: 0.392, alpha: 1),
        dark: UIColor(red: 0.478, green: 0.447, blue: 0.408, alpha: 1)
    )
    static let rating = dynamic(
        light: UIColor(red: 0.620, green: 0.400, blue: 0.090, alpha: 1),
        dark: UIColor(red: 0.965, green: 0.784, blue: 0.376, alpha: 1)
    )
    static let positive = dynamic(
        light: UIColor(red: 0.180, green: 0.450, blue: 0.300, alpha: 1),
        dark: UIColor(red: 0.455, green: 0.730, blue: 0.520, alpha: 1)
    )
    static var destructive: Color { negative }

    static let negative = dynamic(
        light: UIColor(red: 0.650, green: 0.220, blue: 0.180, alpha: 1),
        dark: UIColor(red: 0.820, green: 0.380, blue: 0.340, alpha: 1)
    )
    static var backgroundPrimary: Color { background }
    static var backgroundSecondary: Color { surface }
    static var surfaceElevated: Color { elevated }

    static let separator = dynamic(
        light: UIColor.black.withAlphaComponent(0.08),
        dark: UIColor.white.withAlphaComponent(0.08)
    )
    static let scrim = Color.black.opacity(0.45)
    static let imagePlaceholder = dynamic(
        light: UIColor(red: 0.850, green: 0.810, blue: 0.760, alpha: 1),
        dark: UIColor(red: 0.140, green: 0.125, blue: 0.110, alpha: 1)
    )

    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    static func posterWash(seed: Int) -> [Color] {
        let hue = Double(abs(seed) % 360) / 360
        return [
            Color(hue: hue, saturation: 0.28, brightness: 0.28),
            Color(hue: (hue + 0.08).truncatingRemainder(dividingBy: 1), saturation: 0.35, brightness: 0.14)
        ]
    }
}
