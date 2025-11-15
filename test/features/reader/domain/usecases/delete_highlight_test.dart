import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:epub_reader/core/database/app_database.dart' as db;
import 'package:epub_reader/features/reader/domain/usecases/delete_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late db.AppDatabase database;
  late DeleteHighlight deleteHighlight;
  late int testBookId;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    deleteHighlight = DeleteHighlight(database);

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

  group('DeleteHighlight', () {
    test('should delete existing highlight', () async {
      // Arrange
      final highlightId = await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'Highlighted text',
            ),
          );

      // Verify highlight exists
      final beforeDelete = await database.select(database.highlights).get();
      expect(beforeDelete.length, 1);

      // Act
      final result = await deleteHighlight(highlightId);

      // Assert
      expect(result.isRight(), true);

      // Verify highlight is deleted
      final afterDelete = await database.select(database.highlights).get();
      expect(afterDelete, isEmpty);
    });

    test('should successfully complete when deleting non-existent highlight', () async {
      // Act - Try to delete a highlight that doesn't exist
      final result = await deleteHighlight(99999);

      // Assert - Should succeed (no error even though nothing was deleted)
      expect(result.isRight(), true);
    });

    test('should only delete specified highlight', () async {
      // Arrange - Create two highlights
      final highlight1Id = await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'First highlight',
            ),
          );

      final highlight2Id = await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/6[chapter02]!/4/2,/1:0,/3:4)',
              selectedText: 'Second highlight',
            ),
          );

      // Act - Delete only first highlight
      final result = await deleteHighlight(highlight1Id);

      // Assert
      expect(result.isRight(), true);

      final remainingHighlights = await database.select(database.highlights).get();
      expect(remainingHighlights.length, 1);
      expect(remainingHighlights[0].id, highlight2Id);
      expect(remainingHighlights[0].selectedText, 'Second highlight');
    });

    test('should delete highlight with note', () async {
      // Arrange
      final highlightId = await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'Highlighted text',
              note: const Value('Important note'),
            ),
          );

      // Act
      final result = await deleteHighlight(highlightId);

      // Assert
      expect(result.isRight(), true);

      final afterDelete = await database.select(database.highlights).get();
      expect(afterDelete, isEmpty);
    });

    test('should delete multiple highlights in sequence', () async {
      // Arrange - Create three highlights
      final ids = <int>[];
      for (int i = 1; i <= 3; i++) {
        final id = await database.into(database.highlights).insert(
              db.HighlightsCompanion.insert(
                bookId: testBookId,
                cfiRange: 'epubcfi(/6/4[chapter0$i]!/4/2,/1:0,/3:4)',
                selectedText: 'Highlight $i',
              ),
            );
        ids.add(id);
      }

      // Verify all exist
      var highlights = await database.select(database.highlights).get();
      expect(highlights.length, 3);

      // Act - Delete them one by one
      for (final id in ids) {
        final result = await deleteHighlight(id);
        expect(result.isRight(), true);
      }

      // Assert - All should be deleted
      highlights = await database.select(database.highlights).get();
      expect(highlights, isEmpty);
    });

    test('should handle concurrent deletes', () async {
      // Arrange - Create multiple highlights
      final ids = <int>[];
      for (int i = 1; i <= 3; i++) {
        final id = await database.into(database.highlights).insert(
              db.HighlightsCompanion.insert(
                bookId: testBookId,
                cfiRange: 'epubcfi(/6/4[chapter0$i]!/4/2,/1:0,/3:4)',
                selectedText: 'Highlight $i',
              ),
            );
        ids.add(id);
      }

      // Act - Delete all at once
      final results = await Future.wait(
        ids.map((id) => deleteHighlight(id)),
      );

      // Assert - All deletes should succeed
      for (final result in results) {
        expect(result.isRight(), true);
      }

      final afterDelete = await database.select(database.highlights).get();
      expect(afterDelete, isEmpty);
    });

    test('should delete highlight with custom color', () async {
      // Arrange
      final highlightId = await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'Highlighted text',
              color: const Value('purple'),
            ),
          );

      // Act
      final result = await deleteHighlight(highlightId);

      // Assert
      expect(result.isRight(), true);

      final afterDelete = await database.select(database.highlights).get();
      expect(afterDelete, isEmpty);
    });

    test('should delete highlight with updatedAt timestamp', () async {
      // Arrange
      final highlightId = await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'Highlighted text',
              updatedAt: Value(DateTime.now()),
            ),
          );

      // Act
      final result = await deleteHighlight(highlightId);

      // Assert
      expect(result.isRight(), true);

      final afterDelete = await database.select(database.highlights).get();
      expect(afterDelete, isEmpty);
    });

    test('should not affect highlights from other books', () async {
      // Arrange - Create another book
      final otherBookId = await database.into(database.books).insert(
            db.BooksCompanion.insert(
              title: 'Other Book',
              author: 'Other Author',
              filePath: '/test/path/other.epub',
              addedDate: Value(DateTime.now()),
            ),
          );

      // Create highlights for both books
      final testBookHighlightId = await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'Test book highlight',
            ),
          );

      await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: otherBookId,
              cfiRange: 'epubcfi(/6/6[chapter02]!/4/2,/1:0,/3:4)',
              selectedText: 'Other book highlight',
            ),
          );

      // Act - Delete only the test book highlight
      final result = await deleteHighlight(testBookHighlightId);

      // Assert
      expect(result.isRight(), true);

      final remainingHighlights = await database.select(database.highlights).get();
      expect(remainingHighlights.length, 1);
      expect(remainingHighlights[0].selectedText, 'Other book highlight');
      expect(remainingHighlights[0].bookId, otherBookId);
    });
  });
}
