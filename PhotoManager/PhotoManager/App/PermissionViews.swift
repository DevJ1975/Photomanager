import SwiftUI
import Photos

struct PermissionRequestView: View {
    let library: PhotoLibraryService

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.stack")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
            Text("Welcome to PhotoManager")
                .font(.largeTitle.bold())
            Text("To browse and organize your photos, PhotoManager needs access to your photo library.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
            Button {
                Task { await library.requestAuthorization() }
            } label: {
                Text("Grant Access")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Photo Access Required")
                .font(.title2.bold())
            Text("Enable photo access in Settings to use PhotoManager.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
