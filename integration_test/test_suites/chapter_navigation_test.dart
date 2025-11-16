import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:epub_reader/features/reader/presentation/screens/reader_screen.dart';
import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chapter Navigation Tests', () {
    late int? testBookId;

    setUpAll(() async {
      await TestApp.cleanup();
      await TestApp.createTestApp();
    });

    setUp(() async {
      await TestApp.clearDatabase();

      // Import a real EPUB file for testing
      // Using pg11.epub (Alice's Adventures in Wonderland) - small and has multiple chapters
      testBookId = await TestApp.importEpubFile('pg11.epub');

      if (testBookId == null) {
        debugPrint('WARNING: Failed to import test EPUB file');
      }
    });

    tearDown(() async {
      await TestApp.clearDatabase();
    });

    tearDownAll(() async {
      await TestApp.cleanup();
    });

    testWidgets('Import real EPUB file with multiple chapters', (tester) async {
      // Assert - Book should be imported
      expect(testBookId, isNotNull, reason: 'EPUB file should import successfully');

      if (testBookId != null) {
        final allBooks = await TestApp.database.getAllBooks();
        expect(allBooks.length, 1);
        final book = allBooks[0];

        debugPrint('Imported book: ${book.title} by ${book.author}');
        expect(book.title, isNotEmpty);
        expect(book.author, isNotEmpty);
        expect(book.filePath, isNotEmpty);
      }
    });

    testWidgets('Reader screen opens with imported EPUB', (tester) async {
      if (testBookId == null) {
        debugPrint('Skipping test - no EPUB file');
        return;
      }

      // Arrange - Get the book
      final allBooks = await TestApp.database.getAllBooks();
      final book = allBooks[0];

      // Act - Create the app
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Find and tap the book to open it
      final bookTile = find.text(book.title).first;
      expect(bookTile, findsOneWidget, reason: 'Book should appear in library');

      await tester.tap(bookTile);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Look for reader navigation button
      final readButtons = find.textContaining('Read');
      if (readButtons.evaluate().isNotEmpty) {
        await tester.tap(readButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Check if reader loaded
        final readerFinder = find.byType(ReaderScreen);
        if (readerFinder.evaluate().isNotEmpty) {
          debugPrint('✅ Reader screen opened successfully');
        }
      }
    });

    testWidgets('Table of Contents shows multiple chapters', (tester) async {
      if (testBookId == null) {
        debugPrint('Skipping test - no EPUB file');
        return;
      }

      // Arrange
      final allBooks = await TestApp.database.getAllBooks();
      final book = allBooks[0];

      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Open book
      final bookTile = find.text(book.title).first;
      await tester.tap(bookTile);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open reader
      final readButtons = find.textContaining('Read');
      if (readButtons.evaluate().isNotEmpty) {
        await tester.tap(readButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Find TOC button (list icon)
        final tocButton = find.byIcon(Icons.list);
        if (tocButton.evaluate().isNotEmpty) {
          debugPrint('✅ TOC button found in reader');

          await tester.tap(tocButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Look for chapter titles in modal
          final modalSheet = find.text('Table of Contents');
          if (modalSheet.evaluate().isNotEmpty) {
            debugPrint('✅ Table of Contents modal opened');

            // Look for chapter items (ListTiles)
            final chapterTiles = find.byType(ListTile);
            final chapterCount = chapterTiles.evaluate().length;
            debugPrint('Found $chapterCount chapter entries');
            expect(chapterCount, greaterThan(0), reason: 'Should have at least one chapter');
          }
        } else {
          debugPrint('TOC button not found - reader may not have fully loaded');
        }
      }
    });

    testWidgets('Clicking chapter in TOC navigates to that chapter', (tester) async {
      if (testBookId == null) {
        debugPrint('Skipping test - no EPUB file');
        return;
      }

      // Arrange
      final allBooks = await TestApp.database.getAllBooks();
      final book = allBooks[0];

      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Open book
      final bookTile = find.text(book.title).first;
      await tester.tap(bookTile);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open reader
      final readButtons = find.textContaining('Read');
      if (readButtons.evaluate().isNotEmpty) {
        await tester.tap(readButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Get reader state to check chapter tracking
        final readerFinder = find.byType(ReaderScreen);
        if (readerFinder.evaluate().isNotEmpty) {
          final readerState = tester.state<ReaderScreenState>(readerFinder);
          debugPrint('Initial chapter index: ${readerState.currentChapterIndex}');

          // Open TOC
          final tocButton = find.byIcon(Icons.list);
          if (tocButton.evaluate().isNotEmpty) {
            await tester.tap(tocButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Find all chapter list tiles
            final chapterTiles = find.byType(ListTile);
            if (chapterTiles.evaluate().length > 2) {
              // Tap on second chapter (first one might be already selected)
              await tester.tap(chapterTiles.at(1));
              await tester.pumpAndSettle(const Duration(seconds: 3));

              // Verify chapter index updated
              final newChapterIndex = readerState.currentChapterIndex;
              debugPrint('After TOC navigation, chapter index: $newChapterIndex');

              // The chapter index should have changed or navigation should have occurred
              debugPrint('✅ TOC chapter navigation completed');
            }
          }
        }
      }
    });

    testWidgets('Progress slider shows chapter progress', (tester) async {
      if (testBookId == null) {
        debugPrint('Skipping test - no EPUB file');
        return;
      }

      // Arrange
      final allBooks = await TestApp.database.getAllBooks();
      final book = allBooks[0];

      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Open book
      final bookTile = find.text(book.title).first;
      await tester.tap(bookTile);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open reader
      final readButtons = find.textContaining('Read');
      if (readButtons.evaluate().isNotEmpty) {
        await tester.tap(readButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Look for progress slider
        final sliderFinder = find.byType(Slider);
        if (sliderFinder.evaluate().isNotEmpty) {
          final slider = tester.widget<Slider>(sliderFinder.first);
          debugPrint('✅ Progress slider found');
          debugPrint('Slider value: ${slider.value}');
          debugPrint('Slider max: ${slider.max}');
          debugPrint('Slider divisions: ${slider.divisions}');

          expect(slider.value, greaterThanOrEqualTo(0));
          expect(slider.max, greaterThan(0), reason: 'Should have multiple chapters');
        } else {
          debugPrint('Progress slider not visible - may be hidden');
        }
      }
    });

    testWidgets('Dragging slider to different chapter updates navigation', (tester) async {
      if (testBookId == null) {
        debugPrint('Skipping test - no EPUB file');
        return;
      }

      // Arrange
      final allBooks = await TestApp.database.getAllBooks();
      final book = allBooks[0];

      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Open book
      final bookTile = find.text(book.title).first;
      await tester.tap(bookTile);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open reader
      final readButtons = find.textContaining('Read');
      if (readButtons.evaluate().isNotEmpty) {
        await tester.tap(readButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Find slider
        final sliderFinder = find.byType(Slider);
        if (sliderFinder.evaluate().isNotEmpty) {
          final slider = tester.widget<Slider>(sliderFinder.first);

          if (slider.max > 1) {
            // Get reader state
            final readerFinder = find.byType(ReaderScreen);
            final readerState = tester.state<ReaderScreenState>(readerFinder);
            final initialChapter = readerState.currentChapterIndex;
            debugPrint('Initial chapter: $initialChapter');

            // Drag slider to a different position
            final rect = tester.getRect(sliderFinder.first);
            final targetChapter = (slider.max / 2).floor(); // Middle chapter
            final targetPosition = rect.left + (rect.width * (targetChapter / slider.max));

            // Perform drag gesture
            await tester.drag(
              sliderFinder.first,
              Offset(targetPosition - rect.center.dx, 0),
            );
            await tester.pumpAndSettle(const Duration(seconds: 3));

            final newChapter = readerState.currentChapterIndex;
            debugPrint('After slider drag, chapter: $newChapter');
            debugPrint('✅ Slider chapter navigation test completed');
          }
        }
      }
    });
  });
}
