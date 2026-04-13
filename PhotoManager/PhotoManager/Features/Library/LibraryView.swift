import SwiftUI
import Photos

struct LibraryView: View {
    @Environment(PhotoLibraryService.self) private var library
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedAsset: PHAsset?

    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 6 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 2), count: count)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<library.allPhotos.count, id: \.self) { index in
                    let asset = library.allPhotos.object(at: index)
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
            .padding(.horizontal, 2)
        }
        .navigationTitle("Library")
        .fullScreenCover(item: Binding(
            get: { selectedAsset.map { IdentifiableAsset(asset: $0) } },
            set: { selectedAsset = $0?.asset }
        )) { wrapped in
            PhotoDetailView(asset: wrapped.asset)
        }
    }
}

struct IdentifiableAsset: Identifiable {
    let asset: PHAsset
    var id: String { asset.localIdentifier }
}
