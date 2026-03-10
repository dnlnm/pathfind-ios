import SwiftUI

struct BookmarkRowView: View {
  let bookmark: Bookmark
  let serverURL: String

  @AppStorage("nsfwDisplayMode") private var nsfwDisplayMode: NsfwDisplayMode = .blur
  @State private var isRevealed = false

  private var hasThumbnail: Bool {
    guard let t = bookmark.thumbnail else { return false }
    return !t.isEmpty
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {

      // ── Thumbnail banner (always shown — real image or dynamic) ──────
      if hasThumbnail {
        ZStack(alignment: .topTrailing) {
          BookmarkThumbnailView(
            rawValue: bookmark.thumbnail,
            serverURL: serverURL,
            domain: bookmark.domain,
            title: bookmark.title,
            favicon: bookmark.favicon
          )
          .blur(
            radius: (bookmark.isNsfw == true && !isRevealed && nsfwDisplayMode == .blur) ? 20 : 0
          )
          .scaleEffect(
            (bookmark.isNsfw == true && !isRevealed && nsfwDisplayMode == .blur) ? 1.1 : 1.0)

          if bookmark.isNsfw == true && !isRevealed && nsfwDisplayMode == .blur {
            Button {
              withAnimation {
                isRevealed.toggle()
              }
            } label: {
              Image(systemName: "eye")
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(8)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
            }
            .padding(8)
          }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .clipped()
      }

      // ── Card content ─────────────────────────────────────────────────
      VStack(alignment: .leading, spacing: 8) {

        // Title
        Text(bookmark.title ?? bookmark.domain)
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundColor(.pfTextPrimary)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)

        // Domain + date row
        HStack(spacing: 5) {
          BookmarkFaviconView(rawValue: bookmark.favicon, serverURL: serverURL)
            .frame(width: 14, height: 14)
            .cornerRadius(3)
            .clipped()

          Text(bookmark.domain)
            .font(.caption)
            .foregroundColor(.pfTextSecondary)
            .lineLimit(1)

          Spacer()

          if let date = bookmark.createdAt.parseDate {
            Text(date.relativeFormatted)
              .font(.system(size: 10))
              .foregroundColor(.pfTextTertiary)
          }
        }

        // Tags
        if !bookmark.tags.isEmpty || bookmark.isReadLater || bookmark.isNsfw == true {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
              if bookmark.isNsfw == true {
                Label("NSFW", systemImage: "eye.slash")
                  .font(.system(size: 9, weight: .semibold))
                  .foregroundColor(.pfDestructive)
                  .padding(.horizontal, 6)
                  .padding(.vertical, 3)
                  .background(Color.pfDestructive.opacity(0.15))
                  .cornerRadius(5)
              }
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
      .padding(12)
    }
    .background(Color.pfSurface)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(Color.pfBorder, lineWidth: 0.5)
    )
    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
  }
}

// MARK: - Compact List Row (old-style horizontal layout)

struct BookmarkCompactRowView: View {
  let bookmark: Bookmark
  let serverURL: String

  @AppStorage("nsfwDisplayMode") private var nsfwDisplayMode: NsfwDisplayMode = .blur
  @State private var isRevealed = false

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
            .lineLimit(1)

          Spacer()

          if let date = bookmark.createdAt.parseDate {
            Text(date.relativeFormatted)
              .font(.system(size: 10))
              .foregroundColor(.pfTextTertiary)
          }
        }

        // Tags
        if !bookmark.tags.isEmpty || bookmark.isReadLater || bookmark.isNsfw == true {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
              if bookmark.isNsfw == true {
                Label("NSFW", systemImage: "eye.slash")
                  .font(.system(size: 9, weight: .semibold))
                  .foregroundColor(.pfDestructive)
                  .padding(.horizontal, 6)
                  .padding(.vertical, 3)
                  .background(Color.pfDestructive.opacity(0.15))
                  .cornerRadius(5)
              }
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

      // Right: small thumbnail
      ZStack(alignment: .topTrailing) {
        BookmarkThumbnailView(
          rawValue: bookmark.thumbnail,
          serverURL: serverURL,
          domain: bookmark.domain,
          title: bookmark.title,
          favicon: bookmark.favicon
        )
        .blur(radius: (bookmark.isNsfw == true && !isRevealed && nsfwDisplayMode == .blur) ? 10 : 0)
        .scaleEffect(
          (bookmark.isNsfw == true && !isRevealed && nsfwDisplayMode == .blur) ? 1.1 : 1.0)

        if bookmark.isNsfw == true && !isRevealed && nsfwDisplayMode == .blur {
          Button {
            withAnimation {
              isRevealed.toggle()
            }
          } label: {
            Image(systemName: "eye")
              .font(.system(size: 10))
              .foregroundColor(.white)
              .padding(6)
              .background(Color.black.opacity(0.5))
              .clipShape(Circle())
          }
          .padding(4)
        }
      }
      .frame(width: 68, height: 68)
      .cornerRadius(10)
      .clipped()
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 2)
  }
}

// MARK: - Thumbnail View

/// Handles all thumbnail formats:
/// 1. "/api/thumbnails/xxx.webp"  — server-stored WebP → AsyncImage via resolved URL
/// 2. "/api/thumbnail?..."        — server SVG iOS can't render → DynamicThumbnailView
/// 3. "https://..."               — remote raster image → AsyncImage
/// 4. nil / empty                 — DynamicThumbnailView
struct BookmarkThumbnailView: View {
  let rawValue: String?
  let serverURL: String
  let domain: String
  let title: String?
  let favicon: String?

  var body: some View {
    Group {
      if let raw = rawValue, !raw.isEmpty {
        if raw.hasPrefix("/api/thumbnail?") || raw.hasPrefix("api/thumbnail?") {
          // ⚡ Server SVG fallback — replace with native dynamic thumbnail
          DynamicThumbnailView(title: title, domain: domain, favicon: favicon, serverURL: serverURL)
        } else if let url = resolvedURL(raw) {
          // 🌐 Remote or local WebP image
          AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
              image.resizable().aspectRatio(contentMode: .fill)
            default:
              DynamicThumbnailView(title: title, domain: domain, favicon: favicon, serverURL: serverURL)
            }
          }
        } else {
          DynamicThumbnailView(title: title, domain: domain, favicon: favicon, serverURL: serverURL)
        }
      } else {
        DynamicThumbnailView(title: title, domain: domain, favicon: favicon, serverURL: serverURL)
      }
    }
  }

  private func resolvedURL(_ path: String) -> URL? {
    if path.hasPrefix("http://") || path.hasPrefix("https://") {
      return URL(string: path)
    }
    let base = serverURL.hasSuffix("/") ? String(serverURL.dropLast()) : serverURL
    let slash = path.hasPrefix("/") ? "" : "/"
    return URL(string: base + slash + path)
  }
}

// MARK: - Dynamic Thumbnail View

/// Generates a branded thumbnail locally on iOS:
/// - Downloads the favicon and extracts the dominant color via Core Image
/// - Falls back to a deterministic hue derived from the domain name
/// - Renders a gradient card with decorative circles and the title text
struct DynamicThumbnailView: View {
  let title: String?
  let domain: String
  let favicon: String?
  let serverURL: String

  @State private var brandColor: Color = .clear
  @State private var colorReady = false

  var body: some View {
    GeometryReader { geo in
      let smallSize = geo.size.height < 80
      let baseColor = colorReady ? brandColor : deterministicColor(for: domain)

      ZStack {
        // ── Gradient background ───────────────────────────────────────
        baseColor
        LinearGradient(
          colors: [Color.black.opacity(0), Color.black.opacity(0.25)],
          startPoint: .top,
          endPoint: .bottom
        )

        // ── Decorative circles ────────────────────────────────────────
        Circle()
          .fill(Color.white.opacity(0.12))
          .frame(width: geo.size.width * 0.55)
          .offset(x: geo.size.width * 0.35, y: -geo.size.height * 0.28)

        Circle()
          .fill(Color.white.opacity(0.07))
          .frame(width: geo.size.width * 0.38)
          .offset(x: -geo.size.width * 0.18, y: geo.size.height * 0.38)

        // ── Text ──────────────────────────────────────────────────────
        if smallSize {
          // Compact view: just the initial
          Text(String(domain.prefix(1)).uppercased())
            .font(.system(size: min(geo.size.width * 0.42, 30), weight: .black, design: .rounded))
            .foregroundColor(.white.opacity(0.9))
            .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
        } else if let title {
          // Banner view: show title
          Text(title)
            .font(.system(size: clampedFontSize(geo: geo), weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
        } else {
          Text(String(domain.prefix(1)).uppercased())
            .font(.system(size: 36, weight: .black, design: .rounded))
            .foregroundColor(.white.opacity(0.9))
        }
      }
      .frame(width: geo.size.width, height: geo.size.height)
      .animation(.easeIn(duration: 0.25), value: colorReady)
    }
    .task(id: favicon ?? domain) {
      await loadBrandColor()
    }
  }

  // MARK: Helpers

  private func clampedFontSize(geo: GeometryProxy) -> CGFloat {
    let ideal = geo.size.height * 0.115
    return min(max(ideal, 12), 17)
  }

  private func loadBrandColor() async {
    let color = await Task.detached(priority: .userInitiated) { () -> Color in
      // Try to download favicon and extract color
      if let raw = self.favicon, !raw.isEmpty {
        if let url = self.resolveFaviconURL(raw),
           let uiColor = await Self.averageColor(fromURL: url)
        {
          return Color(uiColor)
        }
      }
      return Self.deterministicColor(for: self.domain)
    }.value

    brandColor = color
    colorReady = true
  }

  private func resolveFaviconURL(_ raw: String) -> URL? {
    if raw.hasPrefix("http://") || raw.hasPrefix("https://") {
      return URL(string: raw)
    }
    let base = serverURL.hasSuffix("/") ? String(serverURL.dropLast()) : serverURL
    let slash = raw.hasPrefix("/") ? "" : "/"
    return URL(string: base + slash + raw)
  }

  /// Deterministic hue from a simple domain hash — same domain always gets same color.
  private static func deterministicColor(for domain: String) -> Color {
    let hash = domain.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
    let hue = Double(abs(hash) % 360) / 360.0
    return Color(hue: hue, saturation: 0.52, brightness: 0.40)
  }

  private func deterministicColor(for domain: String) -> Color {
    Self.deterministicColor(for: domain)
  }

  /// Downloads an image from a URL and extracts the average color using Core Image.
  private static func averageColor(fromURL url: URL) async -> UIColor? {
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      guard let uiImage = UIImage(data: data) else { return nil }
      return uiImage.pfAverageColor
    } catch {
      return nil
    }
  }
}

// MARK: - Favicon View

struct BookmarkFaviconView: View {
  let rawValue: String?
  let serverURL: String

  var body: some View {
    if let raw = rawValue, !raw.isEmpty {
      if let url = resolvedURL(raw) {
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
    let slash = path.hasPrefix("/") ? "" : "/"
    return URL(string: base + slash + path)
  }
}

// MARK: - UIImage Average Color (Core Image)

extension UIImage {
  /// Returns the average color of the image using `CIAreaAverage`.
  /// Darkened slightly so it works as a readable thumbnail background.
  var pfAverageColor: UIColor? {
    guard let ciImage = CIImage(image: self) else { return nil }
    let extent = ciImage.extent
    let extentVector = CIVector(
      x: extent.origin.x, y: extent.origin.y,
      z: extent.size.width, w: extent.size.height)
    guard
      let filter = CIFilter(
        name: "CIAreaAverage",
        parameters: [
          kCIInputImageKey: ciImage,
          kCIInputExtentKey: extentVector,
        ]),
      let output = filter.outputImage
    else { return nil }

    var bitmap = [UInt8](repeating: 0, count: 4)
    let ctx = CIContext(options: [.workingColorSpace: kCFNull as Any])
    ctx.render(
      output,
      toBitmap: &bitmap,
      rowBytes: 4,
      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
      format: .RGBA8,
      colorSpace: nil)

    // Darken by 30 % so white-dominant favicons still give a readable dark bg
    let factor: CGFloat = 0.70
    return UIColor(
      red: CGFloat(bitmap[0]) / 255 * factor,
      green: CGFloat(bitmap[1]) / 255 * factor,
      blue: CGFloat(bitmap[2]) / 255 * factor,
      alpha: 1
    )
  }
}
