import SwiftUI
import UIKit

enum AppColors {
    static let background = dynamic(
        light: UIColor(red: 0.965, green: 0.953, blue: 0.933, alpha: 1),
        dark: UIColor(red: 0.043, green: 0.039, blue: 0.035, alpha: 1)
    )
    static let surface = dynamic(
        light: UIColor(red: 0.996, green: 0.988, blue: 0.973, alpha: 1),
        dark: UIColor(red: 0.086, green: 0.080, blue: 0.074, alpha: 1)
    )
    static let elevated = dynamic(
        light: UIColor(red: 0.925, green: 0.898, blue: 0.855, alpha: 1),
        dark: UIColor(red: 0.133, green: 0.118, blue: 0.100, alpha: 1)
    )
    static var surfaceElevated: Color { elevated }

    /// Icons, selected labels, and other small accent text. Darker in light mode so it stays readable.
    static let accent = dynamic(
        light: UIColor(red: 0.545, green: 0.318, blue: 0.067, alpha: 1),
        dark: UIColor(red: 1.000, green: 0.773, blue: 0.157, alpha: 1)
    )
    /// Filled buttons. Bright amber in dark mode, a deeper gold in light mode.
    static let accentFill = dynamic(
        light: UIColor(red: 0.769, green: 0.478, blue: 0.118, alpha: 1),
        dark: UIColor(red: 1.000, green: 0.710, blue: 0.106, alpha: 1)
    )
    static var accentStrong: Color { accentFill }
    static let accentSoft = dynamic(
        light: UIColor(red: 0.545, green: 0.318, blue: 0.067, alpha: 0.12),
        dark: UIColor(red: 1.000, green: 0.710, blue: 0.106, alpha: 0.16)
    )
    static let onAccent = Color(red: 0.102, green: 0.067, blue: 0.024)

    static let textPrimary = dynamic(
        light: UIColor(red: 0.102, green: 0.086, blue: 0.067, alpha: 1),
        dark: UIColor(red: 0.980, green: 0.969, blue: 0.945, alpha: 1)
    )
    static let textSecondary = dynamic(
        light: UIColor(red: 0.345, green: 0.310, blue: 0.267, alpha: 1),
        dark: UIColor(red: 0.655, green: 0.635, blue: 0.608, alpha: 1)
    )
    static let textTertiary = dynamic(
        light: UIColor(red: 0.420, green: 0.380, blue: 0.330, alpha: 1),
        dark: UIColor(red: 0.560, green: 0.530, blue: 0.490, alpha: 1)
    )
    static let separator = dynamic(
        light: UIColor.black.withAlphaComponent(0.10),
        dark: UIColor.white.withAlphaComponent(0.12)
    )
    static var border: Color { separator }
    static let selectedBackground = dynamic(
        light: UIColor(red: 0.973, green: 0.929, blue: 0.855, alpha: 1),
        dark: UIColor(red: 0.176, green: 0.141, blue: 0.098, alpha: 1)
    )
    static let positive = dynamic(
        light: UIColor(red: 0.133, green: 0.545, blue: 0.133, alpha: 1),
        dark: UIColor(red: 0.486, green: 0.780, blue: 0.455, alpha: 1)
    )
    static let destructive = dynamic(
        light: UIColor(red: 0.769, green: 0.180, blue: 0.180, alpha: 1),
        dark: UIColor(red: 1.000, green: 0.420, blue: 0.380, alpha: 1)
    )
    /// Badge fill behind dark label text. Same family as the button fill.
    static var rating: Color { accentFill }
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

    /// Warm stand-in when a poster image is missing. Stays in the amber family.
    static func posterWash(seed: Int) -> [Color] {
        let shift = Double(abs(seed) % 16) / 100
        return [
            Color(hue: 0.07 + shift, saturation: 0.42, brightness: 0.24),
            Color(hue: 0.08, saturation: 0.50, brightness: 0.12)
        ]
    }
}
