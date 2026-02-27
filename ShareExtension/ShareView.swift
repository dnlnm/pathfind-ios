import SwiftUI

struct ShareView: View {
  let url: String
  let title: String?
  let onDismiss: () -> Void

  @State private var notes: String = ""
  @State private var tagInput: String = ""
  @State private var tags: [String] = []
  @State private var isReadLater: Bool = false
  @State private var isSaving: Bool = false
  @State private var isDuplicate: Bool = false
  @State private var isCheckingDuplicate: Bool = true
  @State private var saveResult: SaveResult?

  private enum SaveResult { case success; case error(String) }

  private var serverURL: String {
    UserDefaults(suiteName: "group.pathfind.mobile")?.string(forKey: "pathfind_server_url") ?? ""
  }
  private var apiToken: String {
    UserDefaults(suiteName: "group.pathfind.mobile")?.string(forKey: "pathfind_api_token") ?? ""
  }
  private var isConfigured: Bool { !serverURL.isEmpty && !apiToken.isEmpty }
  private var domain: String { URL(string: url)?.host ?? url }
  private let accent = Color(hex: "#6366f1") ?? .blue

  var body: some View {
    Group {
      if !isConfigured {
        notConfiguredView
      } else if let result = saveResult {
        resultView(result)
      } else {
        formView
      }
    }
    .task {
      if isConfigured { await checkDuplicate() }
    }
  }

  // MARK: - Not Configured

  private var notConfiguredView: some View {
    VStack(spacing: 16) {
      Spacer()
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 36)).foregroundColor(.orange)
      Text("Not Connected").font(.headline).foregroundColor(.white)
      Text("Open PathFind Mobile and connect to your server first.")
        .font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center)
      Button("Close") { onDismiss() }
        .buttonStyle(PFButtonStyle(color: accent)).padding(.top, 8)
      Spacer()
    }
    .padding(.horizontal, 24)
  }

  // MARK: - Result

  private func resultView(_ result: SaveResult) -> some View {
    VStack(spacing: 16) {
      Spacer()
      switch result {
      case .success:
        Image(systemName: "checkmark.circle.fill").font(.system(size: 52)).foregroundColor(.green)
        Text("Saved!").font(.title2.weight(.bold)).foregroundColor(.white)
        Text(domain).font(.subheadline).foregroundColor(.gray)
      case .error(let msg):
        Image(systemName: "xmark.circle.fill").font(.system(size: 52)).foregroundColor(.red)
        Text("Failed to Save").font(.title2.weight(.bold)).foregroundColor(.white)
        Text(msg).font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center)
      }
      Button("Done") { onDismiss() }
        .buttonStyle(PFButtonStyle(color: accent)).padding(.top, 8)
      Spacer()
    }
    .padding(.horizontal, 24)
    .onAppear {
      if case .success = result {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { onDismiss() }
      }
    }
  }

  // MARK: - Form
  // Wrapped in NavigationStack so Cancel/Save buttons render identically to AddBookmarkView

  private var formView: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 16) {

          // URL preview row
          HStack(spacing: 10) {
            Image(systemName: "link").foregroundColor(.gray).frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
              if let title, !title.isEmpty {
                Text(title).font(.subheadline.weight(.medium)).foregroundColor(.white).lineLimit(1)
              }
              Text(domain).font(.caption).foregroundColor(.gray).lineLimit(1)
            }
            Spacer()
            if isCheckingDuplicate {
              ProgressView().scaleEffect(0.7).tint(.gray)
            } else if isDuplicate {
              Text("Already saved")
                .font(.system(size: 10, weight: .semibold)).foregroundColor(.orange)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.orange.opacity(0.15)).cornerRadius(6)
            }
          }
          .padding(12)
          .background(Color.white.opacity(0.07))
          .cornerRadius(12)

          // Notes
          TextField("Add a note (optional)", text: $notes, axis: .vertical)
            .lineLimit(2...4).font(.subheadline).foregroundColor(.white)
            .padding(12).background(Color.white.opacity(0.07)).cornerRadius(12)

          // Tag input
          HStack {
            TextField("Add tag", text: $tagInput)
              .font(.subheadline).foregroundColor(.white)
              .autocapitalization(.none).autocorrectionDisabled()
              .onSubmit { addTag() }
            Button { addTag() } label: {
              Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(accent)
            }
            .disabled(tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
          }
          .padding(12).background(Color.white.opacity(0.07)).cornerRadius(12)

          // Tag chips
          if !tags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                  HStack(spacing: 4) {
                    Text("#\(tag)").font(.system(size: 12, weight: .medium)).foregroundColor(accent)
                    Button { tags.removeAll { $0 == tag } } label: {
                      Image(systemName: "xmark.circle.fill").font(.system(size: 10)).foregroundColor(.gray)
                    }
                  }
                  .padding(.horizontal, 8).padding(.vertical, 5)
                  .background(accent.opacity(0.15)).cornerRadius(6)
                }
              }
            }
          }

          // Read Later
          Toggle(isOn: $isReadLater) {
            HStack(spacing: 8) {
              Image(systemName: "bookmark.fill").foregroundColor(.orange)
              Text("Read Later").font(.subheadline).foregroundColor(.white)
            }
          }
          .tint(accent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
      }
      .scrollContentBackground(.hidden)
      .background(Color.clear)
      .navigationTitle("Save to PathFind")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { onDismiss() }
            .foregroundColor(.gray)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button {
            Task { await saveBookmark() }
          } label: {
            if isSaving { ProgressView().tint(accent) }
            else { Text("Save").fontWeight(.semibold) }
          }
          .foregroundColor(accent)
          .disabled(isSaving)
        }
      }
    }
  }

  // MARK: - Actions

  private func addTag() {
    let tag = tagInput.trimmingCharacters(in: .whitespaces).lowercased()
    guard !tag.isEmpty, !tags.contains(tag) else { return }
    tags.append(tag); tagInput = ""
  }

  private func checkDuplicate() async {
    isCheckingDuplicate = true
    defer { isCheckingDuplicate = false }
    guard let u = buildURL("/api/bookmarks/check", query: [URLQueryItem(name: "url", value: url)]) else { return }
    var req = URLRequest(url: u)
    req.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
    if let (data, _) = try? await URLSession.shared.data(for: req),
       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let bookmarked = json["bookmarked"] as? Bool { isDuplicate = bookmarked }
  }

  private func saveBookmark() async {
    isSaving = true
    guard let u = buildURL("/api/bookmarks") else { saveResult = .error("Invalid URL"); return }
    var req = URLRequest(url: u)
    req.httpMethod = "POST"
    req.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    var body: [String: Any] = ["url": url]
    if !notes.isEmpty { body["notes"] = notes }
    if !tags.isEmpty  { body["tags"] = tags }
    if isReadLater    { body["isReadLater"] = true }
    do {
      req.httpBody = try JSONSerialization.data(withJSONObject: body)
      let (_, res) = try await URLSession.shared.data(for: req)
      saveResult = (res as? HTTPURLResponse).map { $0.statusCode < 300 } == true
        ? .success : .error("Server error")
    } catch { saveResult = .error(error.localizedDescription) }
    isSaving = false
  }

  private func buildURL(_ path: String, query: [URLQueryItem]? = nil) -> URL? {
    guard var c = URLComponents(string: serverURL + path) else { return nil }
    c.queryItems = query; return c.url
  }
}

// MARK: - Button Style

struct PFButtonStyle: ButtonStyle {
  let color: Color
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.body.weight(.semibold)).foregroundColor(.white)
      .padding(.horizontal, 36).padding(.vertical, 13)
      .background(color).cornerRadius(12)
      .opacity(configuration.isPressed ? 0.8 : 1)
  }
}

// MARK: - Hex Color

extension Color {
  init?(hex: String) {
    var h = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
    guard h.count == 6 else { return nil }
    var rgb: UInt64 = 0; Scanner(string: h).scanHexInt64(&rgb)
    self.init(red: Double((rgb >> 16) & 0xFF) / 255,
              green: Double((rgb >> 8) & 0xFF) / 255,
              blue: Double(rgb & 0xFF) / 255)
  }
}
