import 'dart:io';
import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/domain/repositories/library_repository.dart';
import 'package:epub_reader/features/library/domain/usecases/delete_book.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLibraryRepository extends Mock implements LibraryRepository {}

void main() {
  late DeleteBook deleteBook;
  late MockLibraryRepository mockRepository;

  setUp(() {
    mockRepository = MockLibraryRepository();
    deleteBook = DeleteBook(mockRepository);
  });

  group('DeleteBook', () {
    final tBook = Book(
      id: 1,
      title: 'Test Book',
      author: 'Test Author',
      filePath: '/test/path/book.epub',
      coverPath: '/test/path/cover.jpg',
      addedDate: DateTime(2025, 1, 1),
    );

    test('should delete book from repository when book has valid ID', () async {
      // Arrange
      when(() => mockRepository.deleteBook(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await deleteBook(tBook);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.deleteBook(1)).called(1);
    });

    test('should return failure when book ID is null', () async {
      // Arrange
      final bookWithoutId = Book(
        title: 'Test Book',
        author: 'Test Author',
        filePath: '/test/path/book.epub',
        addedDate: DateTime(2025, 1, 1),
      );

      // Act
      final result = await deleteBook(bookWithoutId);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Book ID is null'),
        (_) => fail('Should return failure'),
      );
    });

    test('should return failure when repository fails to delete', () async {
      // Arrange
      when(() => mockRepository.deleteBook(any()))
          .thenAnswer((_) async => const Left(DatabaseFailure('Failed to delete')));

      // Act
      final result = await deleteBook(tBook);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to delete'),
        (_) => fail('Should return failure'),
      );
      verify(() => mockRepository.deleteBook(1)).called(1);
    });

    test('should handle exceptions gracefully', () async {
      // Arrange
      when(() => mockRepository.deleteBook(any()))
          .thenThrow(Exception('Unexpected error'));

      // Act
      final result = await deleteBook(tBook);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should delete EPUB file when it exists', () async {
      // Arrange - Create a temporary EPUB file
      final tempDir = Directory.systemTemp.createTempSync('delete_test_');
      final epubFile = File('${tempDir.path}/test.epub');
      await epubFile.writeAsBytes([0, 0, 0, 0]);

      final bookWithRealFile = Book(
        id: 1,
        title: 'Test Book',
        author: 'Test Author',
        filePath: epubFile.path,
        addedDate: DateTime(2025, 1, 1),
      );

      when(() => mockRepository.deleteBook(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await deleteBook(bookWithRealFile);

      // Assert
      expect(result.isRight(), true);
      expect(await epubFile.exists(), false); // File should be deleted

      // Clean up
      await tempDir.delete(recursive: true);
    });

    test('should delete cover file when it exists', () async {
      // Arrange - Create temporary EPUB and cover files
      final tempDir = Directory.systemTemp.createTempSync('delete_test_');
      final epubFile = File('${tempDir.path}/test.epub');
      final coverFile = File('${tempDir.path}/cover.jpg');
      await epubFile.writeAsBytes([0, 0, 0, 0]);
      await coverFile.writeAsBytes([0, 0, 0, 0]);

      final bookWithCover = Book(
        id: 1,
        title: 'Test Book',
        author: 'Test Author',
        filePath: epubFile.path,
        coverPath: coverFile.path,
        addedDate: DateTime(2025, 1, 1),
      );

      when(() => mockRepository.deleteBook(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await deleteBook(bookWithCover);

      // Assert
      expect(result.isRight(), true);
      expect(await epubFile.exists(), false); // EPUB should be deleted
      expect(await coverFile.exists(), false); // Cover should be deleted

      // Clean up
      await tempDir.delete(recursive: true);
    });

    test('should handle book with no cover path', () async {
      // Arrange - Create temporary EPUB file only
      final tempDir = Directory.systemTemp.createTempSync('delete_test_');
      final epubFile = File('${tempDir.path}/test.epub');
      await epubFile.writeAsBytes([0, 0, 0, 0]);

      final bookNoCover = Book(
        id: 1,
        title: 'Test Book',
        author: 'Test Author',
        filePath: epubFile.path,
        coverPath: null, // No cover path
        addedDate: DateTime(2025, 1, 1),
      );

      when(() => mockRepository.deleteBook(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await deleteBook(bookNoCover);

      // Assert
      expect(result.isRight(), true);
      expect(await epubFile.exists(), false); // EPUB should be deleted

      // Clean up
      await tempDir.delete(recursive: true);
    });

    test('should handle file deletion errors gracefully', () async {
      // Arrange - Use a path that will cause an error when trying to delete
      final bookWithBadPath = Book(
        id: 1,
        title: 'Test Book',
        author: 'Test Author',
        filePath: '/invalid/path/that/does/not/exist/book.epub',
        coverPath: '/invalid/path/that/does/not/exist/cover.jpg',
        addedDate: DateTime(2025, 1, 1),
      );

      when(() => mockRepository.deleteBook(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await deleteBook(bookWithBadPath);

      // Assert - Should succeed even if file deletion fails
      expect(result.isRight(), true);
      verify(() => mockRepository.deleteBook(1)).called(1);
    });

    test('should handle exceptions during file deletion', () async {
      // Arrange - Create a temp file and open it for reading to lock it
      final tempDir = Directory.systemTemp.createTempSync('delete_test_');
      final epubFile = File('${tempDir.path}/locked.epub');
      await epubFile.writeAsBytes([0, 0, 0, 0]);

      // Open the file to lock it (keep a handle open)
      final fileHandle = await epubFile.open(mode: FileMode.read);

      final bookWithLockedFile = Book(
        id: 1,
        title: 'Test Book',
        author: 'Test Author',
        filePath: epubFile.path,
        addedDate: DateTime(2025, 1, 1),
      );

      when(() => mockRepository.deleteBook(any()))
          .thenAnswer((_) async => const Right(null));

      try {
        // Act - Should not throw, just log the error
        final result = await deleteBook(bookWithLockedFile);

        // Assert - Should succeed even if file deletion throws
        expect(result.isRight(), true);
        verify(() => mockRepository.deleteBook(1)).called(1);
      } finally {
        // Clean up - close the file handle first
        await fileHandle.close();
        await tempDir.delete(recursive: true);
      }
    });
  });
}
