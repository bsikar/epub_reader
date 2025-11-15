# EPUB Reader - Feature Specifications

## 1. Library Management

### 1.1 Book Import
**Description**: Import EPUB files from local storage

**Features**:
- File picker integration (supports .epub files)
- Drag-and-drop support (desktop)
- Batch import (multiple files at once)
- Automatic metadata extraction
- Cover image extraction and caching
- Progress indicator during import
- Error handling for corrupted files

**User Flow**:
1. Tap "+" button in library
2. Select "Import from Files"
3. Choose one or more EPUB files
4. See import progress with book titles
5. Books appear in library upon completion

**Technical Details**:
- Run import in background isolate
- Extract: title, author, cover, publisher, ISBN, language
- Store file path and metadata in database
- Generate thumbnail from cover (256x384)

---

### 1.2 Library View
**Description**: Display all imported books in organized layout

**View Modes**:
- **Grid View**: 2-4 columns (responsive)
  - Book cover thumbnail
  - Title (truncated to 2 lines)
  - Author (truncated to 1 line)
  - Reading progress badge

- **List View**: Single column
  - Book cover (left)
  - Title, author, last opened date
  - Reading progress bar
  - Quick actions (swipe)

- **Compact View**: Dense list
  - Small cover icon
  - Title and author inline
  - Progress percentage

**Features**:
- Toggle between view modes
- Recently opened section
- Continue reading quick access
- Empty state with import instructions
- Pull to refresh
- Infinite scroll pagination (50 books/page)

**Sorting Options**:
- Recently opened (default)
- Title (A-Z, Z-A)
- Author (A-Z, Z-A)
- Date added (newest, oldest)
- Reading progress (% complete)

**Filtering**:
- All books
- Currently reading
- Completed
- Not started
- By collection
- By language

---

### 1.3 Collections/Categories
**Description**: Organize books into custom groups

**Features**:
- Create custom collections
- Add books to multiple collections
- Collection colors/icons
- Smart collections (auto-populate by criteria)
  - Recently added
  - Completed this month
  - Author-based
  - Genre-based (from metadata)

**UI**:
- Collections tab in library
- Drag-and-drop to add books
- Collection manager dialog
- Book count per collection

---

### 1.4 Search
**Description**: Find books quickly

**Search Scope**:
- Book title
- Author name
- Publisher
- ISBN

**Features**:
- Real-time search (debounced)
- Search history
- Advanced filters (combine with sort/filter)
- Fuzzy matching for typos

---

### 1.5 Book Details
**Description**: View and edit book information

**Display**:
- Large cover image
- Full metadata (title, author, publisher, etc.)
- File information (size, format, location)
- Reading statistics
  - Total time read
  - Pages read
  - Completion percentage
  - First opened date
  - Last opened date
- Bookmarks count
- Highlights count
- Notes count

**Actions**:
- Open book (continue reading)
- Edit metadata
- Change cover image
- Move to collections
- Delete book
- Share (export metadata/notes)

---

## 2. EPUB Reader

### 2.1 Reading Experience
**Description**: Core book reading functionality

**Features**:
- High-quality text rendering
- Image support (inline and full-page)
- CSS styling preservation
- Responsive layout
- Smooth page transitions
- CFI-based position tracking

**Navigation**:
- **Pagination Mode**:
  - Tap left/right edge to turn pages
  - Swipe left/right to turn pages
  - Animation: slide or curl
  - Page number indicator

- **Scroll Mode**:
  - Continuous vertical scrolling
  - Scroll position indicator
  - Auto-hide controls

- **Chapter Navigation**:
  - Previous/Next chapter buttons
  - Chapter progress indicator

**Controls**:
- Auto-hide UI (3 seconds after tap)
- Tap center to show/hide controls
- Top bar: back button, book title, search, TOC
- Bottom bar: progress slider, chapter info, settings

---

### 2.2 Table of Contents
**Description**: Navigate book structure

**Features**:
- Hierarchical chapter list
- Current chapter highlighted
- Chapter completion indicators
- Quick jump to any chapter
- Nested sub-chapters (collapsible)
- Search within TOC

**UI**:
- Drawer (mobile) or sidebar (desktop)
- Smooth scroll to section
- Close after selection

---

### 2.3 Bookmarks
**Description**: Mark important pages for quick access

**Features**:
- Add bookmark at current position
- List all bookmarks
- Edit bookmark notes
- Delete bookmarks
- Jump to bookmark location
- Bookmark indicators in progress slider
- Quick bookmark (ribbon icon)

**Display**:
- Bookmarks panel/drawer
- Chapter name
- Page number
- Timestamp
- Optional note preview
- Sort by: date, chapter, note

---

### 2.4 Highlights & Annotations
**Description**: Mark and annotate text

**Highlight Colors**:
- Yellow (default)
- Green
- Blue
- Pink
- Orange
- Custom color picker

**Features**:
- Select text to highlight
- Add note to highlight
- Edit highlight color/note
- Delete highlight
- View all highlights
- Export highlights (Markdown, PDF, CSV)
- Jump to highlight location
- Share highlight with citation

**Selection Menu**:
- Highlight (with color picker)
- Add note
- Copy text
- Dictionary lookup
- Share

**Annotations**:
- Standalone notes (not tied to highlight)
- Rich text editor
- Attach to specific location
- Timestamp and date
- Edit/delete

---

### 2.5 Text Search
**Description**: Find text within the book

**Features**:
- Full-text search across entire book
- Search within current chapter
- Case-sensitive toggle
- Whole word toggle
- Regex support (advanced mode)
- Search results with context
- Navigate between results
- Result count
- Highlight all matches

**UI**:
- Search bar in top toolbar
- Results panel
- Jump to result on tap
- Previous/Next match buttons

---

### 2.6 Reading Customization
**Description**: Personalize reading experience

**Font Settings**:
- **Font Family**:
  - System default
  - Serif (Georgia, Times New Roman)
  - Sans-serif (Arial, Helvetica)
  - Monospace (Courier New)
  - Custom fonts (Merriweather, Literata, etc.)

- **Font Size**: 12pt - 48pt (slider)
- **Line Height**: 1.0 - 2.5 (slider)
- **Letter Spacing**: -0.05 - 0.2em (slider)
- **Paragraph Spacing**: 0 - 2em (slider)
- **Text Alignment**: left, justify, center

**Theme Settings**:
- **Light Theme**: White background, black text
- **Dark Theme**: Black background, light gray text
- **Sepia Theme**: Cream background, dark brown text
- **Custom Theme**: User-defined colors
- **Auto-Switch**: Follow system theme

**Layout Settings**:
- **Margins**: Small, Medium, Large
- **Page Mode**: Pagination, Continuous scroll
- **Page Transition**: Slide, Curl, Fade, None
- **Keep Screen On**: Toggle
- **Status Bar**: Show/Hide

**Presets**:
- Save custom presets
- Quick switch between presets
- Default preset

---

### 2.7 Reading Progress
**Description**: Track and visualize reading progress

**Features**:
- CFI-based position saving
- Auto-save on page turn
- Progress percentage
- Pages read / Total pages
- Time spent reading (session + total)
- Reading streak
- Estimated time remaining (based on reading speed)

**Display**:
- Progress bar at bottom
- Percentage in toolbar
- Chapter completion
- Visual milestone indicators

**Statistics**:
- Daily reading time
- Pages per day average
- Books completed
- Current reading speed (pages/hour)
- Reading goals (optional)

---

## 3. Dictionary

### 3.1 Word Lookup
**Description**: Perfect offline dictionary integration

**Lookup Methods**:
1. **Long-press word**: Shows popup immediately
2. **Select text**: Context menu includes "Define"
3. **Tap with dictionary mode on**: Instant lookup
4. **Manual search**: Dictionary screen with search bar

**Features**:
- Instant lookup (< 50ms)
- Offline database (150,000+ words)
- Multiple definitions per word
- Part of speech indicators
- Etymology
- Example sentences
- Synonyms and antonyms
- Pronunciation (IPA)
- Audio pronunciation (TTS)

**UI**:
- **Popup Card** (in-reader):
  - Word (bold, large)
  - Pronunciation
  - Play audio button
  - Part of speech
  - Definition (primary)
  - "See more" → full screen

- **Full Screen** (detailed view):
  - All definitions
  - Etymology
  - Examples
  - Synonyms/Antonyms
  - Related words
  - Add to favorites
  - Share definition

**Data Source**:
- WordNet 3.1
- Wiktionary offline dump
- Custom pronunciation database
- IPA notation

---

### 3.2 Dictionary Features
**Description**: Additional dictionary functionality

**Favorites**:
- Star words to favorite
- Favorite words list
- Export favorites (CSV, TXT)
- Study mode (flashcards)

**History**:
- Track all looked-up words
- Timestamp and book context
- Clear history
- Search history
- Filter by book

**Pronunciation**:
- Text-to-speech (offline)
- IPA notation
- Syllable breakdown
- Stress markers

**Multi-Dictionary**:
- Switch between sources
- Compare definitions
- Merge results

---

### 3.3 Dictionary Screen
**Description**: Standalone dictionary access

**Features**:
- Search bar with autocomplete
- Recent searches
- Word of the day
- Browse alphabetically
- Random word
- Category browsing (if available)

**UI**:
- Accessible from main menu
- Independent from reader
- Full functionality
- Optimized for study use

---

## 4. Settings & Preferences

### 4.1 Reading Settings
- All font and theme settings (see 2.6)
- Default reading mode (pagination/scroll)
- Auto-save frequency
- Backup settings

### 4.2 Dictionary Settings
- Default dictionary source
- Auto-play pronunciation
- Show etymology by default
- History retention period
- Favorite words export format

### 4.3 Library Settings
- Default view mode
- Default sort order
- Thumbnail quality
- Import location
- Auto-organize

### 4.4 Appearance
- App theme (independent of reading theme)
- Language (future: i18n)
- Accent color

### 4.5 Storage
- Clear cache
- Clear history
- Clear thumbnails
- Database optimization
- Storage usage display

### 4.6 Privacy
- No analytics toggle (always off by default)
- No crash reports toggle
- Clear all data

### 4.7 About
- App version
- Open source licenses
- Credits
- Dictionary sources
- Contact/Support

---

## 5. Advanced Features

### 5.1 Backup & Restore
**Description**: Protect user data

**Backup Includes**:
- All books metadata (not EPUB files)
- Bookmarks
- Highlights
- Annotations
- Reading progress
- Settings
- Dictionary favorites
- Collections

**Features**:
- Export to ZIP file
- Import from ZIP
- Auto-backup (scheduled)
- Cloud integration (future)

---

### 5.2 Import/Export
**Description**: Data portability

**Export Formats**:
- **Highlights**: Markdown, PDF, CSV, JSON
- **Bookmarks**: CSV, JSON
- **Notes**: Markdown, TXT
- **Reading stats**: CSV, JSON

**Import**:
- Import highlights from other apps (JSON)
- Import collections

---

### 5.3 Gestures (Mobile)
**Description**: Intuitive touch controls

**Gestures**:
- Swipe left/right: Page turn
- Swipe up/down: Scroll (scroll mode)
- Pinch to zoom: Font size (quick adjust)
- Two-finger tap: Bookmark
- Long-press: Word lookup
- Double-tap: Hide/show controls

---

### 5.4 Keyboard Shortcuts (Desktop)
**Description**: Efficient keyboard navigation

**Shortcuts**:
- `Arrow Left/Right`: Previous/Next page
- `Arrow Up/Down`: Scroll
- `Space`: Next page
- `Shift + Space`: Previous page
- `Home`: First page
- `End`: Last page
- `Ctrl/Cmd + F`: Search
- `Ctrl/Cmd + B`: Bookmarks
- `Ctrl/Cmd + T`: Table of contents
- `Ctrl/Cmd + D`: Dictionary
- `Ctrl/Cmd + ,`: Settings
- `Ctrl/Cmd + +/-`: Font size
- `Esc`: Close dialogs/Back

---

### 5.5 Accessibility
**Description**: Inclusive design

**Features**:
- Screen reader support (TalkBack, VoiceOver)
- High contrast themes
- Minimum font size (12pt)
- Maximum font size (48pt)
- Semantic labels
- Focus indicators
- Keyboard-only navigation
- Reduced motion option

---

## 6. Performance Features

### 6.1 Lazy Loading
- Load current chapter only
- Preload next chapter
- Unload distant chapters
- Lazy image loading

### 6.2 Caching
- Cover image cache (LRU, 100 images)
- Chapter content cache (LRU, 5 chapters)
- Dictionary lookup cache (in-memory)
- Image cache (LRU, 50 images)

### 6.3 Optimization
- Background parsing (isolates)
- Efficient database queries (indexed)
- Minimal rebuilds (const widgets, RepaintBoundary)
- Debounced search
- Throttled scroll events

---

## 7. Error Handling

### 7.1 User-Facing Errors
- **Corrupted EPUB**: "This file appears to be damaged. Try re-importing."
- **Storage Full**: "Not enough space. Free up XX MB to continue."
- **Import Failed**: "Could not import [filename]. Ensure it's a valid EPUB file."
- **Dictionary Not Found**: "Dictionary database missing. Reinstall the app."

### 7.2 Graceful Degradation
- Show partial content if parsing partially succeeds
- Fallback to system fonts if custom font fails
- Skip corrupted images
- Continue reading even if TOC is missing

---

## 8. Platform-Specific Features

### 8.1 Mobile (Android/iOS)
- Share integration
- File provider access
- Notification shade controls (future)
- Wear OS integration (future)

### 8.2 Desktop (Windows/Mac/Linux)
- Window state persistence
- System tray integration
- Menu bar
- Native file dialogs
- Multiple windows (future)

### 8.3 Web
- PWA support
- Offline capability
- Local storage
- IndexedDB for database

---

## Feature Priority Matrix

### P0 (MVP - Must Have)
- EPUB import
- Library view (grid/list)
- Basic reader (pagination)
- Reading progress saving
- Font size adjustment
- Basic dictionary lookup
- Bookmarks

### P1 (Launch)
- Highlights & annotations
- Table of contents
- Search in book
- Full theme customization
- Dictionary favorites/history
- Collections
- Backup/Export

### P2 (Post-Launch)
- Reading statistics
- Advanced search
- Multiple dictionaries
- Gesture customization
- Keyboard shortcuts
- Accessibility enhancements
- Cloud sync

---

**Last Updated**: 2025-11-14
**Version**: 1.0
**Status**: Specification Complete
