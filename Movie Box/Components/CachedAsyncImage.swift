import SwiftUI

struct CachedAsyncImage: View {
    let url: URL?
    var maxPixel: CGFloat = 720
    var seed: Int = 0
    var accessibilityLabel: String

    var body: some View {
        RemoteArtwork(url: url, maxPixel: maxPixel, seed: seed, accessibilityLabel: accessibilityLabel)
    }
}

private struct RemoteArtwork: View {
    let url: URL?
    var maxPixel: CGFloat
    var seed: Int
    var accessibilityLabel: String
    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            } else {
                ArtworkPlaceholder(seed: seed, failed: failed)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isImage)
        .task(id: url?.absoluteString) {
            await load()
        }
    }

    private func load() async {
        failed = false
        guard let url else {
            image = nil
            failed = true
            return
        }
        do {
            let data = try await ImageStore.shared.data(for: url, maxPixel: maxPixel)
            try Task.checkCancellation()
            guard let rendered = UIImage(data: data) else {
                failed = true
                return
            }
            withAnimation(AppAnimation.gentle) {
                image = rendered
            }
        } catch is CancellationError {
            return
        } catch AppError.cancelled {
            return
        } catch {
            if !Task.isCancelled {
                failed = true
            }
        }
    }
}

struct ArtworkPlaceholder: View {
    var seed: Int
    var failed: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(colors: AppColors.posterWash(seed: seed), startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: failed ? "photo" : "film")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.72))
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    CachedAsyncImage(url: nil, seed: 4, accessibilityLabel: "Poster placeholder")
        .frame(width: 140, height: 210)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .padding()
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
