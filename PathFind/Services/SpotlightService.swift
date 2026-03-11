import CoreSpotlight
import Foundation
import UniformTypeIdentifiers

final class SpotlightService {
  static let shared = SpotlightService()

  private init() {}

  func index(bookmarks: [Bookmark]) {
    // Only index if the setting is enabled (defaults to true if not set)
    let isEnabled =
      UserDefaults.standard.object(forKey: "enableSpotlightSearch") == nil
      ? true : UserDefaults.standard.bool(forKey: "enableSpotlightSearch")
    guard isEnabled else { return }

    Task {
      var items: [CSSearchableItem] = []

      for bookmark in bookmarks {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .url)
        attributeSet.title = bookmark.title ?? bookmark.url
        attributeSet.contentDescription = bookmark.description ?? bookmark.notes ?? bookmark.domain

        let urlDomain = URL(string: bookmark.url)?.host ?? bookmark.url
        attributeSet.keywords =
          [urlDomain, bookmark.title].compactMap { $0 } + bookmark.tags.map { $0.name }

        // We can add more metadata if we want, like thumbnail URL, but we need local paths for thumbnails usually in Spotlight.

        let identifier = "\(bookmark.id)||\(bookmark.url)"
        let item = CSSearchableItem(
          uniqueIdentifier: identifier,
          domainIdentifier: "com.pathfind.bookmarks",
          attributeSet: attributeSet
        )
        items.append(item)
      }

      do {
        try await CSSearchableIndex.default().indexSearchableItems(items)
      } catch {
        print("Failed to index bookmarks for Spotlight: \(error)")
      }
    }
  }

  func deindex(bookmark: Bookmark) {
    Task {
      do {
        let identifier = "\(bookmark.id)||\(bookmark.url)"
        try await CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [identifier])
      } catch {
        print("Failed to remove bookmark from Spotlight: \(error)")
      }
    }
  }

  func deindexAll() {
    Task {
      do {
        try await CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [
          "com.pathfind.bookmarks"
        ])
      } catch {
        print("Failed to delete all bookmarks from Spotlight: \(error)")
      }
    }
  }
}
