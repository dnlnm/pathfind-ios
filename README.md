# PathFind Mobile

A native iOS companion app for [PathFind](https://github.com/dnlnm/pathfind) — the self-hosted bookmark manager. Built with SwiftUI, targeting **iOS 26+**.

---

## Features

### Bookmarks
- **Card & Compact views** — toggle between a rich card layout (with thumbnail banner) and a compact list view
- **Dynamic thumbnails** — generated natively on-device using the site's brand color extracted from its favicon via Core Image; no server-rendered SVG required
- **Favicon display** — decoded from base64 or fetched from the server inline
- **Infinite scroll pagination** — loads the next page as you approach the bottom
- **Pull-to-refresh** — swipe down to reload the current list
- **Swipe actions**:
  - Trailing: Delete (with confirmation alert), Archive / Unarchive
  - Leading: View Detail, Read Later / Remove
- **Sort** — Newest, Oldest, Title A→Z, Title Z→A
- **Filter** — All, Read Later, Archived
- **Tag & Collection filters** — tap any tag or collection to filter the list

### Bookmark Detail
- Full-width thumbnail (real image or dynamic branded card)
- Title, URL, description, and notes
- Tappable tags and collections — sets the filter and returns to the list
- Actions: Open in Safari, Archive, Read Later, Copy Link, Delete

### Collections & Tags
- Browse all collections with color indicators
- Browse all tags; tap to filter bookmarks

### Search
- Dedicated search tab (iOS 26 native search tab role)
- Full-text search across all bookmarks with pagination

### Add Bookmark
- Add a URL manually from inside the app with optional notes, tags, and Read Later flag

### Share Extension
- Save any URL to PathFind directly from the iOS Share Sheet
- Duplicate detection — warns if the URL is already saved
- Supports notes, tags, and Read Later at save time
- Auto-dismisses after a successful save

### Settings
- Connect / disconnect from your PathFind server (URL + API token)
- Credential validation on connect (live API handshake)
- Appearance toggle (Light / Dark / System)
- Open links in Safari or an in-app browser

---

## Requirements

| Requirement | Version |
|---|---|
| iOS | 26.0+ |
| Xcode | 16.0+ |
| Swift | 6.0+ |
| PathFind server | Any recent version |

---

## Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/dnlnm/PathFindMobile.git
cd PathFindMobile
```

### 2. Open in Xcode

```bash
open PathFind.xcodeproj
```

### 3. Configure the App Group

The main app and Share Extension share credentials via an **App Group**. The group ID is `group.pathfind.mobile`.

In Xcode, for both the **PathFind** target and the **ShareExtension** target:
1. Select the target → **Signing & Capabilities**
2. Add **App Groups** and set the identifier to `group.pathfind.mobile`
3. Ensure both targets use the same Team

### 4. Build & Run

Select the **PathFind** scheme, choose a simulator or device running iOS 26+, and hit **Run**.

---

## Connecting to Your Server

1. Launch the app — the **Setup** screen appears if no server is configured
2. Enter your PathFind server URL (e.g. `https://bookmarks.example.com`)
3. Enter your API token (found in PathFind → Settings → API Tokens)
4. Tap **Connect** — the app validates credentials with a live API call before saving

Credentials are stored in the shared `UserDefaults` suite (`group.pathfind.mobile`) so the Share Extension can access them without requiring a separate login.

---

## Architecture

```
PathFind/
├── PathFind.swift              # App entry point (@main)
├── Models/
│   ├── Bookmark.swift          # Codable bookmark + related models
│   ├── Collection.swift
│   ├── Tag.swift
│   └── AppearanceSetting.swift
├── Services/
│   ├── APIClient.swift         # Generic async/await REST client (actor)
│   └── BookmarkService.swift   # Bookmark, collection, and tag endpoints
├── Stores/
│   ├── AuthStore.swift         # @Observable — server URL, API token, connect/disconnect
│   └── BookmarkStore.swift     # @Observable — bookmarks, pagination, filters, search
├── Views/
│   ├── Main/
│   │   ├── MainTabView.swift         # Tab bar (iOS 26 Tab API + search role)
│   │   ├── BookmarkListView.swift    # Card/compact list, toolbar, swipe actions
│   │   ├── BookmarkRowView.swift     # Card row, compact row, thumbnail views
│   │   ├── BookmarkDetailView.swift  # Full detail sheet
│   │   └── SearchView.swift         # Search tab
│   ├── AddBookmark/
│   ├── Collections/
│   ├── Tags/
│   ├── Settings/
│   └── Setup/
└── Extensions/                 # Color tokens, date formatting, etc.

ShareExtension/
├── ShareViewController.swift   # UIViewController entry point for the share sheet
└── ShareView.swift             # SwiftUI share UI (notes, tags, read later)
```

### Key Design Decisions

**`@Observable` stores injected via `environment`**  
`AuthStore` and `BookmarkStore` are passed top-down through the environment so any view can read them without prop-drilling.

**Dynamic thumbnails on-device**  
When a bookmark's thumbnail is a server-generated SVG path (`/api/thumbnail?...`) — which iOS `AsyncImage` cannot render — the app instead generates a branded card locally:
1. Extracts the dominant color from the base64 favicon using `CIAreaAverage` (Core Image)
2. Falls back to a deterministic hue derived from the domain name hash
3. Renders a gradient card with decorative circles and the bookmark title

**Atomic list updates in `BookmarkStore`**  
Pagination appends via full array replacement (`bookmarks = merged`) rather than `append()`, avoiding `@Observable` per-element fires that caused `UICollectionView` data source inconsistency crashes.

**Shared App Group for the Share Extension**  
Both targets read/write `pathfind_server_url` and `pathfind_api_token` from `UserDefaults(suiteName: "group.pathfind.mobile")`, eliminating any need to re-authenticate in the extension.

---

## iOS 26 APIs Used

| API | Usage |
|---|---|
| `Tab(value:role:.search)` | Dedicated search tab pinned to trailing edge of tab bar |
| `.tabViewSearchActivation(.searchTabSelection)` | Activates search on tab selection |
| `.tabBarMinimizeBehavior(.onScrollDown)` | Collapses tab bar while scrolling |
| `ToolbarSpacer(.fixed, placement:)` | Visual gap between toolbar item groups |

---

## License

MIT © Daniel
