import CoreTransferable
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct PickedPhoto: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            PickedPhoto(data: data)
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
                Text("Choose posters from your photo library or from image files.")
            }
            .photosPicker(isPresented: $showPhotos, selection: $photos, maxSelectionCount: 40, matching: .images)
            .onChange(of: photos) { _, items in
                guard !items.isEmpty else { return }
                let batch = items
                photos = []
                Task { await importPhotos(batch) }
            }
            .fileImporter(isPresented: $showFiles, allowedContentTypes: [.image], allowsMultipleSelection: true) { result in
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
        var next = env.imports.movies.count + 1
        var images: [(title: String, data: Data)] = []
        for item in items {
            guard let photo = try? await item.loadTransferable(type: PickedPhoto.self),
                  let prepared = await PosterEncoding.prepared(photo.data) else { continue }
            images.append((title: "Movie \(next)", data: prepared))
            next += 1
        }
        await finishImport(images, attempted: !items.isEmpty)
    }

    func importFiles(_ result: Result<[URL], Error>) async {
        guard case .success(let urls) = result else { return }
        var images: [(title: String, data: Data)] = []
        for url in urls {
            guard let prepared = await PosterEncoding.preparedFile(url) else { continue }
            images.append((title: url.deletingPathExtension().lastPathComponent, data: prepared))
        }
        await finishImport(images, attempted: !urls.isEmpty)
    }

    func finishImport(_ images: [(title: String, data: Data)], attempted: Bool) async {
        guard attempted else { return }
        let added = await env.importImages(images)
        if added == 0 {
            notice = images.isEmpty
                ? "Those files couldn't be imported."
                : "Those posters are already in your library."
        }
    }
}
