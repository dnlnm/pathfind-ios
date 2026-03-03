# PathFind iOS

[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-iOS_26+-007AFF?style=for-the-badge&logo=swift)](https://developer.apple.com/xcode/swiftui/)
[![platform](https://img.shields.io/badge/Platform-iOS-lightgrey?style=for-the-badge&logo=apple)](https://www.apple.com/ios/)

A native iOS companion app for [PathFind](https://github.com/dnlnm/pathfind). Built with SwiftUI and targeting **iOS 26+**, this app provides a world-class mobile experience for your self-hosted bookmarks.

![PathFind iOS Mockup](pathfind_ios_mockup_1772558620433.png)

---

## 🌐 The PathFind Ecosystem

- **[PathFind Web](https://github.com/dnlnm/pathfind)**: The core self-hosted server and dashboard.
- **[PathFind Extension](https://github.com/dnlnm/pathfind-ext)**: Browser extension for Chrome, Edge, and Firefox.
- **[PathFind iOS](https://github.com/dnlnm/pathfind-ios)**: Native SwiftUI mobile app for iPhone.
- **[PathFind Android](https://github.com/dnlnm/pathfind-kt)**: Native Kotlin & Compose mobile app.

---

## ✨ Features

- **📱 Premium SwiftUI UI**: Native iOS experience with Card & Compact views, fluid animations, and SF Symbols.
- **🎨 Dynamic Thumbnails**: High-quality thumbnails generated on-device using brand colors extracted from favicons.
- **📥 Share Extension**: Save any URL to PathFind directly from the iOS Share Sheet with duplicate detection.
- **🔍 Native Search**: Dedicated search tab leveraging iOS 26 native search APIs for instant results.
- **🔄 Infinite Scroll**: Effortless browsing with pagination and pull-to-refresh support.
- **🛠️ Swipe Actions**: Archive, Read Later, or Delete bookmarks with native swipe gestures.

---

## 🚀 Getting Started

### Prerequisites

| Requirement     | Version            |
| --------------- | ------------------ |
| iOS             | 26.0+              |
| Xcode           | 16.0+              |
| Swift           | 6.0+               |
| PathFind server | Any recent version |

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/dnlnm/pathfind-ios.git
   cd pathfind-ios
   ```
2. Open in Xcode:
   ```bash
   open PathFind.xcodeproj
   ```
3. **Configure App Group**:
   - The app uses `group.pathfind.mobile` to share credentials between the main app and the Share Extension.
   - Update the Team and ensure the App Group is active for both targets.

---

## 🛠 Tech Stack & Architecture

PathFind iOS is built with a modern, reactive architecture:

- **State Management**: `@Observable` stores injected via `environment`.
- **Networking**: Generic async/await REST client (Actor-based).
- **Persistence**: Shared `UserDefaults` suite for App Group access.
- **Image Processing**: `Core Image` for color extraction and dynamic card generation.

### Directory Structure

```
PathFind/
├── PathFind.swift              # App entry point
├── Models/                     # Codable bookmark, Collection, Tag models
├── Services/                   # APIClient & BookmarkService
├── Stores/                     # AuthStore & BookmarkStore (@Observable)
├── Views/                      # SwiftUI Views (Main, List, Detail, Setup)
└── Extensions/                 # Shared UI tokens & Utilities
```

---

## 📄 License

MIT © [dnlnm](https://github.com/dnlnm)

