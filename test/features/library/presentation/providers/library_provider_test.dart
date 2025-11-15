import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/domain/usecases/delete_book.dart';
import 'package:epub_reader/features/library/domain/usecases/get_all_books.dart';
import 'package:epub_reader/features/library/domain/usecases/get_recent_books.dart';
import 'package:epub_reader/features/library/presentation/providers/library_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetAllBooks extends Mock implements GetAllBooks {}
class MockGetRecentBooks extends Mock implements GetRecentBooks {}
class MockDeleteBook extends Mock implements DeleteBook {}

class FakeBook extends Fake implements Book {}

void main() {
  late LibraryNotifier libraryNotifier;
  late MockGetAllBooks mockGetAllBooks;
  late MockGetRecentBooks mockGetRecentBooks;
  late MockDeleteBook mockDeleteBook;

  setUpAll(() {
    registerFallbackValue(FakeBook());
  });

  setUp(() {
    mockGetAllBooks = MockGetAllBooks();
    mockGetRecentBooks = MockGetRecentBooks();
    mockDeleteBook = MockDeleteBook();

    // Default mock for loadBooks called in constructor
    when(() => mockGetAllBooks()).thenAnswer((_) async => const Right([]));

    libraryNotifier = LibraryNotifier(
      mockGetAllBooks,
      mockGetRecentBooks,
      mockDeleteBook,
    );
  });

  group('LibraryNotifier', () {
    final tBooks = [
      Book(
        id: 1,
        title: 'Book 1',
        author: 'Author 1',
        filePath: '/path/book1.epub',
        addedDate: DateTime(2025, 1, 1),
      ),
      Book(
        id: 2,
        title: 'Book 2',
        author: 'Author 2',
        filePath: '/path/book2.epub',
        addedDate: DateTime(2025, 1, 2),
      ),
      Book(
        id: 3,
        title: 'Book 3',
        author: 'Author 3',
        filePath: '/path/book3.epub',
        addedDate: DateTime(2025, 1, 3),
      ),
    ];

    group('loadBooks', () {
      test('should update state with books when successful', () async {
        // Arrange
        when(() => mockGetAllBooks()).thenAnswer((_) async => Right(tBooks));

        // Act
        await libraryNotifier.loadBooks();

        // Assert
        expect(libraryNotifier.state.books, tBooks);
        expect(libraryNotifier.state.isLoading, false);
        expect(libraryNotifier.state.error, null);
      });

      test('should update state with error when failed', () async {
        // Arrange
        when(() => mockGetAllBooks())
            .thenAnswer((_) async => Left(DatabaseFailure('Failed to load')));

        // Act
        await libraryNotifier.loadBooks();

        // Assert
        expect(libraryNotifier.state.books, isEmpty);
        expect(libraryNotifier.state.isLoading, false);
        expect(libraryNotifier.state.error, 'Failed to load');
      });

      test('should set isLoading to true while loading', () async {
        // Arrange
        when(() => mockGetAllBooks()).thenAnswer(
          (_) => Future.delayed(const Duration(milliseconds: 100), () => const Right([])),
        );

        // Act
        final future = libraryNotifier.loadBooks();

        // Assert - immediately after calling
        expect(libraryNotifier.state.isLoading, true);

        await future;
        expect(libraryNotifier.state.isLoading, false);
      });
    });

    group('deleteBook', () {
      test('should remove book from state when deletion succeeds', () async {
        // Arrange
        when(() => mockGetAllBooks()).thenAnswer((_) async => Right(tBooks));
        await libraryNotifier.loadBooks();

        when(() => mockDeleteBook(any())).thenAnswer((_) async => const Right(null));

        // Act
        await libraryNotifier.deleteBook(tBooks[0]);

        // Assert
        expect(libraryNotifier.state.books.length, 2);
        expect(libraryNotifier.state.books.contains(tBooks[0]), false);
        expect(libraryNotifier.state.error, null);
      });

      test('should update error when deletion fails', () async {
        // Arrange
        when(() => mockGetAllBooks()).thenAnswer((_) async => Right(tBooks));
        await libraryNotifier.loadBooks();

        when(() => mockDeleteBook(any()))
            .thenAnswer((_) async => Left(DatabaseFailure('Delete failed')));

        // Act
        await libraryNotifier.deleteBook(tBooks[0]);

        // Assert
        expect(libraryNotifier.state.books.length, 3); // Should not remove
        expect(libraryNotifier.state.error, 'Delete failed');
      });
    });

    group('deleteSelectedBooks', () {
      test('should delete all selected books and exit selection mode', () async {
        // Arrange
        when(() => mockGetAllBooks()).thenAnswer((_) async => Right(tBooks));
        await libraryNotifier.loadBooks();

        libraryNotifier.toggleSelectionMode();
        libraryNotifier.toggleBookSelection(1);
        libraryNotifier.toggleBookSelection(2);

        when(() => mockDeleteBook(any())).thenAnswer((_) async => const Right(null));

        // Act
        await libraryNotifier.deleteSelectedBooks();

        // Assert
        expect(libraryNotifier.state.books.length, 1);
        expect(libraryNotifier.state.isSelectionMode, false);
        expect(libraryNotifier.state.selectedBookIds, isEmpty);
      });
    });

    group('toggleSelectionMode', () {
      test('should toggle selection mode and clear selection', () {
        // Arrange
        libraryNotifier.toggleSelectionMode();
        libraryNotifier.toggleBookSelection(1);

        // Act
        libraryNotifier.toggleSelectionMode();

        // Assert
        expect(libraryNotifier.state.isSelectionMode, false);
        expect(libraryNotifier.state.selectedBookIds, isEmpty);
      });
    });

    group('toggleBookSelection', () {
      test('should add book to selection when not selected', () {
        // Arrange
        libraryNotifier.toggleSelectionMode();

        // Act
        libraryNotifier.toggleBookSelection(1);

        // Assert
        expect(libraryNotifier.state.selectedBookIds, {1});
      });

      test('should remove book from selection when already selected', () {
        // Arrange
        libraryNotifier.toggleSelectionMode();
        libraryNotifier.toggleBookSelection(1);

        // Act
        libraryNotifier.toggleBookSelection(1);

        // Assert
        expect(libraryNotifier.state.selectedBookIds, isEmpty);
      });

      test('should handle multiple book selections', () {
        // Arrange
        libraryNotifier.toggleSelectionMode();

        // Act
        libraryNotifier.toggleBookSelection(1);
        libraryNotifier.toggleBookSelection(2);
        libraryNotifier.toggleBookSelection(3);

        // Assert
        expect(libraryNotifier.state.selectedBookIds, {1, 2, 3});
      });
    });

    group('selectAll', () {
      test('should select all books', () async {
        // Arrange
        when(() => mockGetAllBooks()).thenAnswer((_) async => Right(tBooks));
        await libraryNotifier.loadBooks();

        // Act
        libraryNotifier.selectAll();

        // Assert
        expect(libraryNotifier.state.selectedBookIds, {1, 2, 3});
      });
    });

    group('deselectAll', () {
      test('should clear all selections', () async {
        // Arrange
        when(() => mockGetAllBooks()).thenAnswer((_) async => Right(tBooks));
        await libraryNotifier.loadBooks();
        libraryNotifier.selectAll();

        // Act
        libraryNotifier.deselectAll();

        // Assert
        expect(libraryNotifier.state.selectedBookIds, isEmpty);
      });
    });

    group('toggleViewMode', () {
      test('should toggle between grid and list view modes', () {
        // Arrange
        expect(libraryNotifier.state.viewMode, LibraryViewMode.grid);

        // Act
        libraryNotifier.toggleViewMode();

        // Assert
        expect(libraryNotifier.state.viewMode, LibraryViewMode.list);

        // Act again
        libraryNotifier.toggleViewMode();

        // Assert
        expect(libraryNotifier.state.viewMode, LibraryViewMode.grid);
      });
    });
  });
}
