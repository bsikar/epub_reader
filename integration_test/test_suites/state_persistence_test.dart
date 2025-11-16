import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_app.dart';
import '../helpers/test_actions.dart';
import '../helpers/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('State Persistence Tests', () {
    setUpAll(() async {
      await TestApp.cleanup();
      // Initialize dependencies once for all tests
      await TestApp.createTestApp();
    });

    setUp(() async {
      await TestApp.clearDatabase();
    });

    tearDown(() async {
      // Don't clear database here to test persistence
    });

    tearDownAll(() async {
      await TestApp.cleanup();
    });

    testWidgets('Reading progress persists across app restarts', (tester) async {
      // Arrange - Add book with progress
      final bookId = await TestApp.addTestBook(
        title: 'Persistent Book',
        author: 'Author',
        readingProgress: 0.75,
        currentCfi: CfiLocations.chapter1Middle,
      );

      // Create first app instance
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      var allBooks = await TestApp.database.getAllBooks();
      var book = allBooks.firstWhere((b) => b.id == bookId);
      expect(book.readingProgress, 0.75);

      // Act - Simulate app restart
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Assert - Progress should persist
      allBooks = await TestApp.database.getAllBooks();
      book = allBooks.firstWhere((b) => b.id == bookId);
      expect(book.readingProgress, 0.75);
      expect(book.currentCfi, CfiLocations.chapter1Middle);
    });

    testWidgets('Bookmarks persist across sessions', (tester) async {
      // Arrange
      final bookId = await TestApp.addTestBook(
        title: 'Book with Bookmarks',
        author: 'Author',
      );

      await TestApp.addTestBookmark(
        bookId: bookId,
        cfiLocation: CfiLocations.chapter1Start,
        chapterName: 'Chapter 1',
        note: 'Persistent bookmark',
      );

      // Create first app instance
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      var bookmarks = await TestApp.database.getBookmarksByBookId(bookId);
      expect(bookmarks.length, 1);

      // Act - Simulate app restart
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Assert - Bookmark should persist
      bookmarks = await TestApp.database.getBookmarksByBookId(bookId);
      expect(bookmarks.length, 1);
      expect(bookmarks[0].note, 'Persistent bookmark');
    });

    testWidgets('Highlights persist across sessions', (tester) async {
      // Arrange
      final bookId = await TestApp.addTestBook(
        title: 'Book with Highlights',
        author: 'Author',
      );

      await TestApp.addTestHighlight(
        bookId: bookId,
        cfiRange: 'epubcfi(/6/4[chapter1]!/4/2,/1:0,/1:50)',
        selectedText: 'Persistent highlight',
        color: '#FFFF00',
      );

      // Create first app instance
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      var highlights = await TestApp.database.getHighlightsByBookId(bookId);
      expect(highlights.length, 1);

      // Act - Simulate app restart
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Assert - Highlight should persist
      highlights = await TestApp.database.getHighlightsByBookId(bookId);
      expect(highlights.length, 1);
      expect(highlights[0].selectedText, 'Persistent highlight');
    });

    testWidgets('All book data persists together', (tester) async {
      // Arrange - Add book with progress, bookmark, and highlight
      final bookId = await TestApp.addTestBook(
        title: 'Complete Persistent Book',
        author: 'Author',
        readingProgress: 0.5,
        currentCfi: CfiLocations.chapter1Middle,
      );

      await TestApp.addTestBookmark(
        bookId: bookId,
        cfiLocation: CfiLocations.chapter1Start,
        chapterName: 'Chapter 1',
      );

      await TestApp.addTestHighlight(
        bookId: bookId,
        cfiRange: 'epubcfi(/6/4[chapter1]!/4/2,/1:0,/1:50)',
        selectedText: SampleText.shortText,
      );

      // Create first app instance
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Act - Simulate app restart
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Assert - All data should persist
      final allBooks = await TestApp.database.getAllBooks();
      final book = allBooks.firstWhere((b) => b.id == bookId);
      expect(book.readingProgress, 0.5);

      final bookmarks = await TestApp.database.getBookmarksByBookId(bookId);
      expect(bookmarks.length, 1);

      final highlights = await TestApp.database.getHighlightsByBookId(bookId);
      expect(highlights.length, 1);
    });
  });
}
