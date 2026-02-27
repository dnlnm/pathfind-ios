import SafariServices
import SwiftUI

struct BookmarkDetailView: View {
  @Environment(AuthStore.self) private var authStore
  @Environment(BookmarkStore.self) private var store
  @Environment(\.dismiss) private var dismiss

  let bookmark: Bookmark

  @State private var showSafari = false
  @State private var showEditSheet = false
  @State private var showDeleteConfirm = false

  var body: some View {
    NavigationStack {
      ZStack {
        Color.pfBackground.ignoresSafeArea()

        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            // Thumbnail
            if let thumbnail = bookmark.thumbnail, !thumbnail.isEmpty {
              let url =
                thumbnail.hasPrefix("http") ? thumbnail : "\(authStore.serverURL)\(thumbnail)"
              AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .success(let image):
                  image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: 220)
                    .clipped()
                    .cornerRadius(16)
                default:
                  EmptyView()
                }
              }
            }

            // Title & URL
            VStack(alignment: .leading, spacing: 8) {
              Text(bookmark.title ?? "Untitled")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.pfTextPrimary)

              Button {
                showSafari = true
              } label: {
                HStack(spacing: 6) {
                  // Favicon
                  if let favicon = bookmark.favicon, !favicon.isEmpty {
                    let faviconURL =
                      favicon.hasPrefix("http") ? favicon : "\(authStore.serverURL)\(favicon)"
                    AsyncImage(url: URL(string: faviconURL)) { phase in
                      if case .success(let img) = phase {
                        img.resizable()
                          .frame(width: 14, height: 14)
                          .cornerRadius(3)
                      }
                    }
                  }

                  Text(bookmark.domain)
                    .font(.subheadline)
                    .foregroundColor(.pfAccent)

                  Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 11))
                    .foregroundColor(.pfAccent)
                }
              }
            }

            // Description
            if let description = bookmark.description, !description.isEmpty {
              VStack(alignment: .leading, spacing: 6) {
                Text("Description")
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundColor(.pfTextTertiary)
                  .textCase(.uppercase)

                Text(description)
                  .font(.body)
                  .foregroundColor(.pfTextSecondary)
                  .fixedSize(horizontal: false, vertical: true)
              }
            }

            // Notes
            if let notes = bookmark.notes, !notes.isEmpty {
              VStack(alignment: .leading, spacing: 6) {
                Text("Notes")
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundColor(.pfTextTertiary)
                  .textCase(.uppercase)

                Text(notes)
                  .font(.body)
                  .foregroundColor(.pfTextSecondary)
                  .fixedSize(horizontal: false, vertical: true)
                  .padding(12)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .background(Color.pfSurface)
                  .cornerRadius(10)
              }
            }

            // Tags
            if !bookmark.tags.isEmpty {
              VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundColor(.pfTextTertiary)
                  .textCase(.uppercase)

                FlowLayout(spacing: 8) {
                  ForEach(bookmark.tags) { tag in
                    Button {
                      Task { await store.setTagFilter(tag.name) }
                      dismiss()
                    } label: {
                      Text("#\(tag.name)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.tagColor(for: tag.name))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.tagColor(for: tag.name).opacity(0.15))
                        .cornerRadius(8)
                    }
                  }
                }
              }
            }

            // Collections
            if let collections = bookmark.collections, !collections.isEmpty {
              VStack(alignment: .leading, spacing: 8) {
                Text("Collections")
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundColor(.pfTextTertiary)
                  .textCase(.uppercase)

                ForEach(collections) { collection in
                  Button {
                    Task {
                      await store.setCollectionFilter(id: collection.id, name: collection.name)
                    }
                    dismiss()
                  } label: {
                    HStack(spacing: 8) {
                      Circle()
                        .fill(Color(hex: collection.color ?? "") ?? .pfAccent)
                        .frame(width: 10, height: 10)
                      Text(collection.name)
                        .font(.subheadline)
                        .foregroundColor(.pfTextPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.pfSurface)
                    .cornerRadius(8)
                  }
                }
              }
            }

            // Metadata
            VStack(alignment: .leading, spacing: 8) {
              if let date = bookmark.createdAt.parseDate {
                HStack(spacing: 6) {
                  Image(systemName: "calendar")
                    .font(.system(size: 11))
                    .foregroundColor(.pfTextTertiary)

                  Text("Saved \(date.relativeFormatted)")
                    .font(.caption)
                    .foregroundColor(.pfTextTertiary)
                }
              }

              HStack(spacing: 12) {
                if bookmark.isReadLater {
                  Label("Read Later", systemImage: "bookmark.fill")
                    .font(.caption)
                    .foregroundColor(.pfWarning)
                }
                if bookmark.isArchived {
                  Label("Archived", systemImage: "archivebox.fill")
                    .font(.caption)
                    .foregroundColor(.pfTextTertiary)
                }
              }
            }

            // Actions
            VStack(spacing: 12) {
              Button {
                showSafari = true
              } label: {
                Label("Open in Safari", systemImage: "safari")
                  .fontWeight(.medium)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 14)
                  .background(Color.pfAccent)
                  .foregroundColor(.white)
                  .cornerRadius(12)
              }

              HStack(spacing: 12) {
                Button {
                  Task { await store.toggleArchive(bookmark: bookmark) }
                  dismiss()
                } label: {
                  Label(
                    bookmark.isArchived ? "Unarchive" : "Archive",
                    systemImage: bookmark.isArchived ? "tray.and.arrow.up" : "archivebox"
                  )
                  .font(.subheadline)
                  .fontWeight(.medium)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)
                  .background(Color.pfSurface)
                  .foregroundColor(.pfTextPrimary)
                  .cornerRadius(10)
                }

                Button {
                  Task { await store.toggleReadLater(bookmark: bookmark) }
                  dismiss()
                } label: {
                  Label(
                    bookmark.isReadLater ? "Unmark" : "Read Later",
                    systemImage: bookmark.isReadLater ? "bookmark.slash" : "bookmark"
                  )
                  .font(.subheadline)
                  .fontWeight(.medium)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)
                  .background(Color.pfSurface)
                  .foregroundColor(.pfTextPrimary)
                  .cornerRadius(10)
                }
              }

              Button {
                UIPasteboard.general.string = bookmark.url
              } label: {
                Label("Copy Link", systemImage: "doc.on.doc")
                  .font(.subheadline)
                  .fontWeight(.medium)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)
                  .background(Color.pfSurface)
                  .foregroundColor(.pfTextPrimary)
                  .cornerRadius(10)
              }

              Button(role: .destructive) {
                showDeleteConfirm = true
              } label: {
                Label("Delete Bookmark", systemImage: "trash")
                  .font(.subheadline)
                  .fontWeight(.medium)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)
                  .background(Color.pfDestructive.opacity(0.15))
                  .foregroundColor(.pfDestructive)
                  .cornerRadius(10)
              }
            }
            .padding(.top, 8)
          }
          .padding(20)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(Color.pfBackground, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.pfTextSecondary)
          }
        }
      }
      .sheet(isPresented: $showSafari) {
        if let url = URL(string: bookmark.url) {
          SafariView(url: url)
            .ignoresSafeArea()
        }
      }
      .alert("Delete Bookmark?", isPresented: $showDeleteConfirm) {
        Button("Cancel", role: .cancel) {}
        Button("Delete", role: .destructive) {
          Task {
            await store.deleteBookmark(id: bookmark.id)
            dismiss()
          }
        }
      } message: {
        Text("This action cannot be undone.")
      }
    }
  }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
  var spacing: CGFloat = 8

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let result = arrangement(proposal: proposal, subviews: subviews)
    return result.size
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    let result = arrangement(proposal: proposal, subviews: subviews)
    for (index, offset) in result.offsets.enumerated() {
      subviews[index].place(
        at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y),
        proposal: .unspecified
      )
    }
  }

  private func arrangement(proposal: ProposedViewSize, subviews: Subviews) -> (
    offsets: [CGPoint], size: CGSize
  ) {
    let maxWidth = proposal.width ?? .infinity
    var offsets: [CGPoint] = []
    var currentX: CGFloat = 0
    var currentY: CGFloat = 0
    var lineHeight: CGFloat = 0
    var maxX: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      if currentX + size.width > maxWidth && currentX > 0 {
        currentX = 0
        currentY += lineHeight + spacing
        lineHeight = 0
      }
      offsets.append(CGPoint(x: currentX, y: currentY))
      lineHeight = max(lineHeight, size.height)
      currentX += size.width + spacing
      maxX = max(maxX, currentX)
    }

    return (offsets, CGSize(width: maxX, height: currentY + lineHeight))
  }
}
