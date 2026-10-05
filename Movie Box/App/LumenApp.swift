import SwiftData
import SwiftUI

@main
struct LumenApp: App {
    @State private var environment: AppEnvironment?
    @State private var launchError: String?

    var body: some Scene {
        WindowGroup {
            Group {
                if let environment {
                    RootView()
                        .environment(environment)
                        .modelContainer(environment.container)
                } else if let launchError {
                    EmptyStateView(
                        systemImage: "exclamationmark.triangle",
                        title: "Lumen could not start",
                        message: launchError
                    )
                    .background(AppColors.background)
                } else {
                    launch
                }
            }
            .task {
                guard environment == nil else { return }
                do {
                    environment = try AppEnvironment.live()
                } catch {
                    launchError = error.localizedDescription
                }
            }
        }
    }

    private var launch: some View {
        VStack(spacing: AppSpacing.md) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(AppColors.accent)
                .frame(width: 12, height: 36)
            Text("LUMEN")
                .font(.system(.largeTitle, design: .serif).weight(.semibold))
                .tracking(4)
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .accessibilityLabel("Lumen")
    }
}
