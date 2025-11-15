import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:epub_reader/core/database/app_database.dart' as db;
import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/features/reader/domain/usecases/delete_bookmark.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late db.AppDatabase database;
  late DeleteBookmark deleteBookmark;
  late int testBookId;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    deleteBookmark = DeleteBookmark(database);

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

  group('DeleteBookmark', () {
    test('should delete existing bookmark', () async {
      // Arrange
      final bookmarkId = await database.into(database.bookmarks).insert(
            db.BookmarksCompanion.insert(
              bookId: testBookId,
              cfiLocation: 'cfi1',
              chapterName: 'Chapter 1',
              pageNumber: 1,
            ),
          );

      // Verify bookmark exists
      final beforeDelete = await database.select(database.bookmarks).get();
      expect(beforeDelete.length, 1);

      // Act
      final result = await deleteBookmark(bookmarkId);

      // Assert
      expect(result.isRight(), true);

      // Verify bookmark is deleted
      final afterDelete = await database.select(database.bookmarks).get();
      expect(afterDelete, isEmpty);
    });

    test('should successfully complete when deleting non-existent bookmark', () async {
      // Act - Try to delete a bookmark that doesn't exist
      final result = await deleteBookmark(99999);

      // Assert - Should succeed (no error even though nothing was deleted)
      expect(result.isRight(), true);
    });

    test('should only delete specified bookmark', () async {
      // Arrange - Create two bookmarks
      final bookmark1Id = await database.into(database.bookmarks).insert(
            db.BookmarksCompanion.insert(
              bookId: testBookId,
              cfiLocation: 'cfi1',
              chapterName: 'Chapter 1',
              pageNumber: 1,
            ),
          );

      final bookmark2Id = await database.into(database.bookmarks).insert(
            db.BookmarksCompanion.insert(
              bookId: testBookId,
              cfiLocation: 'cfi2',
              chapterName: 'Chapter 2',
              pageNumber: 2,
            ),
          );

      // Act - Delete only first bookmark
      final result = await deleteBookmark(bookmark1Id);

      // Assert
      expect(result.isRight(), true);

      final remainingBookmarks = await database.select(database.bookmarks).get();
      expect(remainingBookmarks.length, 1);
      expect(remainingBookmarks[0].id, bookmark2Id);
      expect(remainingBookmarks[0].chapterName, 'Chapter 2');
    });

    test('should delete bookmark with note', () async {
      // Arrange
      final bookmarkId = await database.into(database.bookmarks).insert(
            db.BookmarksCompanion.insert(
              bookId: testBookId,
              cfiLocation: 'cfi1',
              chapterName: 'Chapter 1',
              pageNumber: 1,
              note: const Value('Important note'),
            ),
          );

      // Act
      final result = await deleteBookmark(bookmarkId);

      // Assert
      expect(result.isRight(), true);

      final afterDelete = await database.select(database.bookmarks).get();
      expect(afterDelete, isEmpty);
    });

    test('should delete multiple bookmarks in sequence', () async {
      // Arrange - Create three bookmarks
      final ids = <int>[];
      for (int i = 1; i <= 3; i++) {
        final id = await database.into(database.bookmarks).insert(
              db.BookmarksCompanion.insert(
                bookId: testBookId,
                cfiLocation: 'cfi$i',
                chapterName: 'Chapter $i',
                pageNumber: i,
              ),
            );
        ids.add(id);
      }

      // Verify all exist
      var bookmarks = await database.select(database.bookmarks).get();
      expect(bookmarks.length, 3);

      // Act - Delete them one by one
      for (final id in ids) {
        final result = await deleteBookmark(id);
        expect(result.isRight(), true);
      }

      // Assert - All should be deleted
      bookmarks = await database.select(database.bookmarks).get();
      expect(bookmarks, isEmpty);
    });

    test('should handle concurrent deletes', () async {
      // Arrange - Create multiple bookmarks
      final ids = <int>[];
      for (int i = 1; i <= 3; i++) {
        final id = await database.into(database.bookmarks).insert(
              db.BookmarksCompanion.insert(
                bookId: testBookId,
                cfiLocation: 'cfi$i',
                chapterName: 'Chapter $i',
                pageNumber: i,
              ),
            );
        ids.add(id);
      }

      // Act - Delete all at once
      final results = await Future.wait(
        ids.map((id) => deleteBookmark(id)),
      );

      // Assert - All deletes should succeed
      for (final result in results) {
        expect(result.isRight(), true);
      }

      final afterDelete = await database.select(database.bookmarks).get();
      expect(afterDelete, isEmpty);
    });
  });
}
