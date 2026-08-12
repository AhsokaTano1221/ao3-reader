# AO3 Reader (iOS App)

A clean, feature-rich native iOS client designed for searching, downloading, bookmarking, and reading fanfictions from Archive of Our Own (AO3) offline.

---

## What the App Can Do So Far

### 1. Reader Panel
- **Immersive View**: Fluid, readable typography with customizable settings.
- **Font Size Adjustment**: Dynamic text resizing controls in the reader toolbar.
- **Appearance Settings**: Integrates with system light/dark modes.
- **Bookmarks**: Bookmark/save toggle in the toolbar for offline preservation.

### 2. Offline Library
- **JSON Serialization**: Saves bookmarked works locally in the app's `Documents/Library/` directory.
- **Library Manager**: Lists downloaded works with title, author, fandom badges, and metadata.
- **Swipe-to-Delete**: Swipe cells to remove works from offline storage instantly.

### 3. Advanced Search & Filtering
- **Segmented Search Mode**:
  - **AO3 Search**: Custom-built search dashboard aligning with AO3's official parameters.
  - **Direct URL**: Option to load any work directly by pasting its archive URL.
- **Search Filters**:
  - **Work Info**: Keywords, Title, Creator/Author, Date, Completion Status, Crossover Status, Single Chapter, Word Count range, and Language.
  - **Stats**: Hits range, Kudos count, Comments volume, and Bookmarks.
  - **Warnings & Categories**: Disclosure panels supporting archive warnings (violence, death, etc.) and category tagging (M/M, F/M, Gen, etc.).
- **Canonical Autocomplete**:
  - Automatically queries suggestions from AO3's autocomplete API for Fandom, Character, Relationship, and Freeform tag inputs as you type.
  - Displays suggestions inline as scrollable badges.
  - Supports comma-separated tag lists, inserting tag names with trailing commas for fast typing.
- **Pagination**:
  - Scroll and load more results using the "Load More" button at the bottom of the search results list.
- **Auto-Clear**:
  - All input parameters, results, and sorting states automatically reset and clear when you switch tabs to keep the search interface clean.

### 4. Native Layout Optimization
- **Letterbox Scaling Fix**: Permanent `UILaunchScreen` configuration inside the project definition ensures zero letterbox borders.
- **Compiler Optimizations**: Decomposed SwiftUI layout sheets into computed components to avoid Swift compiler timeout bugs.

---

## Technical Stack
- **Framework**: SwiftUI, Combine
- **Project Structure**: Generated via `XCodeGen`
- **Parsing Engine**: SwiftSoup (HTML Web Scraping)
- **Minimum Target**: iOS 16.0
