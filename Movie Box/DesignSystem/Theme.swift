import SwiftUI

struct LumenCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(AppColors.separator, lineWidth: 1)
            }
            .shadow(
                color: colorScheme == .light ? AppShadow.cardColor : .clear,
                radius: AppShadow.cardRadius,
                y: AppShadow.cardY
            )
    }
}

struct PressScaleStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!reduceMotion && configuration.isPressed ? 0.97 : 1)
            .animation(AppAnimation.quick, value: configuration.isPressed)
    }
}

extension View {
    func lumenCard() -> some View {
        modifier(LumenCardModifier())
    }

    @ViewBuilder
    func matchedZoomSource<ID: Hashable>(id: ID, in namespace: Namespace.ID?) -> some View {
        if #available(iOS 18, *), let namespace {
            self.matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    @ViewBuilder
    func matchedZoomDestination<ID: Hashable>(id: ID, in namespace: Namespace.ID?) -> some View {
        if #available(iOS 18, *), let namespace {
            self.navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}
