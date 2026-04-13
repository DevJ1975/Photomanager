import SwiftUI
import Photos

struct SearchView: View {
    @Environment(PhotoLibraryService.self) private var library
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var query = ""
    @State private var filter: Filter = .all
    @State private var results: [PHAsset] = []
    @State private var selectedAsset: PHAsset?

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case photos = "Photos"
        case videos = "Videos"
        case favorites = "Favorites"
        var id: String { rawValue }
    }

    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 6 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 2), count: count)
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $filter) {
                ForEach(Filter.allCases) { f in Text(f.rawValue).tag(f) }
            }
            .pickerStyle(.segmented)
            .padding()

            if results.isEmpty {
                ContentUnavailableView("No Results",
                                       systemImage: "magnifyingglass",
                                       description: Text("Try a different date, year, or filter."))
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(results, id: \.localIdentifier) { asset in
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
        .navigationTitle("Search")
        .searchable(text: $query, prompt: "Year (e.g. 2024) or date")
        .onChange(of: query) { _, _ in runSearch() }
        .onChange(of: filter) { _, _ in runSearch() }
        .task { runSearch() }
        .fullScreenCover(item: Binding(
            get: { selectedAsset.map { IdentifiableAsset(asset: $0) } },
            set: { selectedAsset = $0?.asset }
        )) { wrapped in
            PhotoDetailView(asset: wrapped.asset)
        }
    }

    private func runSearch() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        var predicates: [NSPredicate] = []
        switch filter {
        case .all: break
        case .photos: predicates.append(NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue))
        case .videos: predicates.append(NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue))
        case .favorites: predicates.append(NSPredicate(format: "favorite == YES"))
        }

        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if let year = Int(trimmed), year > 1900, year < 3000 {
            var comps = DateComponents(); comps.year = year
            let cal = Calendar.current
            if let start = cal.date(from: comps),
               let end = cal.date(byAdding: .year, value: 1, to: start) {
                predicates.append(NSPredicate(format: "creationDate >= %@ AND creationDate < %@",
                                              start as NSDate, end as NSDate))
            }
        }

        if !predicates.isEmpty {
            options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        let fetch = PHAsset.fetchAssets(with: options)
        var list: [PHAsset] = []
        fetch.enumerateObjects { asset, _, _ in list.append(asset) }
        results = list
    }
}
