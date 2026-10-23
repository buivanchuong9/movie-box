import CoreTransferable
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// A video from the Photos picker, handed over as a file inside the app's temporary directory.
struct PickedVideo: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let ext = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let copy = FileManager.default.temporaryDirectory
                .appendingPathComponent("import-\(UUID().uuidString).\(ext)")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return PickedVideo(url: copy)
        }
    }
}

struct MovieImporter: ViewModifier {
    @Environment(AppEnvironment.self) private var env
    @Binding var isPresented: Bool
    @State private var showPhotos = false
    @State private var showFiles = false
    @State private var photos: [PhotosPickerItem] = []
    @State private var notice: String?

    func body(content: Content) -> some View {
        content
            .confirmationDialog("Import movies", isPresented: $isPresented, titleVisibility: .visible) {
                Button("Photo Library") { showPhotos = true }
                Button("Files") { showFiles = true }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose videos from your photo library or from the Files app. They are copied into the app and play offline.")
            }
            .photosPicker(isPresented: $showPhotos, selection: $photos, maxSelectionCount: 40, matching: .videos)
            .onChange(of: photos) { _, items in
                guard !items.isEmpty else { return }
                let batch = items
                photos = []
                Task { await importPhotos(batch) }
            }
            .fileImporter(isPresented: $showFiles, allowedContentTypes: [.movie], allowsMultipleSelection: true) { result in
                Task { await importFiles(result) }
            }
            .alert("Import", isPresented: noticePresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(notice ?? "")
            }
    }

    private var noticePresented: Binding<Bool> {
        Binding(
            get: { notice != nil },
            set: { if !$0 { notice = nil } }
        )
    }
}

extension View {
    func movieImporter(isPresented: Binding<Bool>) -> some View {
        modifier(MovieImporter(isPresented: isPresented))
    }
}

private extension MovieImporter {
    func importPhotos(_ items: [PhotosPickerItem]) async {
        var outcomes: [VideoImportResult] = []
        for item in items {
            guard let video = try? await item.loadTransferable(type: PickedVideo.self) else {
                outcomes.append(.failed)
                continue
            }
            let title = "Video \(env.imports.movies.count + 1)"
            outcomes.append(await env.importVideo(from: video.url, title: title, movesSource: true))
            try? FileManager.default.removeItem(at: video.url)
        }
        report(outcomes)
    }

    func importFiles(_ result: Result<[URL], Error>) async {
        guard case .success(let urls) = result else {
            if case .failure = result { notice = "Those files couldn't be imported." }
            return
        }
        var outcomes: [VideoImportResult] = []
        for url in urls {
            let title = url.deletingPathExtension().lastPathComponent
            outcomes.append(await env.importVideo(from: url, title: title, movesSource: false))
        }
        report(outcomes)
    }

    func report(_ outcomes: [VideoImportResult]) {
        guard !outcomes.isEmpty, !outcomes.contains(.added) else { return }
        notice = outcomes.contains(.failed)
            ? "Those videos couldn't be imported. Choose a video file that this device can play."
            : "Those videos are already in your library."
    }
}
