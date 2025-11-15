import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/domain/usecases/delete_book.dart';
import 'package:epub_reader/features/library/domain/usecases/get_all_books.dart';
import 'package:epub_reader/features/library/domain/usecases/get_recent_books.dart';
import 'package:epub_reader/features/library/presentation/providers/library_provider.dart';
import 'package:epub_reader/features/library/presentation/widgets/book_list_item.dart';
import 'package:epub_reader/features/library/presentation/widgets/library_search_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetAllBooks extends Mock implements GetAllBooks {}
class MockGetRecentBooks extends Mock implements GetRecentBooks {}
class MockDeleteBook extends Mock implements DeleteBook {}
class FakeBook extends Fake implements Book {}

void main() {
  late MockGetAllBooks mockGetAllBooks;
  late MockGetRecentBooks mockGetRecentBooks;
  late MockDeleteBook mockDeleteBook;
  late List<Book> testBooks;

  setUpAll(() {
    registerFallbackValue(FakeBook());
  });

  setUp(() {
    mockGetAllBooks = MockGetAllBooks();
    mockGetRecentBooks = MockGetRecentBooks();
    mockDeleteBook = MockDeleteBook();

    testBooks = [
      Book(
        id: 1,
        title: 'Flutter Development',
        author: 'John Doe',
        filePath: '/path/book1.epub',
        addedDate: DateTime(2025, 1, 1),
      ),
      Book(
        id: 2,
        title: 'Dart Programming',
        author: 'Jane Smith',
        filePath: '/path/book2.epub',
        addedDate: DateTime(2025, 1, 2),
      ),
      Book(
        id: 3,
        title: 'Mobile Development',
        author: 'Bob Johnson',
        filePath: '/path/book3.epub',
        addedDate: DateTime(2025, 1, 3),
      ),
    ];

    when(() => mockGetAllBooks()).thenAnswer((_) async => Right(testBooks));
  });

  Widget createTestApp(LibrarySearchDelegate delegate) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () {
                showSearch(context: context, delegate: delegate);
              },
              child: const Text('Search'),
            ),
          ),
        ),
      ),
    );
  }

  group('LibrarySearchDelegate', () {
    testWidgets('should have correct search field label', (tester) async {
      // Arrange
      final delegate = LibrarySearchDelegate();

      // Assert
      expect(delegate.searchFieldLabel, 'Search books...');
    });

    testWidgets('should show clear button when query is not empty', (tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          libraryProvider.overrideWith((ref) => LibraryNotifier(
                mockGetAllBooks,
                mockGetRecentBooks,
                mockDeleteBook,
              )),
        ],
      );
      addTearDown(container.dispose);

      final delegate = LibrarySearchDelegate();
      delegate.query = 'Flutter';

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: createTestApp(delegate),
        ),
      );

      // Act - Open search
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('should not show clear button when query is empty', (tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          libraryProvider.overrideWith((ref) => LibraryNotifier(
                mockGetAllBooks,
                mockGetRecentBooks,
                mockDeleteBook,
              )),
        ],
      );
      addTearDown(container.dispose);

      final delegate = LibrarySearchDelegate();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: createTestApp(delegate),
        ),
      );

      // Act - Open search
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('should clear query when clear button tapped', (tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          libraryProvider.overrideWith((ref) => LibraryNotifier(
                mockGetAllBooks,
                mockGetRecentBooks,
                mockDeleteBook,
              )),
        ],
      );
      addTearDown(container.dispose);

      final delegate = LibrarySearchDelegate();
      delegate.query = 'Flutter';

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: createTestApp(delegate),
        ),
      );

      // Act - Open search
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Act - Tap clear
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Assert
      expect(delegate.query, '');
    });

    testWidgets('should show back button', (tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          libraryProvider.overrideWith((ref) => LibraryNotifier(
                mockGetAllBooks,
                mockGetRecentBooks,
                mockDeleteBook,
              )),
        ],
      );
      addTearDown(container.dispose);

      final delegate = LibrarySearchDelegate();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: createTestApp(delegate),
        ),
      );

      // Act - Open search
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('should show empty state when query is empty', (tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          libraryProvider.overrideWith((ref) => LibraryNotifier(
                mockGetAllBooks,
                mockGetRecentBooks,
                mockDeleteBook,
              )),
        ],
      );
      addTearDown(container.dispose);

      final delegate = LibrarySearchDelegate();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: createTestApp(delegate),
        ),
      );

      // Act - Open search
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Search your library by title or author'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('should filter books by title', (tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          libraryProvider.overrideWith((ref) => LibraryNotifier(
                mockGetAllBooks,
                mockGetRecentBooks,
                mockDeleteBook,
              )),
        ],
      );
      addTearDown(container.dispose);

      // Load books into state BEFORE building widget
      await container.read(libraryProvider.notifier).loadBooks();

      final delegate = LibrarySearchDelegate();
      delegate.query = 'Flutter';

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: createTestApp(delegate),
        ),
      );

      // Act - Open search
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BookListItem), findsOneWidget);
      expect(find.text('Flutter Development'), findsOneWidget);
    });

    testWidgets('should filter books by author', (tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          libraryProvider.overrideWith((ref) => LibraryNotifier(
                mockGetAllBooks,
                mockGetRecentBooks,
                mockDeleteBook,
              )),
        ],
      );
      addTearDown(container.dispose);

      // Load books into state
      await container.read(libraryProvider.notifier).loadBooks();

      final delegate = LibrarySearchDelegate();
      delegate.query = 'Jane';

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: createTestApp(delegate),
        ),
      );

      // Act - Open search
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BookListItem), findsOneWidget);
      expect(find.text('Dart Programming'), findsOneWidget);
    });

    testWidgets('should be case insensitive', (tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          libraryProvider.overrideWith((ref) => LibraryNotifier(
                mockGetAllBooks,
                mockGetRecentBooks,
                mockDeleteBook,
              )),
        ],
      );
      addTearDown(container.dispose);

      // Load books into state
      await container.read(libraryProvider.notifier).loadBooks();

      final delegate = LibrarySearchDelegate();
      delegate.query = 'FLUTTER';

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: createTestApp(delegate),
        ),
      );

      // Act - Open search
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BookListItem), findsOneWidget);
      expect(find.text('Flutter Development'), findsOneWidget);
    });

    testWidgets('should show multiple results for partial match', (tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          libraryProvider.overrideWith((ref) => LibraryNotifier(
                mockGetAllBooks,
                mockGetRecentBooks,
                mockDeleteBook,
              )),
        ],
      );
      addTearDown(container.dispose);

      // Load books into state
      await container.read(libraryProvider.notifier).loadBooks();

      final delegate = LibrarySearchDelegate();
      delegate.query = 'Development';

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: createTestApp(delegate),
        ),
      );

      // Act - Open search
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Assert - Should find both Flutter Development and Mobile Development
      expect(find.byType(BookListItem), findsNWidgets(2));
    });

    testWidgets('should show no results message when no books match', (tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          libraryProvider.overrideWith((ref) => LibraryNotifier(
                mockGetAllBooks,
                mockGetRecentBooks,
                mockDeleteBook,
              )),
        ],
      );
      addTearDown(container.dispose);

      // Load books into state
      await container.read(libraryProvider.notifier).loadBooks();

      final delegate = LibrarySearchDelegate();
      delegate.query = 'Nonexistent Book';

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: createTestApp(delegate),
        ),
      );

      // Act - Open search
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No books found for "Nonexistent Book"'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.byType(BookListItem), findsNothing);
    });

    testWidgets('should show all results in buildResults', (tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          libraryProvider.overrideWith((ref) => LibraryNotifier(
                mockGetAllBooks,
                mockGetRecentBooks,
                mockDeleteBook,
              )),
        ],
      );
      addTearDown(container.dispose);

      // Load books into state
      await container.read(libraryProvider.notifier).loadBooks();

      final delegate = LibrarySearchDelegate();
      delegate.query = 'Dart';

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: createTestApp(delegate),
        ),
      );

      // Act - Open search
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Submit search to trigger buildResults
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BookListItem), findsOneWidget);
    });
  });
}
