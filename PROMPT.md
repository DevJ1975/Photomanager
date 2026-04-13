# PhotoManager — Generation Prompt

Paste the prompt below into a fresh Claude (or any coding agent) session to regenerate this project from scratch. It is self-contained — no prior context required.

---

## Prompt

> Build a universal iPhone/iPad photo-management app called **PhotoManager**, from scratch, in a clean empty directory. Follow every spec below exactly. Create all files in a single pass; do not ask clarifying questions.
>
> ### Platform / stack
> - SwiftUI, Swift 5.9, targeting **iOS 17.0+**
> - Universal (iPhone + iPad) — `TARGETED_DEVICE_FAMILY = "1,2"`
> - **PhotoKit** (`Photos` framework) for on-device library access — no server, no cloud
> - **SwiftData** for app-owned metadata
> - `@Observable` macro for view-model state (no `ObservableObject`)
> - **XcodeGen** for project generation — do NOT hand-craft `project.pbxproj`
>
> ### Architecture
> - MVVM-lite. A single `@Observable` service (`PhotoLibraryService`) owns PhotoKit access and publishes state to views.
> - Adaptive layout driven by `horizontalSizeClass`:
>   - **iPhone** (compact): `TabView` with Library / Albums / Collections / Search tabs
>   - **iPad** (regular): `NavigationSplitView` with a sidebar (Library, Albums, Favorites, Collections, Search)
> - Permissions gate: on launch, route to a welcome view if `.notDetermined`, a "denied" view with a Settings deep-link if denied/restricted, and the main UI if `.authorized` or `.limited`.
>
> ### File layout (create exactly this tree)
> ```
> PhotoManager/
> ├── .gitignore
> ├── README.md
> ├── PROMPT.md                                    # (this file)
> └── PhotoManager/
>     ├── project.yml                              # XcodeGen spec
>     └── PhotoManager/
>         ├── App/
>         │   ├── PhotoManagerApp.swift            # @main, SwiftData container
>         │   ├── RootView.swift                   # auth gate + adaptive layout
>         │   └── PermissionViews.swift            # request + denied views
>         ├── Features/
>         │   ├── Library/
>         │   │   ├── LibraryView.swift            # grid of PHAsset
>         │   │   └── PhotoThumbnailView.swift     # single cell
>         │   ├── Albums/
>         │   │   └── AlbumsView.swift             # smart + user albums, detail
>         │   ├── Detail/
>         │   │   └── PhotoDetailView.swift        # full-screen viewer, zoom, info
>         │   ├── Collections/
>         │   │   └── CollectionsView.swift        # user collections + favorites
>         │   └── Search/
>         │       └── SearchView.swift             # segmented filter + year
>         ├── Models/
>         │   └── SwiftDataModels.swift            # UserCollection, PhotoTag, FavoriteRef
>         ├── Services/
>         │   └── PhotoLibraryService.swift        # PHPhotoLibrary wrapper
>         ├── Resources/
>         │   ├── Info.plist
>         │   └── Assets.xcassets/
>         │       ├── Contents.json
>         │       ├── AppIcon.appiconset/Contents.json
>         │       └── AccentColor.colorset/Contents.json
>         └── Preview Content/
>             └── Preview Assets.xcassets/Contents.json
> ```
>
> ### `PhotoLibraryService` (must implement all of this)
> - `@Observable final class PhotoLibraryService: NSObject, PHPhotoLibraryChangeObserver`
> - Published state: `authorizationStatus: PHAuthorizationStatus`, `allPhotos: PHFetchResult<PHAsset>`, `userAlbums: [PHAssetCollection]`, `smartAlbums: [PHAssetCollection]`
> - Owns a `PHCachingImageManager`
> - Registers as `PHPhotoLibrary.shared().register(self)` in `init`, unregisters in `deinit`
> - `refreshAuthorizationStatus()` — reads current status, reloads if authorized
> - `requestAuthorization()` — uses `PHPhotoLibrary.requestAuthorization(for: .readWrite)`
> - `reloadCollections()` — fetches all photos (sorted by `creationDate` desc), smart albums, user albums
> - `requestThumbnail(for:targetSize:completion:)` — `.opportunistic` delivery, `.fast` resize, network-allowed
> - `requestFullImage(for:completion:)` — `.highQualityFormat`, `PHImageManagerMaximumSize`, `.aspectFit`
> - `startCaching(assets:targetSize:)` / `stopCaching(assets:targetSize:)`
> - `toggleSystemFavorite(_ asset: PHAsset) async throws` — via `PHAssetChangeRequest`
> - `delete(_ assets: [PHAsset]) async throws` — via `PHAssetChangeRequest.deleteAssets`
> - `assets(in collection: PHAssetCollection) -> PHFetchResult<PHAsset>` — sorted desc
> - `favoriteAssets() -> PHFetchResult<PHAsset>` — predicate `favorite == YES`
> - `photoLibraryDidChange(_:)` — triggers `reloadCollections()` on the main actor
>
> ### SwiftData models
> ```swift
> @Model final class UserCollection {
>     @Attribute(.unique) var id: UUID
>     var name: String
>     var createdAt: Date
>     var assetIdentifiers: [String]       // PHAsset.localIdentifier
>     var colorHex: String?
> }
> @Model final class PhotoTag {
>     @Attribute(.unique) var id: UUID
>     var name: String
>     var assetIdentifiers: [String]
> }
> @Model final class FavoriteRef {
>     @Attribute(.unique) var assetIdentifier: String
>     var addedAt: Date
> }
> ```
> Register all three in the root `.modelContainer(for:)`.
>
> ### Views — required behaviors
> - **`LibraryView`**: `LazyVGrid`, 3 columns iPhone / 6 columns iPad, spacing 2, tapping a cell opens `PhotoDetailView` in a `fullScreenCover`.
> - **`PhotoThumbnailView`**: uses `GeometryReader` to request a thumbnail at the cell's pixel size (`* UIScreen.main.scale`); overlays a play-icon with duration for videos and a heart for `asset.isFavorite`.
> - **`AlbumsView`**: two sections — Smart Albums then My Albums — each a 2-col (iPhone) / 4-col (iPad) grid of `AlbumTile`s. Each tile is a rounded-corner square cover image plus title and count. Tapping pushes `AlbumDetailView`.
> - **`PhotoDetailView`**: black background, `ZoomableImage` with pinch-to-zoom (max 5x), drag-to-pan while zoomed, double-tap to toggle zoom. Toolbar: Done (leading), heart toggle + info button (trailing), ShareLink (bottom bar). Info sheet shows created/modified date, dimensions, media type, duration (video), favorite flag, GPS if present.
> - **`CollectionsView`**: `@Query` sorted by `createdAt` desc; `ContentUnavailableView` empty state; toolbar `+` opens `NewCollectionSheet`; swipe-to-delete. `CollectionDetailView` resolves `assetIdentifiers` via `PHAsset.fetchAssets(withLocalIdentifiers:options:)`.
> - **`FavoritesView`**: grid backed by `library.favoriteAssets()`.
> - **`SearchView`**: `.searchable` prompt "Year (e.g. 2024) or date"; segmented picker All/Photos/Videos/Favorites; builds a compound `NSPredicate` combining media-type and creation-date range (when query parses as a year 1900<y<3000).
>
> ### `Info.plist` (required keys)
> - `NSPhotoLibraryUsageDescription` — explain browse/organize/favorite/share
> - `NSPhotoLibraryAddUsageDescription` — explain saving edited/imported photos
> - `UILaunchScreen` — empty dict
> - `UISupportedInterfaceOrientations` — portrait + both landscapes (iPhone)
> - `UISupportedInterfaceOrientations~ipad` — all four
>
> ### `project.yml` (XcodeGen)
> - `name: PhotoManager`
> - `options.deploymentTarget.iOS: "17.0"`, `createIntermediateGroups: true`
> - `settings.base`: `SWIFT_VERSION: "5.9"`, `TARGETED_DEVICE_FAMILY: "1,2"`, `ENABLE_PREVIEWS: YES`, `DEVELOPMENT_ASSET_PATHS: "\"PhotoManager/Preview Content\""`, `MARKETING_VERSION: "1.0"`, `CURRENT_PROJECT_VERSION: "1"`
> - One target `PhotoManager` of type `application`, platform iOS
> - `sources: [PhotoManager]` excluding `Resources/Info.plist`
> - `resources`: the two `.xcassets` directories
> - `info.path: PhotoManager/Resources/Info.plist` with the keys above
> - `PRODUCT_BUNDLE_IDENTIFIER: com.photomanager.PhotoManager`
>
> ### `.gitignore`
> Ignore `build/`, `DerivedData/`, `*.xcuserstate`, `xcuserdata/`, `.build/`, `.swiftpm/`, `.DS_Store`, `Pods/`, `Carthage/Build/`, and the generated `PhotoManager/PhotoManager.xcodeproj/`.
>
> ### `README.md`
> Cover: plan/scope table, architecture summary, project layout, build steps (`brew install xcodegen`, `xcodegen generate`, `open PhotoManager.xcodeproj`, Cmd+R), key file pointers, and a post-v1 roadmap (map view, Live Photos + video, edit/crop/filters with CoreImage, CloudKit sync via SwiftData, shared albums, on-device Vision search).
>
> ### Non-goals (do NOT include)
> - No networking layer, no server, no auth, no analytics
> - No CocoaPods / Carthage / SPM dependencies
> - No hand-written `.pbxproj` — rely on XcodeGen
> - No unit-test target in v1
> - No emoji in code or docs
>
> ### Output
> Produce every file, correctly nested. Do not stub files with TODOs — every view and service must compile and run on a clean iOS 17 simulator after `xcodegen generate`.

---

## How to use

1. Copy the block between the horizontal rules into a new Claude session.
2. Point it at an empty directory.
3. After generation: `cd PhotoManager && xcodegen generate && open PhotoManager.xcodeproj`.
