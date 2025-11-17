import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:epub_reader/core/database/app_database.dart' as db;
import 'package:epub_reader/features/reader/domain/usecases/get_bookmarks.dart';
import 'package:flutter_test/flutter_test.dart' hide isNull;

void main() {
  late db.AppDatabase database;
  late GetBookmarks getBookmarks;
  late int testBookId;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    getBookmarks = GetBookmarks(database);

    // Create a test book
    testBookId = await database.into(database.books).insert(
          db.BooksCompanion.insert(
            title: 'Test Book',
            author: 'Test Author',
            filePath: '/test/path/book.epub',
            addedDate: Value(DateTime.now()),
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  group('GetBookmarks', () {
    test('should return empty list when no bookmarks exist', () async {
      // Act
      final result = await getBookmarks(testBookId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (bookmarks) {
          expect(bookmarks, isEmpty);
        },
      );
    });

    test('should return all bookmarks for a book', () async {
      // Arrange - Add some bookmarks with explicit timestamps
      final now = DateTime.now();

      await database.into(database.bookmarks).insert(
            db.BookmarksCompanion.insert(
              bookId: testBookId,
              cfiLocation: 'cfi1',
              chapterName: 'Chapter 1',
              pageNumber: 1,
              createdAt: Value(now.subtract(const Duration(hours: 1))),
            ),
          );

      await database.into(database.bookmarks).insert(
            db.BookmarksCompanion.insert(
              bookId: testBookId,
              cfiLocation: 'cfi2',
              chapterName: 'Chapter 2',
              pageNumber: 2,
              createdAt: Value(now),
            ),
          );

      // Act
      final result = await getBookmarks(testBookId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (bookmarks) {
          expect(bookmarks.length, 2);
          expect(bookmarks[0].chapterName, 'Chapter 2'); // Most recent first
          expect(bookmarks[1].chapterName, 'Chapter 1');
        },
      );
    });

    test('should return bookmarks ordered by creation date descending', () async {
      // Arrange - Add bookmarks with explicit timestamps
      final now = DateTime.now();

      final bookmark1Id = await database.into(database.bookmarks).insert(
            db.BookmarksCompanion.insert(
              bookId: testBookId,
              cfiLocation: 'cfi1',
              chapterName: 'First Bookmark',
              pageNumber: 1,
              createdAt: Value(now.subtract(const Duration(minutes: 5))),
            ),
          );

      final bookmark2Id = await database.into(database.bookmarks).insert(
            db.BookmarksCompanion.insert(
              bookId: testBookId,
              cfiLocation: 'cfi2',
              chapterName: 'Second Bookmark',
              pageNumber: 2,
              createdAt: Value(now),
            ),
          );

      // Act
      final result = await getBookmarks(testBookId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (bookmarks) {
          expect(bookmarks.length, 2);
          expect(bookmarks[0].id, bookmark2Id); // Most recent first
          expect(bookmarks[1].id, bookmark1Id);
        },
      );
    });

    test('should only return bookmarks for specified book', () async {
      // Arrange - Create another book
      final otherBookId = await database.into(database.books).insert(
            db.BooksCompanion.insert(
              title: 'Other Book',
              author: 'Other Author',
              filePath: '/test/path/other.epub',
              addedDate: Value(DateTime.now()),
            ),
          );

      // Add bookmarks to both books
      await database.into(database.bookmarks).insert(
            db.BookmarksCompanion.insert(
              bookId: testBookId,
              cfiLocation: 'cfi1',
              chapterName: 'Test Book Chapter',
              pageNumber: 1,
            ),
          );
      await database.into(database.bookmarks).insert(
            db.BookmarksCompanion.insert(
              bookId: otherBookId,
              cfiLocation: 'cfi2',
              chapterName: 'Other Book Chapter',
              pageNumber: 1,
            ),
          );

      // Act
      final result = await getBookmarks(testBookId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (bookmarks) {
          expect(bookmarks.length, 1);
          expect(bookmarks[0].chapterName, 'Test Book Chapter');
          expect(bookmarks[0].bookId, testBookId);
        },
      );
    });

    test('should include optional note when present', () async {
      // Arrange
      await database.into(database.bookmarks).insert(
            db.BookmarksCompanion.insert(
              bookId: testBookId,
              cfiLocation: 'cfi1',
              chapterName: 'Chapter 1',
              pageNumber: 1,
              note: const Value('This is a note'),
            ),
          );

      // Act
      final result = await getBookmarks(testBookId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (bookmarks) {
          expect(bookmarks.length, 1);
          expect(bookmarks[0].note, 'This is a note');
        },
      );
    });

    test('should handle bookmark without note', () async {
      // Arrange
      await database.into(database.bookmarks).insert(
            db.BookmarksCompanion.insert(
              bookId: testBookId,
              cfiLocation: 'cfi1',
              chapterName: 'Chapter 1',
              pageNumber: 1,
            ),
          );

      // Act
      final result = await getBookmarks(testBookId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (bookmarks) {
          expect(bookmarks.length, 1);
          expect(bookmarks[0].note, null);
        },
      );
    });

    test('should handle non-existent book ID', () async {
      // Act
      final result = await getBookmarks(99999);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (bookmarks) {
          expect(bookmarks, isEmpty);
        },
      );
    });
  });
}
