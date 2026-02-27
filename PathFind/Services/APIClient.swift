import Foundation

enum APIError: LocalizedError {
  case invalidURL
  case unauthorized
  case serverError(statusCode: Int, message: String?)
  case networkError(Error)
  case decodingError(Error)
  case unknown

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid server URL"
    case .unauthorized:
      return "Invalid or expired API token"
    case .serverError(let code, let message):
      return message ?? "Server error (\(code))"
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    case .decodingError(let error):
      return "Failed to parse response: \(error.localizedDescription)"
    case .unknown:
      return "An unknown error occurred"
    }
  }
}

actor APIClient {
  private let session: URLSession
  private var baseURL: String
  private var apiToken: String

  init(baseURL: String = "", apiToken: String = "") {
    self.baseURL = baseURL
    self.apiToken = apiToken

    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 60
    self.session = URLSession(configuration: config)
  }

  func configure(baseURL: String, apiToken: String) {
    // Normalize: strip trailing slash
    self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
    self.apiToken = apiToken
  }

  // MARK: - Generic Request

  func request<T: Decodable>(
    endpoint: String,
    method: String = "GET",
    body: (any Encodable)? = nil,
    queryItems: [URLQueryItem]? = nil
  ) async throws -> T {
    guard var components = URLComponents(string: "\(baseURL)\(endpoint)") else {
      throw APIError.invalidURL
    }

    if let queryItems, !queryItems.isEmpty {
      components.queryItems = queryItems
    }

    guard let url = components.url else {
      throw APIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    if let body {
      let encoder = JSONEncoder()
      request.httpBody = try encoder.encode(body)
    }

    let data: Data
    let response: URLResponse

    do {
      (data, response) = try await session.data(for: request)
    } catch {
      throw APIError.networkError(error)
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.unknown
    }

    switch httpResponse.statusCode {
    case 200...299:
      break
    case 401:
      throw APIError.unauthorized
    default:
      let message = try? JSONDecoder().decode([String: String].self, from: data)["error"]
      throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
    }

    do {
      let decoder = JSONDecoder()
      return try decoder.decode(T.self, from: data)
    } catch {
      throw APIError.decodingError(error)
    }
  }

  // MARK: - Void request (DELETE etc.)

  func request(
    endpoint: String,
    method: String = "DELETE",
    body: (any Encodable)? = nil,
    queryItems: [URLQueryItem]? = nil
  ) async throws {
    let _: EmptyResponse = try await request(
      endpoint: endpoint,
      method: method,
      body: body,
      queryItems: queryItems
    )
  }
}

private struct EmptyResponse: Decodable {}
