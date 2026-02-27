import Foundation
import SwiftUI

enum BookmarkFilter: String, CaseIterable {
  case all = "all"
  case readLater = "readlater"
  case archived = "archived"

  var label: String {
    switch self {
    case .all: return "All"
    case .readLater: return "Read Later"
    case .archived: return "Archived"
    }
  }

  var icon: String {
    switch self {
    case .all: return "tray.full"
    case .readLater: return "bookmark"
    case .archived: return "archivebox"
    }
  }
}

enum BookmarkSort: String, CaseIterable {
  case newest = "newest"
  case oldest = "oldest"
  case titleAsc = "title_asc"
  case titleDesc = "title_desc"

  var label: String {
    switch self {
    case .newest: return "Newest First"
    case .oldest: return "Oldest First"
    case .titleAsc: return "Title A→Z"
    case .titleDesc: return "Title Z→A"
    }
  }

  var icon: String {
    switch self {
    case .newest: return "arrow.down"
    case .oldest: return "arrow.up"
    case .titleAsc: return "textformat.abc"
    case .titleDesc: return "textformat.abc"
    }
  }
}

@Observable
final class BookmarkStore {
  var bookmarks: [Bookmark] = []
  var isLoading: Bool = false
  var isLoadingMore: Bool = false
  var error: String?

  var currentPage: Int = 1
  var totalPages: Int = 1
  var total: Int = 0

  var filter: BookmarkFilter = .all
  var sort: BookmarkSort = .newest
  var searchQuery: String = ""
  var selectedTab: Int = 0

  // MARK: - Search (Search Tab)
  var searchResults: [Bookmark] = []
  var searchCurrentPage: Int = 1
  var searchTotalPages: Int = 1
  var isSearchLoading: Bool = false
  var isSearchLoadingMore: Bool = false

  // Filter by tag or collection
  var filterTag: String?
  var filterCollectionId: String?
  var filterCollectionName: String?

  var collections: [Collection] = []
  var tags: [Tag] = []

  private var service: BookmarkService?
  private var loadNextPageTask: Task<Void, Never>?

  var hasMorePages: Bool {
    currentPage < totalPages
  }

  var activeFilterDescription: String? {
    if let tag = filterTag {
      return "#\(tag)"
    }
    if let name = filterCollectionName {
      return name
    }
    return nil
  }

  func configure(service: BookmarkService) {
    self.service = service
  }

  // MARK: - Load Bookmarks

  @MainActor
  func loadBookmarks(reset: Bool = true) async {
    guard let service else { return }

    if reset {
      currentPage = 1
      isLoading = true
    }

    error = nil

    do {
      let response = try await service.fetchBookmarks(
        filter: filter.rawValue,
        query: searchQuery.isEmpty ? nil : searchQuery,
        tag: filterTag,
        collection: filterCollectionId,
        sort: sort.rawValue,
        page: currentPage
      )

      if reset {
        bookmarks = response.bookmarks
      } else {
        // Atomic replacement: build a new array and assign in one shot.
        // Mutating via append() causes @Observable to fire per-element,
        // which causes UICollectionView data source inconsistency crashes.
        var merged = bookmarks
        merged.append(contentsOf: response.bookmarks)
        bookmarks = merged
      }

      totalPages = response.totalPages
      total = response.total
      isLoading = false
      isLoadingMore = false
    } catch {
      self.error = error.localizedDescription
      isLoading = false
      isLoadingMore = false
    }
  }

  @MainActor
  func loadNextPage() async {
    // Cancel any in-flight page load to avoid double-fetches from
    // multiple .onAppear calls on the last visible row.
    guard hasMorePages, !isLoadingMore else { return }
    loadNextPageTask?.cancel()
    loadNextPageTask = Task { @MainActor in
      isLoadingMore = true
      currentPage += 1
      await loadBookmarks(reset: false)
    }
    await loadNextPageTask?.value
  }

  @MainActor
  func refresh() async {
    await loadBookmarks(reset: true)
  }

  // MARK: - Search Tab

  @MainActor
  func runSearch(reset: Bool = true) async {
    guard let service, !searchQuery.isEmpty else { return }

    if reset {
      searchCurrentPage = 1
      isSearchLoading = true
    } else {
      isSearchLoadingMore = true
    }

    do {
      let response = try await service.fetchBookmarks(
        filter: BookmarkFilter.all.rawValue,
        query: searchQuery,
        tag: nil,
        collection: nil,
        sort: BookmarkSort.newest.rawValue,
        page: searchCurrentPage
      )

      if reset {
        searchResults = response.bookmarks
      } else {
        var merged = searchResults
        merged.append(contentsOf: response.bookmarks)
        searchResults = merged
      }

      searchTotalPages = response.totalPages
      isSearchLoading = false
      isSearchLoadingMore = false
    } catch {
      self.error = error.localizedDescription
      isSearchLoading = false
      isSearchLoadingMore = false
    }
  }

  @MainActor
  func clearSearchResults() {
    searchResults = []
    searchCurrentPage = 1
    searchTotalPages = 1
  }

  @MainActor
  func loadNextSearchPage() async {
    guard searchCurrentPage < searchTotalPages, !isSearchLoadingMore else { return }
    searchCurrentPage += 1
    await runSearch(reset: false)
  }

  // MARK: - Actions

  @MainActor
  func deleteBookmark(id: String) async {
    guard let service else { return }

    do {
      try await service.deleteBookmark(id: id)
      bookmarks.removeAll { $0.id == id }
      total -= 1
    } catch {
      self.error = error.localizedDescription
    }
  }

  @MainActor
  func toggleArchive(bookmark: Bookmark) async {
    guard let service else { return }

    do {
      let updated = try await service.updateBookmark(
        id: bookmark.id,
        BookmarkUpdateRequest(isArchived: !bookmark.isArchived)
      )
      if let index = bookmarks.firstIndex(where: { $0.id == updated.id }) {
        // If we're filtering, the bookmark may no longer match — remove it
        if filter != .all {
          bookmarks.remove(at: index)
          total -= 1
        } else {
          bookmarks[index] = updated
        }
      }
    } catch {
      self.error = error.localizedDescription
    }
  }

  @MainActor
  func toggleReadLater(bookmark: Bookmark) async {
    guard let service else { return }

    do {
      let updated = try await service.updateBookmark(
        id: bookmark.id,
        BookmarkUpdateRequest(isReadLater: !bookmark.isReadLater)
      )
      if let index = bookmarks.firstIndex(where: { $0.id == updated.id }) {
        if filter == .readLater {
          bookmarks.remove(at: index)
          total -= 1
        } else {
          bookmarks[index] = updated
        }
      }
    } catch {
      self.error = error.localizedDescription
    }
  }

  // MARK: - Filters

  @MainActor
  func setFilter(_ newFilter: BookmarkFilter) async {
    filter = newFilter
    filterTag = nil
    filterCollectionId = nil
    filterCollectionName = nil
    await loadBookmarks(reset: true)
  }

  @MainActor
  func setTagFilter(_ tag: String) async {
    filterTag = tag
    filterCollectionId = nil
    filterCollectionName = nil
    filter = .all
    selectedTab = 0
    await loadBookmarks(reset: true)
  }

  @MainActor
  func setCollectionFilter(id: String, name: String) async {
    filterCollectionId = id
    filterCollectionName = name
    filterTag = nil
    filter = .all
    selectedTab = 0
    await loadBookmarks(reset: true)
  }

  @MainActor
  func clearCustomFilter() async {
    filterTag = nil
    filterCollectionId = nil
    filterCollectionName = nil
    selectedTab = 0
    await loadBookmarks(reset: true)
  }

  @MainActor
  func setSort(_ newSort: BookmarkSort) async {
    sort = newSort
    await loadBookmarks(reset: true)
  }

  // MARK: - Collections & Tags

  @MainActor
  func loadCollections() async {
    guard let service else { return }
    do {
      collections = try await service.fetchCollections()
    } catch {
      self.error = error.localizedDescription
    }
  }

  @MainActor
  func loadTags() async {
    guard let service else { return }
    do {
      tags = try await service.fetchTags()
    } catch {
      self.error = error.localizedDescription
    }
  }
}
