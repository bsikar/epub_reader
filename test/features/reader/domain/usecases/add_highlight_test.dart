import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:epub_reader/core/database/app_database.dart' as db;
import 'package:epub_reader/features/reader/domain/usecases/add_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late db.AppDatabase database;
  late AddHighlight addHighlight;
  late int testBookId;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addHighlight = AddHighlight(database);

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

  group('AddHighlight', () {
    test('should add highlight with all fields', () async {
      // Act
      final result = await addHighlight(
        bookId: testBookId,
        cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
        selectedText: 'This is the highlighted text',
        color: 'blue',
        note: 'Important passage',
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (highlightId) async {
          expect(highlightId, greaterThan(0));

          // Verify the highlight was inserted
          final highlights = await database.select(database.highlights).get();
          expect(highlights.length, 1);
          expect(highlights[0].bookId, testBookId);
          expect(highlights[0].cfiRange, 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)');
          expect(highlights[0].selectedText, 'This is the highlighted text');
          expect(highlights[0].color, 'blue');
          expect(highlights[0].note, 'Important passage');
        },
      );
    });

    test('should add highlight with default color when not specified', () async {
      // Act
      final result = await addHighlight(
        bookId: testBookId,
        cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
        selectedText: 'Highlighted text',
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (highlightId) async {
          final highlights = await database.select(database.highlights).get();
          expect(highlights.length, 1);
          expect(highlights[0].color, 'yellow'); // Default color
        },
      );
    });

    test('should add highlight without note', () async {
      // Act
      final result = await addHighlight(
        bookId: testBookId,
        cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
        selectedText: 'Highlighted text',
        color: 'green',
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (highlightId) async {
          final highlights = await database.select(database.highlights).get();
          expect(highlights.length, 1);
          expect(highlights[0].note, null);
        },
      );
    });

    test('should add multiple highlights to same book', () async {
      // Act
      await addHighlight(
        bookId: testBookId,
        cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
        selectedText: 'First highlight',
      );

      await addHighlight(
        bookId: testBookId,
        cfiRange: 'epubcfi(/6/6[chapter02]!/4/2,/1:0,/3:4)',
        selectedText: 'Second highlight',
      );

      // Assert
      final highlights = await database.select(database.highlights).get();
      expect(highlights.length, 2);
    });

    test('should handle long selected text', () async {
      // Arrange
      final longText = 'Lorem ipsum ' * 100;

      // Act
      final result = await addHighlight(
        bookId: testBookId,
        cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
        selectedText: longText,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (highlightId) async {
          final highlights = await database.select(database.highlights).get();
          expect(highlights[0].selectedText, longText);
        },
      );
    });

    test('should handle special characters in selected text', () async {
      // Act
      final result = await addHighlight(
        bookId: testBookId,
        cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
        selectedText: 'Text with "quotes" and \'apostrophes\' & special <chars>',
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (highlightId) async {
          final highlights = await database.select(database.highlights).get();
          expect(highlights[0].selectedText, 'Text with "quotes" and \'apostrophes\' & special <chars>');
        },
      );
    });

    test('should set createdAt timestamp', () async {
      // Arrange
      final beforeInsert = DateTime.now();

      // Act
      final result = await addHighlight(
        bookId: testBookId,
        cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
        selectedText: 'Highlighted text',
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (highlightId) async {
          final highlights = await database.select(database.highlights).get();
          expect(highlights[0].createdAt.isAfter(beforeInsert.subtract(const Duration(seconds: 1))), true);
          expect(highlights[0].createdAt.isBefore(DateTime.now().add(const Duration(seconds: 1))), true);
        },
      );
    });

    test('should not set updatedAt on creation', () async {
      // Act
      final result = await addHighlight(
        bookId: testBookId,
        cfiRange: 'epubcfi(/6/4[chapter01]!/4/2,/1:0,/3:4)',
        selectedText: 'Highlighted text',
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (highlightId) async {
          final highlights = await database.select(database.highlights).get();
          expect(highlights[0].updatedAt, null);
        },
      );
    });

    test('should support different highlight colors', () async {
      // Arrange
      final colors = ['yellow', 'blue', 'green', 'red', 'purple'];

      // Act & Assert
      for (var i = 0; i < colors.length; i++) {
        final result = await addHighlight(
          bookId: testBookId,
          cfiRange: 'epubcfi(/6/4[chapter0$i]!/4/2,/1:0,/3:4)',
          selectedText: 'Text $i',
          color: colors[i],
        );

        expect(result.isRight(), true);
      }

      final highlights = await database.select(database.highlights).get();
      expect(highlights.length, colors.length);
      for (var i = 0; i < colors.length; i++) {
        expect(highlights[i].color, colors[i]);
      }
    });
  });
}
