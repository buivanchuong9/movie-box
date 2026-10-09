import SwiftUI
import UIKit

enum AppColors {
    static let background = dynamic(
        light: UIColor(red: 0.933, green: 0.953, blue: 0.973, alpha: 1),
        dark: UIColor(red: 0.027, green: 0.055, blue: 0.110, alpha: 1)
    )
    static let surface = dynamic(
        light: UIColor(red: 0.969, green: 0.980, blue: 0.992, alpha: 1),
        dark: UIColor(red: 0.063, green: 0.094, blue: 0.149, alpha: 1)
    )
    static let elevated = dynamic(
        light: UIColor(red: 0.851, green: 0.894, blue: 0.941, alpha: 1),
        dark: UIColor(red: 0.102, green: 0.153, blue: 0.251, alpha: 1)
    )
    static var surfaceElevated: Color { elevated }

    /// Icons, selected labels, and other small accent text. Darker in light mode so it stays readable.
    static let accent = dynamic(
        light: UIColor(red: 0.000, green: 0.310, blue: 0.722, alpha: 1),
        dark: UIColor(red: 0.302, green: 0.671, blue: 1.000, alpha: 1)
    )
    /// Filled buttons. Logo blue (`#0070F0`) in both modes so white labels stay readable.
    static let accentFill = dynamic(
        light: UIColor(red: 0.000, green: 0.439, blue: 0.941, alpha: 1),
        dark: UIColor(red: 0.000, green: 0.439, blue: 0.941, alpha: 1)
    )
    static var accentStrong: Color { accentFill }
    static let accentSoft = dynamic(
        light: UIColor(red: 0.000, green: 0.310, blue: 0.722, alpha: 0.12),
        dark: UIColor(red: 0.302, green: 0.671, blue: 1.000, alpha: 0.18)
    )
    /// Glow and icon highlights. Too light to sit behind white button labels.
    static let accentBright = dynamic(
        light: UIColor(red: 0.157, green: 0.655, blue: 1.000, alpha: 1),
        dark: UIColor(red: 0.208, green: 0.714, blue: 1.000, alpha: 1)
    )
    /// Deep end of primary fills. Keeps white labels readable on a blue gradient.
    static let accentDeep = dynamic(
        light: UIColor(red: 0.027, green: 0.333, blue: 0.788, alpha: 1),
        dark: UIColor(red: 0.027, green: 0.333, blue: 0.788, alpha: 1)
    )
    static let onAccent = Color(red: 0.969, green: 0.980, blue: 1.000)

    static let textPrimary = dynamic(
        light: UIColor(red: 0.055, green: 0.090, blue: 0.149, alpha: 1),
        dark: UIColor(red: 0.949, green: 0.969, blue: 0.988, alpha: 1)
    )
    static let textSecondary = dynamic(
        light: UIColor(red: 0.239, green: 0.298, blue: 0.388, alpha: 1),
        dark: UIColor(red: 0.639, green: 0.702, blue: 0.780, alpha: 1)
    )
    static let textTertiary = dynamic(
        light: UIColor(red: 0.353, green: 0.416, blue: 0.510, alpha: 1),
        dark: UIColor(red: 0.494, green: 0.565, blue: 0.659, alpha: 1)
    )
    static let separator = dynamic(
        light: UIColor.black.withAlphaComponent(0.10),
        dark: UIColor.white.withAlphaComponent(0.12)
    )
    static var border: Color { separator }
    static let selectedBackground = dynamic(
        light: UIColor(red: 0.839, green: 0.910, blue: 0.988, alpha: 1),
        dark: UIColor(red: 0.071, green: 0.137, blue: 0.235, alpha: 1)
    )
    static let positive = dynamic(
        light: UIColor(red: 0.133, green: 0.545, blue: 0.133, alpha: 1),
        dark: UIColor(red: 0.486, green: 0.780, blue: 0.455, alpha: 1)
    )
    static let destructive = dynamic(
        light: UIColor(red: 0.769, green: 0.180, blue: 0.180, alpha: 1),
        dark: UIColor(red: 1.000, green: 0.420, blue: 0.380, alpha: 1)
    )
    /// Badge fill behind light label text. Same family as the button fill.
    static var rating: Color { accentFill }
    static let scrim = Color.black.opacity(0.45)
    static let imagePlaceholder = dynamic(
        light: UIColor(red: 0.773, green: 0.831, blue: 0.902, alpha: 1),
        dark: UIColor(red: 0.086, green: 0.125, blue: 0.200, alpha: 1)
    )

    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    /// Cool stand-in when a poster image is missing. Stays in the logo blue family.
    static func posterWash(seed: Int) -> [Color] {
        let shift = Double(abs(seed) % 16) / 100
        return [
            Color(hue: 0.56 + shift * 0.4, saturation: 0.55, brightness: 0.28),
            Color(hue: 0.58, saturation: 0.62, brightness: 0.14)
        ]
    }
}
