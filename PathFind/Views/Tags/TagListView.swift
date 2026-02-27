import SwiftUI

struct TagListView: View {
  @Environment(BookmarkStore.self) private var store

  @State private var regularExpanded = true
  @State private var redditExpanded = true

  // Split tags into regular vs reddit (r/...)
  private var regularTags: [Tag] {
    store.tags.filter { !$0.name.hasPrefix("r/") }
  }
  private var redditTags: [Tag] {
    store.tags.filter { $0.name.hasPrefix("r/") }
  }

  var body: some View {
    NavigationStack {
      ZStack {
        Color.pfBackground.ignoresSafeArea()

        if store.tags.isEmpty {
          VStack(spacing: 12) {
            Image(systemName: "tag")
              .font(.system(size: 44))
              .foregroundColor(.pfTextTertiary)
            Text("No tags yet")
              .font(.headline)
              .foregroundColor(.pfTextSecondary)
            Text("Tags appear when you add them to bookmarks")
              .font(.subheadline)
              .foregroundColor(.pfTextTertiary)
          }
        } else {
          List {
            // MARK: Regular tags section
            if !regularTags.isEmpty {
              Section {
                if regularExpanded {
                  ForEach(regularTags) { tag in
                    tagRow(tag)
                  }
                }
              } header: {
                sectionHeader(
                  title: "Tags",
                  icon: "tag.fill",
                  color: .pfAccent,
                  count: regularTags.count,
                  isExpanded: $regularExpanded
                )
              }
            }

            // MARK: Reddit subreddits section
            if !redditTags.isEmpty {
              Section {
                if redditExpanded {
                  ForEach(redditTags) { tag in
                    tagRow(tag)
                  }
                }
              } header: {
                sectionHeader(
                  title: "Subreddits",
                  icon: "person.2.fill",
                  color: Color(hex: "#ff4500") ?? .orange,
                  count: redditTags.count,
                  isExpanded: $redditExpanded
                )
              }
            }
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
        }
      }
      .navigationTitle("Tags")
      .navigationBarTitleDisplayMode(.large)
      .toolbarBackground(Color.pfBackground, for: .navigationBar)
    }
    .task {
      await store.loadTags()
    }
  }

  // MARK: - Tag Row

  private func tagRow(_ tag: Tag) -> some View {
    Button {
      Task { await store.setTagFilter(tag.name) }
    } label: {
      HStack(spacing: 12) {
        // Icon
        if tag.name.hasPrefix("r/") {
          // Show subreddit initial shield
          Text("r/")
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(Color(hex: "#ff4500") ?? .orange)
            .frame(width: 30)
        } else {
          Text("#")
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundColor(Color.tagColor(for: tag.name))
            .frame(width: 30)
        }

        // Name: strip "r/" prefix for reddit tags to keep it clean
        Text(tag.name.hasPrefix("r/") ? String(tag.name.dropFirst(2)) : tag.name)
          .font(.body)
          .fontWeight(.medium)
          .foregroundColor(.pfTextPrimary)

        Spacer()

        // Count badge
        Text("\(tag.bookmarkCount)")
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundColor(.pfTextSecondary)
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(Color.pfSurfaceLight)
          .cornerRadius(8)
      }
      .padding(.vertical, 2)
    }
    .listRowBackground(Color.pfBackground)
    .listRowSeparatorTint(.pfBorder)
  }

  // MARK: - Section Header

  private func sectionHeader(
    title: String,
    icon: String,
    color: Color,
    count: Int,
    isExpanded: Binding<Bool>
  ) -> some View {
    Button {
      withAnimation(.easeInOut(duration: 0.2)) {
        isExpanded.wrappedValue.toggle()
      }
    } label: {
      HStack(spacing: 8) {
        Image(systemName: icon)
          .font(.system(size: 11, weight: .semibold))
          .foregroundColor(color)

        Text(title.uppercased())
          .font(.system(size: 11, weight: .semibold))
          .foregroundColor(.pfTextTertiary)
          .tracking(0.5)

        Text("\(count)")
          .font(.system(size: 11, weight: .medium))
          .foregroundColor(.pfTextTertiary)

        Spacer()

        Image(systemName: isExpanded.wrappedValue ? "chevron.down" : "chevron.right")
          .font(.system(size: 11, weight: .semibold))
          .foregroundColor(.pfTextTertiary)
          .animation(.easeInOut(duration: 0.2), value: isExpanded.wrappedValue)
      }
      .padding(.vertical, 4)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .listRowBackground(Color.pfBackground)
  }
}

#Preview {
  TagListView()
    .environment(BookmarkStore())
}
