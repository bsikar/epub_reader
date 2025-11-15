# EPUB Reader - Architecture Document

## Overview
A fully-fledged offline EPUB reader application built with Flutter, featuring comprehensive reading features and perfect offline dictionary support.

## Architecture Pattern
**Clean Architecture with Feature-First Structure**

### Layer Structure
```
Presentation Layer (UI)
    ↓
Domain Layer (Business Logic)
    ↓
Data Layer (Repositories & Data Sources)
```

### Dependency Rule
- Outer layers depend on inner layers
- Inner layers have no knowledge of outer layers
- Domain layer has zero dependencies on other layers

## State Management
**Riverpod 3.x** - Chosen for:
- Compile-time safety
- No BuildContext dependency
- Excellent async support
- Fine-grained rebuilds
- Easy testing

**hydrated_bloc** - For persistence:
- Reading progress across app restarts
- User preferences
- Last opened book state

## Database Strategy

### Primary Database: Drift (SQLite)
**Tables:**
1. **books**
   - id, title, author, cover_path, file_path
   - last_opened, reading_progress, total_pages
   - metadata (publisher, language, isbn, etc.)

2. **bookmarks**
   - id, book_id, cfi_location, chapter_name
   - page_number, created_at, note

3. **highlights**
   - id, book_id, cfi_range, selected_text
   - color, created_at, note

4. **annotations**
   - id, book_id, cfi_location, note_text
   - created_at, updated_at

5. **collections**
   - id, name, description, created_at
   - book_id (many-to-many relationship)

6. **reading_sessions**
   - id, book_id, start_time, end_time
   - pages_read, duration_minutes

7. **dictionary_history**
   - id, word, definition, timestamp
   - book_id, cfi_location (context)

8. **dictionary_favorites**
   - id, word, definition, added_at

### Dictionary Database: Separate SQLite with FTS5
**Tables:**
1. **dictionary_entries** (FTS5)
   - word, definition, etymology
   - pronunciation, part_of_speech, examples

2. **dictionary_metadata**
   - source_name, version, language
   - total_entries, last_updated

## Project Structure
```
lib/
├── main.dart
├── app.dart
├── injection.dart (DI setup)
│
├── core/
│   ├── config/
│   │   ├── theme.dart
│   │   └── constants.dart
│   ├── error/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── utils/
│   │   ├── either.dart (fpdart)
│   │   ├── logger.dart
│   │   └── validators.dart
│   ├── database/
│   │   ├── app_database.dart (Drift)
│   │   └── dictionary_database.dart
│   └── widgets/
│       ├── loading_indicator.dart
│       └── error_view.dart
│
├── shared/
│   ├── services/
│   │   ├── file_service.dart
│   │   ├── storage_service.dart
│   │   └── analytics_service.dart
│   └── widgets/
│       ├── custom_button.dart
│       ├── custom_text_field.dart
│       └── custom_dialog.dart
│
└── features/
    ├── library/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── library_local_datasource.dart
    │   │   ├── models/
    │   │   │   └── book_model.dart
    │   │   └── repositories/
    │   │       └── library_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── book.dart
    │   │   ├── repositories/
    │   │   │   └── library_repository.dart
    │   │   └── usecases/
    │   │       ├── get_books.dart
    │   │       ├── delete_book.dart
    │   │       └── get_book_by_id.dart
    │   └── presentation/
    │       ├── providers/
    │       │   └── library_provider.dart
    │       ├── screens/
    │       │   ├── library_screen.dart
    │       │   └── book_details_screen.dart
    │       └── widgets/
    │           ├── book_card.dart
    │           └── book_grid.dart
    │
    ├── reader/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── reader_local_datasource.dart
    │   │   ├── models/
    │   │   │   ├── bookmark_model.dart
    │   │   │   └── highlight_model.dart
    │   │   └── repositories/
    │   │       └── reader_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── bookmark.dart
    │   │   │   └── highlight.dart
    │   │   ├── repositories/
    │   │   │   └── reader_repository.dart
    │   │   └── usecases/
    │   │       ├── save_progress.dart
    │   │       ├── add_bookmark.dart
    │   │       └── add_highlight.dart
    │   └── presentation/
    │       ├── providers/
    │       │   └── reader_provider.dart
    │       ├── screens/
    │       │   └── reader_screen.dart
    │       └── widgets/
    │           ├── reader_controls.dart
    │           ├── toc_drawer.dart
    │           └── font_settings.dart
    │
    ├── import/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── epub_parser_datasource.dart
    │   │   ├── models/
    │   │   │   └── epub_metadata_model.dart
    │   │   └── repositories/
    │   │       └── import_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── epub_metadata.dart
    │   │   ├── repositories/
    │   │   │   └── import_repository.dart
    │   │   └── usecases/
    │   │       ├── import_epub.dart
    │   │       └── extract_metadata.dart
    │   └── presentation/
    │       ├── providers/
    │       │   └── import_provider.dart
    │       └── widgets/
    │           └── import_progress.dart
    │
    ├── dictionary/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── dictionary_local_datasource.dart
    │   │   ├── models/
    │   │   │   └── definition_model.dart
    │   │   └── repositories/
    │   │       └── dictionary_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── definition.dart
    │   │   ├── repositories/
    │   │   │   └── dictionary_repository.dart
    │   │   └── usecases/
    │   │       ├── lookup_word.dart
    │   │       ├── add_to_favorites.dart
    │   │       └── get_history.dart
    │   └── presentation/
    │       ├── providers/
    │       │   └── dictionary_provider.dart
    │       ├── screens/
    │       │   └── dictionary_screen.dart
    │       └── widgets/
    │           ├── definition_card.dart
    │           └── word_lookup_popup.dart
    │
    ├── bookmarks/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │
    ├── settings/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │
    └── statistics/
        ├── data/
        ├── domain/
        └── presentation/
```

## Key Dependencies

### EPUB Handling
- **epub_pro** (or epub_view) - EPUB parsing and rendering
- Performance-optimized for large files

### State Management
- **flutter_riverpod** ^2.5.0 - State management
- **riverpod_annotation** - Code generation
- **hydrated_bloc** - State persistence

### Database
- **drift** ^2.18.0 - SQLite wrapper
- **drift_flutter** - Platform integration
- **sqlite3_flutter_libs** - SQLite native libraries

### Dependency Injection
- **get_it** ^7.7.0 - Service locator
- **injectable** ^2.4.0 - DI code generation

### File Management
- **file_picker** - File selection
- **path_provider** - App directories
- **path** - Path manipulation

### Error Handling
- **fpdart** - Functional programming (Either type)

### UI Components
- **flutter_slidable** - Swipe actions
- **cached_network_image** - Image caching
- **shimmer** - Loading effects
- **flutter_staggered_grid_view** - Grid layouts

### Text-to-Speech
- **flutter_tts** - Offline pronunciation

### Utilities
- **intl** - Internationalization
- **uuid** - Unique IDs
- **equatable** - Value equality

### Testing
- **mockito** - Mocking
- **build_runner** - Code generation
- **flutter_test** (SDK)

## EPUB Rendering Strategy

### CFI (Canonical Fragment Identifier)
- Use CFI for all position tracking
- Ensures cross-device compatibility
- Format: `epubcfi(/6/4[chap01ref]!/4[body01]/10[para05]/1:0)`

### Lazy Loading Pipeline
1. **Load ZIP central directory** (instant)
2. **Extract metadata** (< 100ms)
3. **Load current chapter only** (on-demand)
4. **Preload next chapter** (background)
5. **Cache recent chapters** (LRU, 3-5 chapters)

### Multi-Level Caching
1. **Memory Cache** - Current + adjacent chapters
2. **Disk Cache** - Recently accessed chapters
3. **Original EPUB** - Full book archive

## Dictionary Implementation

### Data Source
**WordNet 3.1** + **Wiktionary Dump**
- 150,000+ entries
- Etymology, pronunciation, examples
- Public domain/CC license

### Database Schema
```sql
CREATE VIRTUAL TABLE dictionary_entries USING fts5(
  word,
  definition,
  etymology,
  pronunciation,
  part_of_speech,
  examples,
  tokenize = 'porter'
);

CREATE INDEX idx_word ON dictionary_entries(word);
```

### Lookup Performance
- FTS5 full-text search: < 10ms average
- Prefix matching for suggestions
- Fuzzy matching for typos

### Integration Points
1. **Text Selection** - Long-press word → popup
2. **Tap Lookup** - Single tap with dictionary mode enabled
3. **Search Bar** - Manual word entry
4. **History** - Recently looked up words

## Performance Targets

### Critical Metrics
- **App Launch**: < 2 seconds to library
- **Book Open**: < 1 second to last position
- **Chapter Turn**: < 200ms
- **Dictionary Lookup**: < 50ms
- **Search Results**: < 500ms per book
- **Memory Usage**: < 200MB for large EPUB

### Optimization Strategies
1. **Isolates** - Parse EPUB in background
2. **RepaintBoundary** - Reduce widget rebuilds
3. **const constructors** - Reduce allocations
4. **ListView.builder** - Virtualized lists
5. **Image caching** - LRU cache with size limits
6. **Database indexes** - On frequently queried fields

## Error Handling

### Error Types
1. **NetworkFailure** - (Not applicable - offline app)
2. **StorageFailure** - Disk full, permissions
3. **ParsingFailure** - Corrupted EPUB
4. **DatabaseFailure** - Query errors
5. **ValidationFailure** - Invalid input

### Error Recovery
- Graceful degradation (show partial data)
- Retry mechanisms for transient failures
- User-friendly error messages
- Logging for debugging

## Testing Strategy

### Unit Tests (70%)
- All use cases
- All repositories
- All services
- Utility functions

### Widget Tests (20%)
- All screens
- Complex widgets
- User interactions

### Integration Tests (10%)
- Import → Library → Read flow
- Dictionary lookup flow
- Bookmark creation flow
- Settings persistence

## Security Considerations

### Data Protection
- No sensitive user data (offline app)
- Local-only storage
- No network requests
- No analytics/tracking

### File Safety
- Validate EPUB files before parsing
- Sanitize file paths
- Limit file sizes
- Isolate parsing in separate thread

## Accessibility

### Features
- Screen reader support (Semantics widgets)
- High contrast themes
- Adjustable font sizes (12pt - 48pt)
- Keyboard navigation (desktop)
- Voice control integration

## Build Targets

### Platforms
- Android (minSdk 21)
- iOS (12.0+)
- Windows (10+)
- macOS (10.14+)
- Linux (Ubuntu 20.04+)
- Web (PWA - offline capable)

## Future Enhancements

### Phase 2 Features
- Cloud sync (optional)
- Multi-language dictionaries
- Audiobook support
- PDF support
- Note export to Markdown
- Reading challenges/goals
- Book recommendations (offline ML)

## References
- W3C EPUB 3.3 Specification
- CFI Standard (IDPF)
- Material Design 3 Guidelines
- Flutter Clean Architecture (Reso Coder)
- Riverpod Documentation

---

**Last Updated**: 2025-11-14
**Version**: 1.0
**Author**: AI Architecture Team
