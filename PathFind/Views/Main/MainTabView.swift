import SwiftUI

struct MainTabView: View {
  @Environment(AuthStore.self) private var authStore
  @State private var bookmarkStore = BookmarkStore()

  var body: some View {
    @Bindable var store = bookmarkStore
    TabView(selection: $store.selectedTab) {
      Tab("Bookmarks", systemImage: "bookmark.fill", value: 0) {
        BookmarkListView()
      }

      Tab("Collections", systemImage: "folder.fill", value: 1) {
        CollectionListView()
      }

      Tab("Tags", systemImage: "tag.fill", value: 2) {
        TagListView()
      }

      Tab("Settings", systemImage: "gearshape.fill", value: 3) {
        SettingsView()
      }

      // iOS 26: dedicated search tab – system auto-applies magnifying glass
      // icon, "Search" title, and pins it to the trailing edge of the tab bar.
      Tab(value: 4, role: .search) {
        SearchView()
      }
    }
    .tabViewSearchActivation(.searchTabSelection)
    .tabBarMinimizeBehavior(.onScrollDown)
    .environment(bookmarkStore)
    .tint(.pfAccent)
    .onAppear {
      let client = authStore.apiClient
      let service = BookmarkService(client: client)
      bookmarkStore.configure(service: service)
    }
  }
}

#Preview {
  MainTabView()
    .environment(AuthStore())
}
