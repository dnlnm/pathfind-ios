import SwiftUI

struct SettingsView: View {
  @Environment(AuthStore.self) private var authStore
  @AppStorage("openInExternalBrowser") private var openInExternalBrowser = false
  @AppStorage("appearanceSetting") private var appearanceSetting: AppearanceSetting = .dark
  @State private var showDisconnectConfirm = false

  var body: some View {
    NavigationStack {
      ZStack {
        Color.pfBackground.ignoresSafeArea()

        List {
          // Server Info
          Section {
            VStack(alignment: .leading, spacing: 12) {
              HStack(spacing: 12) {
                Image(systemName: "server.rack")
                  .font(.system(size: 24))
                  .foregroundColor(.pfAccent)
                  .frame(width: 40, height: 40)
                  .background(Color.pfAccent.opacity(0.15))
                  .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                  Text("Connected Server")
                    .font(.caption)
                    .foregroundColor(.pfTextTertiary)
                    .textCase(.uppercase)

                  Text(authStore.serverURL)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.pfTextPrimary)
                    .lineLimit(1)
                }
              }

              HStack(spacing: 12) {
                Image(systemName: "key.fill")
                  .font(.system(size: 24))
                  .foregroundColor(.pfSuccess)
                  .frame(width: 40, height: 40)
                  .background(Color.pfSuccess.opacity(0.15))
                  .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                  Text("API Token")
                    .font(.caption)
                    .foregroundColor(.pfTextTertiary)
                    .textCase(.uppercase)

                  Text(authStore.maskedToken)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.pfTextSecondary)
                }
              }
            }
            .padding(.vertical, 4)
            .listRowBackground(Color.pfSurface)
          } header: {
            Text("Connection")
              .foregroundColor(.pfTextTertiary)
          }

          // Actions
          Section {
            Button {
              showDisconnectConfirm = true
            } label: {
              HStack {
                Image(systemName: "arrow.right.square")
                Text("Disconnect")
              }
              .foregroundColor(.pfDestructive)
            }
            .listRowBackground(Color.pfSurface)
          }

          // Appearance
          Section {
            VStack(alignment: .leading, spacing: 12) {
              HStack(spacing: 12) {
                Image(systemName: appearanceSetting.icon)
                  .font(.system(size: 18))
                  .foregroundColor(.pfAccent)
                  .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                  Text("App Appearance")
                    .foregroundColor(.pfTextPrimary)
                  Text(
                    appearanceSetting == .system
                      ? "Follows device setting"
                      : appearanceSetting == .light ? "Always light" : "Always dark"
                  )
                  .font(.caption)
                  .foregroundColor(.pfTextTertiary)
                }
              }

              Picker("", selection: $appearanceSetting) {
                ForEach(AppearanceSetting.allCases, id: \.self) { option in
                  Label(option.label, systemImage: option.icon)
                    .tag(option)
                }
              }
              .pickerStyle(.segmented)
            }
            .padding(.vertical, 4)
            .listRowBackground(Color.pfSurface)
          } header: {
            Text("Appearance")
              .foregroundColor(.pfTextTertiary)
          }

          // Browser
          Section {
            Toggle(isOn: $openInExternalBrowser) {
              HStack(spacing: 12) {
                Image(systemName: openInExternalBrowser ? "safari" : "safari.fill")
                  .font(.system(size: 18))
                  .foregroundColor(.pfAccent)
                  .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                  Text("Open in External Browser")
                    .foregroundColor(.pfTextPrimary)
                  Text(openInExternalBrowser ? "Uses Safari app" : "Uses in-app browser")
                    .font(.caption)
                    .foregroundColor(.pfTextTertiary)
                }
              }
            }
            .tint(.pfAccent)
            .listRowBackground(Color.pfSurface)
          } header: {
            Text("Browser")
              .foregroundColor(.pfTextTertiary)
          }

          // About
          Section {
            HStack {
              Text("App Version")
                .foregroundColor(.pfTextSecondary)
              Spacer()
              Text("1.0.0")
                .foregroundColor(.pfTextTertiary)
            }
            .listRowBackground(Color.pfSurface)

            HStack {
              Text("Built with")
                .foregroundColor(.pfTextSecondary)
              Spacer()
              Text("SwiftUI")
                .foregroundColor(.pfTextTertiary)
            }
            .listRowBackground(Color.pfSurface)
          } header: {
            Text("About")
              .foregroundColor(.pfTextTertiary)
          }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.large)
      .toolbarBackground(Color.pfBackground, for: .navigationBar)
      .alert("Disconnect?", isPresented: $showDisconnectConfirm) {
        Button("Cancel", role: .cancel) {}
        Button("Disconnect", role: .destructive) {
          authStore.disconnect()
        }
      } message: {
        Text("You'll need to re-enter your server URL and API token to reconnect.")
      }
    }
  }
}

#Preview {
  SettingsView()
    .environment(AuthStore())
}
