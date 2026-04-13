import SwiftUI

struct RootView: View {
    @State private var library = PhotoLibraryService()
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            switch library.authorizationStatus {
            case .notDetermined:
                PermissionRequestView(library: library)
            case .denied, .restricted:
                PermissionDeniedView()
            case .authorized, .limited:
                MainTabs()
                    .environment(library)
            @unknown default:
                PermissionRequestView(library: library)
            }
        }
        .task {
            await library.refreshAuthorizationStatus()
        }
    }
}

struct MainTabs: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            // iPad: sidebar
            NavigationSplitView {
                SidebarView()
            } detail: {
                LibraryView()
            }
        } else {
            // iPhone: tab bar
            TabView {
                LibraryView()
                    .tabItem { Label("Library", systemImage: "photo.on.rectangle") }
                AlbumsView()
                    .tabItem { Label("Albums", systemImage: "rectangle.stack") }
                CollectionsView()
                    .tabItem { Label("Collections", systemImage: "folder") }
                SearchView()
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
            }
        }
    }
}

struct SidebarView: View {
    @State private var selection: SidebarItem? = .library

    enum SidebarItem: Hashable {
        case library, albums, collections, favorites, search
    }

    var body: some View {
        List(selection: $selection) {
            Section("Photos") {
                NavigationLink(value: SidebarItem.library) {
                    Label("Library", systemImage: "photo.on.rectangle")
                }
                NavigationLink(value: SidebarItem.albums) {
                    Label("Albums", systemImage: "rectangle.stack")
                }
                NavigationLink(value: SidebarItem.favorites) {
                    Label("Favorites", systemImage: "heart")
                }
            }
            Section("Organize") {
                NavigationLink(value: SidebarItem.collections) {
                    Label("Collections", systemImage: "folder")
                }
                NavigationLink(value: SidebarItem.search) {
                    Label("Search", systemImage: "magnifyingglass")
                }
            }
        }
        .navigationTitle("PhotoManager")
        .navigationDestination(for: SidebarItem.self) { item in
            switch item {
            case .library: LibraryView()
            case .albums: AlbumsView()
            case .collections: CollectionsView()
            case .favorites: FavoritesView()
            case .search: SearchView()
            }
        }
    }
}
