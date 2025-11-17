import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Real EPUB Import Integration Tests', () {
    setUpAll(() async {
      await TestApp.cleanup();
      // Initialize dependencies once for all tests
      await TestApp.createTestApp();
    });

    setUp(() async {
      // Clear database before each test
      await TestApp.clearDatabase();
    });

    tearDownAll(() async {
      await TestApp.cleanup();
    });

    testWidgets('Import Frankenstein (pg84.epub) and verify metadata', (tester) async {
      // Import the EPUB file
      final bookId = await TestApp.importEpubFile('pg84.epub');
      expect(bookId, isNotNull, reason: 'Book import should succeed');

      // Create the app widget with the imported book in database
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Verify the book appears in library with actual extracted title
      // The full title is "Frankenstein; Or, The Modern Prometheus"
      expect(find.textContaining('Frankenstein'), findsOneWidget);
      expect(find.textContaining('Mary'), findsOneWidget);
    });

    testWidgets('Import Pride and Prejudice (pg1342.epub) and verify metadata', (tester) async {
      // Import the EPUB file
      final bookId = await TestApp.importEpubFile('pg1342.epub');
      expect(bookId, isNotNull, reason: 'Book import should succeed');

      // Create the app widget with the imported book in database
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Verify the book appears in library
      expect(find.textContaining('Pride'), findsOneWidget);
    });

    testWidgets('Import Moby Dick (pg2701.epub) and verify metadata', (tester) async {
      // Import the EPUB file
      final bookId = await TestApp.importEpubFile('pg2701.epub');
      expect(bookId, isNotNull, reason: 'Book import should succeed');

      // Create the app widget with the imported book in database
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Verify the book appears in library
      expect(find.textContaining('Moby'), findsOneWidget);
    });

    testWidgets('Import EPUB with images (pg84-images.epub)', (tester) async {
      // Import the EPUB file with images
      final bookId = await TestApp.importEpubFile('pg84-images.epub');
      expect(bookId, isNotNull, reason: 'Book import should succeed');

      // Create the app widget with the imported book in database
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Verify the book appears in library
      expect(find.textContaining('Frankenstein'), findsOneWidget);

      // Verify the book has metadata extracted
      final allBooks = await TestApp.database.getAllBooks();
      final importedBook = allBooks.firstWhere((b) => b.id == bookId);

      expect(importedBook.title, isNotEmpty);
      expect(importedBook.author, isNotEmpty);
      expect(importedBook.filePath, isNotEmpty);
      // Cover might be extracted
      print('Cover path: ${importedBook.coverPath}');
    });

    testWidgets('Import multiple EPUBs in sequence', (tester) async {
      // Import first EPUB
      final book1Id = await TestApp.importEpubFile('pg84.epub');
      expect(book1Id, isNotNull);

      // Import second EPUB
      final book2Id = await TestApp.importEpubFile('pg1342.epub');
      expect(book2Id, isNotNull);

      // Create the app widget with both imported books in database
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Verify both books appear in library (only first 2 visible in tests)
      expect(find.textContaining('Frankenstein'), findsOneWidget);
      expect(find.textContaining('Pride'), findsOneWidget);

      // Verify both books are in database
      final allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, equals(2));
    });

    testWidgets('Import EPUB and open book details', (tester) async {
      // Import the EPUB file
      final bookId = await TestApp.importEpubFile('pg84.epub');
      expect(bookId, isNotNull);

      // Create the app widget
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Open book details - use partial title match
      final frankensteinFinder = find.textContaining('Frankenstein');
      expect(frankensteinFinder, findsOneWidget);

      await tester.tap(frankensteinFinder.first);
      await tester.pumpAndSettle();

      // Verify we're on book details screen
      expect(find.textContaining('Frankenstein'), findsWidgets);
    });

    testWidgets('Verify extracted metadata fields', (tester) async {
      // Import the EPUB file
      final bookId = await TestApp.importEpubFile('pg1342.epub');
      expect(bookId, isNotNull);

      // Get the book from database
      final allBooks = await TestApp.database.getAllBooks();
      final book = allBooks.firstWhere((b) => b.id == bookId);

      // Verify metadata was extracted
      expect(book.title, isNotEmpty);
      expect(book.author, isNotEmpty);
      expect(book.filePath, contains('.epub'));
      expect(book.addedDate, isNotNull);

      // Language and publisher might be extracted
      print('Title: ${book.title}');
      print('Author: ${book.author}');
      print('Publisher: ${book.publisher}');
      print('Language: ${book.language}');
      print('Description: ${book.description}');
    });

    testWidgets('Import EPUB-3 format (pg84-images-3.epub)', (tester) async {
      // Import the EPUB-3 file
      final bookId = await TestApp.importEpubFile('pg84-images-3.epub');
      expect(bookId, isNotNull, reason: 'EPUB-3 import should succeed');

      // Create the app widget
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Verify the book appears in library
      expect(find.textContaining('Frankenstein'), findsOneWidget);
    });

    testWidgets('Import fails gracefully for non-existent file', (tester) async {
      // Try to import a non-existent file
      final bookId = await TestApp.importEpubFile('non_existent.epub');

      // Should return null for failed import
      expect(bookId, isNull);

      // Create the app widget
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Library should be empty
      final allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, equals(0));
    });
  });
}
