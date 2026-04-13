import SwiftUI
import Photos

struct AlbumsView: View {
    @Environment(PhotoLibraryService.self) private var library
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 4 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !library.smartAlbums.isEmpty {
                    Text("Smart Albums")
                        .font(.title2.bold())
                        .padding(.horizontal)
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(library.smartAlbums, id: \.localIdentifier) { album in
                            NavigationLink {
                                AlbumDetailView(album: album)
                            } label: {
                                AlbumTile(album: album)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                if !library.userAlbums.isEmpty {
                    Text("My Albums")
                        .font(.title2.bold())
                        .padding(.horizontal)
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(library.userAlbums, id: \.localIdentifier) { album in
                            NavigationLink {
                                AlbumDetailView(album: album)
                            } label: {
                                AlbumTile(album: album)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Albums")
    }
}

struct AlbumTile: View {
    let album: PHAssetCollection
    @Environment(PhotoLibraryService.self) private var library
    @State private var coverImage: UIImage?
    @State private var count: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack {
                    Color(.systemGray5)
                    if let coverImage {
                        Image(uiImage: coverImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.width)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .aspectRatio(1, contentMode: .fit)

            Text(album.localizedTitle ?? "Album")
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .task(id: album.localIdentifier) {
            let assets = library.assets(in: album)
            count = assets.count
            if let first = assets.firstObject {
                library.requestThumbnail(for: first, targetSize: CGSize(width: 400, height: 400)) { img in
                    Task { @MainActor in self.coverImage = img }
                }
            }
        }
    }
}

struct AlbumDetailView: View {
    let album: PHAssetCollection
    @Environment(PhotoLibraryService.self) private var library
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var assets: PHFetchResult<PHAsset> = PHFetchResult<PHAsset>()
    @State private var selectedAsset: PHAsset?

    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 6 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 2), count: count)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<assets.count, id: \.self) { index in
                    let asset = assets.object(at: index)
                    Button {
                        selectedAsset = asset
                    } label: {
                        PhotoThumbnailView(asset: asset)
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(album.localizedTitle ?? "Album")
        .task {
            assets = library.assets(in: album)
        }
        .fullScreenCover(item: Binding(
            get: { selectedAsset.map { IdentifiableAsset(asset: $0) } },
            set: { selectedAsset = $0?.asset }
        )) { wrapped in
            PhotoDetailView(asset: wrapped.asset)
        }
    }
}
