import SwiftUI
import SwiftData

@main
struct PhotoManagerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [UserCollection.self, PhotoTag.self, FavoriteRef.self])
    }
}
