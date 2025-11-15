# Comprehensive Best Practices for Building EPUB Reader Applications in Flutter

This document provides detailed, research-backed guidance for building EPUB reader applications in Flutter based on industry standards, official documentation, and successful real-world implementations.

---

## Table of Contents

1. [Package Selection and Comparison](#1-package-selection-and-comparison)
2. [EPUB Rendering Best Practices](#2-epub-rendering-best-practices)
3. [Reading Progress Tracking and Bookmarks](#3-reading-progress-tracking-and-bookmarks)
4. [Annotations and Highlighting](#4-annotations-and-highlighting)
5. [Table of Contents Navigation](#5-table-of-contents-navigation)
6. [Font Customization](#6-font-customization)
7. [Offline Storage and Library Management](#7-offline-storage-and-library-management)
8. [Performance Optimization for Large EPUBs](#8-performance-optimization-for-large-epubs)
9. [Text Selection and Copying](#9-text-selection-and-copying)
10. [Search Functionality](#10-search-functionality)
11. [Implementation Examples](#11-implementation-examples)

---

## 1. Package Selection and Comparison

### Overview of Available Flutter EPUB Packages

#### **1.1 epub_view** (Recommended for Cross-Platform)

**Authority Level:** Popular community package with active forks

**Key Characteristics:**
- Pure Flutter widget implementation (no native dependencies)
- Cross-platform support: Web, macOS, Windows, Linux, Android, iOS
- Based on the dart-epub package
- CFI (Canonical Fragment Identifier) support for precise location tracking

**Advantages:**
- Works on all platforms including web and desktop
- Highly customizable due to pure Flutter implementation
- No native dependencies simplifies integration
- Built-in table of contents widget
- Chapter tracking functionality

**Limitations:**
- Rendering via Flutter widgets may have performance considerations for complex EPUBs
- Some forks are more actively maintained than the original (e.g., epub_view_plus by hosseinshaya)

**Use Cases:**
- Multi-platform applications (especially web/desktop support)
- Projects requiring full UI customization
- Applications where pure Flutter implementation is preferred

---

#### **1.2 vocsy_epub_viewer**

**Authority Level:** Fork of epub_kitty with additional features

**Key Characteristics:**
- Native implementation using FolioReader framework
- iOS and Android only (no web/desktop support)
- Encapsulates the folioreader framework
- Minimum iOS deployment target: 9.0
- Requires Swift for iOS

**Advantages:**
- Ready-made UI with good features out of the box
- Native performance benefits
- Built-in reading features from FolioReader
- Location tracking with locator stream
- Supports opening from assets and URLs

**Limitations:**
- Limited customization options
- No comprehensive documentation
- Platform restricted (mobile only)
- Not actively maintained by original author

**Use Cases:**
- Mobile-only applications (iOS/Android)
- Projects preferring ready-made UI over customization
- Applications requiring native performance

---

#### **1.3 flutter_epub_viewer / flutter_epub_reader**

**Authority Level:** Community packages combining Epub.js and InAppWebView

**Key Characteristics:**
- Combines Epubjs JavaScript library with flutter_inappwebview
- Support for highlights, underlines, and annotations
- Built-in search functionality
- Text selection capabilities

**Advantages:**
- Leverages mature Epub.js rendering engine
- Rich annotation features (highlights, underlines)
- Search functionality built-in
- Custom context menu for text selection
- Comprehensive text selection callbacks

**Limitations:**
- Depends on WebView performance
- Larger bundle size due to WebView dependency
- WebView-related performance considerations

**Use Cases:**
- Applications requiring advanced annotation features
- Projects needing robust search capabilities
- Applications where WebView dependency is acceptable

---

#### **1.4 epub_pro**

**Authority Level:** Performance-optimized package with advanced features

**Key Characteristics:**
- Performance improvements scale with EPUB size
- CFIAnnotationManager for precise annotations
- Smart NCX/Spine reconciliation
- Optional chapter splitting functionality

**Advantages:**
- Specifically optimized for large EPUB files
- Industry-standard CFI positioning
- Advanced annotation management
- Cross-device synchronization support

**Limitations:**
- Less documentation available
- Smaller community compared to other packages

**Use Cases:**
- Applications handling large EPUB files
- Projects requiring professional annotation systems
- Applications needing cross-device sync

---

#### **1.5 cosmos_epub**

**Authority Level:** Community package with good UI

**Key Characteristics:**
- Easy-to-use interface
- Theme support
- Font customization
- Chapter content access

**Advantages:**
- Simple integration
- Built-in theme switching
- Font style and size adjustment
- Good default UI

**Limitations:**
- Less feature-rich than other options
- Smaller community

**Use Cases:**
- Quick prototyping
- Simple EPUB reader applications
- Projects prioritizing ease of use

---

### Package Selection Decision Matrix

| Feature | epub_view | vocsy_epub_viewer | flutter_epub_viewer | epub_pro | cosmos_epub |
|---------|-----------|-------------------|---------------------|----------|-------------|
| Cross-Platform | ✓ (All) | ✗ (Mobile only) | ✓ (Most) | ✓ (Most) | ✓ (Most) |
| Pure Flutter | ✓ | ✗ (Native) | ✗ (WebView) | ✓ | ✓ |
| Customization | High | Low | Medium | High | Medium |
| Annotations | Basic | Good | Excellent | Excellent | Basic |
| Search | Manual | Built-in | Built-in | Manual | Manual |
| Performance | Good | Excellent | Medium | Excellent | Good |
| Documentation | Good | Limited | Good | Limited | Good |
| Active Maintenance | Medium | Low | Medium | Medium | Medium |

---

## 2. EPUB Rendering Best Practices

### 2.1 Text Rendering and Typography

**Official EPUB Specification:** EPUB 3.3 (W3C Standard)

#### Typography Hierarchy Best Practices

**Source:** W3C EPUB Content Documents 3.2/3.3

Reading systems must support visual rendering of XHTML content documents as defined in CSS style sheets. Key principles:

1. **Use Proper CSS Profile**
   - EPUB 3 defines a profile based on CSS 2.1 with CSS3 module capabilities
   - Use unprefixed CSS properties (required since EPUB 3.2)
   - Authors should use unprefixed properties; Reading Systems should support current CSS specifications

2. **Respect Style Hierarchy**
   - Author CSS styles should be respected
   - User styles can override through Reading System Overrides
   - Reading system user agent style sheets should support HTML suggested default rendering

3. **Typography Best Practices**
   ```dart
   // Flutter TextStyle configuration for EPUB rendering
   TextStyle(
     fontFamily: 'Book Antiqua', // Or user-selected font
     fontSize: 16.0, // User adjustable
     height: 1.5, // Line height (spacing)
     letterSpacing: 0.5, // Optional letter spacing
     fontWeight: FontWeight.normal,
     color: Colors.black87, // Adjust for theme
   )
   ```

4. **Implement StrutStyle for Consistent Line Heights**
   ```dart
   StrutStyle(
     fontSize: 16.0,
     height: 1.5,
     forceStrutHeight: true, // Ensures consistent line height
   )
   ```

---

### 2.2 Image Handling

**Best Practice Sources:** Flutter official documentation, industry memory optimization guides

#### Image Loading Strategies

1. **Lazy Loading**
   - Load images only when they enter the viewport
   - Reduces memory consumption significantly
   - Improves scrolling performance

2. **Memory Optimization**
   ```dart
   Image.network(
     imageUrl,
     cacheWidth: 800, // Decode at lower resolution
     cacheHeight: 600,
     fit: BoxFit.contain,
   )
   ```

3. **Format Optimization**
   - Use WebP format instead of PNG/JPEG
   - Better compression without quality loss
   - Flutter supports WebP natively

4. **Caching Strategy**
   ```dart
   // Use cached_network_image for efficient caching
   CachedNetworkImage(
     imageUrl: imageUrl,
     memCacheWidth: 800,
     memCacheHeight: 600,
     placeholder: (context, url) => CircularProgressIndicator(),
     errorWidget: (context, url, error) => Icon(Icons.error),
   )
   ```

5. **Dispose Properly**
   - Always dispose of image resources when not needed
   - Clear image cache when memory is limited
   ```dart
   @override
   void dispose() {
     imageCache.clear();
     imageCache.clearLiveImages();
     super.dispose();
   }
   ```

---

### 2.3 CSS Support

**Authority:** W3C EPUB 3.3 Specification

#### CSS Implementation Requirements

1. **Core Requirements**
   - Reading systems must support CSS 2.1 profile
   - Support for CSS3 modules is recommended
   - Reading System developers should implement CSS at browser level

2. **SVG Rendering**
   - Reading systems with viewport must support SVG rendering using CSS

3. **Best Practices for EPUB Authors**
   - Use mobile-friendly CSS
   - Avoid fixed dimensions
   - Use relative units (em, rem, %) instead of absolute (px)
   - Test across different screen sizes

4. **CSS Property Support**
   ```css
   /* Recommended CSS for EPUB compatibility */
   body {
     font-size: 1em;
     line-height: 1.5;
     margin: 1em;
     text-align: justify;
     hyphens: auto;
     -webkit-hyphens: auto;
   }

   p {
     text-indent: 1.5em;
     margin: 0;
   }

   img {
     max-width: 100%;
     height: auto;
   }
   ```

---

### 2.4 Pagination vs Scrolling

**Source:** UX research, industry discussions, EPUB 3 specification

#### Pagination Benefits

1. **Cognitive Advantages**
   - Memory chunking - manageable cognitive units
   - Clear sense of progress
   - Natural signposts for stopping points
   - Familiar to paper book readers

2. **Technical Benefits**
   - Better for e-ink displays (slow refresh rates)
   - Immediate page turns (no blank screens)
   - Natural swiping gesture
   - Better performance on low-end devices

3. **Implementation (epub_view)**
   ```dart
   EpubView(
     controller: _epubController,
     builders: EpubViewBuilders<DefaultBuilderOptions>(
       options: const DefaultBuilderOptions(
         // Paginated flow
       ),
     ),
   )
   ```

4. **Implementation (flutter_epub_viewer)**
   ```dart
   EpubViewer.setConfig(
     EpubDisplaySettings(
       flow: EpubFlow.paginated,
       snap: true,
     ),
   );
   ```

#### Scrolling Benefits

1. **User Control**
   - Fine-grained reading position control
   - Natural touch interaction
   - Prevents accidental page turns
   - Keep difficult passages together on screen

2. **Technical Benefits**
   - More precise bookmarking
   - Better for complex content layout
   - Eliminates scaling issues across devices
   - Smoother experience on modern devices

3. **Implementation**
   ```dart
   EpubViewer.setConfig(
     EpubDisplaySettings(
       flow: EpubFlow.scrolled,
       snap: false,
     ),
   );
   ```

#### Recommendation

**Best Practice:** Provide both options and let users choose based on preference. Default to pagination for fiction/linear reading, scrolling for textbooks/reference material.

```dart
enum ReadingMode { paginated, scrolled }

class ReadingPreferences {
  ReadingMode mode = ReadingMode.paginated;

  void toggleMode() {
    mode = mode == ReadingMode.paginated
      ? ReadingMode.scrolled
      : ReadingMode.paginated;
    // Update EPUB viewer settings
  }
}
```

---

### 2.5 Night Mode / Dark Theme Implementation

**Sources:** Flutter official documentation, community best practices

#### Implementation Strategy

1. **Use ThemeData System**
   ```dart
   MaterialApp(
     theme: ThemeData.light(),
     darkTheme: ThemeData.dark(),
     themeMode: _themeMode, // ThemeMode.system, .light, or .dark
   )
   ```

2. **EPUB-Specific Theme Settings**
   ```dart
   class EpubTheme {
     final Color backgroundColor;
     final Color textColor;
     final Color linkColor;

     const EpubTheme({
       required this.backgroundColor,
       required this.textColor,
       required this.linkColor,
     });

     static const light = EpubTheme(
       backgroundColor: Color(0xFFFFFFF5), // Sepia-tinted
       textColor: Color(0xFF222222),
       linkColor: Color(0xFF0066CC),
     );

     static const dark = EpubTheme(
       backgroundColor: Color(0xFF1E1E1E),
       textColor: Color(0xFFE0E0E0),
       linkColor: Color(0xFF66B3FF),
     );

     static const sepia = EpubTheme(
       backgroundColor: Color(0xFFFBF0D9),
       textColor: Color(0xFF5F4B32),
       linkColor: Color(0xFF8B6914),
     );
   }
   ```

3. **Persist Theme Preference**
   ```dart
   import 'package:shared_preferences/shared_preferences.dart';

   class ThemePreferences {
     static const THEME_KEY = 'theme_preference';

     Future<void> saveTheme(ThemeMode mode) async {
       final prefs = await SharedPreferences.getInstance();
       await prefs.setInt(THEME_KEY, mode.index);
     }

     Future<ThemeMode> getTheme() async {
       final prefs = await SharedPreferences.getInstance();
       final index = prefs.getInt(THEME_KEY) ?? ThemeMode.system.index;
       return ThemeMode.values[index];
     }
   }
   ```

4. **System Theme Detection**
   ```dart
   // Default to system theme
   ThemeMode _themeMode = ThemeMode.system;

   // Listen to system changes
   @override
   void didChangePlatformBrightness() {
     if (_themeMode == ThemeMode.system) {
       setState(() {}); // Rebuild with new system brightness
     }
   }
   ```

5. **Smooth Theme Transitions**
   ```dart
   AnimatedTheme(
     data: _currentTheme,
     duration: Duration(milliseconds: 300),
     curve: Curves.easeInOut,
     child: EpubView(controller: _epubController),
   )
   ```

6. **Package-Specific Implementation**

   **For flutter_epub_viewer:**
   ```dart
   EpubViewer.setConfig(
     EpubDisplaySettings(
       nightMode: true, // Enable night mode
     ),
   );
   ```

   **For vocsy_epub_viewer:**
   ```dart
   VocsyEpub.setConfig(
     nightMode: true,
     themeColor: Colors.blue,
   );
   ```

#### Best Practices

1. **Testing**
   - Test on multiple devices and OS versions
   - Verify text legibility in all themes
   - Ensure proper image/icon visibility
   - Test button and UI element contrast

2. **User Options**
   - Provide at least 3 themes: Light, Dark, Sepia
   - Include system default option
   - Allow brightness adjustment independent of theme

3. **Default Behavior**
   - Default to ThemeMode.system (respects user device preference)
   - Persist user's manual theme selection

---

## 3. Reading Progress Tracking and Bookmarks

**Key Concept:** CFI (Canonical Fragment Identifier) - EPUB industry standard

### 3.1 Understanding CFI

**Authority:** IDPF/W3C EPUB Canonical Fragment Identifier Specification

#### What is CFI?

CFI defines a standardized method for referencing arbitrary content within an EPUB Publication through fragment identifiers. It provides:

- Interoperability across different reading systems
- Precise location identification without document modification
- Resilience to document revisions
- Efficient identifier resolution

#### CFI Structure

```
epubcfi(/6/14!/4/2/4/1:0)
│       │  │  └─ Path to element and offset
│       │  └─ Spine item reference
│       └─ Path from package document
└─ Identifier prefix
```

**Components:**
1. **Prefix:** `epubcfi` identifies the reference method
2. **Path:** Sequence of structural steps separated by `/`
3. **Offset:** Optional character position, temporal, or spatial fragment
4. **Assertions:** Substrings in brackets for robustness

---

### 3.2 Reading Progress Implementation

#### Using epub_view

```dart
class EpubReaderPage extends StatefulWidget {
  @override
  _EpubReaderPageState createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  late EpubController _epubController;
  String? _lastSavedCfi;

  @override
  void initState() {
    super.initState();
    _loadLastPosition();
  }

  Future<void> _loadLastPosition() async {
    // Load saved reading position from database/preferences
    final savedCfi = await _getLastReadingPosition();

    _epubController = EpubController(
      document: EpubDocument.openAsset('assets/book.epub'),
      epubCfi: savedCfi, // Resume from last position
    );
  }

  Future<String?> _getLastReadingPosition() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_cfi_position');
  }

  Future<void> _saveReadingPosition() async {
    final currentCfi = _epubController.generateEpubCfi();
    if (currentCfi != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_cfi_position', currentCfi);
      _lastSavedCfi = currentCfi;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EpubView(
        controller: _epubController,
        onChapterChanged: (chapter) {
          // Save progress when chapter changes
          _saveReadingPosition();
        },
      ),
    );
  }

  @override
  void dispose() {
    _saveReadingPosition(); // Save on exit
    _epubController.dispose();
    super.dispose();
  }
}
```

#### Using flutter_epub_viewer

```dart
class EpubReaderPage extends StatefulWidget {
  @override
  _EpubReaderPageState createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  late EpubController _epubController;

  @override
  void initState() {
    super.initState();
    _epubController = EpubController();
    _loadBook();
  }

  Future<void> _loadBook() async {
    final savedCfi = await _getLastReadingPosition();

    await _epubController.loadBook(
      EpubDocument.fromAssets('assets/book.epub'),
      lastLocation: EpubLocation.fromCfi(savedCfi),
    );

    // Listen to location changes
    _epubController.onRelocated.listen((location) {
      _saveReadingPosition(location.cfi);
    });
  }

  Future<String?> _getLastReadingPosition() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_cfi_position');
  }

  Future<void> _saveReadingPosition(String cfi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_cfi_position', cfi);
  }
}
```

---

### 3.3 Bookmark Implementation

#### Data Model

```dart
class Bookmark {
  final String id;
  final String bookId;
  final String cfi;
  final String chapterTitle;
  final String snippet; // Text excerpt
  final DateTime createdAt;
  final String? note;

  Bookmark({
    required this.id,
    required this.bookId,
    required this.cfi,
    required this.chapterTitle,
    required this.snippet,
    required this.createdAt,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookId': bookId,
    'cfi': cfi,
    'chapterTitle': chapterTitle,
    'snippet': snippet,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
  };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    id: json['id'],
    bookId: json['bookId'],
    cfi: json['cfi'],
    chapterTitle: json['chapterTitle'],
    snippet: json['snippet'],
    createdAt: DateTime.parse(json['createdAt']),
    note: json['note'],
  );
}
```

#### Bookmark Manager

```dart
class BookmarkManager {
  final Database db; // SQLite or other database

  Future<void> addBookmark({
    required String bookId,
    required String cfi,
    required String chapterTitle,
    required String snippet,
    String? note,
  }) async {
    final bookmark = Bookmark(
      id: Uuid().v4(),
      bookId: bookId,
      cfi: cfi,
      chapterTitle: chapterTitle,
      snippet: snippet,
      createdAt: DateTime.now(),
      note: note,
    );

    await db.insert('bookmarks', bookmark.toJson());
  }

  Future<List<Bookmark>> getBookmarks(String bookId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'bookmarks',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => Bookmark.fromJson(map)).toList();
  }

  Future<void> deleteBookmark(String id) async {
    await db.delete(
      'bookmarks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateBookmarkNote(String id, String note) async {
    await db.update(
      'bookmarks',
      {'note': note},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
```

#### UI Integration

```dart
class BookmarkButton extends StatelessWidget {
  final EpubController controller;
  final BookmarkManager bookmarkManager;
  final String bookId;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.bookmark_add),
      onPressed: () async {
        final cfi = controller.generateEpubCfi();
        final chapter = controller.currentChapter;

        if (cfi != null && chapter != null) {
          await bookmarkManager.addBookmark(
            bookId: bookId,
            cfi: cfi,
            chapterTitle: chapter.title ?? 'Unknown Chapter',
            snippet: _getTextSnippet(controller),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bookmark added')),
          );
        }
      },
    );
  }

  String _getTextSnippet(EpubController controller) {
    // Extract current text (implementation depends on package)
    return 'Text snippet...';
  }
}
```

---

### 3.4 Progress Calculation

```dart
class ReadingProgress {
  final int currentPage;
  final int totalPages;
  final double percentage;
  final Duration estimatedTimeRemaining;

  ReadingProgress({
    required this.currentPage,
    required this.totalPages,
    required this.percentage,
    required this.estimatedTimeRemaining,
  });

  static ReadingProgress calculate({
    required EpubController controller,
    required int wordsPerMinute,
  }) {
    // Note: Exact implementation depends on package capabilities
    final currentPage = controller.currentValue?.position?.page ?? 0;
    final totalPages = controller.currentValue?.totalPages ?? 1;
    final percentage = (currentPage / totalPages) * 100;

    final remainingPages = totalPages - currentPage;
    final estimatedMinutes = (remainingPages * 250) ~/ wordsPerMinute; // Avg 250 words/page

    return ReadingProgress(
      currentPage: currentPage,
      totalPages: totalPages,
      percentage: percentage,
      estimatedTimeRemaining: Duration(minutes: estimatedMinutes),
    );
  }
}

// Display widget
class ProgressIndicator extends StatelessWidget {
  final ReadingProgress progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(value: progress.percentage / 100),
        SizedBox(height: 8),
        Text(
          'Page ${progress.currentPage} of ${progress.totalPages} '
          '(${progress.percentage.toStringAsFixed(1)}%)',
        ),
        Text(
          'Estimated time remaining: ${_formatDuration(progress.estimatedTimeRemaining)}',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }
}
```

---

## 4. Annotations and Highlighting

### 4.1 Using epub_pro with CFIAnnotationManager

**Authority:** epub_pro package documentation

#### Setup

```dart
import 'package:epub_pro/epub_pro.dart';

class AnnotationService {
  late CFIAnnotationManager _annotationManager;

  Future<void> initialize(String bookId, BookRef bookRef) async {
    _annotationManager = CFIAnnotationManager(
      bookId: bookId,
      bookRef: bookRef,
      storage: AnnotationStorageImpl(),
    );
  }

  // Create highlight
  Future<Highlight> createHighlight({
    required String startCFI,
    required String endCFI,
    required String selectedText,
    required String color,
    String? note,
  }) async {
    return await _annotationManager.createHighlight(
      startCFI: CFI(startCFI),
      endCFI: CFI(endCFI),
      selectedText: selectedText,
      color: color,
      note: note,
    );
  }

  // Create note
  Future<Note> createNote({
    required String cfi,
    required String text,
    String? title,
    String? category,
  }) async {
    return await _annotationManager.createNote(
      cfi: CFI(cfi),
      text: text,
      title: title,
      category: category,
    );
  }

  // Create bookmark
  Future<Bookmark> createBookmark({
    required String cfi,
    required String title,
    String? description,
  }) async {
    return await _annotationManager.createBookmark(
      cfi: CFI(cfi),
      title: title,
      description: description,
    );
  }

  // Retrieve all annotations
  Future<List<Annotation>> getAllAnnotations() async {
    return await _annotationManager.getAllAnnotations();
  }

  // Delete annotation
  Future<void> deleteAnnotation(String annotationId) async {
    await _annotationManager.deleteAnnotation(annotationId);
  }

  // Update annotation
  Future<void> updateAnnotation(Annotation annotation) async {
    await _annotationManager.updateAnnotation(annotation);
  }
}
```

#### Storage Implementation

```dart
class AnnotationStorageImpl implements AnnotationStorage {
  final Database db;

  @override
  Future<void> saveAnnotation(Annotation annotation) async {
    await db.insert('annotations', annotation.toJson());
  }

  @override
  Future<List<Annotation>> getAnnotations(String bookId) async {
    final results = await db.query(
      'annotations',
      where: 'bookId = ?',
      whereArgs: [bookId],
    );
    return results.map((json) => Annotation.fromJson(json)).toList();
  }

  @override
  Future<void> deleteAnnotation(String id) async {
    await db.delete('annotations', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> updateAnnotation(Annotation annotation) async {
    await db.update(
      'annotations',
      annotation.toJson(),
      where: 'id = ?',
      whereArgs: [annotation.id],
    );
  }
}
```

---

### 4.2 Using flutter_epub_viewer for Highlights

```dart
class EpubReaderPage extends StatefulWidget {
  @override
  _EpubReaderPageState createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  late EpubController _epubController;
  final List<HighlightData> _highlights = [];

  @override
  void initState() {
    super.initState();
    _epubController = EpubController();
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    // Load saved highlights from database
    final savedHighlights = await _getHighlightsFromDb();

    for (final highlight in savedHighlights) {
      await _epubController.addHighlight(
        cfi: highlight.cfi,
        color: highlight.color,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EpubViewer(
        controller: _epubController,

        // Handle text selection
        onTextSelected: (EpubTextSelection selection) {
          _showHighlightOptions(selection);
        },

        // Handle annotation clicks
        onAnnotationClicked: (String cfi) {
          _showAnnotationDetails(cfi);
        },

        // Custom selection context menu
        selectionContextMenu: (EpubTextSelection selection) {
          return _buildSelectionMenu(selection);
        },
      ),
    );
  }

  void _showHighlightOptions(EpubTextSelection selection) {
    showModalBottomSheet(
      context: context,
      builder: (context) => HighlightColorPicker(
        onColorSelected: (color) async {
          // Add highlight
          await _epubController.addHighlight(
            cfi: selection.cfi,
            color: color,
          );

          // Save to database
          await _saveHighlight(HighlightData(
            cfi: selection.cfi,
            color: color,
            text: selection.text,
            createdAt: DateTime.now(),
          ));

          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildSelectionMenu(EpubTextSelection selection) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.highlight),
            onPressed: () => _showHighlightOptions(selection),
            tooltip: 'Highlight',
          ),
          IconButton(
            icon: Icon(Icons.note_add),
            onPressed: () => _addNote(selection),
            tooltip: 'Add Note',
          ),
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: () => _copyText(selection.text),
            tooltip: 'Copy',
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareText(selection.text),
            tooltip: 'Share',
          ),
        ],
      ),
    );
  }

  Future<void> _addNote(EpubTextSelection selection) async {
    final note = await showDialog<String>(
      context: context,
      builder: (context) => NoteDialog(),
    );

    if (note != null) {
      await _saveNote(NoteData(
        cfi: selection.cfi,
        text: selection.text,
        note: note,
        createdAt: DateTime.now(),
      ));
    }
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Text copied to clipboard')),
    );
  }

  // Database operations
  Future<List<HighlightData>> _getHighlightsFromDb() async {
    // Implementation depends on your database choice
    return [];
  }

  Future<void> _saveHighlight(HighlightData highlight) async {
    // Save to database
  }

  Future<void> _saveNote(NoteData note) async {
    // Save to database
  }
}
```

#### Highlight Color Picker Widget

```dart
class HighlightColorPicker extends StatelessWidget {
  final Function(String) onColorSelected;

  final List<HighlightColor> colors = [
    HighlightColor('Yellow', '#FFEB3B'),
    HighlightColor('Green', '#4CAF50'),
    HighlightColor('Blue', '#2196F3'),
    HighlightColor('Pink', '#E91E63'),
    HighlightColor('Orange', '#FF9800'),
  ];

  HighlightColorPicker({required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Choose highlight color',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: colors.map((color) {
              return GestureDetector(
                onTap: () => onColorSelected(color.hex),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.hex.substring(1), radix: 16) + 0xFF000000),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      color.name[0],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class HighlightColor {
  final String name;
  final String hex;
  HighlightColor(this.name, this.hex);
}
```

---

### 4.3 Annotation Data Models

```dart
// Base annotation class
abstract class Annotation {
  final String id;
  final String bookId;
  final String cfi;
  final DateTime createdAt;
  final DateTime? modifiedAt;

  Annotation({
    required this.id,
    required this.bookId,
    required this.cfi,
    required this.createdAt,
    this.modifiedAt,
  });

  Map<String, dynamic> toJson();
}

// Highlight
class HighlightData extends Annotation {
  final String text;
  final String color;
  final String? note;

  HighlightData({
    String? id,
    required String bookId,
    required String cfi,
    required this.text,
    required this.color,
    this.note,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) : super(
    id: id ?? Uuid().v4(),
    bookId: bookId,
    cfi: cfi,
    createdAt: createdAt ?? DateTime.now(),
    modifiedAt: modifiedAt,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'bookId': bookId,
    'cfi': cfi,
    'text': text,
    'color': color,
    'note': note,
    'type': 'highlight',
    'createdAt': createdAt.toIso8601String(),
    'modifiedAt': modifiedAt?.toIso8601String(),
  };

  factory HighlightData.fromJson(Map<String, dynamic> json) => HighlightData(
    id: json['id'],
    bookId: json['bookId'],
    cfi: json['cfi'],
    text: json['text'],
    color: json['color'],
    note: json['note'],
    createdAt: DateTime.parse(json['createdAt']),
    modifiedAt: json['modifiedAt'] != null
      ? DateTime.parse(json['modifiedAt'])
      : null,
  );
}

// Note
class NoteData extends Annotation {
  final String text;
  final String note;
  final String? title;

  NoteData({
    String? id,
    required String bookId,
    required String cfi,
    required this.text,
    required this.note,
    this.title,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) : super(
    id: id ?? Uuid().v4(),
    bookId: bookId,
    cfi: cfi,
    createdAt: createdAt ?? DateTime.now(),
    modifiedAt: modifiedAt,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'bookId': bookId,
    'cfi': cfi,
    'text': text,
    'note': note,
    'title': title,
    'type': 'note',
    'createdAt': createdAt.toIso8601String(),
    'modifiedAt': modifiedAt?.toIso8601String(),
  };

  factory NoteData.fromJson(Map<String, dynamic> json) => NoteData(
    id: json['id'],
    bookId: json['bookId'],
    cfi: json['cfi'],
    text: json['text'],
    note: json['note'],
    title: json['title'],
    createdAt: DateTime.parse(json['createdAt']),
    modifiedAt: json['modifiedAt'] != null
      ? DateTime.parse(json['modifiedAt'])
      : null,
  );
}
```

---

## 5. Table of Contents Navigation

### 5.1 Using epub_view

```dart
class EpubReaderPage extends StatefulWidget {
  @override
  _EpubReaderPageState createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  late EpubController _epubController;

  @override
  void initState() {
    super.initState();
    _epubController = EpubController(
      document: EpubDocument.openAsset('assets/book.epub'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: EpubViewActualChapter(
          controller: _epubController,
          builder: (chapterValue) => Text(
            chapterValue?.chapter?.Title?.replaceAll('\n', '').trim() ?? '',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
      drawer: Drawer(
        child: EpubViewTableOfContents(
          controller: _epubController,
          // Optional: Custom item builder
          itemBuilder: (context, index, chapter, itemCount) {
            return ListTile(
              title: Text(chapter.Title ?? 'Chapter $index'),
              subtitle: chapter.SubChapters?.isNotEmpty == true
                ? Text('${chapter.SubChapters!.length} sub-chapters')
                : null,
              onTap: () {
                _epubController.gotoEpubCfi(chapter.Anchor!);
                Navigator.pop(context); // Close drawer
              },
            );
          },
        ),
      ),
      body: EpubView(
        controller: _epubController,
      ),
    );
  }

  @override
  void dispose() {
    _epubController.dispose();
    super.dispose();
  }
}
```

---

### 5.2 Custom Table of Contents Widget

```dart
class CustomTableOfContents extends StatelessWidget {
  final List<EpubChapter> chapters;
  final EpubController controller;
  final Function(String)? onChapterSelected;

  const CustomTableOfContents({
    required this.chapters,
    required this.controller,
    this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return ExpansionTile(
          title: Text(
            chapter.Title ?? 'Chapter ${index + 1}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          leading: Icon(Icons.book_outlined),
          children: [
            if (chapter.SubChapters?.isNotEmpty == true)
              ...chapter.SubChapters!.map((subChapter) {
                return ListTile(
                  title: Text(
                    subChapter.Title ?? 'Sub-chapter',
                    style: TextStyle(fontSize: 14),
                  ),
                  leading: SizedBox(width: 20),
                  trailing: Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    if (subChapter.Anchor != null) {
                      controller.gotoEpubCfi(subChapter.Anchor!);
                      onChapterSelected?.call(subChapter.Anchor!);
                    }
                  },
                );
              }).toList(),
          ],
          onExpansionChanged: (expanded) {
            if (expanded && chapter.Anchor != null) {
              controller.gotoEpubCfi(chapter.Anchor!);
              onChapterSelected?.call(chapter.Anchor!);
            }
          },
        );
      },
    );
  }
}
```

---

### 5.3 Enhanced TOC with Search

```dart
class SearchableTableOfContents extends StatefulWidget {
  final List<EpubChapter> chapters;
  final EpubController controller;

  @override
  _SearchableTableOfContentsState createState() =>
    _SearchableTableOfContentsState();
}

class _SearchableTableOfContentsState extends State<SearchableTableOfContents> {
  String _searchQuery = '';
  List<EpubChapter> _filteredChapters = [];

  @override
  void initState() {
    super.initState();
    _filteredChapters = widget.chapters;
  }

  void _filterChapters(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredChapters = widget.chapters;
      } else {
        _filteredChapters = widget.chapters.where((chapter) {
          final title = chapter.Title?.toLowerCase() ?? '';
          return title.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search chapters...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: _filterChapters,
          ),
        ),
        Expanded(
          child: CustomTableOfContents(
            chapters: _filteredChapters,
            controller: widget.controller,
            onChapterSelected: (_) => Navigator.pop(context),
          ),
        ),
      ],
    );
  }
}
```

---

## 6. Font Customization

### 6.1 Font Size, Family, and Line Spacing

**Sources:** Flutter official typography documentation, TextStyle API

#### Implementation

```dart
class FontSettings {
  double fontSize;
  String fontFamily;
  double lineHeight;
  double letterSpacing;

  FontSettings({
    this.fontSize = 16.0,
    this.fontFamily = 'Default',
    this.lineHeight = 1.5,
    this.letterSpacing = 0.5,
  });

  TextStyle toTextStyle({Color? color}) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily == 'Default' ? null : fontFamily,
      height: lineHeight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  StrutStyle toStrutStyle() {
    return StrutStyle(
      fontSize: fontSize,
      height: lineHeight,
      forceStrutHeight: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'fontSize': fontSize,
    'fontFamily': fontFamily,
    'lineHeight': lineHeight,
    'letterSpacing': letterSpacing,
  };

  factory FontSettings.fromJson(Map<String, dynamic> json) => FontSettings(
    fontSize: json['fontSize'] ?? 16.0,
    fontFamily: json['fontFamily'] ?? 'Default',
    lineHeight: json['lineHeight'] ?? 1.5,
    letterSpacing: json['letterSpacing'] ?? 0.5,
  );
}
```

---

### 6.2 Font Settings UI

```dart
class FontSettingsPanel extends StatefulWidget {
  final FontSettings initialSettings;
  final Function(FontSettings) onSettingsChanged;

  @override
  _FontSettingsPanelState createState() => _FontSettingsPanelState();
}

class _FontSettingsPanelState extends State<FontSettingsPanel> {
  late FontSettings _settings;

  final List<String> _fontFamilies = [
    'Default',
    'Serif',
    'Sans Serif',
    'Monospace',
    'Georgia',
    'Palatino',
    'Times New Roman',
    'Book Antiqua',
    'Bookerly', // Amazon Kindle font
  ];

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  void _updateSettings() {
    widget.onSettingsChanged(_settings);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Font Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 24),

          // Font Size
          _buildSetting(
            label: 'Font Size',
            value: _settings.fontSize.toStringAsFixed(0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: _settings.fontSize > 8 ? () {
                    setState(() {
                      _settings.fontSize = (_settings.fontSize - 1).clamp(8.0, 32.0);
                      _updateSettings();
                    });
                  } : null,
                ),
                Expanded(
                  child: Slider(
                    value: _settings.fontSize,
                    min: 8,
                    max: 32,
                    divisions: 24,
                    label: _settings.fontSize.toStringAsFixed(0),
                    onChanged: (value) {
                      setState(() {
                        _settings.fontSize = value;
                        _updateSettings();
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _settings.fontSize < 32 ? () {
                    setState(() {
                      _settings.fontSize = (_settings.fontSize + 1).clamp(8.0, 32.0);
                      _updateSettings();
                    });
                  } : null,
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Font Family
          _buildSetting(
            label: 'Font Family',
            value: _settings.fontFamily,
            child: DropdownButton<String>(
              isExpanded: true,
              value: _settings.fontFamily,
              items: _fontFamilies.map((font) {
                return DropdownMenuItem(
                  value: font,
                  child: Text(
                    font,
                    style: TextStyle(
                      fontFamily: font == 'Default' ? null : font,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _settings.fontFamily = value;
                    _updateSettings();
                  });
                }
              },
            ),
          ),

          SizedBox(height: 16),

          // Line Height
          _buildSetting(
            label: 'Line Spacing',
            value: _settings.lineHeight.toStringAsFixed(1),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: _settings.lineHeight > 1.0 ? () {
                    setState(() {
                      _settings.lineHeight = (_settings.lineHeight - 0.1).clamp(1.0, 3.0);
                      _updateSettings();
                    });
                  } : null,
                ),
                Expanded(
                  child: Slider(
                    value: _settings.lineHeight,
                    min: 1.0,
                    max: 3.0,
                    divisions: 20,
                    label: _settings.lineHeight.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _settings.lineHeight = value;
                        _updateSettings();
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _settings.lineHeight < 3.0 ? () {
                    setState(() {
                      _settings.lineHeight = (_settings.lineHeight + 0.1).clamp(1.0, 3.0);
                      _updateSettings();
                    });
                  } : null,
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Letter Spacing
          _buildSetting(
            label: 'Letter Spacing',
            value: _settings.letterSpacing.toStringAsFixed(1),
            child: Slider(
              value: _settings.letterSpacing,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              label: _settings.letterSpacing.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _settings.letterSpacing = value;
                  _updateSettings();
                });
              },
            ),
          ),

          SizedBox(height: 24),

          // Preview
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'The quick brown fox jumps over the lazy dog. This is a preview of your font settings.',
              style: _settings.toTextStyle(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetting({
    required String label,
    required String value,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
            Text(value, style: TextStyle(color: Colors.grey)),
          ],
        ),
        SizedBox(height: 8),
        child,
      ],
    );
  }
}
```

---

### 6.3 Persisting Font Settings

```dart
class FontPreferences {
  static const PREFS_KEY = 'font_settings';

  Future<void> save(FontSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PREFS_KEY, jsonEncode(settings.toJson()));
  }

  Future<FontSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(PREFS_KEY);

    if (jsonString != null) {
      return FontSettings.fromJson(jsonDecode(jsonString));
    }

    return FontSettings(); // Return default settings
  }
}
```

---

### 6.4 Adding Custom Fonts

**pubspec.yaml**

```yaml
flutter:
  fonts:
    - family: Bookerly
      fonts:
        - asset: fonts/Bookerly-Regular.ttf
        - asset: fonts/Bookerly-Bold.ttf
          weight: 700
        - asset: fonts/Bookerly-Italic.ttf
          style: italic

    - family: OpenDyslexic
      fonts:
        - asset: fonts/OpenDyslexic-Regular.otf
        - asset: fonts/OpenDyslexic-Bold.otf
          weight: 700

    - family: Atkinson
      fonts:
        - asset: fonts/Atkinson-Hyperlegible-Regular.ttf
        - asset: fonts/Atkinson-Hyperlegible-Bold.ttf
          weight: 700
```

---

## 7. Offline Storage and Library Management

### 7.1 Database Options

**Authority:** Flutter community best practices, package documentation

#### Option 1: SQLite (sqflite) - Recommended for Complex Queries

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('epub_library.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT,
        coverPath TEXT,
        filePath TEXT NOT NULL,
        fileSize INTEGER,
        lastOpenedAt INTEGER,
        currentCfi TEXT,
        progress REAL DEFAULT 0.0,
        isFavorite INTEGER DEFAULT 0,
        addedAt INTEGER NOT NULL,
        metadata TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmarks (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        cfi TEXT NOT NULL,
        chapterTitle TEXT,
        snippet TEXT,
        note TEXT,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE highlights (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        cfi TEXT NOT NULL,
        text TEXT NOT NULL,
        color TEXT NOT NULL,
        note TEXT,
        createdAt INTEGER NOT NULL,
        modifiedAt INTEGER,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        cfi TEXT NOT NULL,
        text TEXT NOT NULL,
        note TEXT NOT NULL,
        title TEXT,
        createdAt INTEGER NOT NULL,
        modifiedAt INTEGER,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE collections (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE collection_books (
        collectionId TEXT NOT NULL,
        bookId TEXT NOT NULL,
        addedAt INTEGER NOT NULL,
        PRIMARY KEY (collectionId, bookId),
        FOREIGN KEY (collectionId) REFERENCES collections (id) ON DELETE CASCADE,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_books_lastOpened ON books(lastOpenedAt)');
    await db.execute('CREATE INDEX idx_bookmarks_bookId ON bookmarks(bookId)');
    await db.execute('CREATE INDEX idx_highlights_bookId ON highlights(bookId)');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
```

---

#### Option 2: Hive - Recommended for Simplicity and Performance

```dart
import 'package:hive_flutter/hive_flutter.dart';

// Book Model
@HiveType(typeId: 0)
class Book extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? author;

  @HiveField(3)
  String? coverPath;

  @HiveField(4)
  String filePath;

  @HiveField(5)
  int? fileSize;

  @HiveField(6)
  DateTime? lastOpenedAt;

  @HiveField(7)
  String? currentCfi;

  @HiveField(8)
  double progress;

  @HiveField(9)
  bool isFavorite;

  @HiveField(10)
  DateTime addedAt;

  @HiveField(11)
  Map<String, dynamic>? metadata;

  Book({
    required this.id,
    required this.title,
    this.author,
    this.coverPath,
    required this.filePath,
    this.fileSize,
    this.lastOpenedAt,
    this.currentCfi,
    this.progress = 0.0,
    this.isFavorite = false,
    required this.addedAt,
    this.metadata,
  });
}

// Initialization
class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(BookAdapter());
    Hive.registerAdapter(BookmarkAdapter());
    Hive.registerAdapter(HighlightDataAdapter());

    // Open boxes
    await Hive.openBox<Book>('books');
    await Hive.openBox<Bookmark>('bookmarks');
    await Hive.openBox<HighlightData>('highlights');
  }

  static Box<Book> get booksBox => Hive.box<Book>('books');
  static Box<Bookmark> get bookmarksBox => Hive.box<Bookmark>('bookmarks');
  static Box<HighlightData> get highlightsBox => Hive.box<HighlightData>('highlights');
}
```

---

### 7.2 Library Manager Implementation

```dart
class LibraryManager {
  final Database db;

  // Add book to library
  Future<void> addBook(Book book) async {
    await db.insert(
      'books',
      book.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all books
  Future<List<Book>> getAllBooks({
    String? sortBy = 'lastOpenedAt',
    bool descending = true,
  }) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      orderBy: '$sortBy ${descending ? 'DESC' : 'ASC'}',
    );

    return maps.map((map) => Book.fromJson(map)).toList();
  }

  // Get recently opened books
  Future<List<Book>> getRecentBooks({int limit = 10}) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'lastOpenedAt IS NOT NULL',
      orderBy: 'lastOpenedAt DESC',
      limit: limit,
    );

    return maps.map((map) => Book.fromJson(map)).toList();
  }

  // Get favorite books
  Future<List<Book>> getFavoriteBooks() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'title ASC',
    );

    return maps.map((map) => Book.fromJson(map)).toList();
  }

  // Search books
  Future<List<Book>> searchBooks(String query) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'title LIKE ? OR author LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );

    return maps.map((map) => Book.fromJson(map)).toList();
  }

  // Update book
  Future<void> updateBook(Book book) async {
    await db.update(
      'books',
      book.toJson(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  // Update reading progress
  Future<void> updateProgress({
    required String bookId,
    required String cfi,
    required double progress,
  }) async {
    await db.update(
      'books',
      {
        'currentCfi': cfi,
        'progress': progress,
        'lastOpenedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  // Toggle favorite
  Future<void> toggleFavorite(String bookId) async {
    final book = await getBook(bookId);
    if (book != null) {
      await db.update(
        'books',
        {'isFavorite': book.isFavorite ? 0 : 1},
        where: 'id = ?',
        whereArgs: [bookId],
      );
    }
  }

  // Delete book
  Future<void> deleteBook(String bookId) async {
    await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [bookId],
    );

    // Delete associated file if needed
    // File(book.filePath).deleteSync();
  }

  // Get book by ID
  Future<Book?> getBook(String bookId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [bookId],
    );

    if (maps.isNotEmpty) {
      return Book.fromJson(maps.first);
    }
    return null;
  }

  // Get library statistics
  Future<LibraryStats> getStats() async {
    final totalBooks = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM books'),
    ) ?? 0;

    final favoriteCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM books WHERE isFavorite = 1'),
    ) ?? 0;

    final totalHighlights = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM highlights'),
    ) ?? 0;

    final totalBookmarks = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM bookmarks'),
    ) ?? 0;

    return LibraryStats(
      totalBooks: totalBooks,
      favoriteCount: favoriteCount,
      totalHighlights: totalHighlights,
      totalBookmarks: totalBookmarks,
    );
  }
}

class LibraryStats {
  final int totalBooks;
  final int favoriteCount;
  final int totalHighlights;
  final int totalBookmarks;

  LibraryStats({
    required this.totalBooks,
    required this.favoriteCount,
    required this.totalHighlights,
    required this.totalBookmarks,
  });
}
```

---

### 7.3 File Management

```dart
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FileManager {
  // Get app documents directory
  static Future<Directory> getBooksDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${appDir.path}/books');

    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }

    return booksDir;
  }

  // Get covers directory
  static Future<Directory> getCoversDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory('${appDir.path}/covers');

    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }

    return coversDir;
  }

  // Import EPUB file
  static Future<String> importEpub(File sourceFile) async {
    final booksDir = await getBooksDirectory();
    final fileName = basename(sourceFile.path);
    final destinationPath = '${booksDir.path}/$fileName';

    // Copy file to app directory
    await sourceFile.copy(destinationPath);

    return destinationPath;
  }

  // Extract cover image
  static Future<String?> extractCover(String epubPath) async {
    try {
      final bytes = await File(epubPath).readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);

      if (epubBook.CoverImage != null) {
        final coversDir = await getCoversDirectory();
        final bookId = basename(epubPath).replaceAll('.epub', '');
        final coverPath = '${coversDir.path}/$bookId.jpg';

        final coverFile = File(coverPath);
        await coverFile.writeAsBytes(epubBook.CoverImage!);

        return coverPath;
      }
    } catch (e) {
      print('Error extracting cover: $e');
    }

    return null;
  }

  // Parse EPUB metadata
  static Future<BookMetadata> parseMetadata(String epubPath) async {
    final bytes = await File(epubPath).readAsBytes();
    final epubBook = await EpubReader.readBook(bytes);

    return BookMetadata(
      title: epubBook.Title ?? 'Unknown Title',
      author: epubBook.Author ?? 'Unknown Author',
      publisher: epubBook.Publisher,
      language: epubBook.Language,
      subjects: epubBook.Subjects,
      description: epubBook.Description,
    );
  }

  // Get file size
  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    return await file.length();
  }

  // Delete book file
  static Future<void> deleteBookFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Calculate total storage used
  static Future<int> getTotalStorageUsed() async {
    final booksDir = await getBooksDirectory();
    final coversDir = await getCoversDirectory();

    int totalSize = 0;

    // Calculate books size
    await for (var entity in booksDir.list()) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    // Calculate covers size
    await for (var entity in coversDir.list()) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }
}

class BookMetadata {
  final String title;
  final String author;
  final String? publisher;
  final String? language;
  final List<String>? subjects;
  final String? description;

  BookMetadata({
    required this.title,
    required this.author,
    this.publisher,
    this.language,
    this.subjects,
    this.description,
  });
}
```

---

### 7.4 Collections/Categories Management

```dart
class CollectionManager {
  final Database db;

  // Create collection
  Future<void> createCollection({
    required String name,
    String? description,
  }) async {
    await db.insert('collections', {
      'id': Uuid().v4(),
      'name': name,
      'description': description,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Get all collections
  Future<List<Collection>> getAllCollections() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'collections',
      orderBy: 'name ASC',
    );

    final collections = <Collection>[];
    for (final map in maps) {
      final bookCount = await getCollectionBookCount(map['id']);
      collections.add(Collection.fromJson({...map, 'bookCount': bookCount}));
    }

    return collections;
  }

  // Add book to collection
  Future<void> addBookToCollection(String collectionId, String bookId) async {
    await db.insert('collection_books', {
      'collectionId': collectionId,
      'bookId': bookId,
      'addedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Remove book from collection
  Future<void> removeBookFromCollection(String collectionId, String bookId) async {
    await db.delete(
      'collection_books',
      where: 'collectionId = ? AND bookId = ?',
      whereArgs: [collectionId, bookId],
    );
  }

  // Get books in collection
  Future<List<Book>> getCollectionBooks(String collectionId) async {
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT b.* FROM books b
      INNER JOIN collection_books cb ON b.id = cb.bookId
      WHERE cb.collectionId = ?
      ORDER BY b.title ASC
    ''', [collectionId]);

    return maps.map((map) => Book.fromJson(map)).toList();
  }

  // Get collection book count
  Future<int> getCollectionBookCount(String collectionId) async {
    return Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) FROM collection_books
      WHERE collectionId = ?
    ''', [collectionId])) ?? 0;
  }

  // Delete collection
  Future<void> deleteCollection(String collectionId) async {
    await db.delete(
      'collections',
      where: 'id = ?',
      whereArgs: [collectionId],
    );
  }
}

class Collection {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final int bookCount;

  Collection({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.bookCount = 0,
  });

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    bookCount: json['bookCount'] ?? 0,
  );
}
```

---

## 8. Performance Optimization for Large EPUBs

**Sources:** epub_pro documentation, Flutter performance guidelines, industry best practices

### 8.1 Lazy Loading Strategy

```dart
class OptimizedEpubController {
  final EpubController _controller;
  final int _preloadChaptersAhead = 2;
  final int _preloadChaptersBehind = 1;

  Set<int> _loadedChapters = {};

  OptimizedEpubController(this._controller) {
    _controller.onChapterChanged.listen(_onChapterChanged);
  }

  void _onChapterChanged(int chapterIndex) {
    _loadAdjacentChapters(chapterIndex);
    _unloadDistantChapters(chapterIndex);
  }

  Future<void> _loadAdjacentChapters(int currentIndex) async {
    // Preload ahead
    for (int i = 1; i <= _preloadChaptersAhead; i++) {
      final index = currentIndex + i;
      if (!_loadedChapters.contains(index)) {
        await _loadChapter(index);
        _loadedChapters.add(index);
      }
    }

    // Preload behind
    for (int i = 1; i <= _preloadChaptersBehind; i++) {
      final index = currentIndex - i;
      if (index >= 0 && !_loadedChapters.contains(index)) {
        await _loadChapter(index);
        _loadedChapters.add(index);
      }
    }
  }

  Future<void> _loadChapter(int index) async {
    // Implementation depends on package
    // This is conceptual
  }

  void _unloadDistantChapters(int currentIndex) {
    final chaptersToKeep = <int>{};

    // Keep current
    chaptersToKeep.add(currentIndex);

    // Keep adjacent
    for (int i = 1; i <= _preloadChaptersAhead; i++) {
      chaptersToKeep.add(currentIndex + i);
    }
    for (int i = 1; i <= _preloadChaptersBehind; i++) {
      if (currentIndex - i >= 0) {
        chaptersToKeep.add(currentIndex - i);
      }
    }

    // Unload others
    final chaptersToUnload = _loadedChapters.difference(chaptersToKeep);
    for (final index in chaptersToUnload) {
      _unloadChapter(index);
    }

    _loadedChapters = chaptersToKeep;
  }

  void _unloadChapter(int index) {
    // Implementation depends on package
    // Clear from memory
  }
}
```

---

### 8.2 Image Optimization

```dart
class EpubImageOptimizer {
  static const int MAX_CACHE_SIZE = 100 * 1024 * 1024; // 100 MB
  static const int MAX_IMAGE_DIMENSION = 1920;

  final ImageCache _imageCache;

  EpubImageOptimizer(this._imageCache) {
    _configureCache();
  }

  void _configureCache() {
    _imageCache.maximumSizeBytes = MAX_CACHE_SIZE;
    _imageCache.maximumSize = 1000; // Max number of images
  }

  Widget buildOptimizedImage(String imagePath) {
    return Image.asset(
      imagePath,
      cacheWidth: MAX_IMAGE_DIMENSION,
      cacheHeight: MAX_IMAGE_DIMENSION,
      fit: BoxFit.contain,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 200,
          color: Colors.grey[300],
          child: Icon(Icons.broken_image, size: 48),
        );
      },
    );
  }

  void clearCache() {
    _imageCache.clear();
    _imageCache.clearLiveImages();
  }

  void trimCache() {
    // Trim to 80% of max size
    final targetSize = (MAX_CACHE_SIZE * 0.8).toInt();
    while (_imageCache.currentSizeBytes > targetSize) {
      _imageCache.evict(null);
    }
  }
}
```

---

### 8.3 Memory Management

```dart
class EpubMemoryManager {
  Timer? _memoryCheckTimer;

  void startMonitoring() {
    _memoryCheckTimer = Timer.periodic(
      Duration(seconds: 30),
      (_) => _checkMemoryUsage(),
    );
  }

  void stopMonitoring() {
    _memoryCheckTimer?.cancel();
  }

  Future<void> _checkMemoryUsage() async {
    // This is conceptual - actual implementation depends on platform
    final memoryInfo = await _getMemoryInfo();

    if (memoryInfo.usagePercentage > 0.8) {
      _performMemoryCleanup();
    }
  }

  void _performMemoryCleanup() {
    // Clear image cache
    imageCache.clear();
    imageCache.clearLiveImages();

    // Trigger garbage collection (conceptual)
    // System.gc(); // Not available in Dart

    // Clear other caches if needed
  }

  Future<MemoryInfo> _getMemoryInfo() async {
    // Platform-specific implementation
    return MemoryInfo(usagePercentage: 0.5);
  }
}

class MemoryInfo {
  final double usagePercentage;
  MemoryInfo({required this.usagePercentage});
}
```

---

### 8.4 Chapter Splitting (epub_pro feature)

```dart
// When using epub_pro package
class LargeEpubHandler {
  Future<void> loadLargeEpub(String filePath) async {
    final epubDoc = await EpubDocument.fromFile(
      filePath,
      // Enable chapter splitting for large files
      splitChapters: true,
      maxChapterSize: 500 * 1024, // 500 KB per chunk
    );

    // epub_pro automatically handles splitting internally
    // This improves performance for large books
  }
}
```

---

### 8.5 Rendering Optimization

```dart
class OptimizedEpubView extends StatefulWidget {
  final EpubController controller;

  @override
  _OptimizedEpubViewState createState() => _OptimizedEpubViewState();
}

class _OptimizedEpubViewState extends State<OptimizedEpubView> {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      // Isolate repaints to this widget
      child: EpubView(
        controller: widget.controller,
        builders: EpubViewBuilders<DefaultBuilderOptions>(
          options: DefaultBuilderOptions(
            // Optimize text rendering
            textSelectionTheme: TextSelectionThemeData(
              selectionColor: Colors.blue.withOpacity(0.3),
            ),
          ),
          // Custom builders for performance
          chapterDividerBuilder: (_) => Divider(),

          // Lazy build paragraphs
          paragraphBuilder: (context, paragraph, chapterIndex, paragraphIndex) {
            return AutomaticKeepAliveClientMixin(
              child: Text(paragraph),
            );
          },
        ),
      ),
    );
  }
}

// Keep alive mixin for paragraphs
mixin AutomaticKeepAliveClientMixin<T extends StatefulWidget> on State<T> {
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context);
}
```

---

### 8.6 Best Practices Summary

1. **Use epub_pro for large files** - Performance improvements scale with file size
2. **Implement lazy loading** - Only load visible and adjacent chapters
3. **Optimize images** - Use cacheWidth/cacheHeight, limit dimensions
4. **Monitor memory** - Implement periodic cleanup
5. **Use RepaintBoundary** - Isolate repaints to improve performance
6. **Enable chapter splitting** - Break large chapters into manageable chunks
7. **Limit cache size** - Set reasonable limits for image and data caches
8. **Dispose properly** - Clean up controllers and resources when not needed

---

## 9. Text Selection and Copying

### 9.1 Using flutter_epub_viewer

```dart
class EpubReaderWithSelection extends StatefulWidget {
  @override
  _EpubReaderWithSelectionState createState() => _EpubReaderWithSelectionState();
}

class _EpubReaderWithSelectionState extends State<EpubReaderWithSelection> {
  late EpubController _epubController;
  EpubTextSelection? _currentSelection;

  @override
  void initState() {
    super.initState();
    _epubController = EpubController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EpubViewer(
        controller: _epubController,

        // Handle text selection changes
        onTextSelected: (EpubTextSelection selection) {
          setState(() {
            _currentSelection = selection;
          });
          _showSelectionToolbar(selection);
        },

        // Custom context menu
        selectionContextMenu: (EpubTextSelection selection) {
          return _buildContextMenu(selection);
        },
      ),
    );
  }

  void _showSelectionToolbar(EpubTextSelection selection) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SelectionActionSheet(
        selection: selection,
        onCopy: () => _copyText(selection.text),
        onHighlight: () => _highlightText(selection),
        onNote: () => _addNote(selection),
        onShare: () => _shareText(selection.text),
        onSearch: () => _searchText(selection.text),
      ),
    );
  }

  Widget _buildContextMenu(EpubTextSelection selection) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuButton(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () => _copyText(selection.text),
          ),
          _buildMenuButton(
            icon: Icons.highlight,
            label: 'Highlight',
            onTap: () => _highlightText(selection),
          ),
          _buildMenuButton(
            icon: Icons.note_add,
            label: 'Note',
            onTap: () => _addNote(selection),
          ),
          _buildMenuButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () => _shareText(selection.text),
          ),
          _buildMenuButton(
            icon: Icons.search,
            label: 'Search',
            onTap: () => _searchText(selection.text),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        onTap();
        Navigator.pop(context); // Close menu
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Text copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _highlightText(EpubTextSelection selection) async {
    final color = await _selectHighlightColor();
    if (color != null) {
      await _epubController.addHighlight(
        cfi: selection.cfi,
        color: color,
      );

      // Save to database
      await _saveHighlight(HighlightData(
        bookId: 'current_book_id',
        cfi: selection.cfi,
        text: selection.text,
        color: color,
        createdAt: DateTime.now(),
      ));
    }
  }

  Future<String?> _selectHighlightColor() async {
    return await showDialog<String>(
      context: context,
      builder: (context) => HighlightColorDialog(),
    );
  }

  Future<void> _addNote(EpubTextSelection selection) async {
    final note = await showDialog<String>(
      context: context,
      builder: (context) => NoteDialog(selectedText: selection.text),
    );

    if (note != null && note.isNotEmpty) {
      await _saveNote(NoteData(
        bookId: 'current_book_id',
        cfi: selection.cfi,
        text: selection.text,
        note: note,
        createdAt: DateTime.now(),
      ));
    }
  }

  void _shareText(String text) {
    Share.share(text);
  }

  void _searchText(String text) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchPage(
          epubController: _epubController,
          initialQuery: text,
        ),
      ),
    );
  }

  Future<void> _saveHighlight(HighlightData highlight) async {
    // Save to database
  }

  Future<void> _saveNote(NoteData note) async {
    // Save to database
  }
}
```

---

### 9.2 Selection Action Sheet

```dart
class SelectionActionSheet extends StatelessWidget {
  final EpubTextSelection selection;
  final VoidCallback onCopy;
  final VoidCallback onHighlight;
  final VoidCallback onNote;
  final VoidCallback onShare;
  final VoidCallback onSearch;

  const SelectionActionSheet({
    required this.selection,
    required this.onCopy,
    required this.onHighlight,
    required this.onNote,
    required this.onShare,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected text preview
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              selection.text.length > 100
                ? '${selection.text.substring(0, 100)}...'
                : selection.text,
              style: TextStyle(fontStyle: FontStyle.italic),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          SizedBox(height: 16),

          // Actions
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildAction(
                context,
                icon: Icons.copy,
                label: 'Copy',
                onTap: onCopy,
              ),
              _buildAction(
                context,
                icon: Icons.highlight,
                label: 'Highlight',
                onTap: onHighlight,
              ),
              _buildAction(
                context,
                icon: Icons.note_add,
                label: 'Note',
                onTap: onNote,
              ),
              _buildAction(
                context,
                icon: Icons.share,
                label: 'Share',
                onTap: onShare,
              ),
              _buildAction(
                context,
                icon: Icons.search,
                label: 'Search',
                onTap: onSearch,
              ),
              _buildAction(
                context,
                icon: Icons.translate,
                label: 'Translate',
                onTap: () => _translate(selection.text),
              ),
              _buildAction(
                context,
                icon: Icons.volume_up,
                label: 'Speak',
                onTap: () => _speak(selection.text),
              ),
              _buildAction(
                context,
                icon: Icons.bookmark_add,
                label: 'Bookmark',
                onTap: () => _bookmark(selection),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Theme.of(context).primaryColor),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _translate(String text) {
    // Implement translation
  }

  void _speak(String text) {
    // Implement text-to-speech
  }

  void _bookmark(EpubTextSelection selection) {
    // Implement bookmarking
  }
}
```

---

### 9.3 For epub_view (Pure Flutter)

```dart
// Note: epub_view has limited built-in text selection support
// You may need to implement custom selection logic

class CustomTextSelection extends StatefulWidget {
  final String text;
  final Function(String) onTextSelected;

  @override
  _CustomTextSelectionState createState() => _CustomTextSelectionState();
}

class _CustomTextSelectionState extends State<CustomTextSelection> {
  @override
  Widget build(BuildContext context) {
    return SelectableText(
      widget.text,
      onSelectionChanged: (selection, cause) {
        if (selection.isCollapsed) return;

        final selectedText = widget.text.substring(
          selection.start,
          selection.end,
        );

        widget.onTextSelected(selectedText);
      },
      contextMenuBuilder: (context, editableTextState) {
        return AdaptiveTextSelectionToolbar.editableText(
          editableTextState: editableTextState,
        );
      },
      style: TextStyle(fontSize: 16),
    );
  }
}
```

---

## 10. Search Functionality

### 10.1 Using flutter_epub_viewer

```dart
class SearchPage extends StatefulWidget {
  final EpubController epubController;
  final String? initialQuery;

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // flutter_epub_viewer provides search functionality
      final results = await widget.epubController.search(query);

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search in book...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
              : null,
          ),
          onChanged: (value) {
            // Debounce search
            Future.delayed(Duration(milliseconds: 500), () {
              if (_searchController.text == value) {
                _performSearch(value);
              }
            });
          },
          onSubmitted: _performSearch,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No results found for "${_searchController.text}"',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Enter a search term',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return SearchResultTile(
          result: result,
          searchQuery: _searchController.text,
          onTap: () {
            _navigateToResult(result);
          },
        );
      },
    );
  }

  void _navigateToResult(SearchResult result) {
    // Navigate to the search result location
    widget.epubController.display(cfi: result.cfi);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
```

---

### 10.2 Search Result Tile

```dart
class SearchResultTile extends StatelessWidget {
  final SearchResult result;
  final String searchQuery;
  final VoidCallback onTap;

  const SearchResultTile({
    required this.result,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        result.chapterTitle ?? 'Chapter ${result.chapterIndex + 1}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8),
        child: _buildHighlightedExcerpt(context),
      ),
      onTap: onTap,
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
    );
  }

  Widget _buildHighlightedExcerpt(BuildContext context) {
    final excerpt = result.excerpt;
    final queryLower = searchQuery.toLowerCase();
    final excerptLower = excerpt.toLowerCase();

    final matches = <TextSpan>[];
    int currentIndex = 0;

    while (true) {
      final matchIndex = excerptLower.indexOf(queryLower, currentIndex);

      if (matchIndex == -1) {
        // No more matches, add remaining text
        if (currentIndex < excerpt.length) {
          matches.add(TextSpan(
            text: excerpt.substring(currentIndex),
            style: TextStyle(color: Colors.black87),
          ));
        }
        break;
      }

      // Add text before match
      if (matchIndex > currentIndex) {
        matches.add(TextSpan(
          text: excerpt.substring(currentIndex, matchIndex),
          style: TextStyle(color: Colors.black87),
        ));
      }

      // Add highlighted match
      matches.add(TextSpan(
        text: excerpt.substring(matchIndex, matchIndex + searchQuery.length),
        style: TextStyle(
          backgroundColor: Colors.yellow,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ));

      currentIndex = matchIndex + searchQuery.length;
    }

    return RichText(
      text: TextSpan(children: matches),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class SearchResult {
  final String cfi;
  final String excerpt;
  final String? chapterTitle;
  final int chapterIndex;

  SearchResult({
    required this.cfi,
    required this.excerpt,
    this.chapterTitle,
    required this.chapterIndex,
  });
}
```

---

### 10.3 Custom Search Implementation (for epub_view)

```dart
class CustomEpubSearch {
  final EpubBook epubBook;

  CustomEpubSearch(this.epubBook);

  Future<List<SearchResult>> search(String query) async {
    final results = <SearchResult>[];

    if (query.isEmpty) return results;

    final queryLower = query.toLowerCase();

    // Search through chapters
    for (int i = 0; i < epubBook.Chapters.length; i++) {
      final chapter = epubBook.Chapters[i];
      final content = await _getChapterText(chapter);

      // Find all occurrences in this chapter
      final matches = _findMatches(content, queryLower);

      for (final match in matches) {
        results.add(SearchResult(
          cfi: _generateCFI(chapter, match.index),
          excerpt: _extractExcerpt(content, match.index, query.length),
          chapterTitle: chapter.Title,
          chapterIndex: i,
        ));
      }
    }

    return results;
  }

  Future<String> _getChapterText(EpubChapter chapter) async {
    // Extract text from chapter HTML
    final htmlContent = chapter.HtmlContent ?? '';

    // Remove HTML tags (basic implementation)
    final textContent = htmlContent
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

    return textContent;
  }

  List<Match> _findMatches(String text, String query) {
    final pattern = RegExp(query, caseSensitive: false);
    return pattern.allMatches(text).toList();
  }

  String _extractExcerpt(String text, int matchIndex, int matchLength) {
    const excerptRadius = 50; // Characters before and after match

    final start = (matchIndex - excerptRadius).clamp(0, text.length);
    final end = (matchIndex + matchLength + excerptRadius).clamp(0, text.length);

    String excerpt = text.substring(start, end);

    if (start > 0) excerpt = '...' + excerpt;
    if (end < text.length) excerpt = excerpt + '...';

    return excerpt;
  }

  String _generateCFI(EpubChapter chapter, int textOffset) {
    // Simplified CFI generation
    // In production, use proper CFI calculation
    return 'epubcfi(${chapter.Anchor})';
  }
}
```

---

### 10.4 Advanced Search Features

```dart
class AdvancedSearch extends StatefulWidget {
  final EpubController controller;

  @override
  _AdvancedSearchState createState() => _AdvancedSearchState();
}

class _AdvancedSearchState extends State<AdvancedSearch> {
  final _searchController = TextEditingController();
  bool _caseSensitive = false;
  bool _wholeWords = false;
  SearchScope _scope = SearchScope.all;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search...',
            prefixIcon: Icon(Icons.search),
          ),
        ),

        SizedBox(height: 16),

        // Search options
        SwitchListTile(
          title: Text('Case sensitive'),
          value: _caseSensitive,
          onChanged: (value) {
            setState(() => _caseSensitive = value);
          },
        ),

        SwitchListTile(
          title: Text('Whole words only'),
          value: _wholeWords,
          onChanged: (value) {
            setState(() => _wholeWords = value);
          },
        ),

        ListTile(
          title: Text('Search scope'),
          trailing: DropdownButton<SearchScope>(
            value: _scope,
            items: [
              DropdownMenuItem(
                value: SearchScope.all,
                child: Text('Entire book'),
              ),
              DropdownMenuItem(
                value: SearchScope.currentChapter,
                child: Text('Current chapter'),
              ),
              DropdownMenuItem(
                value: SearchScope.fromCurrent,
                child: Text('From current position'),
              ),
            ],
            onChanged: (value) {
              setState(() => _scope = value!);
            },
          ),
        ),

        SizedBox(height: 16),

        ElevatedButton(
          onPressed: _performAdvancedSearch,
          child: Text('Search'),
        ),
      ],
    );
  }

  Future<void> _performAdvancedSearch() async {
    String pattern = _searchController.text;

    if (_wholeWords) {
      pattern = '\\b$pattern\\b';
    }

    final regex = RegExp(
      pattern,
      caseSensitive: _caseSensitive,
    );

    // Perform search with options
    // Implementation depends on package capabilities
  }
}

enum SearchScope {
  all,
  currentChapter,
  fromCurrent,
}
```

---

## 11. Implementation Examples

### 11.1 Complete EPUB Reader App Structure

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseHelper.instance.database;

  // Initialize Hive (if using)
  // await HiveService.init();

  runApp(EpubReaderApp());
}

class EpubReaderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EPUB Reader',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: LibraryPage(),
      routes: {
        '/reader': (context) => ReaderPage(),
        '/settings': (context) => SettingsPage(),
        '/bookmarks': (context) => BookmarksPage(),
        '/highlights': (context) => HighlightsPage(),
      },
    );
  }
}
```

---

### 11.2 Complete Reader Page

```dart
class ReaderPage extends StatefulWidget {
  final Book book;

  @override
  _ReaderPageState createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late EpubController _epubController;
  FontSettings _fontSettings = FontSettings();
  EpubTheme _currentTheme = EpubTheme.light;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeReader();
  }

  Future<void> _loadSettings() async {
    final fontPrefs = FontPreferences();
    final themePrefs = ThemePreferences();

    final savedFont = await fontPrefs.load();
    final savedTheme = await themePrefs.getTheme();

    setState(() {
      _fontSettings = savedFont;
      // Apply theme
    });
  }

  Future<void> _initializeReader() async {
    final lastCfi = await _getLastPosition();

    _epubController = EpubController(
      document: EpubDocument.openAsset(widget.book.filePath),
      epubCfi: lastCfi,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _showControls ? _buildAppBar() : null,
      drawer: _buildDrawer(),
      body: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
        },
        child: Container(
          color: _currentTheme.backgroundColor,
          child: EpubView(
            controller: _epubController,
            onChapterChanged: _onChapterChanged,
          ),
        ),
      ),
      bottomNavigationBar: _showControls ? _buildBottomBar() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: EpubViewActualChapter(
        controller: _epubController,
        builder: (chapter) => Text(chapter?.chapter?.Title ?? 'Reading'),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search),
          onPressed: _openSearch,
        ),
        IconButton(
          icon: Icon(Icons.bookmark_add),
          onPressed: _addBookmark,
        ),
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: _openSettings,
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: EpubViewTableOfContents(controller: _epubController),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: _toggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.format_size),
            onPressed: _showFontSettings,
          ),
          IconButton(
            icon: Icon(Icons.list),
            onPressed: _showTableOfContents,
          ),
        ],
      ),
    );
  }

  void _onChapterChanged(EpubChapterViewValue? value) {
    _saveProgress();
  }

  Future<void> _saveProgress() async {
    final cfi = _epubController.generateEpubCfi();
    if (cfi != null) {
      await LibraryManager(DatabaseHelper.instance.database).updateProgress(
        bookId: widget.book.id,
        cfi: cfi,
        progress: 0.5, // Calculate actual progress
      );
    }
  }

  Future<String?> _getLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_cfi_${widget.book.id}');
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchPage(epubController: _epubController),
      ),
    );
  }

  void _addBookmark() {
    // Implementation
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => FontSettingsPanel(
        initialSettings: _fontSettings,
        onSettingsChanged: (settings) {
          setState(() => _fontSettings = settings);
        },
      ),
    );
  }

  void _toggleTheme() {
    // Toggle between themes
  }

  void _showFontSettings() {
    _openSettings();
  }

  void _showTableOfContents() {
    Scaffold.of(context).openDrawer();
  }

  @override
  void dispose() {
    _saveProgress();
    _epubController.dispose();
    super.dispose();
  }
}
```

---

## Conclusion

This comprehensive guide covers all major aspects of building a professional EPUB reader application in Flutter. Key takeaways:

1. **Package Selection:** Choose based on your needs:
   - epub_view for cross-platform pure Flutter
   - vocsy_epub_viewer for mobile-only with native performance
   - flutter_epub_viewer for advanced features with WebView
   - epub_pro for large files and professional annotations

2. **Core Features:** Implement:
   - CFI-based position tracking for accuracy
   - Proper annotation system with database storage
   - Customizable fonts and themes
   - Efficient search functionality
   - Comprehensive text selection

3. **Performance:** Optimize through:
   - Lazy loading strategies
   - Image optimization
   - Memory management
   - Chapter splitting for large files

4. **User Experience:** Provide:
   - Both pagination and scrolling options
   - Dark mode and multiple themes
   - Intuitive navigation
   - Rich annotation capabilities

5. **Data Management:** Use:
   - SQLite or Hive for local storage
   - Proper database schema for books, annotations, and bookmarks
   - File management for EPUB imports

Follow EPUB 3.3 W3C specifications for compatibility and use CFI (Canonical Fragment Identifier) standard for cross-device synchronization.

---

## References

- W3C EPUB 3.3 Specification: https://www.w3.org/TR/epub-33/
- EPUB CFI Specification: https://idpf.org/epub/linking/cfi/
- Flutter Official Documentation: https://docs.flutter.dev/
- pub.dev packages: epub_view, vocsy_epub_viewer, flutter_epub_viewer, epub_pro
- Flutter Performance Best Practices: Official Flutter documentation
- Epub.js Library: https://github.com/futurepress/epub.js

---

**Document Version:** 1.0
**Last Updated:** 2025-01-14
**Compiled by:** Claude Code Research Assistant
