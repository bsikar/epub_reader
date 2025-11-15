import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:epub_reader/core/database/app_database.dart' as db;
import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/features/reader/domain/usecases/update_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late db.AppDatabase database;
  late UpdateHighlight updateHighlight;
  late int testBookId;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    updateHighlight = UpdateHighlight(database);

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

  group('UpdateHighlight', () {
    test('should update highlight color', () async {
      // Arrange
      final highlightId = await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'Highlighted text',
              color: const Value('yellow'),
            ),
          );

      // Act
      final result = await updateHighlight(
        highlightId: highlightId,
        color: 'blue',
      );

      // Assert
      expect(result.isRight(), true);

      // Verify the update
      final highlight = await (database.select(database.highlights)
            ..where((tbl) => tbl.id.equals(highlightId)))
          .getSingle();

      expect(highlight.color, 'blue');
      expect(highlight.selectedText, 'Highlighted text'); // Unchanged
    });

    test('should update highlight note', () async {
      // Arrange
      final highlightId = await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'Highlighted text',
            ),
          );

      // Act
      final result = await updateHighlight(
        highlightId: highlightId,
        note: 'This is a new note',
      );

      // Assert
      expect(result.isRight(), true);

      // Verify the update
      final highlight = await (database.select(database.highlights)
            ..where((tbl) => tbl.id.equals(highlightId)))
          .getSingle();

      expect(highlight.note, 'This is a new note');
    });

    test('should update both color and note', () async {
      // Arrange
      final highlightId = await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'Highlighted text',
              color: const Value('yellow'),
            ),
          );

      // Act
      final result = await updateHighlight(
        highlightId: highlightId,
        color: 'green',
        note: 'Updated note',
      );

      // Assert
      expect(result.isRight(), true);

      // Verify the update
      final highlight = await (database.select(database.highlights)
            ..where((tbl) => tbl.id.equals(highlightId)))
          .getSingle();

      expect(highlight.color, 'green');
      expect(highlight.note, 'Updated note');
    });

    test('should set updatedAt timestamp', () async {
      // Arrange
      final highlightId = await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'Highlighted text',
            ),
          );

      final beforeUpdate = DateTime.now();

      // Act
      await updateHighlight(
        highlightId: highlightId,
        color: 'blue',
      );

      // Assert
      final highlight = await (database.select(database.highlights)
            ..where((tbl) => tbl.id.equals(highlightId)))
          .getSingle();

      expect(highlight.updatedAt, isNotNull);
      expect(highlight.updatedAt!.isAfter(beforeUpdate.subtract(const Duration(seconds: 1))), true);
      expect(highlight.updatedAt!.isBefore(DateTime.now().add(const Duration(seconds: 1))), true);
    });

    test('should remove note when set to null', () async {
      // Arrange
      final highlightId = await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'Highlighted text',
              note: const Value('Original note'),
            ),
          );

      // Act
      final result = await updateHighlight(
        highlightId: highlightId,
        note: null,
      );

      // Assert
      expect(result.isRight(), true);

      // Verify the update
      final highlight = await (database.select(database.highlights)
            ..where((tbl) => tbl.id.equals(highlightId)))
          .getSingle();

      expect(highlight.note, null);
    });

    test('should return failure when highlight not found', () async {
      // Act
      final result = await updateHighlight(
        highlightId: 99999,
        color: 'blue',
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<DatabaseFailure>());
          expect((failure as DatabaseFailure).message, 'Highlight not found');
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should keep existing color when not updated', () async {
      // Arrange
      final highlightId = await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'Highlighted text',
              color: const Value('red'),
            ),
          );

      // Act
      final result = await updateHighlight(
        highlightId: highlightId,
        note: 'Just adding a note',
      );

      // Assert
      expect(result.isRight(), true);

      // Verify the color is unchanged
      final highlight = await (database.select(database.highlights)
            ..where((tbl) => tbl.id.equals(highlightId)))
          .getSingle();

      expect(highlight.color, 'red'); // Original color preserved
      expect(highlight.note, 'Just adding a note');
    });

    test('should handle multiple sequential updates', () async {
      // Arrange
      final highlightId = await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'Highlighted text',
              color: const Value('yellow'),
            ),
          );

      // Act - First update
      await updateHighlight(
        highlightId: highlightId,
        color: 'blue',
      );

      // Act - Second update
      await updateHighlight(
        highlightId: highlightId,
        note: 'A note',
      );

      // Act - Third update
      final result = await updateHighlight(
        highlightId: highlightId,
        color: 'green',
        note: 'Updated note',
      );

      // Assert
      expect(result.isRight(), true);

      final highlight = await (database.select(database.highlights)
            ..where((tbl) => tbl.id.equals(highlightId)))
          .getSingle();

      expect(highlight.color, 'green');
      expect(highlight.note, 'Updated note');
    });

    test('should not modify cfiRange or selectedText', () async {
      // Arrange
      final originalCfi = 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)';
      final originalText = 'This is the original highlighted text';

      final highlightId = await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: originalCfi,
              selectedText: originalText,
            ),
          );

      // Act
      await updateHighlight(
        highlightId: highlightId,
        color: 'purple',
        note: 'New note',
      );

      // Assert
      final highlight = await (database.select(database.highlights)
            ..where((tbl) => tbl.id.equals(highlightId)))
          .getSingle();

      expect(highlight.cfiRange, originalCfi); // Unchanged
      expect(highlight.selectedText, originalText); // Unchanged
    });
  });
}
