import CoreSpotlight
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
            .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
              if let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier]
                as? String
              {
                let parts = identifier.components(separatedBy: "||")
                if parts.count == 2, let url = URL(string: parts[1]) {
                  UIApplication.shared.open(url)
                }
              }
            }
        } else {
          SetupView()
        }
      }
      .environment(authStore)
      .preferredColorScheme(appearanceSetting.colorScheme)
    }
  }
}
