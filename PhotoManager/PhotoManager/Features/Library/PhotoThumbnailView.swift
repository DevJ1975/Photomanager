import SwiftUI
import Photos
import UIKit

struct PhotoThumbnailView: View {
    let asset: PHAsset
    @Environment(PhotoLibraryService.self) private var library
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.systemGray5)
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                if asset.mediaType == .video {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "play.fill")
                            Text(durationString)
                            Spacer()
                        }
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(.black.opacity(0.35))
                    }
                }
                if asset.isFavorite {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .shadow(radius: 1)
                                .padding(4)
                        }
                        Spacer()
                    }
                }
            }
            .task(id: asset.localIdentifier) {
                let size = CGSize(width: geo.size.width * UIScreen.main.scale,
                                  height: geo.size.height * UIScreen.main.scale)
                library.requestThumbnail(for: asset, targetSize: size) { img in
                    Task { @MainActor in self.image = img }
                }
            }
        }
    }

    private var durationString: String {
        let seconds = Int(asset.duration)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
