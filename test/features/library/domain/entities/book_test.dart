import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Book Entity', () {
    final testDate = DateTime(2025, 1, 1);
    final testBook = Book(
      id: 1,
      title: 'Test Book',
      author: 'Test Author',
      filePath: '/test/path/book.epub',
      coverPath: '/test/path/cover.jpg',
      publisher: 'Test Publisher',
      language: 'en',
      description: 'Test description',
      addedDate: testDate,
      lastOpened: testDate,
    );

    test('should create a Book with all properties', () {
      expect(testBook.id, 1);
      expect(testBook.title, 'Test Book');
      expect(testBook.author, 'Test Author');
      expect(testBook.filePath, '/test/path/book.epub');
      expect(testBook.coverPath, '/test/path/cover.jpg');
      expect(testBook.publisher, 'Test Publisher');
      expect(testBook.language, 'en');
      expect(testBook.description, 'Test description');
      expect(testBook.addedDate, testDate);
      expect(testBook.lastOpened, testDate);
    });

    test('should create a Book with only required properties', () {
      final minimalBook = Book(
        title: 'Minimal Book',
        author: 'Minimal Author',
        filePath: '/minimal/path.epub',
        addedDate: testDate,
      );

      expect(minimalBook.id, null);
      expect(minimalBook.title, 'Minimal Book');
      expect(minimalBook.author, 'Minimal Author');
      expect(minimalBook.filePath, '/minimal/path.epub');
      expect(minimalBook.coverPath, null);
      expect(minimalBook.publisher, null);
      expect(minimalBook.language, null);
      expect(minimalBook.description, null);
      expect(minimalBook.lastOpened, null);
    });

    test('should create a copy with updated properties', () {
      final updatedBook = testBook.copyWith(
        title: 'Updated Title',
      );

      expect(updatedBook.id, 1);
      expect(updatedBook.title, 'Updated Title');
      expect(updatedBook.author, 'Test Author');
      expect(updatedBook.filePath, testBook.filePath);
    });

    test('should create a copy without changing original', () {
      final originalTitle = testBook.title;
      final updatedBook = testBook.copyWith(title: 'New Title');

      expect(testBook.title, originalTitle);
      expect(updatedBook.title, 'New Title');
    });

    test('should support equality comparison', () {
      final book1 = Book(
        id: 1,
        title: 'Book',
        author: 'Author',
        filePath: '/path.epub',
        addedDate: testDate,
      );

      final book2 = Book(
        id: 1,
        title: 'Book',
        author: 'Author',
        filePath: '/path.epub',
        addedDate: testDate,
      );

      expect(book1, equals(book2));
    });

    test('should have different hash codes for different books', () {
      final book1 = Book(
        id: 1,
        title: 'Book 1',
        author: 'Author',
        filePath: '/path1.epub',
        addedDate: testDate,
      );

      final book2 = Book(
        id: 2,
        title: 'Book 2',
        author: 'Author',
        filePath: '/path2.epub',
        addedDate: testDate,
      );

      expect(book1.hashCode, isNot(equals(book2.hashCode)));
    });

    test('should preserve values not specified in copyWith', () {
      final updatedBook = testBook.copyWith(
        title: 'New Title',
      );

      expect(updatedBook.coverPath, testBook.coverPath);
      expect(updatedBook.description, testBook.description);
      expect(updatedBook.title, 'New Title');
    });

  });
}
