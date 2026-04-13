# PhotoManager

A universal iPhone/iPad photo browsing and organization app built with SwiftUI, PhotoKit, and SwiftData.

## Plan & Scope

Since the repository started empty, this is a clean greenfield iOS app. The v1 goals:

| Area | Feature |
| --- | --- |
| Library | Grid view of all photos, adaptive columns (3 on iPhone, 6 on iPad) |
| Albums | System smart albums + user-created albums from PhotoKit |
| Detail | Full-screen viewer with pinch-to-zoom, double-tap zoom, share, favorite |
| Collections | App-managed collections (SwiftData) grouping assets across albums |
| Favorites | Mirrors `PHAsset.isFavorite` + app-level favorites via `FavoriteRef` |
| Search | Filter by media type / favorite / year |
| Permissions | Proper full/limited PhotoKit authorization flow |

## Architecture

- **SwiftUI** for all views, targeting **iOS 17+**.
- **MVVM-lite** using the new `@Observable` macro (`PhotoLibraryService`).
- **PhotoKit** (`PHAsset`, `PHAssetCollection`, `PHCachingImageManager`) for on-device library access — no server, no cloud, everything stays on device.
- **SwiftData** for app-owned metadata: `UserCollection`, `PhotoTag`, `FavoriteRef`.
- **Universal layout** driven by `horizontalSizeClass`:
  - iPhone → `TabView`
  - iPad → `NavigationSplitView` with a sidebar

## Project layout

```
PhotoManager/
├── project.yml                         # XcodeGen spec
├── PhotoManager/
│   ├── App/                            # Entry point, root view, permission gates
│   ├── Features/
│   │   ├── Library/                    # Grid of all photos
│   │   ├── Albums/                     # Smart + user albums
│   │   ├── Detail/                     # Photo viewer, info sheet, zoom
│   │   ├── Collections/                # SwiftData collections + favorites
│   │   └── Search/
│   ├── Services/
│   │   └── PhotoLibraryService.swift   # PhotoKit wrapper, caching
│   ├── Models/
│   │   └── SwiftDataModels.swift
│   └── Resources/                      # Info.plist, Assets.xcassets
```

## Building

### Requirements
- Xcode 15.3 or newer
- iOS 17 SDK
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Generate the Xcode project
```bash
cd PhotoManager
xcodegen generate
open PhotoManager.xcodeproj
```

### Run
1. Select an iPhone or iPad simulator (or a connected device).
2. Cmd+R.
3. On first launch, grant photo-library access when prompted.

## Key files

- `PhotoManager/App/PhotoManagerApp.swift` — app entry, SwiftData container.
- `PhotoManager/App/RootView.swift` — permissions gate + adaptive iPhone/iPad layout.
- `PhotoManager/Services/PhotoLibraryService.swift` — `PHPhotoLibrary` observer, fetch + cache.
- `PhotoManager/Features/Detail/PhotoDetailView.swift` — zoom, share, favorite, info.

## Roadmap (post-v1)

- Map view for geotagged photos
- Live Photo and video playback in detail view
- Edit/crop/filters via `CIImage`
- iCloud sync for `UserCollection` via CloudKit-backed SwiftData
- Shared albums via `PHAssetCollectionChangeRequest`
- Visual similarity / on-device search with `Vision`
