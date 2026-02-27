import SwiftUI

struct MainTabView: View {
  @Environment(AuthStore.self) private var authStore
  @State private var bookmarkStore = BookmarkStore()

  var body: some View {
    @Bindable var store = bookmarkStore
    TabView(selection: $store.selectedTab) {
      BookmarkListView()
        .tabItem {
          Label("Bookmarks", systemImage: "bookmark.fill")
        }
        .tag(0)

      CollectionListView()
        .tabItem {
          Label("Collections", systemImage: "folder.fill")
        }
        .tag(1)

      TagListView()
        .tabItem {
          Label("Tags", systemImage: "tag.fill")
        }
        .tag(2)

      SettingsView()
        .tabItem {
          Label("Settings", systemImage: "gearshape.fill")
        }
        .tag(3)
    }
    .environment(bookmarkStore)
    .tint(.pfAccent)
    .onAppear {
      configureTabBarAppearance()
      let client = authStore.apiClient
      let service = BookmarkService(client: client)
      bookmarkStore.configure(service: service)
    }
  }

  private func configureTabBarAppearance() {
    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor(Color.pfSurface)
    UITabBar.appearance().standardAppearance = appearance
    UITabBar.appearance().scrollEdgeAppearance = appearance
  }
}

#Preview {
  MainTabView()
    .environment(AuthStore())
}
