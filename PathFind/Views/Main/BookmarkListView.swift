import SafariServices
import SwiftUI

struct BookmarkListView: View {
  @Environment(AuthStore.self) private var authStore
  @Environment(BookmarkStore.self) private var store
  @AppStorage("openInExternalBrowser") private var openInExternalBrowser = false
  @AppStorage("bookmarkViewStyle") private var isCardView = true
  @AppStorage("nsfwDisplayMode") private var nsfwDisplayMode: NsfwDisplayMode = .blur

  @State private var showAddBookmark = false
  @State private var safariURL: URL?
  @State private var selectedBookmark: Bookmark?
  @State private var bookmarkToDelete: Bookmark?

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

        // Group 1: view toggle + sort + filter
        ToolbarItemGroup(placement: .topBarTrailing) {
          Button {
            withAnimation(.easeInOut(duration: 0.2)) {
              isCardView.toggle()
            }
          } label: {
            Image(systemName: isCardView ? "list.bullet" : "rectangle.grid.1x2")
              .foregroundColor(.pfTextSecondary)
          }

          sortMenu
          filterMenu
        }

        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        // Group 2: add bookmark — rendered as a separate Liquid Glass pill
        ToolbarItemGroup(placement: .topBarTrailing) {
          Button {
            showAddBookmark = true
          } label: {
            Image(systemName: "plus")
              .fontWeight(.semibold)
              .foregroundColor(.pfAccent)
          }
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
      .alert(
        "Delete Bookmark?",
        isPresented: Binding(
          get: { bookmarkToDelete != nil },
          set: { if !$0 { bookmarkToDelete = nil } }
        )
      ) {
        Button("Cancel", role: .cancel) { bookmarkToDelete = nil }
        Button("Delete", role: .destructive) {
          if let bookmark = bookmarkToDelete {
            Task {
              await store.deleteBookmark(id: bookmark.id)
              bookmarkToDelete = nil
            }
          }
        }
      } message: {
        if let bookmark = bookmarkToDelete {
          Text(
            "\"\(bookmark.title ?? bookmark.domain)\" will be permanently deleted. This action cannot be undone."
          )
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

  // MARK: - Bookmark list (card or compact depending on isCardView)

  private var bookmarkList: some View {
    Group {
      if isCardView {
        cardList
      } else {
        compactList
      }
    }
  }

  private var visibleBookmarks: [Bookmark] {
    if nsfwDisplayMode == .hide {
      return store.bookmarks.filter { $0.isNsfw != true }
    }
    return store.bookmarks
  }

  // Card layout — List with invisible row chrome so cards look floating
  // (swipeActions only work inside List, not ScrollView)
  private var cardList: some View {
    List {
      ForEach(visibleBookmarks) { bookmark in
        BookmarkRowView(
          bookmark: bookmark, 
          serverURL: authStore.serverURL,
          showMenu: true,
          onDetail: { selectedBookmark = bookmark },
          onDelete: { bookmarkToDelete = bookmark }
        )
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
          .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
          .modifier(
            BookmarkActionsModifier(
              bookmark: bookmark,
              openInExternalBrowser: openInExternalBrowser,
              safariURL: $safariURL,
              selectedBookmark: $selectedBookmark,
              bookmarkToDelete: $bookmarkToDelete,
              store: store,
              enableSwipeActions: false
            ))
      }

      if store.isLoadingMore {
        HStack {
          Spacer()
          ProgressView().tint(.pfAccent)
          Spacer()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .refreshable { await store.refresh() }
  }

  // Compact layout — plain List with row separators
  private var compactList: some View {
    List {
      ForEach(visibleBookmarks) { bookmark in
        BookmarkCompactRowView(bookmark: bookmark, serverURL: authStore.serverURL)
          .listRowBackground(Color.pfBackground)
          .listRowSeparatorTint(.pfBorder)
          .contentShape(Rectangle())
          .modifier(
            BookmarkActionsModifier(
              bookmark: bookmark,
              openInExternalBrowser: openInExternalBrowser,
              safariURL: $safariURL,
              selectedBookmark: $selectedBookmark,
              bookmarkToDelete: $bookmarkToDelete,
              store: store,
              enableSwipeActions: true
            ))
      }

      if store.isLoadingMore {
        HStack {
          Spacer()
          ProgressView().tint(.pfAccent)
          Spacer()
        }
        .listRowBackground(Color.pfBackground)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .refreshable { await store.refresh() }
  }

  private var emptyState: some View {
    VStack(spacing: 16) {
      Image(systemName: "bookmark.slash")
        .font(.system(size: 48))
        .foregroundColor(.pfTextTertiary)

      Text("No bookmarks found")
        .font(.headline)
        .foregroundColor(.pfTextSecondary)

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
          Label(sortOption.label, systemImage: sortOption.icon)
            .symbolVariant(store.sort == sortOption ? .fill : .none)
        }
      }
    } label: {
      Image(systemName: store.sort.icon)
        .foregroundColor(.pfTextSecondary)
    }
  }

  private var filterMenu: some View {
    Menu {
      ForEach(BookmarkFilter.allCases, id: \.self) { filterOption in
        Button {
          Task { await store.setFilter(filterOption) }
        } label: {
          Label(filterOption.label, systemImage: filterOption.icon)
            .symbolVariant(
              store.filter == filterOption && store.filterTag == nil
                && store.filterCollectionId == nil ? .fill : .none)
        }
      }
    } label: {
      Image(systemName: store.filter.icon)
        .foregroundColor(.pfTextSecondary)
    }
  }
}

// MARK: - Bookmark Interactions Modifier

/// Bundles tap / long-press / swipe actions so they work identically
/// in both the card layout and the compact list layout.
struct BookmarkActionsModifier: ViewModifier {
  let bookmark: Bookmark
  let openInExternalBrowser: Bool
  @Binding var safariURL: URL?
  @Binding var selectedBookmark: Bookmark?
  @Binding var bookmarkToDelete: Bookmark?
  let store: BookmarkStore
  var enableSwipeActions: Bool = true

  @ViewBuilder
  func body(content: Content) -> some View {
    if enableSwipeActions {
      content
        .onTapGesture { handleTap() }
        .onLongPressGesture { selectedBookmark = bookmark }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
          Button(role: .destructive) {
            bookmarkToDelete = bookmark  // ← bubble up; alert lives in parent
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
        .onAppear { handleAppear() }
    } else {
      content
        .onTapGesture { handleTap() }
        .onLongPressGesture { selectedBookmark = bookmark }
        .onAppear { handleAppear() }
    }
  }

  private func handleTap() {
    guard let url = URL(string: bookmark.url) else { return }
    if openInExternalBrowser {
      UIApplication.shared.open(url)
    } else {
      safariURL = url
    }
  }

  private func handleAppear() {
    if bookmark.id == store.bookmarks.last?.id {
      Task { await store.loadNextPage() }
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
