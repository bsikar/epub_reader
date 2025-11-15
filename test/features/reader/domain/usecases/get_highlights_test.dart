import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:epub_reader/core/database/app_database.dart' as db;
import 'package:epub_reader/features/reader/domain/usecases/get_highlights.dart';
import 'package:flutter_test/flutter_test.dart' hide isNull;

void main() {
  late db.AppDatabase database;
  late GetHighlights getHighlights;
  late int testBookId;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    getHighlights = GetHighlights(database);

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

  group('GetHighlights', () {
    test('should return empty list when no highlights exist', () async {
      // Act
      final result = await getHighlights(testBookId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (highlights) {
          expect(highlights, isEmpty);
        },
      );
    });

    test('should return all highlights for a book', () async {
      // Arrange - Add some highlights with explicit timestamps
      final now = DateTime.now();

      await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'First highlight',
              createdAt: Value(now.subtract(const Duration(hours: 1))),
            ),
          );

      await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/6[chapter02]!/4/2,/1:0,/3:4)',
              selectedText: 'Second highlight',
              createdAt: Value(now),
            ),
          );

      // Act
      final result = await getHighlights(testBookId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (highlights) {
          expect(highlights.length, 2);
          expect(highlights[0].selectedText, 'Second highlight'); // Most recent first
          expect(highlights[1].selectedText, 'First highlight');
        },
      );
    });

    test('should return highlights ordered by creation date descending', () async {
      // Arrange - Add highlights with explicit timestamps
      final now = DateTime.now();

      final highlight1Id = await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'First highlight',
              createdAt: Value(now.subtract(const Duration(minutes: 5))),
            ),
          );

      final highlight2Id = await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/6[chapter02]!/4/2,/1:0,/3:4)',
              selectedText: 'Second highlight',
              createdAt: Value(now),
            ),
          );

      // Act
      final result = await getHighlights(testBookId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (highlights) {
          expect(highlights.length, 2);
          expect(highlights[0].id, highlight2Id); // Most recent first
          expect(highlights[1].id, highlight1Id);
        },
      );
    });

    test('should only return highlights for specified book', () async {
      // Arrange - Create another book
      final otherBookId = await database.into(database.books).insert(
            db.BooksCompanion.insert(
              title: 'Other Book',
              author: 'Other Author',
              filePath: '/test/path/other.epub',
              addedDate: Value(DateTime.now()),
            ),
          );

      // Add highlights to both books
      await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'Test Book Highlight',
            ),
          );
      await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: otherBookId,
              cfiRange: 'epubcfi(/6/6[chapter02]!/4/2,/1:0,/3:4)',
              selectedText: 'Other Book Highlight',
            ),
          );

      // Act
      final result = await getHighlights(testBookId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (highlights) {
          expect(highlights.length, 1);
          expect(highlights[0].selectedText, 'Test Book Highlight');
          expect(highlights[0].bookId, testBookId);
        },
      );
    });

    test('should include optional note when present', () async {
      // Arrange
      await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'Highlighted text',
              note: const Value('This is a note'),
            ),
          );

      // Act
      final result = await getHighlights(testBookId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (highlights) {
          expect(highlights.length, 1);
          expect(highlights[0].note, 'This is a note');
        },
      );
    });

    test('should handle highlight without note', () async {
      // Arrange
      await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'Highlighted text',
            ),
          );

      // Act
      final result = await getHighlights(testBookId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (highlights) {
          expect(highlights.length, 1);
          expect(highlights[0].note, null);
        },
      );
    });

    test('should handle non-existent book ID', () async {
      // Act
      final result = await getHighlights(99999);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (highlights) {
          expect(highlights, isEmpty);
        },
      );
    });

    test('should include color information', () async {
      // Arrange
      await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'Highlighted text',
              color: const Value('blue'),
            ),
          );

      // Act
      final result = await getHighlights(testBookId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (highlights) {
          expect(highlights.length, 1);
          expect(highlights[0].color, 'blue');
        },
      );
    });

    test('should return highlights with different colors', () async {
      // Arrange
      final colors = ['yellow', 'blue', 'green'];
      for (var i = 0; i < colors.length; i++) {
        await database.into(database.highlights).insert(
              db.HighlightsCompanion.insert(
                bookId: testBookId,
                cfiRange: 'epubcfi(/6/4[chapter0$i]!/4/2,/1:0,/3:4)',
                selectedText: 'Text $i',
                color: Value(colors[i]),
              ),
            );
      }

      // Act
      final result = await getHighlights(testBookId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (highlights) {
          expect(highlights.length, colors.length);
        },
      );
    });

    test('should handle updatedAt timestamp when present', () async {
      // Arrange
      final now = DateTime.now();
      await database.into(database.highlights).insert(
            db.HighlightsCompanion.insert(
              bookId: testBookId,
              cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
              selectedText: 'Highlighted text',
              updatedAt: Value(now),
            ),
          );

      // Act
      final result = await getHighlights(testBookId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (highlights) {
          expect(highlights.length, 1);
          expect(highlights[0].updatedAt, isNotNull);
        },
      );
    });
  });
}
