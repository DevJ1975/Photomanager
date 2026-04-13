import Foundation
import SwiftData

/// A user-created collection that groups photos by their local asset identifier.
@Model
final class UserCollection {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var assetIdentifiers: [String]
    var colorHex: String?

    init(name: String, assetIdentifiers: [String] = [], colorHex: String? = nil) {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
        self.assetIdentifiers = assetIdentifiers
        self.colorHex = colorHex
    }
}

/// An app-level tag that can be applied to any asset.
@Model
final class PhotoTag {
    @Attribute(.unique) var id: UUID
    var name: String
    var assetIdentifiers: [String]

    init(name: String, assetIdentifiers: [String] = []) {
        self.id = UUID()
        self.name = name
        self.assetIdentifiers = assetIdentifiers
    }
}

/// An app-level favorite independent from the system-level `PHAsset.isFavorite` flag.
@Model
final class FavoriteRef {
    @Attribute(.unique) var assetIdentifier: String
    var addedAt: Date

    init(assetIdentifier: String) {
        self.assetIdentifier = assetIdentifier
        self.addedAt = .now
    }
}
