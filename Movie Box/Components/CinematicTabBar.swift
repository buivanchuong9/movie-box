import Observation
import SwiftUI

struct CinematicTabBar: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                let selected = env.tabs.selection == tab
                Button {
                    guard env.tabs.selection != tab else { return }
                    Haptics.selection()
                    if reduceMotion {
                        env.tabs.selection = tab
                    } else {
                        withAnimation(AppAnimation.quick) { env.tabs.selection = tab }
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol(selected: selected))
                            .font(.system(size: 18, weight: .semibold))
                            .frame(height: 22)
                        Text(tab.title)
                            .font(AppTypography.tab)
                            .lineLimit(1)
                    }
                    .foregroundStyle(selected ? AppColors.accent : AppColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: AppSpacing.touch)
                    .background {
                        if selected {
                            Capsule().fill(AppColors.accent.opacity(0.16))
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle().fill(AppColors.separator).frame(height: 0.5)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

@MainActor
@Observable
final class TabRouter {
    var selection: AppTab = .home
    var loaded: Set<AppTab> = [.home]

    func select(_ tab: AppTab) {
        loaded.insert(tab)
        selection = tab
    }
}
