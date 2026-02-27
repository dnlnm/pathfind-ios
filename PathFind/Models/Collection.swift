import Foundation

struct Collection: Codable, Identifiable {
  let id: String
  let name: String
  let description: String?
  let icon: String?
  let color: String?
  let _count: CollectionCount?

  var bookmarkCount: Int {
    _count?.bookmarks ?? 0
  }

  struct CollectionCount: Codable {
    let bookmarks: Int
  }
}
