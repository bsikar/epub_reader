# EPUB Reader - Implementation Roadmap

## Overview
This document outlines the phased implementation plan for building a fully-fledged offline EPUB reader with perfect dictionary support.

---

## Phase 1: Foundation & Core Setup
**Duration**: 3-5 days
**Goal**: Establish project structure, dependencies, and core infrastructure

### Tasks

#### 1.1 Project Configuration
- [x] Update `pubspec.yaml` with all dependencies
- [x] Configure analysis_options.yaml for strict linting
- [x] Set up build_runner for code generation
- [x] Configure platform-specific settings (Android, iOS, Windows, macOS, Linux)

#### 1.2 Folder Structure
- [x] Create feature-first folder structure
- [x] Set up core/ directory (config, error, utils, database, widgets)
- [ ] Set up shared/ directory (services, widgets)
- [x] Create feature directories (library, reader, import, dictionary, etc.)

#### 1.3 Dependency Injection
- [x] Configure get_it service locator
- [x] Set up injectable with code generation
- [x] Create injection.dart with all registrations
- [x] Test DI container initialization

#### 1.4 Error Handling
- [x] Create failure classes (StorageFailure, ParsingFailure, etc.)
- [x] Create exception classes
- [x] Set up Either type (fpdart)
- [x] Create error handling utilities
- [ ] Create global error handler

#### 1.5 Database Setup
- [x] Design Drift database schema (books table)
- [x] Design Drift database schema (bookmarks table)
- [x] Design Drift database schema (highlights table)
- [x] Design Drift database schema (annotations table)
- [x] Design Drift database schema (collections table)
- [x] Design Drift database schema (reading_sessions table)
- [x] Create database migration strategy
- [x] Set up database connection
- [x] Create DAOs (Data Access Objects)

#### 1.6 Theme System
- [x] Create AppTheme class
- [x] Define light theme
- [x] Define dark theme
- [x] Define sepia theme
- [x] Create custom theme builder
- [ ] Set up theme provider (Riverpod)

#### 1.7 Core Widgets
- [x] Create LoadingIndicator widget
- [x] Create ErrorView widget
- [x] Create EmptyState widget
- [ ] Create CustomButton widget
- [ ] Create CustomTextField widget
- [ ] Create CustomDialog widget

**Deliverables**:
- Fully configured project structure
- Working dependency injection
- Database schema with migrations
- Theme system
- Reusable core widgets

---

## Phase 2: EPUB Import & Library
**Duration**: 5-7 days
**Goal**: Enable users to import books and view their library

### Tasks

#### 2.1 File Service
- [x] Create FileService for file operations
- [x] Implement file picker integration
- [x] Create file validation (EPUB format check)
- [x] Implement file copying to app directory
- [x] Create file deletion with cleanup

#### 2.2 EPUB Parser
- [x] Research epub_pro vs epub_view vs vocsy_epub_viewer
- [x] Implement EPUB metadata extraction
- [x] Create cover image extraction
- [ ] Implement thumbnail generation
- [x] Handle parsing errors gracefully
- [ ] Create progress callback for large files

#### 2.3 Import Feature
**Data Layer**:
- [x] Create EpubMetadata model
- [ ] Create ImportRepository interface
- [ ] Create ImportRepositoryImpl
- [ ] Create EpubParserDataSource
- [ ] Implement isolate-based parsing

**Domain Layer**:
- [x] Create EpubMetadata entity
- [ ] Create ImportRepository interface
- [x] Create ImportEpub use case
- [x] Create ExtractMetadata use case

**Presentation Layer**:
- [x] Create ImportProvider (Riverpod)
- [ ] Create ImportProgressWidget
- [ ] Create import error dialogs
- [x] Add import to library screen

#### 2.4 Library Feature
**Data Layer**:
- [x] Create Book model (Drift table)
- [x] Create LibraryRepository interface
- [x] Create LibraryRepositoryImpl
- [x] Create LibraryLocalDataSource
- [x] Implement CRUD operations

**Domain Layer**:
- [x] Create Book entity
- [x] Create LibraryRepository interface
- [x] Create GetBooks use case
- [x] Create GetBookById use case
- [x] Create DeleteBook use case
- [ ] Create UpdateBookMetadata use case

**Presentation Layer**:
- [x] Create LibraryProvider (Riverpod)
- [x] Create LibraryScreen
- [x] Create BookCard widget (grid view)
- [x] Create BookListItem widget (list view)
- [x] Implement view mode toggle (grid/list)
- [ ] Implement sort options
- [ ] Implement filter options
- [x] Create empty state
- [x] Add pull-to-refresh
- [x] Implement search in library

#### 2.5 Book Details
- [x] Create BookDetailsScreen
- [x] Display full metadata
- [ ] Show reading statistics
- [ ] Implement metadata editing
- [x] Add delete book functionality
- [ ] Show bookmarks/highlights count

**Deliverables**:
- Working EPUB import
- Functional library screen with grid/list views
- Search, sort, and filter capabilities
- Book details screen

---

## Phase 3: Core Reader Functionality
**Duration**: 7-10 days
**Goal**: Implement the main EPUB reading experience

### Tasks

#### 3.1 Reader Setup
- [x] Choose EPUB rendering package (epub_view recommended)
- [x] Create ReaderScreen
- [x] Implement basic EPUB rendering
- [ ] Add page/scroll mode toggle
- [x] Implement CFI-based position tracking
- [ ] Add auto-hide UI controls

#### 3.2 Navigation
- [x] Implement page turn (tap/swipe)
- [x] Add previous/next chapter buttons
- [x] Create progress slider
- [ ] Add page number indicator
- [ ] Implement smooth animations

#### 3.3 Table of Contents
- [x] Extract TOC from EPUB
- [ ] Create TocDrawer widget
- [ ] Implement hierarchical chapter list
- [ ] Add current chapter highlighting
- [x] Implement jump-to-chapter
- [ ] Add search within TOC

#### 3.4 Reading Progress
**Data Layer**:
- [x] Create ReadingProgress model
- [ ] Update ReaderRepository
- [x] Implement auto-save mechanism

**Domain Layer**:
- [x] Create SaveProgress use case
- [x] Create GetProgress use case

**Presentation Layer**:
- [x] Track current CFI position
- [x] Save progress on page turn
- [x] Save progress on app pause
- [x] Display progress percentage
- [ ] Show estimated time remaining

#### 3.5 Bookmarks
**Data Layer**:
- [x] Create Bookmark model (Drift table)
- [x] Implement bookmark CRUD in repository

**Domain Layer**:
- [x] Create Bookmark entity
- [x] Create AddBookmark use case
- [x] Create GetBookmarks use case
- [x] Create DeleteBookmark use case

**Presentation Layer**:
- [x] Create BookmarksDrawer widget
- [x] Add bookmark button in reader
- [x] Display bookmark list
- [x] Implement jump-to-bookmark
- [x] Add bookmark notes
- [x] Show bookmark indicators in progress slider

**Deliverables**:
- Fully functional EPUB reader
- Table of contents navigation
- Reading progress tracking
- Bookmark system

---

## Phase 4: Advanced Reading Features
**Duration**: 5-7 days
**Goal**: Add highlights, annotations, search, and customization

### Tasks

#### 4.1 Highlights & Annotations
**Data Layer**:
- [x] Create Highlight model (Drift table)
- [x] Create Annotation model (Drift table)
- [x] Implement highlight CRUD
- [ ] Implement annotation CRUD

**Domain Layer**:
- [x] Create Highlight entity
- [ ] Create Annotation entity
- [x] Create AddHighlight use case
- [x] Create GetHighlights use case
- [x] Create UpdateHighlight use case
- [x] Create DeleteHighlight use case
- [ ] Create AddAnnotation use case

**Presentation Layer**:
- [ ] Implement text selection
- [ ] Create selection context menu
- [ ] Add color picker for highlights
- [ ] Create highlight note dialog
- [ ] Display highlights in reader
- [ ] Create HighlightsDrawer
- [ ] Implement export highlights (Markdown, PDF, CSV)

#### 4.2 In-Book Search
- [ ] Create SearchService
- [ ] Implement full-text search across book
- [ ] Add search within chapter option
- [ ] Create SearchScreen
- [ ] Display search results with context
- [ ] Highlight matches in reader
- [ ] Add navigation between results
- [ ] Implement case-sensitive toggle
- [ ] Implement whole word toggle

#### 4.3 Reading Customization
**Font Settings**:
- [ ] Create FontSettingsDrawer
- [ ] Implement font family picker
- [x] Add font size slider (12-48pt)
- [ ] Add line height slider
- [ ] Add letter spacing slider
- [ ] Add paragraph spacing slider
- [ ] Add text alignment options
- [ ] Save settings to database

**Theme Settings**:
- [ ] Create ThemeSettingsDrawer
- [x] Implement light/dark/sepia themes
- [ ] Add custom theme builder
- [ ] Add auto-switch with system theme
- [ ] Implement margin options
- [ ] Add page transition animations

**Settings Persistence**:
- [ ] Create SettingsRepository
- [ ] Save user preferences
- [ ] Load settings on app start
- [ ] Create preset system

**Deliverables**:
- Highlights and annotations
- In-book search
- Complete reading customization
- Export functionality

---

## Phase 5: Offline Dictionary Integration
**Duration**: 7-10 days
**Goal**: Implement perfect offline dictionary with word lookup

### Tasks

#### 5.1 Dictionary Database
- [ ] Research dictionary data sources (WordNet, Wiktionary)
- [ ] Download dictionary dataset
- [ ] Convert to SQLite format
- [ ] Create dictionary database schema (FTS5)
- [ ] Populate dictionary_entries table (150,000+ words)
- [ ] Create indexes for fast lookup
- [ ] Add pronunciation data
- [ ] Add etymology data
- [ ] Add example sentences

#### 5.2 Dictionary Service
**Data Layer**:
- [ ] Create DictionaryDatabase (separate from main DB)
- [ ] Create Definition model
- [ ] Create DictionaryLocalDataSource
- [ ] Implement FTS5 queries

**Domain Layer**:
- [ ] Create Definition entity
- [ ] Create DictionaryRepository interface
- [ ] Create LookupWord use case
- [ ] Create GetWordSuggestions use case
- [ ] Create AddToFavorites use case
- [ ] Create GetHistory use case

**Presentation Layer**:
- [ ] Create DictionaryProvider
- [ ] Test lookup performance (< 50ms target)

#### 5.3 Word Lookup UI
- [ ] Create WordLookupPopup widget
- [ ] Implement long-press word detection
- [ ] Create quick definition card
- [ ] Add "See more" button
- [ ] Create DefinitionScreen (full view)
- [ ] Display all definitions
- [ ] Show pronunciation (IPA)
- [ ] Display etymology
- [ ] Show examples
- [ ] Add favorites button
- [ ] Add share button

#### 5.4 Pronunciation
- [ ] Integrate flutter_tts
- [ ] Configure offline TTS
- [ ] Add play button
- [ ] Display IPA notation
- [ ] Show syllable breakdown

#### 5.5 Dictionary History & Favorites
**Data Layer**:
- [x] Create DictionaryHistory model (Drift table)
- [x] Create DictionaryFavorites model (Drift table)
- [ ] Implement history tracking
- [ ] Implement favorites management

**Presentation Layer**:
- [ ] Create DictionaryScreen (standalone)
- [ ] Create search bar with autocomplete
- [ ] Display recent searches
- [ ] Create favorites list
- [ ] Implement clear history
- [ ] Add export favorites

#### 5.6 Integration with Reader
- [ ] Connect text selection to dictionary lookup
- [ ] Add "Define" to selection context menu
- [ ] Implement dictionary mode (tap to lookup)
- [ ] Show lookup in context (book + CFI)

**Deliverables**:
- Fully functional offline dictionary
- Fast word lookup (< 50ms)
- Pronunciation support
- History and favorites
- Seamless reader integration

---

## Phase 6: Collections & Organization
**Duration**: 3-4 days
**Goal**: Add library organization features

### Tasks

#### 6.1 Collections System
**Data Layer**:
- [x] Create Collection model (Drift table)
- [x] Create book-collection junction table
- [ ] Implement collections CRUD

**Domain Layer**:
- [ ] Create Collection entity
- [ ] Create CreateCollection use case
- [ ] Create AddBookToCollection use case
- [ ] Create GetCollections use case

**Presentation Layer**:
- [ ] Create CollectionsScreen
- [ ] Create CollectionCard widget
- [ ] Implement drag-and-drop
- [ ] Add collection colors/icons
- [ ] Create smart collections
- [ ] Filter library by collection

#### 6.2 Advanced Library Features
- [ ] Implement batch operations (delete, move)
- [ ] Add recently opened section
- [ ] Create continue reading widget
- [ ] Implement library statistics

**Deliverables**:
- Collections/categories system
- Enhanced library organization
- Batch operations

---

## Phase 7: Statistics & Analytics
**Duration**: 3-4 days
**Goal**: Add reading statistics and insights

### Tasks

#### 7.1 Reading Sessions
**Data Layer**:
- [x] Create ReadingSession model (Drift table)
- [ ] Track session start/end times
- [ ] Calculate pages read per session
- [ ] Calculate total time read

**Domain Layer**:
- [ ] Create RecordReadingSession use case
- [ ] Create GetStatistics use case

**Presentation Layer**:
- [ ] Create StatisticsScreen
- [ ] Display daily reading time
- [ ] Show pages per day average
- [ ] Display books completed
- [ ] Calculate reading speed
- [ ] Show reading streaks
- [ ] Create charts/graphs
- [ ] Set reading goals (optional)

**Deliverables**:
- Comprehensive reading statistics
- Visual analytics
- Reading goals

---

## Phase 8: Settings & Preferences
**Duration**: 2-3 days
**Goal**: Centralize all app settings

### Tasks

#### 8.1 Settings Screen
- [ ] Create SettingsScreen
- [ ] Organize into sections (Reading, Dictionary, Library, etc.)
- [ ] Implement all reading settings
- [ ] Implement all dictionary settings
- [ ] Implement all library settings
- [ ] Implement appearance settings
- [ ] Add storage management
- [ ] Create privacy settings
- [ ] Add about section

#### 8.2 Settings Persistence
- [ ] Create SettingsRepository
- [x] Save all preferences to database
- [ ] Load settings on app start
- [ ] Implement settings sync

**Deliverables**:
- Centralized settings screen
- All customization options
- Settings persistence

---

## Phase 9: Backup & Export
**Duration**: 3-4 days
**Goal**: Data protection and portability

### Tasks

#### 9.1 Backup System
- [ ] Create BackupService
- [ ] Export all user data (excluding EPUBs)
- [ ] Create ZIP archive format
- [ ] Implement restore functionality
- [ ] Add auto-backup scheduling
- [ ] Create backup manager UI

#### 9.2 Export Features
- [ ] Export highlights to Markdown
- [ ] Export highlights to PDF
- [ ] Export highlights to CSV
- [ ] Export bookmarks to CSV
- [ ] Export notes to text files
- [ ] Export reading stats to JSON/CSV
- [ ] Create share functionality

**Deliverables**:
- Backup and restore
- Multiple export formats
- Auto-backup option

---

## Phase 10: Performance Optimization
**Duration**: 4-5 days
**Goal**: Ensure smooth performance with large files

### Tasks

#### 10.1 Memory Management
- [ ] Implement lazy loading for chapters
- [ ] Implement lazy loading for images
- [ ] Create LRU cache for covers
- [ ] Create LRU cache for chapters
- [ ] Create LRU cache for images
- [ ] Profile memory usage
- [ ] Optimize memory footprint (target < 200MB)

#### 10.2 Rendering Optimization
- [ ] Add RepaintBoundary to widgets
- [ ] Use const constructors
- [x] Implement ListView.builder for lists
- [ ] Optimize database queries
- [x] Add database indexes
- [ ] Profile rendering performance
- [ ] Optimize frame rate (target 60fps)

#### 10.3 App Size Optimization
- [ ] Optimize assets
- [ ] Minimize dictionary database size
- [ ] Use code splitting
- [ ] Profile APK/IPA size

**Deliverables**:
- Optimized memory usage
- Smooth 60fps performance
- Reduced app size

---

## Phase 11: Platform-Specific Features
**Duration**: 3-4 days
**Goal**: Enhance experience on each platform

### Tasks

#### 11.1 Mobile (Android/iOS)
- [ ] Implement gestures (swipe, pinch, etc.)
- [ ] Add share integration
- [ ] Configure file provider
- [ ] Optimize touch targets
- [ ] Test on various screen sizes

#### 11.2 Desktop (Windows/macOS/Linux)
- [ ] Add keyboard shortcuts
- [ ] Create menu bar
- [ ] Implement window state persistence
- [ ] Add drag-and-drop import
- [ ] Test multiple window sizes
- [ ] Add system tray (optional)

#### 11.3 Web (PWA)
- [ ] Configure PWA manifest
- [ ] Set up service workers
- [ ] Enable offline mode
- [ ] Test IndexedDB storage
- [ ] Optimize for web performance

**Deliverables**:
- Platform-optimized experiences
- Keyboard shortcuts
- Gesture controls

---

## Phase 12: Accessibility
**Duration**: 2-3 days
**Goal**: Make app accessible to all users

### Tasks

- [ ] Add semantic labels to all widgets
- [ ] Test with screen readers (TalkBack, VoiceOver)
- [ ] Ensure keyboard-only navigation
- [ ] Add focus indicators
- [ ] Implement high contrast themes
- [ ] Add reduced motion option
- [ ] Test font scaling (up to 48pt)
- [ ] Ensure color contrast ratios (WCAG AA)
- [ ] Add descriptive error messages
- [ ] Test with accessibility tools

**Deliverables**:
- Full screen reader support
- Keyboard navigation
- High contrast themes
- WCAG compliance

---

## Phase 13: Testing
**Duration**: 5-7 days
**Goal**: Comprehensive test coverage

### Tasks

#### 13.1 Unit Tests
- [x] Test all use cases (library feature)
- [x] Test all use cases (reader feature)
- [ ] Test all use cases (import feature)
- [ ] Test all use cases (dictionary feature)
- [ ] Test all repositories
- [x] Test all services
- [ ] Test utility functions
- [ ] Achieve 70% code coverage

#### 13.2 Widget Tests
- [ ] Test LibraryScreen
- [x] Test ReaderScreen
- [x] Test BookDetailsScreen
- [ ] Test DictionaryScreen
- [ ] Test SettingsScreen
- [x] Test all major widgets
- [ ] Test user interactions

#### 13.3 Integration Tests
- [ ] Test import → library → read flow
- [ ] Test dictionary lookup flow
- [ ] Test bookmark creation flow
- [ ] Test highlight creation flow
- [ ] Test settings persistence
- [ ] Test backup/restore flow

#### 13.4 Platform Testing
- [ ] Test on Android (multiple devices)
- [ ] Test on iOS (multiple devices)
- [ ] Test on Windows
- [ ] Test on macOS
- [ ] Test on Linux
- [ ] Test on Web browsers

**Deliverables**:
- 70% unit test coverage
- Widget tests for all screens
- Integration tests for critical flows
- Cross-platform validation

---

## Phase 14: Polish & UI/UX
**Duration**: 3-4 days
**Goal**: Final polish and user experience improvements

### Tasks

#### 14.1 UI Polish
- [ ] Design app icons (all platforms)
- [ ] Create splash screen
- [ ] Add animations and transitions
- [ ] Polish all dialogs
- [ ] Ensure consistent spacing
- [ ] Verify color consistency
- [ ] Add loading states everywhere
- [ ] Polish empty states

#### 14.2 UX Improvements
- [ ] Add tooltips
- [ ] Improve error messages
- [ ] Add confirmation dialogs
- [ ] Implement undo for destructive actions
- [ ] Add progress indicators
- [ ] Improve onboarding flow
- [ ] Add quick tour/tutorial

#### 14.3 Final Touches
- [ ] Optimize app launch time
- [ ] Test all edge cases
- [ ] Fix visual bugs
- [ ] Ensure smooth animations
- [ ] Verify all features work offline

**Deliverables**:
- Polished UI
- Smooth UX
- App icons and splash screen

---

## Phase 15: Documentation & Release
**Duration**: 2-3 days
**Goal**: Prepare for release

### Tasks

#### 15.1 Documentation
- [ ] Write comprehensive README.md
- [ ] Document all features
- [ ] Create usage guide
- [ ] Write developer documentation
- [ ] Document architecture decisions
- [ ] Create API documentation
- [ ] Add inline code documentation

#### 15.2 User Help
- [ ] Create in-app help section
- [ ] Write FAQ
- [ ] Create keyboard shortcuts reference
- [ ] Add tooltips and hints

#### 15.3 Release Preparation
- [ ] Update app version
- [ ] Create changelog
- [ ] Generate release builds
- [ ] Test release builds on all platforms
- [ ] Prepare store listings (if applicable)
- [ ] Create screenshots
- [ ] Write app description

**Deliverables**:
- Complete documentation
- Release-ready builds
- Help and support materials

---

## Total Estimated Timeline

| Phase | Duration | Cumulative |
|-------|----------|-----------|
| 1. Foundation & Core Setup | 3-5 days | 5 days |
| 2. EPUB Import & Library | 5-7 days | 12 days |
| 3. Core Reader Functionality | 7-10 days | 22 days |
| 4. Advanced Reading Features | 5-7 days | 29 days |
| 5. Offline Dictionary | 7-10 days | 39 days |
| 6. Collections & Organization | 3-4 days | 43 days |
| 7. Statistics & Analytics | 3-4 days | 47 days |
| 8. Settings & Preferences | 2-3 days | 50 days |
| 9. Backup & Export | 3-4 days | 54 days |
| 10. Performance Optimization | 4-5 days | 59 days |
| 11. Platform-Specific Features | 3-4 days | 63 days |
| 12. Accessibility | 2-3 days | 66 days |
| 13. Testing | 5-7 days | 73 days |
| 14. Polish & UI/UX | 3-4 days | 77 days |
| 15. Documentation & Release | 2-3 days | 80 days |

**Total: ~80 days (16 weeks / 4 months)**

---

## Priority Levels

### P0 (Critical - Must Have for MVP)
- Phase 1: Foundation
- Phase 2: EPUB Import & Library
- Phase 3: Core Reader
- Phase 5: Dictionary (basic lookup)

### P1 (High - Launch Ready)
- Phase 4: Advanced Reading Features
- Phase 5: Dictionary (complete)
- Phase 8: Settings
- Phase 13: Testing (critical tests)

### P2 (Medium - Post-Launch)
- Phase 6: Collections
- Phase 7: Statistics
- Phase 9: Backup/Export
- Phase 11: Platform-Specific
- Phase 12: Accessibility

### P3 (Low - Future Enhancements)
- Advanced analytics
- Cloud sync
- Multi-language support
- Audio book support

---

## Success Metrics

### Performance
- [ ] App launch < 2 seconds
- [ ] Book open < 1 second
- [ ] Dictionary lookup < 50ms
- [ ] 60fps rendering
- [ ] Memory usage < 200MB

### Quality
- [ ] 70% test coverage
- [ ] Zero critical bugs
- [ ] All features work offline
- [ ] WCAG AA accessibility

### User Experience
- [ ] Intuitive navigation
- [ ] Smooth animations
- [ ] Clear error messages
- [ ] Comprehensive help

---

**Last Updated**: 2025-11-14
**Version**: 1.0
**Status**: Planning Complete
