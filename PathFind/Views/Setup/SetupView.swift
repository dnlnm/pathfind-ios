import SwiftUI

struct SetupView: View {
  @Environment(AuthStore.self) private var authStore

  @State private var serverURL: String = ""
  @State private var apiToken: String = ""
  @State private var isConnecting = false
  @State private var showError = false
  @State private var errorMessage = ""

  var body: some View {
    ZStack {
      Color.pfBackground.ignoresSafeArea()

      ScrollView {
        VStack(spacing: 32) {
          Spacer(minLength: 60)

          // Logo & Title
          VStack(spacing: 16) {
            Image(systemName: "mappin.and.ellipse")
              .font(.system(size: 56))
              .foregroundStyle(
                LinearGradient(
                  colors: [.pfAccent, .pfAccentLight],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )

            Text("PathFind")
              .font(.system(size: 34, weight: .bold, design: .rounded))
              .foregroundColor(.pfTextPrimary)

            Text("Connect to your self-hosted instance")
              .font(.subheadline)
              .foregroundColor(.pfTextSecondary)
          }

          // Form
          VStack(spacing: 20) {
            // Server URL
            VStack(alignment: .leading, spacing: 8) {
              Text("Server URL")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.pfTextSecondary)
                .textCase(.uppercase)

              TextField("https://pathfind.example.com", text: $serverURL)
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

            // API Token
            VStack(alignment: .leading, spacing: 8) {
              Text("API Token")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.pfTextSecondary)
                .textCase(.uppercase)

              SecureField("pf_xxxxxxxx...", text: $apiToken)
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

              Text("Generate a token from Settings → API Tokens in your PathFind web app.")
                .font(.caption2)
                .foregroundColor(.pfTextTertiary)
            }
          }
          .padding(.horizontal, 4)

          // Connect Button
          Button {
            Task { await connect() }
          } label: {
            HStack(spacing: 8) {
              if isConnecting {
                ProgressView()
                  .tint(.white)
                  .scaleEffect(0.85)
              }
              Text(isConnecting ? "Connecting..." : "Connect")
                .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
              canConnect
                ? LinearGradient(
                  colors: [.pfAccent, .pfAccentLight], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(
                  colors: [Color.pfSurfaceLight, Color.pfSurfaceLight], startPoint: .leading,
                  endPoint: .trailing)
            )
            .foregroundColor(canConnect ? .white : .pfTextTertiary)
            .cornerRadius(14)
          }
          .disabled(!canConnect || isConnecting)

          Spacer(minLength: 40)
        }
        .padding(.horizontal, 28)
      }
    }
    .alert("Connection Failed", isPresented: $showError) {
      Button("OK") {}
    } message: {
      Text(errorMessage)
    }
  }

  private var canConnect: Bool {
    !serverURL.trimmingCharacters(in: .whitespaces).isEmpty
      && !apiToken.trimmingCharacters(in: .whitespaces).isEmpty
  }

  private func connect() async {
    isConnecting = true
    do {
      try await authStore.connect(
        serverURL: serverURL.trimmingCharacters(in: .whitespaces),
        apiToken: apiToken.trimmingCharacters(in: .whitespaces)
      )
    } catch {
      errorMessage = error.localizedDescription
      showError = true
    }
    isConnecting = false
  }
}

#Preview {
  SetupView()
    .environment(AuthStore())
}
