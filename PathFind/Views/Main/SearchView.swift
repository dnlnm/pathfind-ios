import SafariServices
import SwiftUI

struct SearchView: View {
  @Environment(AuthStore.self) private var authStore
  @Environment(BookmarkStore.self) private var store
  @AppStorage("openInExternalBrowser") private var openInExternalBrowser = false
  @AppStorage("bookmarkViewStyle") private var isCardView = true

  @State private var safariURL: URL?
  @State private var selectedBookmark: Bookmark?
  @State private var bookmarkToDelete: Bookmark?

  var body: some View {
    @Bindable var store = store

    NavigationStack {
      ZStack {
        Color.pfBackground.ignoresSafeArea()

        if store.searchQuery.isEmpty {
          searchPrompt
        } else if store.isSearchLoading && store.searchResults.isEmpty {
          ProgressView()
            .tint(.pfAccent)
            .scaleEffect(1.2)
        } else if store.searchResults.isEmpty && !store.isSearchLoading {
          noResults
        } else {
          resultsList
        }
      }
      .navigationTitle("Search")
      .navigationBarTitleDisplayMode(.large)
      .toolbarBackground(Color.pfBackground, for: .navigationBar)
    }
    .searchable(text: $store.searchQuery, prompt: "Search bookmarks…")
    .onSubmit(of: .search) {
      Task { await store.runSearch(reset: true) }
    }
    .onChange(of: store.searchQuery) { oldValue, newValue in
      if newValue.isEmpty && !oldValue.isEmpty {
        store.clearSearchResults()
      } else if !newValue.isEmpty {
        Task {
          try? await Task.sleep(for: .milliseconds(400))
          // Only fire if query hasn't changed since the sleep started
          if store.searchQuery == newValue {
            await store.runSearch(reset: true)
          }
        }
      }
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

  // MARK: - Subviews

  private var searchPrompt: some View {
    VStack(spacing: 16) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 52))
        .foregroundColor(.pfTextTertiary)

      Text("Search Bookmarks")
        .font(.title3.weight(.semibold))
        .foregroundColor(.pfTextSecondary)

      Text("Type to search by title, URL, or description")
        .font(.subheadline)
        .foregroundColor(.pfTextTertiary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
    }
  }

  private var noResults: some View {
    VStack(spacing: 16) {
      Image(systemName: "bookmark.slash")
        .font(.system(size: 48))
        .foregroundColor(.pfTextTertiary)

      Text("No results for \"\(store.searchQuery)\"")
        .font(.headline)
        .foregroundColor(.pfTextSecondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)

      Text("Try a different keyword")
        .font(.subheadline)
        .foregroundColor(.pfTextTertiary)
    }
  }

  @ViewBuilder
  private var resultsList: some View {
    @Bindable var store = store
    List {
      ForEach(store.searchResults) { bookmark in
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
              store: store
            )
          )
          .onAppear {
            if bookmark.id == store.searchResults.last?.id {
              Task { await store.loadNextSearchPage() }
            }
          }
      }

      if store.isSearchLoadingMore {
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
  }
}

#Preview {
  SearchView()
    .environment(AuthStore())
    .environment(BookmarkStore())
}
