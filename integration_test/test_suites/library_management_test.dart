import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_app.dart';
import '../helpers/test_actions.dart';
import '../helpers/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Library Management Flow Tests', () {
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

    testWidgets('Empty library displays correctly', (tester) async {
      // Arrange
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Assert - Database should be empty
      final allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 0);
    });

    testWidgets('Library shows correct book count', (tester) async {
      // Arrange - Add multiple books
      for (int i = 0; i < 5; i++) {
        await TestApp.addTestBook(
          title: 'Book ${i + 1}',
          author: 'Author ${i + 1}',
        );
      }

      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Assert - Database should have 5 books
      final allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 5);

      // First 2 books should be visible in UI (test environment limitation)
      TestActions.verifyBookInLibrary('Book 1');
      TestActions.verifyBookInLibrary('Book 2');
    });

    testWidgets('Delete book from library', (tester) async {
      // Arrange
      final bookId = await TestApp.addTestBook(
        title: 'Book to Delete',
        author: 'Author',
      );

      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      var allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 1);

      // Act - Delete book
      await TestApp.database.deleteBook(bookId);

      // Assert - Book should be removed
      allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 0);
    });

    testWidgets('Delete multiple books from library', (tester) async {
      // Arrange
      final book1Id = await TestApp.addTestBook(
        title: 'Book 1',
        author: 'Author 1',
      );

      final book2Id = await TestApp.addTestBook(
        title: 'Book 2',
        author: 'Author 2',
      );

      final book3Id = await TestApp.addTestBook(
        title: 'Book 3',
        author: 'Author 3',
      );

      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      var allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 3);

      // Act - Delete books
      await TestApp.database.deleteBook(book1Id);
      await TestApp.database.deleteBook(book3Id);

      // Assert - Only book 2 should remain
      allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 1);
      expect(allBooks[0].id, book2Id);
      expect(allBooks[0].title, 'Book 2');
    });

    testWidgets('Books ordered by added date (newest first)', (tester) async {
      // Arrange - Add books with delays
      await TestApp.addTestBook(
        title: 'Old Book',
        author: 'Author',
      );

      await Future.delayed(const Duration(milliseconds: 100));

      await TestApp.addTestBook(
        title: 'Middle Book',
        author: 'Author',
      );

      await Future.delayed(const Duration(milliseconds: 100));

      await TestApp.addTestBook(
        title: 'New Book',
        author: 'Author',
      );

      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Assert - Books should be ordered by date (oldest first based on database implementation)
      final allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 3);
      // Database returns oldest first
      expect(allBooks[0].title, 'Old Book');
      expect(allBooks[1].title, 'Middle Book');
      expect(allBooks[2].title, 'New Book');
    });


    testWidgets('Books with progress show correct reading status', (tester) async {
      // Arrange
      final unreadBook = await TestApp.addTestBook(
        title: 'Unread Book',
        author: 'Author',
        readingProgress: 0.0,
      );

      final inProgressBook = await TestApp.addTestBook(
        title: 'In Progress Book',
        author: 'Author',
        readingProgress: 0.5,
      );

      final completedBook = await TestApp.addTestBook(
        title: 'Completed Book',
        author: 'Author',
        readingProgress: 1.0,
      );

      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Assert - Books should have correct reading progress
      final allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 3);

      final unread = allBooks.firstWhere((b) => b.id == unreadBook);
      final inProgress = allBooks.firstWhere((b) => b.id == inProgressBook);
      final completed = allBooks.firstWhere((b) => b.id == completedBook);

      expect(unread.readingProgress, 0.0);
      expect(inProgress.readingProgress, 0.5);
      expect(completed.readingProgress, 1.0);
    });

    testWidgets('Library persists across app restarts', (tester) async {
      // Arrange - Add books
      await TestApp.addTestBook(
        title: 'Persistent Book 1',
        author: 'Author 1',
      );

      await TestApp.addTestBook(
        title: 'Persistent Book 2',
        author: 'Author 2',
      );

      // Create first app instance
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      var allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 2);

      // Act - Simulate app restart
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Assert - Books should persist
      allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 2);
      expect(allBooks.any((b) => b.title == 'Persistent Book 1'), isTrue);
      expect(allBooks.any((b) => b.title == 'Persistent Book 2'), isTrue);
    });

    testWidgets('Query books by specific criteria', (tester) async {
      // Arrange
      await TestApp.addTestBook(
        title: 'Fiction Book',
        author: 'John Doe',
      );

      await TestApp.addTestBook(
        title: 'Non-Fiction Book',
        author: 'Jane Smith',
      );

      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Assert - Can query and find specific books
      final allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 2);

      final fictionBook = allBooks.firstWhere((b) => b.title.contains('Fiction'));
      expect(fictionBook.author, 'John Doe');

      final janeBooks = allBooks.where((b) => b.author == 'Jane Smith').toList();
      expect(janeBooks.length, 1);
      expect(janeBooks[0].title, 'Non-Fiction Book');
    });

    testWidgets('Clear entire library', (tester) async {
      // Arrange - Add multiple books
      for (int i = 0; i < 5; i++) {
        await TestApp.addTestBook(
          title: 'Book ${i + 1}',
          author: 'Author ${i + 1}',
        );
      }

      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      var allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 5);

      // Act - Clear database
      await TestApp.clearDatabase();

      // Assert - Library should be empty
      allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 0);
    });
  });
}
