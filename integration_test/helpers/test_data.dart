import 'dart:typed_data';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/core/database/app_database.dart' as db;

/// Factory class for creating test data
class TestData {
  /// Sample book titles for testing
  static const List<String> bookTitles = [
    'The Great Gatsby',
    '1984',
    'Pride and Prejudice',
    'To Kill a Mockingbird',
    'The Catcher in the Rye',
    'Brave New World',
    'The Lord of the Rings',
    'Harry Potter and the Philosopher\'s Stone',
  ];

  /// Sample authors
  static const List<String> authors = [
    'F. Scott Fitzgerald',
    'George Orwell',
    'Jane Austen',
    'Harper Lee',
    'J.D. Salinger',
    'Aldous Huxley',
    'J.R.R. Tolkien',
    'J.K. Rowling',
  ];

  /// Create a test book entity
  static Book createBook({
    int? id,
    String? title,
    String? author,
    String? filePath,
    String? coverPath,
    String? publisher,
    String? language,
    String? isbn,
    String? description,
    DateTime? addedDate,
    DateTime? lastOpened,
    double readingProgress = 0.0,
    int? currentPage,
    int? totalPages,
    String? currentCfi,
  }) {
    final bookId = id ?? DateTime.now().millisecondsSinceEpoch;
    return Book(
      id: bookId,
      title: title ?? bookTitles[0],
      author: author ?? authors[0],
      filePath: filePath ?? '/storage/books/test_book.epub',
      coverPath: coverPath,
      publisher: publisher ?? 'Test Publisher',
      language: language ?? 'en',
      isbn: isbn ?? '978-0-123456-78-9',
      description: description ?? 'This is a test book description for integration testing.',
      addedDate: addedDate ?? DateTime.now(),
      lastOpened: lastOpened,
      readingProgress: readingProgress,
      currentPage: currentPage ?? 0,
      totalPages: totalPages ?? 300,
      currentCfi: currentCfi,
    );
  }

  /// Create multiple test books
  static List<Book> createBooks(int count) {
    final books = <Book>[];
    for (int i = 0; i < count && i < bookTitles.length; i++) {
      books.add(createBook(
        id: i + 1,
        title: bookTitles[i],
        author: authors[i],
        filePath: '/storage/books/${bookTitles[i].toLowerCase().replaceAll(' ', '_')}.epub',
        readingProgress: i * 0.1, // Varying progress levels
      ));
    }
    return books;
  }

  /// Create a test bookmark
  static db.Bookmark createBookmark({
    int? id,
    int? bookId,
    String? cfiLocation,
    String? chapterName,
    int? pageNumber,
    String? note,
    DateTime? createdAt,
  }) {
    return db.Bookmark(
      id: id ?? DateTime.now().millisecondsSinceEpoch,
      bookId: bookId ?? 1,
      cfiLocation: cfiLocation ?? 'epubcfi(/6/4[chapter1]!/4/2/1:0)',
      chapterName: chapterName ?? 'Chapter 1: Introduction',
      pageNumber: pageNumber ?? 10,
      note: note ?? 'Important passage',
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Create multiple test bookmarks
  static List<db.Bookmark> createBookmarks(int count, {required int bookId}) {
    final bookmarks = <db.Bookmark>[];
    for (int i = 0; i < count; i++) {
      bookmarks.add(createBookmark(
        id: i + 1,
        bookId: bookId,
        cfiLocation: 'epubcfi(/6/4[chapter${i + 1}]!/4/2/1:0)',
        chapterName: 'Chapter ${i + 1}',
        pageNumber: (i + 1) * 10,
        note: 'Bookmark ${i + 1}',
      ));
    }
    return bookmarks;
  }

  /// Create a test highlight
  static db.Highlight createHighlight({
    int? id,
    int? bookId,
    String? cfiRange,
    String? selectedText,
    String? color,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return db.Highlight(
      id: id ?? DateTime.now().millisecondsSinceEpoch,
      bookId: bookId ?? 1,
      cfiRange: cfiRange ?? 'epubcfi(/6/4[chapter1]!/4/2,/1:0,/1:100)',
      selectedText: selectedText ?? 'This is a highlighted text passage from the book.',
      color: color ?? '#FFFF00',
      note: note ?? 'Important concept',
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
    );
  }

  /// Create multiple test highlights
  static List<db.Highlight> createHighlights(int count, {required int bookId}) {
    final highlights = <db.Highlight>[];
    final colors = ['#FFFF00', '#00FF00', '#00FFFF', '#FF00FF', '#FFA500'];

    for (int i = 0; i < count; i++) {
      highlights.add(createHighlight(
        id: i + 1,
        bookId: bookId,
        cfiRange: 'epubcfi(/6/4[chapter${i + 1}]!/4/2,/1:${i * 10},/1:${(i + 1) * 10})',
        selectedText: 'Highlighted text ${i + 1} from the book content.',
        color: colors[i % colors.length],
        note: 'Note for highlight ${i + 1}',
      ));
    }
    return highlights;
  }

  /// Get the path for a test EPUB file
  static String getTestEpubPath(String fileName) {
    return 'test_data/epubs/$fileName';
  }

  /// Create minimal EPUB bytes (simplified structure)
  static Uint8List createMinimalEpubBytes() {
    // This is a simplified representation
    // In a real test, you'd want to use a proper EPUB file
    // or a library to generate valid EPUB content

    final String mimetypeContent = 'application/epub+zip';
    final String containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

    final String contentOpf = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Test Book</dc:title>
    <dc:creator>Test Author</dc:creator>
    <dc:language>en</dc:language>
    <meta property="dcterms:modified">2024-01-01T00:00:00Z</meta>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="chapter1"/>
  </spine>
</package>''';

    final String navXhtml = '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head>
  <title>Navigation</title>
</head>
<body>
  <nav epub:type="toc">
    <h1>Table of Contents</h1>
    <ol>
      <li><a href="chapter1.xhtml">Chapter 1</a></li>
    </ol>
  </nav>
</body>
</html>''';

    final String chapter1Xhtml = '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Chapter 1</title>
</head>
<body>
  <h1>Chapter 1: Introduction</h1>
  <p>This is the first paragraph of the test book.</p>
  <p>This is the second paragraph with more content for testing.</p>
  <p>Here's a third paragraph to make the chapter longer.</p>
</body>
</html>''';

    // For simplicity, return a basic byte array
    // In production, you'd create a proper ZIP file with the EPUB structure
    return Uint8List.fromList(mimetypeContent.codeUnits);
  }



  /// Generate a unique timestamp-based ID
  static int generateId() {
    return DateTime.now().millisecondsSinceEpoch +
           (DateTime.now().microsecondsSinceEpoch % 1000);
  }

  /// Create test chapter titles
  static List<String> createChapterTitles(int count) {
    final titles = <String>[];
    for (int i = 1; i <= count; i++) {
      titles.add('Chapter $i');
    }
    return titles;
  }

}

/// CFI locations for testing
class CfiLocations {
  static const String chapter1Start = 'epubcfi(/6/4[chapter1]!/4/2/1:0)';
  static const String chapter1Middle = 'epubcfi(/6/4[chapter1]!/4/2/1:50)';
  static const String chapter1End = 'epubcfi(/6/4[chapter1]!/4/2/1:100)';
  static const String chapter2Start = 'epubcfi(/6/4[chapter2]!/4/2/1:0)';
  static const String chapter2Middle = 'epubcfi(/6/4[chapter2]!/4/2/1:50)';
}

/// Sample text content for testing
class SampleText {
  static const String shortText = 'This is a short sample text.';
  static const String mediumText = 'This is a medium length sample text that contains '
      'more words and can be used for testing various text-related features '
      'in the EPUB reader application.';
  static const String longText = 'This is a much longer sample text that spans multiple '
      'lines and contains enough content to test features like text selection, '
      'highlighting, and navigation. It includes multiple sentences and paragraphs '
      'to simulate real book content. The text continues with more information '
      'about various topics to make it suitable for comprehensive testing of '
      'the EPUB reader\'s text handling capabilities. Additional content is added '
      'here to ensure the text is long enough for all test scenarios.';
}

/// Test search queries
class SearchQueries {
  static const String authorSearch = 'Orwell';
  static const String titleSearch = 'Great';
  static const String partialSearch = 'the';
  static const String noResultsSearch = 'xyz123abc';
}

/// Test user preferences
class UserPreferences {
  static const double defaultFontSize = 16.0;
  static const double largeFontSize = 20.0;
  static const double smallFontSize = 14.0;
  static const String lightTheme = 'light';
  static const String darkTheme = 'dark';
  static const String sepiaTheme = 'sepia';
}

/// Error messages for testing error scenarios
class ErrorMessages {
  static const String fileNotFound = 'File not found';
  static const String invalidEpub = 'Invalid EPUB file';
  static const String databaseError = 'Database operation failed';
  static const String networkError = 'Network connection failed';
  static const String permissionDenied = 'Permission denied';
}