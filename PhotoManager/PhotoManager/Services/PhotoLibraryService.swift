import Foundation
import Photos
import UIKit
import Observation

@Observable
final class PhotoLibraryService: NSObject {
    var authorizationStatus: PHAuthorizationStatus = .notDetermined
    var allPhotos: PHFetchResult<PHAsset> = PHFetchResult<PHAsset>()
    var userAlbums: [PHAssetCollection] = []
    var smartAlbums: [PHAssetCollection] = []

    private let imageManager = PHCachingImageManager()

    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    @MainActor
    func refreshAuthorizationStatus() async {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if authorizationStatus == .authorized || authorizationStatus == .limited {
            await reloadCollections()
        }
    }

    @MainActor
    func requestAuthorization() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
        if status == .authorized || status == .limited {
            await reloadCollections()
        }
    }

    @MainActor
    func reloadCollections() async {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allPhotos = PHAsset.fetchAssets(with: options)

        let smart = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        var smartList: [PHAssetCollection] = []
        smart.enumerateObjects { collection, _, _ in smartList.append(collection) }
        smartAlbums = smartList.filter { $0.estimatedAssetCount > 0 || $0.assetCollectionSubtype == .smartAlbumUserLibrary }

        let user = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        var userList: [PHAssetCollection] = []
        user.enumerateObjects { collection, _, _ in userList.append(collection) }
        userAlbums = userList
    }

    // MARK: - Image Loading

    func requestThumbnail(for asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        imageManager.requestImage(for: asset,
                                  targetSize: targetSize,
                                  contentMode: .aspectFill,
                                  options: options) { image, _ in
            completion(image)
        }
    }

    func requestFullImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        imageManager.requestImage(for: asset,
                                  targetSize: PHImageManagerMaximumSize,
                                  contentMode: .aspectFit,
                                  options: options) { image, _ in
            completion(image)
        }
    }

    func startCaching(assets: [PHAsset], targetSize: CGSize) {
        imageManager.startCachingImages(for: assets, targetSize: targetSize,
                                        contentMode: .aspectFill, options: nil)
    }

    func stopCaching(assets: [PHAsset], targetSize: CGSize) {
        imageManager.stopCachingImages(for: assets, targetSize: targetSize,
                                       contentMode: .aspectFill, options: nil)
    }

    // MARK: - Mutations

    func toggleSystemFavorite(_ asset: PHAsset) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest(for: asset)
            request.isFavorite = !asset.isFavorite
        }
    }

    func delete(_ assets: [PHAsset]) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }
    }

    // MARK: - Helpers

    func assets(in collection: PHAssetCollection) -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(in: collection, options: options)
    }

    func favoriteAssets() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "favorite == YES")
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(with: options)
    }
}

extension PhotoLibraryService: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            await reloadCollections()
        }
    }
}
