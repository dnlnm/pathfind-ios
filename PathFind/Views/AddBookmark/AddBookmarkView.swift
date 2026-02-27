import SwiftUI

struct AddBookmarkView: View {
  @Environment(AuthStore.self) private var authStore
  @Environment(BookmarkStore.self) private var store
  @Environment(\.dismiss) private var dismiss

  @State private var url: String = ""
  @State private var notes: String = ""
  @State private var tagInput: String = ""
  @State private var tags: [String] = []
  @State private var selectedCollectionId: String?
  @State private var isReadLater: Bool = false
  @State private var isSaving: Bool = false
  @State private var errorMessage: String?

  var body: some View {
    NavigationStack {
      ZStack {
        Color.pfBackground.ignoresSafeArea()

        ScrollView {
          VStack(spacing: 24) {
            // URL Field
            VStack(alignment: .leading, spacing: 8) {
              Text("URL")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.pfTextSecondary)
                .textCase(.uppercase)

              TextField("https://example.com", text: $url)
                .textFieldStyle(.plain)
                .padding(14)
                .background(Color.pfSurface)
                .cornerRadius(12)
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.pfBorder, lineWidth: 1)
                )
                .foregroundColor(.pfTextPrimary)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .autocorrectionDisabled()
            }

            // Notes Field
            VStack(alignment: .leading, spacing: 8) {
              Text("Notes (optional)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.pfTextSecondary)
                .textCase(.uppercase)

              TextField("Add a note...", text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .padding(14)
                .background(Color.pfSurface)
                .cornerRadius(12)
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.pfBorder, lineWidth: 1)
                )
                .foregroundColor(.pfTextPrimary)
            }

            // Tags
            VStack(alignment: .leading, spacing: 8) {
              Text("Tags (optional)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.pfTextSecondary)
                .textCase(.uppercase)

              HStack {
                TextField("Add tag...", text: $tagInput)
                  .textFieldStyle(.plain)
                  .padding(14)
                  .background(Color.pfSurface)
                  .cornerRadius(12)
                  .overlay(
                    RoundedRectangle(cornerRadius: 12)
                      .stroke(Color.pfBorder, lineWidth: 1)
                  )
                  .foregroundColor(.pfTextPrimary)
                  .autocapitalization(.none)
                  .autocorrectionDisabled()
                  .onSubmit { addTag() }

                Button {
                  addTag()
                } label: {
                  Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.pfAccent)
                }
                .disabled(tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
              }

              if !tags.isEmpty {
                FlowLayout(spacing: 8) {
                  ForEach(tags, id: \.self) { tag in
                    HStack(spacing: 4) {
                      Text("#\(tag)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.tagColor(for: tag))

                      Button {
                        tags.removeAll { $0 == tag }
                      } label: {
                        Image(systemName: "xmark.circle.fill")
                          .font(.system(size: 12))
                          .foregroundColor(.pfTextTertiary)
                      }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.tagColor(for: tag).opacity(0.15))
                    .cornerRadius(8)
                  }
                }
              }
            }

            // Collection Picker
            if !store.collections.isEmpty {
              VStack(alignment: .leading, spacing: 8) {
                Text("Collection (optional)")
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundColor(.pfTextSecondary)
                  .textCase(.uppercase)

                ScrollView(.horizontal, showsIndicators: false) {
                  HStack(spacing: 8) {
                    // "None" option
                    collectionChip(
                      name: "None", color: nil, isSelected: selectedCollectionId == nil
                    ) {
                      selectedCollectionId = nil
                    }

                    ForEach(store.collections) { collection in
                      collectionChip(
                        name: collection.name,
                        color: collection.color,
                        isSelected: selectedCollectionId == collection.id
                      ) {
                        selectedCollectionId = collection.id
                      }
                    }
                  }
                }
              }
            }

            // Read Later Toggle
            Toggle(isOn: $isReadLater) {
              HStack {
                Image(systemName: "bookmark")
                  .foregroundColor(.pfWarning)
                Text("Read Later")
                  .foregroundColor(.pfTextPrimary)
              }
            }
            .tint(.pfAccent)
            .padding(.horizontal, 4)

            // Error Message
            if let error = errorMessage {
              Text(error)
                .font(.caption)
                .foregroundColor(.pfDestructive)
                .padding(.horizontal, 4)
            }
          }
          .padding(20)
        }
      }
      .navigationTitle("Add Bookmark")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(Color.pfBackground, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
            .foregroundColor(.pfTextSecondary)
        }

        ToolbarItem(placement: .confirmationAction) {
          Button {
            Task { await saveBookmark() }
          } label: {
            if isSaving {
              ProgressView()
                .tint(.pfAccent)
            } else {
              Text("Save")
                .fontWeight(.semibold)
            }
          }
          .disabled(url.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
          .foregroundColor(.pfAccent)
        }
      }
    }
    .task {
      if store.collections.isEmpty {
        await store.loadCollections()
      }
    }
  }

  // MARK: - Helpers

  private func addTag() {
    let tag = tagInput.trimmingCharacters(in: .whitespaces).lowercased()
    guard !tag.isEmpty, !tags.contains(tag) else { return }
    tags.append(tag)
    tagInput = ""
  }

  private func saveBookmark() async {
    isSaving = true
    errorMessage = nil

    let service = BookmarkService(client: authStore.apiClient)

    var request = BookmarkCreateRequest(url: url.trimmingCharacters(in: .whitespaces))
    request.notes = notes.isEmpty ? nil : notes
    request.tags = tags.isEmpty ? nil : tags
    request.collections = selectedCollectionId.map { [$0] }
    request.isReadLater = isReadLater

    do {
      let _ = try await service.createBookmark(request)
      await store.refresh()
      dismiss()
    } catch {
      errorMessage = error.localizedDescription
      isSaving = false
    }
  }

  private func collectionChip(
    name: String, color: String?, isSelected: Bool, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 6) {
        if let color, let c = Color(hex: color) {
          Circle()
            .fill(c)
            .frame(width: 8, height: 8)
        }
        Text(name)
          .font(.system(size: 13, weight: .medium))
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(isSelected ? Color.pfAccent.opacity(0.2) : Color.pfSurface)
      .foregroundColor(isSelected ? .pfAccent : .pfTextSecondary)
      .cornerRadius(8)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(isSelected ? Color.pfAccent : Color.pfBorder, lineWidth: 1)
      )
    }
  }
}

#Preview {
  AddBookmarkView()
    .environment(AuthStore())
    .environment(BookmarkStore())
}
