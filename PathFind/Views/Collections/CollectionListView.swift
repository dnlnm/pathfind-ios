import SwiftUI

struct CollectionListView: View {
  @Environment(BookmarkStore.self) private var store

  var body: some View {
    NavigationStack {
      ZStack {
        Color.pfBackground.ignoresSafeArea()

        if store.collections.isEmpty {
          VStack(spacing: 12) {
            Image(systemName: "folder")
              .font(.system(size: 44))
              .foregroundColor(.pfTextTertiary)
            Text("No collections yet")
              .font(.headline)
              .foregroundColor(.pfTextSecondary)
            Text("Create collections from the web app")
              .font(.subheadline)
              .foregroundColor(.pfTextTertiary)
          }
        } else {
          List {
            ForEach(store.collections) { collection in
              Button {
                Task {
                  await store.setCollectionFilter(id: collection.id, name: collection.name)
                }
              } label: {
                HStack(spacing: 14) {
                  // Color dot or icon
                  ZStack {
                    Circle()
                      .fill(Color(hex: collection.color ?? "") ?? .pfAccent)
                      .frame(width: 36, height: 36)

                    if let icon = collection.icon, !icon.isEmpty {
                      Text(icon)
                        .font(.system(size: 16))
                    } else {
                      Image(systemName: "folder.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                    }
                  }

                  VStack(alignment: .leading, spacing: 2) {
                    Text(collection.name)
                      .font(.body)
                      .fontWeight(.medium)
                      .foregroundColor(.pfTextPrimary)

                    if let desc = collection.description, !desc.isEmpty {
                      Text(desc)
                        .font(.caption)
                        .foregroundColor(.pfTextTertiary)
                        .lineLimit(1)
                    }
                  }

                  Spacer()

                  Text("\(collection.bookmarkCount)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.pfTextSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.pfSurfaceLight)
                    .cornerRadius(8)
                }
                .padding(.vertical, 4)
              }
              .listRowBackground(Color.pfBackground)
              .listRowSeparatorTint(.pfBorder)
            }
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
        }
      }
      .navigationTitle("Collections")
      .navigationBarTitleDisplayMode(.large)
      .toolbarBackground(Color.pfBackground, for: .navigationBar)
    }
    .task {
      await store.loadCollections()
    }
  }
}

#Preview {
  CollectionListView()
    .environment(BookmarkStore())
}
