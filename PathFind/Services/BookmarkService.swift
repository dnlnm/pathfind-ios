import Foundation

struct BookmarkService {
  let client: APIClient

  // MARK: - Bookmarks

  func fetchBookmarks(
    filter: String = "all",
    query: String? = nil,
    tag: String? = nil,
    collection: String? = nil,
    sort: String = "newest",
    page: Int = 1,
    limit: Int = 30
  ) async throws -> PaginatedBookmarkResponse {
    var queryItems = [
      URLQueryItem(name: "filter", value: filter),
      URLQueryItem(name: "sort", value: sort),
      URLQueryItem(name: "page", value: String(page)),
      URLQueryItem(name: "limit", value: String(limit)),
    ]

    if let query, !query.isEmpty {
      queryItems.append(URLQueryItem(name: "q", value: query))
    }
    if let tag, !tag.isEmpty {
      queryItems.append(URLQueryItem(name: "tag", value: tag))
    }
    if let collection, !collection.isEmpty {
      queryItems.append(URLQueryItem(name: "collection", value: collection))
    }

    return try await client.request(
      endpoint: "/api/bookmarks",
      queryItems: queryItems
    )
  }

  func createBookmark(_ request: BookmarkCreateRequest) async throws -> Bookmark {
    return try await client.request(
      endpoint: "/api/bookmarks",
      method: "POST",
      body: request
    )
  }

  func updateBookmark(id: String, _ request: BookmarkUpdateRequest) async throws -> Bookmark {
    return try await client.request(
      endpoint: "/api/bookmarks/\(id)",
      method: "PUT",
      body: request
    )
  }

  func deleteBookmark(id: String) async throws {
    try await client.request(
      endpoint: "/api/bookmarks/\(id)",
      method: "DELETE"
    )
  }

  // MARK: - Collections

  func fetchCollections() async throws -> [Collection] {
    return try await client.request(endpoint: "/api/collections")
  }

  func createCollection(
    name: String, description: String? = nil, icon: String? = nil, color: String? = nil
  ) async throws -> Collection {
    struct Body: Encodable {
      let name: String
      let description: String?
      let icon: String?
      let color: String?
    }
    return try await client.request(
      endpoint: "/api/collections",
      method: "POST",
      body: Body(name: name, description: description, icon: icon, color: color)
    )
  }

  // MARK: - Tags

  func fetchTags() async throws -> [Tag] {
    return try await client.request(endpoint: "/api/tags")
  }
}
