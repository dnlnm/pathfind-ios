import Foundation

struct Bookmark: Codable, Identifiable {
  let id: String
  let url: String
  let title: String?
  let description: String?
  let notes: String?
  let favicon: String?
  let thumbnail: String?
  let isArchived: Bool
  let isReadLater: Bool
  let createdAt: String
  let updatedAt: String
  let userId: String
  let tags: [BookmarkTag]
  let collections: [BookmarkCollection]?

  var domain: String {
    URL(string: url)?.host?.replacingOccurrences(of: "www.", with: "") ?? url
  }

  var createdDate: Date? {
    ISO8601DateFormatter.flexible.date(from: createdAt)
  }
}

struct BookmarkTag: Codable, Identifiable, Hashable {
  let id: String
  let name: String
}

struct BookmarkCollection: Codable, Identifiable, Hashable {
  let id: String
  let name: String
  let color: String?
}

struct PaginatedBookmarkResponse: Codable {
  let bookmarks: [Bookmark]
  let total: Int
  let page: Int
  let totalPages: Int
}

struct BookmarkCreateRequest: Encodable {
  let url: String
  var title: String?
  var notes: String?
  var tags: [String]?
  var collections: [String]?
  var isReadLater: Bool?
}

struct BookmarkUpdateRequest: Encodable {
  var title: String?
  var description: String?
  var notes: String?
  var tags: [String]?
  var collections: [String]?
  var isArchived: Bool?
  var isReadLater: Bool?
}

extension ISO8601DateFormatter {
  static let flexible: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()
}
