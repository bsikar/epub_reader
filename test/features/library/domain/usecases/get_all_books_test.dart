import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/domain/repositories/library_repository.dart';
import 'package:epub_reader/features/library/domain/usecases/get_all_books.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLibraryRepository extends Mock implements LibraryRepository {}

void main() {
  late GetAllBooks getAllBooks;
  late MockLibraryRepository mockRepository;

  setUp(() {
    mockRepository = MockLibraryRepository();
    getAllBooks = GetAllBooks(mockRepository);
  });

  group('GetAllBooks', () {
    final tBooks = [
      Book(
        id: 1,
        title: 'Test Book 1',
        author: 'Author 1',
        filePath: '/test/path/book1.epub',
        addedDate: DateTime(2025, 1, 1),
      ),
      Book(
        id: 2,
        title: 'Test Book 2',
        author: 'Author 2',
        filePath: '/test/path/book2.epub',
        addedDate: DateTime(2025, 1, 2),
      ),
      Book(
        id: 3,
        title: 'Test Book 3',
        author: 'Author 3',
        filePath: '/test/path/book3.epub',
        addedDate: DateTime(2025, 1, 3),
      ),
    ];

    test('should return list of books from repository when successful', () async {
      // Arrange
      when(() => mockRepository.getAllBooks())
          .thenAnswer((_) async => Right(tBooks));

      // Act
      final result = await getAllBooks();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return books'),
        (books) {
          expect(books, tBooks);
          expect(books.length, 3);
          expect(books[0].title, 'Test Book 1');
          expect(books[1].title, 'Test Book 2');
          expect(books[2].title, 'Test Book 3');
        },
      );
      verify(() => mockRepository.getAllBooks()).called(1);
    });

    test('should return empty list when no books exist', () async {
      // Arrange
      when(() => mockRepository.getAllBooks())
          .thenAnswer((_) async => const Right([]));

      // Act
      final result = await getAllBooks();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return empty list'),
        (books) {
          expect(books, isEmpty);
          expect(books.length, 0);
        },
      );
      verify(() => mockRepository.getAllBooks()).called(1);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const tFailure = DatabaseFailure('Failed to fetch books');
      when(() => mockRepository.getAllBooks())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await getAllBooks();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<DatabaseFailure>());
          expect(failure.message, 'Failed to fetch books');
        },
        (_) => fail('Should return failure'),
      );
      verify(() => mockRepository.getAllBooks()).called(1);
    });

    test('should return storage failure when storage error occurs', () async {
      // Arrange
      const tFailure = StorageFailure('Storage error');
      when(() => mockRepository.getAllBooks())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await getAllBooks();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<StorageFailure>());
          expect(failure.message, 'Storage error');
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should return books in correct order', () async {
      // Arrange
      when(() => mockRepository.getAllBooks())
          .thenAnswer((_) async => Right(tBooks));

      // Act
      final result = await getAllBooks();

      // Assert
      result.fold(
        (_) => fail('Should return books'),
        (books) {
          expect(books[0].id, 1);
          expect(books[1].id, 2);
          expect(books[2].id, 3);
        },
      );
    });

    test('should handle large number of books', () async {
      // Arrange
      final manyBooks = List.generate(
        100,
        (index) => Book(
          id: index,
          title: 'Book $index',
          author: 'Author $index',
          filePath: '/test/path/book$index.epub',
          addedDate: DateTime(2025, 1, 1),
        ),
      );
      when(() => mockRepository.getAllBooks())
          .thenAnswer((_) async => Right(manyBooks));

      // Act
      final result = await getAllBooks();

      // Assert
      result.fold(
        (_) => fail('Should return books'),
        (books) {
          expect(books.length, 100);
          expect(books.first.title, 'Book 0');
          expect(books.last.title, 'Book 99');
        },
      );
    });

    test('should handle books with partial information', () async {
      // Arrange
      final booksWithPartialInfo = [
        Book(
          title: 'Minimal Book',
          author: 'Unknown',
          filePath: '/path/minimal.epub',
          addedDate: DateTime(2025, 1, 1),
        ),
      ];
      when(() => mockRepository.getAllBooks())
          .thenAnswer((_) async => Right(booksWithPartialInfo));

      // Act
      final result = await getAllBooks();

      // Assert
      result.fold(
        (_) => fail('Should return books'),
        (books) {
          expect(books.length, 1);
          expect(books[0].id, null);
          expect(books[0].coverPath, null);
          expect(books[0].title, 'Minimal Book');
        },
      );
    });

    test('should call repository only once per invocation', () async {
      // Arrange
      when(() => mockRepository.getAllBooks())
          .thenAnswer((_) async => Right(tBooks));

      // Act
      await getAllBooks();
      await getAllBooks();
      await getAllBooks();

      // Assert
      verify(() => mockRepository.getAllBooks()).called(3);
    });

    test('should handle different failure types', () async {
      // Arrange - Test each failure type
      final failures = [
        const DatabaseFailure('DB error'),
        const StorageFailure('Storage error'),
        const ParsingFailure('Parse error'),
        const UnknownFailure('Unknown error'),
      ];

      for (final failure in failures) {
        when(() => mockRepository.getAllBooks())
            .thenAnswer((_) async => Left(failure));

        // Act
        final result = await getAllBooks();

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
