import SwiftUI

enum AppAnimation {
    static let quick = Animation.spring(duration: 0.22, bounce: 0.12)
    static let standard = Animation.spring(duration: 0.34, bounce: 0.18)
    static let gentle = Animation.easeInOut(duration: 0.25)
    static let hero = Animation.easeInOut(duration: 0.45)
}
