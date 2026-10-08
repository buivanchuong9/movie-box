import SwiftUI

enum AppTypography {
    /// Serif is reserved for the wordmark and cinematic screen titles.
    static let display = Font.system(.largeTitle, design: .serif).weight(.semibold)
    static let largeTitle = Font.system(.title, design: .serif).weight(.semibold)
    static let wordmark = Font.system(.title3, design: .serif).weight(.semibold)
    static let screenTitle = display
    static let heroTitle = largeTitle
    static let title = Font.title2.weight(.semibold)
    static let headline = Font.headline
    static let section = Font.title3.weight(.semibold)
    static let cardTitle = Font.subheadline.weight(.semibold)
    static let body = Font.body
    static let callout = Font.callout
    static let footnote = Font.footnote
    static let caption = Font.caption
    static let captionBold = Font.caption.weight(.semibold)
    static let metadata = Font.subheadline
    static let meta = Font.caption
    static let ratingLarge = Font.title.weight(.semibold)
    static let button = Font.body.weight(.semibold)
    static let tab = Font.caption2.weight(.medium)
}
