import os
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
                        title: "Movie Box could not start",
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
                    Logger(subsystem: "com.lumen.discovery", category: "persistence")
                        .error("Library store failed: \(error.localizedDescription, privacy: .public)")
                    launchError = "Your library couldn't be opened. Please try again."
                }
            }
        }
    }

    private var launch: some View {
        VStack(spacing: AppSpacing.md) {
            Image("AppLogo")
                .resizable()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            Text("Movie Box")
                .font(.system(.largeTitle, design: .serif).weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .accessibilityLabel("Movie Box")
    }
}
