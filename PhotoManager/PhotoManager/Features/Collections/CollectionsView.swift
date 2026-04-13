import SwiftUI
import SwiftData
import Photos

struct CollectionsView: View {
    @Environment(\.modelContext) private var context
    @Environment(PhotoLibraryService.self) private var library
    @Query(sort: \UserCollection.createdAt, order: .reverse) private var collections: [UserCollection]
    @State private var showingNewSheet = false

    var body: some View {
        List {
            if collections.isEmpty {
                ContentUnavailableView("No Collections",
                                       systemImage: "folder.badge.plus",
                                       description: Text("Tap + to create your first collection."))
            } else {
                ForEach(collections) { collection in
                    NavigationLink {
                        CollectionDetailView(collection: collection)
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.tint)
                            VStack(alignment: .leading) {
                                Text(collection.name)
                                    .font(.headline)
                                Text("\(collection.assetIdentifiers.count) items")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet { context.delete(collections[index]) }
                }
            }
        }
        .navigationTitle("Collections")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingNewSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewSheet) {
            NewCollectionSheet()
        }
    }
}

struct NewCollectionSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        let new = UserCollection(name: name.trimmingCharacters(in: .whitespaces))
                        context.insert(new)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct CollectionDetailView: View {
    let collection: UserCollection
    @Environment(PhotoLibraryService.self) private var library
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedAsset: PHAsset?

    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 6 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 2), count: count)
    }

    private var assets: [PHAsset] {
        guard !collection.assetIdentifiers.isEmpty else { return [] }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: collection.assetIdentifiers, options: nil)
        var list: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in list.append(asset) }
        return list
    }

    var body: some View {
        Group {
            if assets.isEmpty {
                ContentUnavailableView("Empty Collection",
                                       systemImage: "photo",
                                       description: Text("Add photos from the library to this collection."))
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(assets, id: \.localIdentifier) { asset in
                            Button { selectedAsset = asset } label: {
                                PhotoThumbnailView(asset: asset)
                                    .aspectRatio(1, contentMode: .fill)
                                    .clipped()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .navigationTitle(collection.name)
        .fullScreenCover(item: Binding(
            get: { selectedAsset.map { IdentifiableAsset(asset: $0) } },
            set: { selectedAsset = $0?.asset }
        )) { wrapped in
            PhotoDetailView(asset: wrapped.asset)
        }
    }
}

struct FavoritesView: View {
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
                    Button { selectedAsset = asset } label: {
                        PhotoThumbnailView(asset: asset)
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Favorites")
        .task {
            assets = library.favoriteAssets()
        }
        .fullScreenCover(item: Binding(
            get: { selectedAsset.map { IdentifiableAsset(asset: $0) } },
            set: { selectedAsset = $0?.asset }
        )) { wrapped in
            PhotoDetailView(asset: wrapped.asset)
        }
    }
}
