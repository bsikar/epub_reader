import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Error Handling Scenarios Tests', () {
    setUpAll(() async {
      await TestApp.cleanup();
      // Initialize dependencies once for all tests
      await TestApp.createTestApp();
    });

    setUp(() async {
      await TestApp.clearDatabase();
    });

    tearDown(() async {
      await TestApp.clearDatabase();
    });

    tearDownAll(() async {
      await TestApp.cleanup();
    });

    testWidgets('Handle non-existent book gracefully', (tester) async {
      // Arrange
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Act - Try to get a non-existent book
      final allBooks = await TestApp.database.getAllBooks();
      final nonExistentBook = allBooks.where((b) => b.id == 99999).toList();

      // Assert - Should return empty list
      expect(nonExistentBook.length, 0);
    });

    testWidgets('Handle empty database queries', (tester) async {
      // Arrange
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Act - Query empty database
      final allBooks = await TestApp.database.getAllBooks();

      // Assert - Should return empty list, not throw error
      expect(allBooks, isNotNull);
      expect(allBooks.length, 0);
    });

    testWidgets('Handle invalid book ID in bookmarks', (tester) async {
      // Arrange
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Act - Query bookmarks for non-existent book
      final bookmarks = await TestApp.database.getBookmarksByBookId(99999);

      // Assert - Should return empty list
      expect(bookmarks, isNotNull);
      expect(bookmarks.length, 0);
    });

    testWidgets('Handle invalid book ID in highlights', (tester) async {
      // Arrange
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Act - Query highlights for non-existent book
      final highlights = await TestApp.database.getHighlightsByBookId(99999);

      // Assert - Should return empty list
      expect(highlights, isNotNull);
      expect(highlights.length, 0);
    });

    testWidgets('Handle concurrent database operations', (tester) async {
      // Arrange
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Act - Perform multiple operations concurrently
      await Future.wait([
        TestApp.addTestBook(title: 'Book 1', author: 'Author 1'),
        TestApp.addTestBook(title: 'Book 2', author: 'Author 2'),
        TestApp.addTestBook(title: 'Book 3', author: 'Author 3'),
      ]);

      // Assert - All books should be added successfully
      final allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 3);
    });

    testWidgets('Handle database integrity after errors', (tester) async {
      // Arrange
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      final bookId = await TestApp.addTestBook(
        title: 'Test Book',
        author: 'Author',
      );

      // Act - Try to operate on the book
      var allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 1);

      // Database should still be operational
      await TestApp.addTestBook(
        title: 'Another Book',
        author: 'Author',
      );

      // Assert - Database integrity maintained
      allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 2);
    });
  });
}
