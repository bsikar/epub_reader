import 'dart:io';
import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/domain/repositories/library_repository.dart';
import 'package:epub_reader/features/library/domain/usecases/delete_book.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'delete_book_test.mocks.dart';

@GenerateMocks([LibraryRepository])
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
      when(mockRepository.deleteBook(any))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await deleteBook(tBook);

      // Assert
      expect(result.isRight(), true);
      verify(mockRepository.deleteBook(1)).called(1);
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
      when(mockRepository.deleteBook(any))
          .thenAnswer((_) async => const Left(DatabaseFailure('Failed to delete')));

      // Act
      final result = await deleteBook(tBook);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to delete'),
        (_) => fail('Should return failure'),
      );
      verify(mockRepository.deleteBook(1)).called(1);
    });

    test('should handle exceptions gracefully', () async {
      // Arrange
      when(mockRepository.deleteBook(any))
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
  });
}
