import Foundation
import SwiftUI

/// Shared App Group suite ID — used by both the main app and the Share Extension
/// to share the server URL and API token.
let appGroupSuiteID = "group.pathfind.mobile"

@Observable
final class AuthStore {
  private(set) var serverURL: String = ""
  private(set) var apiToken: String = ""
  private(set) var isConnecting: Bool = false
  var connectionError: String?

  var isAuthenticated: Bool {
    !serverURL.isEmpty && !apiToken.isEmpty
  }

  var maskedToken: String {
    guard apiToken.count > 8 else { return "••••" }
    let prefix = String(apiToken.prefix(4))
    let suffix = String(apiToken.suffix(4))
    return "\(prefix)•••\(suffix)"
  }

  private let serverURLKey = "pathfind_server_url"
  private let apiTokenKey = "pathfind_api_token"

  /// Shared UserDefaults suite so the Share Extension can read these too
  private var sharedDefaults: UserDefaults {
    UserDefaults(suiteName: appGroupSuiteID) ?? .standard
  }

  init() {
    self.serverURL = sharedDefaults.string(forKey: serverURLKey) ?? ""
    self.apiToken = sharedDefaults.string(forKey: apiTokenKey) ?? ""

    // Migration: if credentials exist in standard but not in shared, copy them over
    if serverURL.isEmpty, let legacy = UserDefaults.standard.string(forKey: serverURLKey) {
      serverURL = legacy
      apiToken = UserDefaults.standard.string(forKey: apiTokenKey) ?? ""
      sharedDefaults.set(serverURL, forKey: serverURLKey)
      sharedDefaults.set(apiToken, forKey: apiTokenKey)
    }
  }

  var apiClient: APIClient {
    let client = APIClient(baseURL: serverURL, apiToken: apiToken)
    return client
  }

  func connect(serverURL: String, apiToken: String) async throws {
    isConnecting = true
    connectionError = nil

    // Normalize URL
    var normalizedURL = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
    if normalizedURL.hasSuffix("/") {
      normalizedURL = String(normalizedURL.dropLast())
    }
    if !normalizedURL.hasPrefix("http://") && !normalizedURL.hasPrefix("https://") {
      normalizedURL = "https://\(normalizedURL)"
    }

    let client = APIClient(baseURL: normalizedURL, apiToken: apiToken)

    do {
      // Validate by fetching bookmarks (page 1, limit 1)
      let _: PaginatedBookmarkResponse = try await client.request(
        endpoint: "/api/bookmarks",
        queryItems: [
          URLQueryItem(name: "page", value: "1"),
          URLQueryItem(name: "limit", value: "1"),
        ]
      )

      // Success — persist credentials to shared suite
      self.serverURL = normalizedURL
      self.apiToken = apiToken
      sharedDefaults.set(normalizedURL, forKey: serverURLKey)
      sharedDefaults.set(apiToken, forKey: apiTokenKey)
      // Also keep in standard for backward compat
      UserDefaults.standard.set(normalizedURL, forKey: serverURLKey)
      UserDefaults.standard.set(apiToken, forKey: apiTokenKey)
      isConnecting = false
    } catch {
      isConnecting = false
      connectionError = error.localizedDescription
      throw error
    }
  }

  func disconnect() {
    serverURL = ""
    apiToken = ""
    sharedDefaults.removeObject(forKey: serverURLKey)
    sharedDefaults.removeObject(forKey: apiTokenKey)
    UserDefaults.standard.removeObject(forKey: serverURLKey)
    UserDefaults.standard.removeObject(forKey: apiTokenKey)
    connectionError = nil
  }
}
