import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/domain/repositories/library_repository.dart';
import 'package:epub_reader/features/reader/domain/usecases/update_reading_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLibraryRepository extends Mock implements LibraryRepository {}

class FakeBook extends Fake implements Book {}

void main() {
  late UpdateReadingProgress updateReadingProgress;
  late MockLibraryRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeBook());
  });

  setUp(() {
    mockRepository = MockLibraryRepository();
    updateReadingProgress = UpdateReadingProgress(mockRepository);
  });

  group('UpdateReadingProgress', () {
    final tBook = Book(
      id: 1,
      title: 'Test Book',
      author: 'Test Author',
      filePath: '/test/path/book.epub',
      addedDate: DateTime(2025, 1, 1),
      readingProgress: 0.5,
      currentCfi: 'epubcfi(/6/4!/4/2/1:0)',
    );

    test('should update book with new CFI and progress', () async {
      // Arrange
      const newCfi = 'epubcfi(/6/4!/4/2/1:100)';
      const newProgress = 0.75;

      when(() => mockRepository.updateBook(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await updateReadingProgress(
        book: tBook,
        cfi: newCfi,
        progress: newProgress,
      );

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.updateBook(any(
        that: predicate<Book>((book) =>
          book.currentCfi == newCfi &&
          book.readingProgress == newProgress &&
          book.lastOpened != null
        )
      ))).called(1);
    });

    test('should update lastOpened timestamp', () async {
      // Arrange
      const newCfi = 'epubcfi(/6/4!/4/2/1:100)';
      final beforeTime = DateTime.now();

      when(() => mockRepository.updateBook(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      await updateReadingProgress(
        book: tBook,
        cfi: newCfi,
      );

      final afterTime = DateTime.now();

      // Assert
      verify(() => mockRepository.updateBook(any(
        that: predicate<Book>((book) =>
          book.lastOpened != null &&
          book.lastOpened!.isAfter(beforeTime.subtract(const Duration(seconds: 1))) &&
          book.lastOpened!.isBefore(afterTime.add(const Duration(seconds: 1)))
        )
      ))).called(1);
    });

    test('should preserve existing progress when not provided', () async {
      // Arrange
      const newCfi = 'epubcfi(/6/4!/4/2/1:200)';

      when(() => mockRepository.updateBook(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      await updateReadingProgress(
        book: tBook,
        cfi: newCfi,
      );

      // Assert
      verify(() => mockRepository.updateBook(any(
        that: predicate<Book>((book) =>
          book.readingProgress == tBook.readingProgress
        )
      ))).called(1);
    });

    test('should preserve other book properties', () async {
      // Arrange
      const newCfi = 'epubcfi(/6/4!/4/2/1:300)';

      when(() => mockRepository.updateBook(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      await updateReadingProgress(
        book: tBook,
        cfi: newCfi,
      );

      // Assert
      verify(() => mockRepository.updateBook(any(
        that: predicate<Book>((book) =>
          book.id == tBook.id &&
          book.title == tBook.title &&
          book.author == tBook.author &&
          book.filePath == tBook.filePath
        )
      ))).called(1);
    });

    test('should return failure when repository update fails', () async {
      // Arrange
      const newCfi = 'epubcfi(/6/4!/4/2/1:100)';
      const tFailure = DatabaseFailure('Update failed');

      when(() => mockRepository.updateBook(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await updateReadingProgress(
        book: tBook,
        cfi: newCfi,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<DatabaseFailure>());
          expect(failure.message, 'Update failed');
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should update progress to 0.0', () async {
      // Arrange
      const newCfi = 'epubcfi(/6/4!/4/2/1:0)';

      when(() => mockRepository.updateBook(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      await updateReadingProgress(
        book: tBook,
        cfi: newCfi,
        progress: 0.0,
      );

      // Assert
      verify(() => mockRepository.updateBook(any(
        that: predicate<Book>((book) => book.readingProgress == 0.0)
      ))).called(1);
    });

    test('should update progress to 1.0 (completion)', () async {
      // Arrange
      const newCfi = 'epubcfi(/6/4!/4/2/1:9999)';

      when(() => mockRepository.updateBook(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      await updateReadingProgress(
        book: tBook,
        cfi: newCfi,
        progress: 1.0,
      );

      // Assert
      verify(() => mockRepository.updateBook(any(
        that: predicate<Book>((book) => book.readingProgress == 1.0)
      ))).called(1);
    });

    test('should handle CFI update without progress change', () async {
      // Arrange
      const newCfi = 'epubcfi(/6/4!/4/2/1:150)';

      when(() => mockRepository.updateBook(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await updateReadingProgress(
        book: tBook,
        cfi: newCfi,
      );

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.updateBook(any(
        that: predicate<Book>((book) =>
          book.currentCfi == newCfi &&
          book.readingProgress == tBook.readingProgress
        )
      ))).called(1);
    });

    test('should handle multiple consecutive updates', () async {
      // Arrange
      when(() => mockRepository.updateBook(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      await updateReadingProgress(book: tBook, cfi: 'cfi1', progress: 0.1);
      await updateReadingProgress(book: tBook, cfi: 'cfi2', progress: 0.2);
      await updateReadingProgress(book: tBook, cfi: 'cfi3', progress: 0.3);

      // Assert
      verify(() => mockRepository.updateBook(any())).called(3);
    });

    test('should handle different failure types', () async {
      // Arrange
      final failures = [
        const DatabaseFailure('DB error'),
        const StorageFailure('Storage error'),
        const UnknownFailure('Unknown error'),
      ];

      for (final failure in failures) {
        when(() => mockRepository.updateBook(any()))
            .thenAnswer((_) async => Left(failure));

        // Act
        final result = await updateReadingProgress(
          book: tBook,
          cfi: 'test-cfi',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (f) => expect(f, failure),
          (_) => fail('Should return failure'),
        );
      }
    });

    test('should handle book without existing CFI', () async {
      // Arrange
      final bookWithoutCfi = Book(
        id: 2,
        title: 'New Book',
        author: 'Author',
        filePath: '/path/book.epub',
        addedDate: DateTime(2025, 1, 1),
      );
      const newCfi = 'epubcfi(/6/4!/4/2/1:0)';

      when(() => mockRepository.updateBook(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      await updateReadingProgress(
        book: bookWithoutCfi,
        cfi: newCfi,
      );

      // Assert
      verify(() => mockRepository.updateBook(any(
        that: predicate<Book>((book) => book.currentCfi == newCfi)
      ))).called(1);
    });

    test('should handle book with no reading progress', () async {
      // Arrange
      final bookNoProgress = Book(
        id: 3,
        title: 'Unread Book',
        author: 'Author',
        filePath: '/path/book.epub',
        addedDate: DateTime(2025, 1, 1),
        readingProgress: 0.0,
      );
      const newCfi = 'epubcfi(/6/4!/4/2/1:50)';
      const newProgress = 0.05;

      when(() => mockRepository.updateBook(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      await updateReadingProgress(
        book: bookNoProgress,
        cfi: newCfi,
        progress: newProgress,
      );

      // Assert
      verify(() => mockRepository.updateBook(any(
        that: predicate<Book>((book) =>
          book.readingProgress == newProgress &&
          book.currentCfi == newCfi
        )
      ))).called(1);
    });
  });
}
