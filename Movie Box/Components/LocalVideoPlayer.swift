import AVKit
import SwiftUI

/// Full-screen offline playback of an imported video using AVKit.
struct LocalVideoPlayer: View {
    let url: URL
    let onClose: () -> Void

    @State private var player: AVPlayer?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.55))
                    .frame(width: AppSpacing.touch, height: AppSpacing.touch)
            }
            .padding(AppSpacing.xs)
            .accessibilityLabel("Close player")
        }
        .onAppear {
            let item = AVPlayer(url: url)
            player = item
            item.play()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
