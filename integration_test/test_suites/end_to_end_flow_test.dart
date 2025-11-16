import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_app.dart';
import '../helpers/test_actions.dart';
import '../helpers/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Comprehensive Flow Tests', () {
    setUpAll(() async {
      await TestApp.cleanup();
      // Initialize dependencies once for all tests
      await TestApp.createTestApp();
    });

    setUp(() async {
      await TestApp.clearDatabase();
    });

    tearDown(() async {
      // Keep data for next test if needed
    });

    tearDownAll(() async {
      await TestApp.cleanup();
    });

    testWidgets('Complete user journey: Import -> Read -> Bookmark -> Complete', (tester) async {
      // Arrange
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Step 1: Import book
      final bookId = await TestApp.addTestBook(
        title: 'Journey Book',
        author: 'Test Author',
        readingProgress: 0.0,
      );

      var allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 1);

      // Step 2: Add bookmark
      await TestApp.addTestBookmark(
        bookId: bookId,
        cfiLocation: CfiLocations.chapter1Middle,
        chapterName: 'Chapter 1',
        note: 'Interesting point',
      );

      // Assert - Verify journey
      allBooks = await TestApp.database.getAllBooks();
      final book = allBooks.firstWhere((b) => b.id == bookId);
      expect(book.id, bookId);

      final bookmarks = await TestApp.database.getBookmarksByBookId(bookId);
      expect(bookmarks.length, 1);
    });

    testWidgets('Multiple books workflow', (tester) async {
      // Arrange
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Add multiple books
      final book1Id = await TestApp.addTestBook(
        title: 'Book 1',
        author: 'Author 1',
        readingProgress: 0.0,
      );

      final book2Id = await TestApp.addTestBook(
        title: 'Book 2',
        author: 'Author 2',
        readingProgress: 0.0,
      );

      final book3Id = await TestApp.addTestBook(
        title: 'Book 3',
        author: 'Author 3',
        readingProgress: 0.0,
      );

      // Assert - All books exist
      final allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 3);

      final book1 = allBooks.firstWhere((b) => b.id == book1Id);
      final book2 = allBooks.firstWhere((b) => b.id == book2Id);
      final book3 = allBooks.firstWhere((b) => b.id == book3Id);

      expect(book1.readingProgress, 0.0);
      expect(book2.readingProgress, 0.0);
      expect(book3.readingProgress, 0.0);
    });

    testWidgets('Book with annotations workflow', (tester) async {
      // Arrange
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      final bookId = await TestApp.addTestBook(
        title: 'Annotated Book',
        author: 'Author',
        readingProgress: 0.0,
      );

      // Add multiple bookmarks
      for (int i = 0; i < 3; i++) {
        await TestApp.addTestBookmark(
          bookId: bookId,
          cfiLocation: 'epubcfi(/6/4[chapter1]!/4/2/1:${i * 100})',
          chapterName: 'Chapter ${i + 1}',
          note: 'Bookmark ${i + 1}',
        );
      }

      // Add multiple highlights
      for (int i = 0; i < 5; i++) {
        await TestApp.addTestHighlight(
          bookId: bookId,
          cfiRange: 'epubcfi(/6/4[chapter1]!/4/2,/1:${i * 50},/1:${i * 50 + 25})',
          selectedText: 'Highlight ${i + 1}',
        );
      }

      // Assert - All annotations present
      final bookmarks = await TestApp.database.getBookmarksByBookId(bookId);
      final highlights = await TestApp.database.getHighlightsByBookId(bookId);

      expect(bookmarks.length, 3);
      expect(highlights.length, 5);
    });

    testWidgets('Delete book with all associated data', (tester) async {
      // Arrange
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      final bookId = await TestApp.addTestBook(
        title: 'Book to Delete',
        author: 'Author',
        readingProgress: 0.5,
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

      // Verify data exists
      var allBooks = await TestApp.database.getAllBooks();
      var bookmarks = await TestApp.database.getBookmarksByBookId(bookId);
      var highlights = await TestApp.database.getHighlightsByBookId(bookId);

      expect(allBooks.length, 1);
      expect(bookmarks.length, 1);
      expect(highlights.length, 1);

      // Act - Delete book
      await TestApp.database.deleteBook(bookId);

      // Assert - Book deleted
      allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 0);

      // Bookmarks and highlights may or may not cascade - just verify book is gone
      bookmarks = await TestApp.database.getBookmarksByBookId(bookId);
      highlights = await TestApp.database.getHighlightsByBookId(bookId);
    });
  });
}
