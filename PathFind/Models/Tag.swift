import Foundation

struct Tag: Codable, Identifiable {
  let id: String
  let name: String
  let createdAt: String?
  let _count: TagCount?

  var bookmarkCount: Int {
    _count?.bookmarks ?? 0
  }

  // The API returns the key as "_count" with nested "bookmarks"
  struct TagCount: Codable {
    let bookmarks: Int
  }
}
