import SafariServices
import SwiftUI

struct BookmarkListView: View {
  @Environment(AuthStore.self) private var authStore
  @Environment(BookmarkStore.self) private var store
  @AppStorage("openInExternalBrowser") private var openInExternalBrowser = false

  @State private var showAddBookmark = false
  @State private var safariURL: URL?
  @State private var selectedBookmark: Bookmark?

  var body: some View {
    @Bindable var store = store

    NavigationStack {
      ZStack {
        Color.pfBackground.ignoresSafeArea()

        if store.isLoading && store.bookmarks.isEmpty {
          ProgressView()
            .tint(.pfAccent)
            .scaleEffect(1.2)
        } else if store.bookmarks.isEmpty && !store.isLoading {
          emptyState
        } else {
          bookmarkList
        }
      }
      .navigationTitle(navigationTitle)
      .navigationBarTitleDisplayMode(.large)
      .toolbarBackground(Color.pfBackground, for: .navigationBar)
      .toolbarColorScheme(.dark, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          if store.activeFilterDescription != nil {
            Button {
              Task { await store.clearCustomFilter() }
            } label: {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.pfTextSecondary)
            }
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          HStack(spacing: 12) {
            sortMenu
            filterMenu
            Button {
              showAddBookmark = true
            } label: {
              Image(systemName: "plus")
                .fontWeight(.semibold)
                .foregroundColor(.pfAccent)
            }
          }
        }
      }
      .searchable(text: $store.searchQuery, prompt: "Search bookmarks...")
      .onSubmit(of: .search) {
        Task { await store.loadBookmarks(reset: true) }
      }
      .onChange(of: store.searchQuery) { oldValue, newValue in
        if newValue.isEmpty && !oldValue.isEmpty {
          Task { await store.loadBookmarks(reset: true) }
        }
      }
      .sheet(isPresented: $showAddBookmark) {
        AddBookmarkView()
      }
      .sheet(item: $selectedBookmark) { bookmark in
        BookmarkDetailView(bookmark: bookmark)
      }
      .sheet(
        isPresented: Binding(
          get: { safariURL != nil },
          set: { if !$0 { safariURL = nil } }
        )
      ) {
        if let url = safariURL {
          SafariView(url: url)
            .ignoresSafeArea()
        }
      }
    }
    .task {
      if store.bookmarks.isEmpty {
        await store.loadBookmarks(reset: true)
      }
    }
  }

  // MARK: - Subviews

  private var navigationTitle: String {
    if let desc = store.activeFilterDescription {
      return desc
    }
    return "Bookmarks"
  }

  private var bookmarkList: some View {
    List {
      ForEach(store.bookmarks) { bookmark in
        BookmarkRowView(bookmark: bookmark, serverURL: authStore.serverURL)
          .listRowBackground(Color.pfBackground)
          .listRowSeparatorTint(.pfBorder)
          .contentShape(Rectangle())
          .onTapGesture {
            guard let url = URL(string: bookmark.url) else { return }
            if openInExternalBrowser {
              UIApplication.shared.open(url)
            } else {
              safariURL = url
            }
          }
          .onLongPressGesture {
            // Long press → show detail sheet
            selectedBookmark = bookmark
          }
          .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
              Task { await store.deleteBookmark(id: bookmark.id) }
            } label: {
              Label("Delete", systemImage: "trash")
            }

            Button {
              Task { await store.toggleArchive(bookmark: bookmark) }
            } label: {
              Label(
                bookmark.isArchived ? "Unarchive" : "Archive",
                systemImage: bookmark.isArchived ? "tray.and.arrow.up" : "archivebox"
              )
            }
            .tint(.pfWarning)
          }
          .swipeActions(edge: .leading) {
            Button {
              selectedBookmark = bookmark
            } label: {
              Label("Detail", systemImage: "info.circle")
            }
            .tint(.pfSurfaceLight)

            Button {
              Task { await store.toggleReadLater(bookmark: bookmark) }
            } label: {
              Label(
                bookmark.isReadLater ? "Remove" : "Read Later",
                systemImage: bookmark.isReadLater ? "bookmark.slash" : "bookmark"
              )
            }
            .tint(.pfAccent)
          }
          .onAppear {
            // Infinite scroll
            if bookmark.id == store.bookmarks.last?.id {
              Task { await store.loadNextPage() }
            }
          }
      }

      if store.isLoadingMore {
        HStack {
          Spacer()
          ProgressView()
            .tint(.pfAccent)
          Spacer()
        }
        .listRowBackground(Color.pfBackground)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .refreshable {
      await store.refresh()
    }
  }

  private var emptyState: some View {
    VStack(spacing: 16) {
      Image(systemName: "bookmark.slash")
        .font(.system(size: 48))
        .foregroundColor(.pfTextTertiary)

      Text("No bookmarks found")
        .font(.headline)
        .foregroundColor(.pfTextSecondary)

      if !store.searchQuery.isEmpty {
        Text("Try a different search term")
          .font(.subheadline)
          .foregroundColor(.pfTextTertiary)
      }

      Button {
        showAddBookmark = true
      } label: {
        Label("Add Bookmark", systemImage: "plus")
          .fontWeight(.medium)
          .padding(.horizontal, 20)
          .padding(.vertical, 10)
          .background(Color.pfAccent)
          .foregroundColor(.white)
          .cornerRadius(10)
      }
    }
  }



  // MARK: - Menus

  private var sortMenu: some View {
    Menu {
      ForEach(BookmarkSort.allCases, id: \.self) { sortOption in
        Button {
          Task { await store.setSort(sortOption) }
        } label: {
          Label {
            Text(sortOption.label)
          } icon: {
            if store.sort == sortOption {
              Image(systemName: "checkmark")
            }
          }
        }
      }
    } label: {
      Image(systemName: "arrow.up.arrow.down")
        .foregroundColor(.pfTextSecondary)
    }
  }

  private var filterMenu: some View {
    Menu {
      ForEach(BookmarkFilter.allCases, id: \.self) { filterOption in
        Button {
          Task { await store.setFilter(filterOption) }
        } label: {
          Label {
            Text(filterOption.label)
          } icon: {
            if store.filter == filterOption && store.filterTag == nil
              && store.filterCollectionId == nil
            {
              Image(systemName: "checkmark")
            }
          }
        }
      }
    } label: {
      Image(systemName: "line.3.horizontal.decrease.circle")
        .foregroundColor(.pfTextSecondary)
    }
  }
}

// MARK: - Safari View

struct SafariView: UIViewControllerRepresentable {
  let url: URL

  func makeUIViewController(context: Context) -> SFSafariViewController {
    let config = SFSafariViewController.Configuration()
    config.entersReaderIfAvailable = false
    let vc = SFSafariViewController(url: url, configuration: config)
    vc.preferredControlTintColor = UIColor(Color.pfAccent)
    return vc
  }

  func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
  BookmarkListView()
    .environment(AuthStore())
    .environment(BookmarkStore())
}
