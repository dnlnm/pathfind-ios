import Foundation

extension Date {
  /// Relative format: "2 hours ago", "3 days ago", "Just now"
  var relativeFormatted: String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    formatter.dateTimeStyle = .named
    return formatter.localizedString(for: self, relativeTo: .now)
  }

  /// Short date: "Feb 27, 2026"
  var shortFormatted: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: self)
  }

  /// Full date: "February 27, 2026 at 6:43 AM"
  var fullFormatted: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .short
    return formatter.string(from: self)
  }
}

extension String {
  /// Parse the SQLite datetime string (e.g. "2026-02-27 06:43:00") or ISO 8601
  var parseDate: Date? {
    // Try ISO 8601 with fractional seconds first
    if let date = ISO8601DateFormatter.flexible.date(from: self) {
      return date
    }
    // Try SQLite datetime format
    let sqliteFormatter = DateFormatter()
    sqliteFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    sqliteFormatter.timeZone = TimeZone(identifier: "UTC")
    return sqliteFormatter.date(from: self)
  }
}
