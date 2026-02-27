import SwiftUI

struct BookmarkRowView: View {
  let bookmark: Bookmark
  let serverURL: String

  var body: some View {
    HStack(spacing: 12) {
      // Left: text content
      VStack(alignment: .leading, spacing: 5) {
        Text(bookmark.title ?? bookmark.domain)
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundColor(.pfTextPrimary)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)

        HStack(spacing: 5) {
          BookmarkFaviconView(rawValue: bookmark.favicon, serverURL: serverURL)
            .frame(width: 14, height: 14)
            .cornerRadius(3)
            .clipped()

          Text(bookmark.domain)
            .font(.caption)
            .foregroundColor(.pfTextSecondary)

          Spacer()

          if let date = bookmark.createdAt.parseDate {
            Text(date.relativeFormatted)
              .font(.system(size: 10))
              .foregroundColor(.pfTextTertiary)
          }
        }

        // Tags
        if !bookmark.tags.isEmpty {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
              if bookmark.isReadLater {
                Label("Later", systemImage: "bookmark.fill")
                  .font(.system(size: 9, weight: .semibold))
                  .foregroundColor(.pfWarning)
                  .padding(.horizontal, 6)
                  .padding(.vertical, 3)
                  .background(Color.pfWarning.opacity(0.15))
                  .cornerRadius(5)
              }
              ForEach(bookmark.tags.prefix(3)) { tag in
                Text("#\(tag.name)")
                  .font(.system(size: 10, weight: .medium))
                  .foregroundColor(Color.tagColor(for: tag.name))
                  .padding(.horizontal, 7)
                  .padding(.vertical, 3)
                  .background(Color.tagColor(for: tag.name).opacity(0.14))
                  .cornerRadius(5)
              }
              if bookmark.tags.count > 3 {
                Text("+\(bookmark.tags.count - 3)")
                  .font(.system(size: 10))
                  .foregroundColor(.pfTextTertiary)
              }
            }
          }
        }
      }

      // Right: thumbnail
      BookmarkThumbnailView(
        rawValue: bookmark.thumbnail, serverURL: serverURL, domain: bookmark.domain
      )
      .frame(width: 72, height: 72)
      .cornerRadius(10)
      .clipped()
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 2)
  }
}

// MARK: - Thumbnail View

/// Handles all three thumbnail formats PathFind stores:
/// 1. "data:image/...;base64,..." — inline base64 image
/// 2. "/api/thumbnail?..." — generated SVG placeholder (relative URL)
/// 3. "https://..." — absolute external URL
struct BookmarkThumbnailView: View {
  let rawValue: String?
  let serverURL: String
  let domain: String

  var body: some View {
    Group {
      if let raw = rawValue, !raw.isEmpty {
        if raw.hasPrefix("data:image") {
          // Base64 inline image — decode directly
          Base64ImageView(dataURI: raw)
        } else if let url = resolvedURL(raw) {
          // Remote URL (absolute or relative to server)
          AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
              image.resizable().aspectRatio(contentMode: .fill)
            default:
              domainFallback
            }
          }
        } else {
          domainFallback
        }
      } else {
        domainFallback
      }
    }
  }

  private var domainFallback: some View {
    ZStack {
      LinearGradient(
        colors: [Color.pfSurface, Color.pfSurfaceLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      Text(String(domain.prefix(1)).uppercased())
        .font(.system(size: 24, weight: .bold, design: .rounded))
        .foregroundColor(.pfAccent.opacity(0.7))
    }
  }

  private func resolvedURL(_ path: String) -> URL? {
    if path.hasPrefix("http://") || path.hasPrefix("https://") {
      return URL(string: path)
    }
    let base = serverURL.hasSuffix("/") ? String(serverURL.dropLast()) : serverURL
    return URL(string: base + path)
  }
}

// MARK: - Favicon View

struct BookmarkFaviconView: View {
  let rawValue: String?
  let serverURL: String

  var body: some View {
    if let raw = rawValue, !raw.isEmpty {
      if raw.hasPrefix("data:image") {
        Base64ImageView(dataURI: raw)
      } else if let url = resolvedURL(raw) {
        AsyncImage(url: url) { phase in
          if case .success(let img) = phase {
            img.resizable().aspectRatio(contentMode: .fit)
          } else {
            Color.clear
          }
        }
      } else {
        Color.clear
      }
    } else {
      Color.clear
    }
  }

  private func resolvedURL(_ path: String) -> URL? {
    if path.hasPrefix("http://") || path.hasPrefix("https://") {
      return URL(string: path)
    }
    let base = serverURL.hasSuffix("/") ? String(serverURL.dropLast()) : serverURL
    return URL(string: base + path)
  }
}

// MARK: - Base64 Image Decoder

/// Decodes a "data:image/...;base64,..." URI into a SwiftUI Image.
struct Base64ImageView: View {
  let dataURI: String

  private var uiImage: UIImage? {
    // Strip the "data:image/...;base64," prefix
    guard let commaIndex = dataURI.firstIndex(of: ",") else { return nil }
    let base64String = String(dataURI[dataURI.index(after: commaIndex)...])
    guard let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else {
      return nil
    }
    return UIImage(data: data)
  }

  var body: some View {
    if let image = uiImage {
      Image(uiImage: image)
        .resizable()
        .aspectRatio(contentMode: .fill)
    } else {
      Color.pfSurfaceLight
    }
  }
}
