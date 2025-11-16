import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_app.dart';
import '../helpers/widget_finders.dart';
import '../helpers/test_actions.dart';
import '../helpers/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Reading Flow and Progress Tracking Tests', () {
    late int testBookId;

    setUpAll(() async {
      await TestApp.cleanup();
      // Initialize dependencies once for all tests
      await TestApp.createTestApp();
    });

    setUp(() async {
      // Create a fresh test app
      await TestApp.clearDatabase();

      // Add a test book for reading
      testBookId = await TestApp.addTestBook(
        title: 'Test Reading Book',
        author: 'Reading Author',
        currentCfi: CfiLocations.chapter1Start,
        readingProgress: 0.0,
      );
    });

    tearDown(() async {
      await TestApp.clearDatabase();
    });

    tearDownAll(() async {
      await TestApp.cleanup();
    });

    testWidgets('Book with zero progress is stored correctly', (tester) async {
      // Arrange
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Assert - Verify book exists with zero progress
      final allBooks = await TestApp.database.getAllBooks();
      final book = allBooks.firstWhere((b) => b.id == testBookId);
      expect(book.readingProgress, 0.0);
      expect(book.currentCfi, CfiLocations.chapter1Start);

      // Verify book appears in library
      TestActions.verifyBookInLibrary('Test Reading Book');
    });

    testWidgets('Book with reading progress is stored correctly', (tester) async {
      // Arrange - Update book with progress
      await TestApp.clearDatabase();
      final bookId = await TestApp.addTestBook(
        title: 'Book with Progress',
        author: 'Author',
        currentCfi: CfiLocations.chapter1Middle,
        readingProgress: 0.5,
      );

      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Assert - Verify progress is stored
      final allBooks = await TestApp.database.getAllBooks();
      final book = allBooks.firstWhere((b) => b.id == bookId);
      expect(book.readingProgress, 0.5);
      expect(book.currentCfi, CfiLocations.chapter1Middle);

      // Verify book appears in library
      TestActions.verifyBookInLibrary('Book with Progress');
    });

    testWidgets('Book with 100% progress is stored correctly', (tester) async {
      // Arrange
      await TestApp.clearDatabase();
      final bookId = await TestApp.addTestBook(
        title: 'Completed Book',
        author: 'Author',
        currentCfi: CfiLocations.chapter1Middle,
        readingProgress: 1.0,
      );

      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Assert - Verify completion is stored
      final allBooks = await TestApp.database.getAllBooks();
      final book = allBooks.firstWhere((b) => b.id == bookId);
      expect(book.readingProgress, 1.0);

      // Verify book appears in library
      TestActions.verifyBookInLibrary('Completed Book');
    });

    testWidgets('Multiple books with different progress levels', (tester) async {
      // Arrange
      await TestApp.clearDatabase();

      final book1Id = await TestApp.addTestBook(
        title: 'Book 1',
        author: 'Author 1',
        readingProgress: 0.0,
      );

      final book2Id = await TestApp.addTestBook(
        title: 'Book 2',
        author: 'Author 2',
        readingProgress: 0.33,
      );

      final book3Id = await TestApp.addTestBook(
        title: 'Book 3',
        author: 'Author 3',
        readingProgress: 0.67,
      );

      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Assert - Verify all books have correct progress
      final allBooks = await TestApp.database.getAllBooks();
      expect(allBooks.length, 3);

      final book1 = allBooks.firstWhere((b) => b.id == book1Id);
      final book2 = allBooks.firstWhere((b) => b.id == book2Id);
      final book3 = allBooks.firstWhere((b) => b.id == book3Id);

      expect(book1.readingProgress, 0.0);
      expect(book2.readingProgress, 0.33);
      expect(book3.readingProgress, 0.67);
    });

    testWidgets('CFI location is preserved in database', (tester) async {
      // Arrange
      final specificCfi = 'epubcfi(/6/8[chapter2]!/4/2/1:100)';
      await TestApp.clearDatabase();
      final bookId = await TestApp.addTestBook(
        title: 'CFI Test Book',
        author: 'Author',
        currentCfi: specificCfi,
        readingProgress: 0.42,
      );

      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Assert - Verify CFI is stored correctly
      final allBooks = await TestApp.database.getAllBooks();
      final book = allBooks.firstWhere((b) => b.id == bookId);
      expect(book.currentCfi, specificCfi);
      expect(book.readingProgress, 0.42);
    });

    testWidgets('Reading progress persists across app restarts', (tester) async {
      // Arrange - Add book with progress
      await TestApp.clearDatabase();
      final bookId = await TestApp.addTestBook(
        title: 'Persistent Book',
        author: 'Author',
        readingProgress: 0.6,
        currentCfi: CfiLocations.chapter1Middle,
      );

      // Create first app instance
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      var allBooks = await TestApp.database.getAllBooks();
      var book = allBooks.firstWhere((b) => b.id == bookId);
      expect(book.readingProgress, 0.6);

      // Act - Simulate app restart by creating new app instance
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Assert - Progress should persist
      allBooks = await TestApp.database.getAllBooks();
      book = allBooks.firstWhere((b) => b.id == bookId);
      expect(book.readingProgress, 0.6);
      expect(book.currentCfi, CfiLocations.chapter1Middle);
    });
  });
}
