import SwiftUI

@main
struct PathFind: App {
  @State private var authStore = AuthStore()
  @AppStorage("appearanceSetting") private var appearanceSetting: AppearanceSetting = .dark

  var body: some Scene {
    WindowGroup {
      Group {
        if authStore.isAuthenticated {
          MainTabView()
        } else {
          SetupView()
        }
      }
      .environment(authStore)
      .preferredColorScheme(appearanceSetting.colorScheme)
    }
  }
}
