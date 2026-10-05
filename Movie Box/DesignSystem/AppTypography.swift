import SwiftUI

enum AppTypography {
    static let wordmark = Font.system(.title3, design: .serif).weight(.semibold)
    static let heroTitle = Font.system(.title, design: .serif).weight(.semibold)
    static let screenTitle = Font.system(.largeTitle, design: .serif).weight(.semibold)
    static let section = Font.system(.title3, design: .serif).weight(.semibold)
    static let cardTitle = Font.system(.subheadline, design: .default).weight(.semibold)
    static let body = Font.body
    static let callout = Font.callout
    static let caption = Font.caption
    static let captionBold = Font.caption.weight(.semibold)
    static let meta = Font.caption
    static let ratingLarge = Font.system(.largeTitle, design: .serif).weight(.semibold)
    static let button = Font.body.weight(.semibold)
    static let tab = Font.system(size: 10, weight: .semibold, design: .default)
}
