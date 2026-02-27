import SwiftUI

private func adaptive(light: UIColor, dark: UIColor) -> Color {
  Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
}

extension Color {
  // MARK: - Brand Colors (adaptive light / dark)
  static let pfAccent = Color(red: 0.4, green: 0.55, blue: 1.0)  // same in both modes
  static let pfAccentLight = Color(red: 0.55, green: 0.7, blue: 1.0)

  /// Page / window background
  static let pfBackground = adaptive(
    light: UIColor(white: 0.96, alpha: 1),
    dark: UIColor(white: 0.0, alpha: 1)  // pure black
  )

  /// Card / list row surface
  static let pfSurface = adaptive(
    light: UIColor(white: 1.0, alpha: 1),
    dark: UIColor(white: 0.07, alpha: 1)  // near-black card
  )

  /// Elevated surface (modals, popovers)
  static let pfSurfaceLight = adaptive(
    light: UIColor(white: 0.92, alpha: 1),
    dark: UIColor(white: 0.12, alpha: 1)  // slightly elevated
  )

  static let pfBorder = adaptive(
    light: UIColor(white: 0.82, alpha: 1),
    dark: UIColor(white: 0.15, alpha: 1)  // subtle border on black
  )

  static let pfTextPrimary = adaptive(
    light: UIColor(white: 0.08, alpha: 1),
    dark: UIColor(white: 0.95, alpha: 1)
  )

  static let pfTextSecondary = adaptive(
    light: UIColor(white: 0.35, alpha: 1),
    dark: UIColor(white: 0.6, alpha: 1)
  )

  static let pfTextTertiary = adaptive(
    light: UIColor(white: 0.55, alpha: 1),
    dark: UIColor(white: 0.4, alpha: 1)
  )

  static let pfDestructive = Color(red: 0.95, green: 0.3, blue: 0.3)
  static let pfSuccess = Color(red: 0.3, green: 0.85, blue: 0.5)
  static let pfWarning = Color(red: 1.0, green: 0.75, blue: 0.3)

  // MARK: - Tag Colors
  static let tagColors: [Color] = [
    Color(red: 0.4, green: 0.55, blue: 1.0),
    Color(red: 0.55, green: 0.4, blue: 1.0),
    Color(red: 1.0, green: 0.5, blue: 0.5),
    Color(red: 0.3, green: 0.8, blue: 0.6),
    Color(red: 1.0, green: 0.7, blue: 0.3),
    Color(red: 0.9, green: 0.4, blue: 0.7),
    Color(red: 0.3, green: 0.75, blue: 0.9),
  ]

  static func tagColor(for name: String) -> Color {
    let hash = abs(name.hashValue)
    return tagColors[hash % tagColors.count]
  }

  // MARK: - From Hex String
  init?(hex: String) {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

    guard hexSanitized.count == 6 else { return nil }

    var rgb: UInt64 = 0
    Scanner(string: hexSanitized).scanHexInt64(&rgb)

    self.init(
      red: Double((rgb & 0xFF0000) >> 16) / 255.0,
      green: Double((rgb & 0x00FF00) >> 8) / 255.0,
      blue: Double(rgb & 0x0000FF) / 255.0
    )
  }
}
