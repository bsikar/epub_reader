import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/domain/repositories/library_repository.dart';
import 'package:epub_reader/features/library/domain/usecases/get_recent_books.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLibraryRepository extends Mock implements LibraryRepository {}

void main() {
  late GetRecentBooks getRecentBooks;
  late MockLibraryRepository mockRepository;

  setUp(() {
    mockRepository = MockLibraryRepository();
    getRecentBooks = GetRecentBooks(mockRepository);
  });

  group('GetRecentBooks', () {
    final tBooks = [
      Book(
        id: 3,
        title: 'Recent Book 3',
        author: 'Author 3',
        filePath: '/test/path/book3.epub',
        addedDate: DateTime(2025, 1, 3),
        lastOpened: DateTime(2025, 1, 15, 10, 0),
      ),
      Book(
        id: 2,
        title: 'Recent Book 2',
        author: 'Author 2',
        filePath: '/test/path/book2.epub',
        addedDate: DateTime(2025, 1, 2),
        lastOpened: DateTime(2025, 1, 14, 10, 0),
      ),
      Book(
        id: 1,
        title: 'Recent Book 1',
        author: 'Author 1',
        filePath: '/test/path/book1.epub',
        addedDate: DateTime(2025, 1, 1),
        lastOpened: DateTime(2025, 1, 13, 10, 0),
      ),
    ];

    test('should return recent books from repository with default limit', () async {
      // Arrange
      when(() => mockRepository.getRecentBooks(limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(tBooks));

      // Act
      final result = await getRecentBooks();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return books'),
        (books) {
          expect(books, tBooks);
          expect(books.length, 3);
        },
      );
      verify(() => mockRepository.getRecentBooks(limit: 10)).called(1);
    });

    test('should return recent books with custom limit', () async {
      // Arrange
      final limitedBooks = tBooks.take(2).toList();
      when(() => mockRepository.getRecentBooks(limit: 2))
          .thenAnswer((_) async => Right(limitedBooks));

      // Act
      final result = await getRecentBooks(limit: 2);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return books'),
        (books) {
          expect(books.length, 2);
          expect(books[0].id, 3);
          expect(books[1].id, 2);
        },
      );
      verify(() => mockRepository.getRecentBooks(limit: 2)).called(1);
    });

    test('should return empty list when no recent books exist', () async {
      // Arrange
      when(() => mockRepository.getRecentBooks(limit: any(named: 'limit')))
          .thenAnswer((_) async => const Right([]));

      // Act
      final result = await getRecentBooks();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return empty list'),
        (books) => expect(books, isEmpty),
      );
    });

    test('should return books in descending order by last opened', () async {
      // Arrange
      when(() => mockRepository.getRecentBooks(limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(tBooks));

      // Act
      final result = await getRecentBooks();

      // Assert
      result.fold(
        (_) => fail('Should return books'),
        (books) {
          // Most recent first
          expect(books[0].lastOpened, DateTime(2025, 1, 15, 10, 0));
          expect(books[1].lastOpened, DateTime(2025, 1, 14, 10, 0));
          expect(books[2].lastOpened, DateTime(2025, 1, 13, 10, 0));
        },
      );
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const tFailure = DatabaseFailure('Failed to fetch recent books');
      when(() => mockRepository.getRecentBooks(limit: any(named: 'limit')))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await getRecentBooks();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<DatabaseFailure>());
          expect(failure.message, 'Failed to fetch recent books');
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should handle limit of 1', () async {
      // Arrange
      final singleBook = [tBooks.first];
      when(() => mockRepository.getRecentBooks(limit: 1))
          .thenAnswer((_) async => Right(singleBook));

      // Act
      final result = await getRecentBooks(limit: 1);

      // Assert
      result.fold(
        (_) => fail('Should return books'),
        (books) {
          expect(books.length, 1);
          expect(books[0].title, 'Recent Book 3');
        },
      );
    });

    test('should handle large limit', () async {
      // Arrange
      when(() => mockRepository.getRecentBooks(limit: 100))
          .thenAnswer((_) async => Right(tBooks));

      // Act
      final result = await getRecentBooks(limit: 100);

      // Assert
      result.fold(
        (_) => fail('Should return books'),
        (books) => expect(books.length, 3), // Only 3 books exist
      );
      verify(() => mockRepository.getRecentBooks(limit: 100)).called(1);
    });

    test('should handle limit of 0', () async {
      // Arrange
      when(() => mockRepository.getRecentBooks(limit: 0))
          .thenAnswer((_) async => const Right([]));

      // Act
      final result = await getRecentBooks(limit: 0);

      // Assert
      result.fold(
        (_) => fail('Should return empty list'),
        (books) => expect(books, isEmpty),
      );
    });

    test('should respect different limit values', () async {
      // Arrange & Act & Assert
      final limits = [1, 5, 10, 20, 50];

      for (final limit in limits) {
        final expectedBooks = tBooks.take(limit).toList();
        when(() => mockRepository.getRecentBooks(limit: limit))
            .thenAnswer((_) async => Right(expectedBooks));

        final result = await getRecentBooks(limit: limit);

        result.fold(
          (_) => fail('Should return books'),
          (books) => expect(books.length, expectedBooks.length),
        );
        verify(() => mockRepository.getRecentBooks(limit: limit)).called(1);
      }
    });

    test('should handle books without last opened date', () async {
      // Arrange
      final booksWithoutLastOpened = [
        Book(
          id: 1,
          title: 'Never Opened',
          author: 'Author',
          filePath: '/path/book.epub',
          addedDate: DateTime(2025, 1, 1),
          lastOpened: null,
        ),
      ];
      when(() => mockRepository.getRecentBooks(limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(booksWithoutLastOpened));

      // Act
      final result = await getRecentBooks();

      // Assert
      result.fold(
        (_) => fail('Should return books'),
        (books) {
          expect(books.length, 1);
          expect(books[0].lastOpened, null);
        },
      );
    });

    test('should handle storage failure', () async {
      // Arrange
      const tFailure = StorageFailure('Storage error');
      when(() => mockRepository.getRecentBooks(limit: any(named: 'limit')))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await getRecentBooks();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<StorageFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should call repository with correct limit parameter', () async {
      // Arrange
      when(() => mockRepository.getRecentBooks(limit: 25))
          .thenAnswer((_) async => Right(tBooks));

      // Act
      await getRecentBooks(limit: 25);

      // Assert
      verify(() => mockRepository.getRecentBooks(limit: 25)).called(1);
      verifyNever(() => mockRepository.getRecentBooks(limit: 10));
    });

    test('should handle different failure types', () async {
      // Arrange
      final failures = [
        const DatabaseFailure('DB error'),
        const StorageFailure('Storage error'),
        const UnknownFailure('Unknown error'),
      ];

      for (final failure in failures) {
        when(() => mockRepository.getRecentBooks(limit: any(named: 'limit')))
            .thenAnswer((_) async => Left(failure));

        // Act
        final result = await getRecentBooks();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (f) => expect(f, failure),
          (_) => fail('Should return failure'),
        );
      }
    });
  });
}
