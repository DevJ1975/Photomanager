import SwiftUI
import Photos
import UIKit

struct PhotoDetailView: View {
    let asset: PHAsset
    @Environment(PhotoLibraryService.self) private var library
    @Environment(\.dismiss) private var dismiss

    @State private var image: UIImage?
    @State private var showInfo = false
    @State private var isFavorite: Bool

    init(asset: PHAsset) {
        self.asset = asset
        self._isFavorite = State(initialValue: asset.isFavorite)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let image {
                    ZoomableImage(image: image)
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .task {
                library.requestFullImage(for: asset) { img in
                    Task { @MainActor in self.image = img }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            try? await library.toggleSystemFavorite(asset)
                            isFavorite.toggle()
                        }
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showInfo = true } label: {
                        Image(systemName: "info.circle")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    if let image {
                        ShareLink(item: Image(uiImage: image), preview: SharePreview("Photo", image: Image(uiImage: image))) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showInfo) {
                PhotoInfoSheet(asset: asset)
                    .presentationDetents([.medium, .large])
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

struct PhotoInfoSheet: View {
    let asset: PHAsset

    var body: some View {
        NavigationStack {
            List {
                Section("Date") {
                    row("Created", asset.creationDate?.formatted(date: .long, time: .shortened) ?? "Unknown")
                    if let modified = asset.modificationDate {
                        row("Modified", modified.formatted(date: .long, time: .shortened))
                    }
                }
                Section("Details") {
                    row("Dimensions", "\(asset.pixelWidth) × \(asset.pixelHeight)")
                    row("Type", asset.mediaType == .video ? "Video" : "Photo")
                    if asset.mediaType == .video {
                        row("Duration", String(format: "%.1fs", asset.duration))
                    }
                    row("Favorite", asset.isFavorite ? "Yes" : "No")
                }
                if let location = asset.location {
                    Section("Location") {
                        row("Latitude", String(format: "%.5f", location.coordinate.latitude))
                        row("Longitude", String(format: "%.5f", location.coordinate.longitude))
                    }
                }
            }
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}

struct ZoomableImage: View {
    let image: UIImage
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = max(1, min(lastScale * value, 5))
                    }
                    .onEnded { _ in
                        lastScale = scale
                        if scale == 1 {
                            withAnimation { offset = .zero; lastOffset = .zero }
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        guard scale > 1 else { return }
                        offset = CGSize(width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height)
                    }
                    .onEnded { _ in lastOffset = offset }
            )
            .onTapGesture(count: 2) {
                withAnimation {
                    if scale > 1 { scale = 1; lastScale = 1; offset = .zero; lastOffset = .zero }
                    else { scale = 2.5; lastScale = 2.5 }
                }
            }
    }
}
