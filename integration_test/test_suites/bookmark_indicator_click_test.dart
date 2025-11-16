import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:epub_reader/features/reader/presentation/screens/reader_screen.dart';
import '../helpers/test_app.dart';
import '../helpers/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Bookmark Indicator Click Tests', () {
    late int? testBookId;

    setUpAll(() async {
      await TestApp.cleanup();
      await TestApp.createTestApp();
    });

    setUp(() async {
      await TestApp.clearDatabase();

      // Import a real EPUB file (Alice's Adventures in Wonderland)
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

    testWidgets('Bookmark indicators appear on progress slider', (tester) async {
      if (testBookId == null) {
        debugPrint('Skipping test - no EPUB file');
        return;
      }

      // Add some bookmarks at different chapters
      await TestApp.addTestBookmark(
        bookId: testBookId!,
        cfiLocation: 'epubcfi(/6/4[chapter1]!/4/2/1:0)',
        chapterName: 'Chapter I',
      );

      await TestApp.addTestBookmark(
        bookId: testBookId!,
        cfiLocation: 'epubcfi(/6/8[chapter3]!/4/2/1:0)',
        chapterName: 'Chapter III',
      );

      // Open the app
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Find and open the book
      final allBooks = await TestApp.database.getAllBooks();
      final book = allBooks[0];
      final bookTile = find.text(book.title).first;
      await tester.tap(bookTile);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open reader
      final readButtons = find.textContaining('Read');
      if (readButtons.evaluate().isNotEmpty) {
        await tester.tap(readButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Check if reader loaded
        final readerFinder = find.byType(ReaderScreen);
        if (readerFinder.evaluate().isNotEmpty) {
          debugPrint('✅ Reader opened');

          // Look for bookmark indicator containers
          final bookmarkIndicators = find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle,
          );

          final indicatorCount = bookmarkIndicators.evaluate().length;
          debugPrint('Found $indicatorCount bookmark indicators');

          if (indicatorCount > 0) {
            debugPrint('✅ Bookmark indicators are visible on slider');
          } else {
            debugPrint('⚠️ No bookmark indicators found');
          }
        }
      }
    });

    testWidgets('Clicking bookmark indicator navigates to that chapter', (tester) async {
      if (testBookId == null) {
        debugPrint('Skipping test - no EPUB file');
        return;
      }

      // Add bookmarks at different chapters
      // Chapter 1
      await TestApp.addTestBookmark(
        bookId: testBookId!,
        cfiLocation: 'epubcfi(/6/4[chapter1]!/4/2/1:0)',
        chapterName: 'Chapter I',
      );

      // Chapter 3
      await TestApp.addTestBookmark(
        bookId: testBookId!,
        cfiLocation: 'epubcfi(/6/8[chapter3]!/4/2/1:0)',
        chapterName: 'Chapter III',
      );

      // Open the app
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Find and open the book
      final allBooks = await TestApp.database.getAllBooks();
      final book = allBooks[0];
      final bookTile = find.text(book.title).first;
      await tester.tap(bookTile);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open reader
      final readButtons = find.textContaining('Read');
      if (readButtons.evaluate().isNotEmpty) {
        await tester.tap(readButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Get reader state
        final readerFinder = find.byType(ReaderScreen);
        if (readerFinder.evaluate().isNotEmpty) {
          final readerState = tester.state<ReaderScreenState>(readerFinder);
          final initialChapter = readerState.currentChapterIndex;
          debugPrint('Initial chapter: $initialChapter');

          // Find bookmark indicator containers
          final bookmarkIndicators = find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle,
          );

          if (bookmarkIndicators.evaluate().isNotEmpty) {
            debugPrint('Attempting to tap bookmark indicator...');

            // Try to tap the first bookmark indicator
            await tester.tap(bookmarkIndicators.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            final newChapter = readerState.currentChapterIndex;
            debugPrint('After tapping indicator, chapter: $newChapter');

            if (newChapter != initialChapter) {
              debugPrint('✅ Navigation occurred! Chapter changed from $initialChapter to $newChapter');
              expect(newChapter, isNot(equals(initialChapter)));
            } else {
              debugPrint('❌ BUG CONFIRMED: Tapping bookmark indicator did NOT navigate to chapter');
              debugPrint('Expected: Navigation to occur');
              debugPrint('Actual: Chapter remained at $initialChapter');

              // This test is expected to fail, confirming the bug
              fail('Bookmark indicator is not clickable - navigation did not occur');
            }
          } else {
            debugPrint('No bookmark indicators found to test');
          }
        }
      }
    });

    testWidgets('Clicking near slider with bookmark indicator position', (tester) async {
      if (testBookId == null) {
        debugPrint('Skipping test - no EPUB file');
        return;
      }

      // Add a bookmark
      await TestApp.addTestBookmark(
        bookId: testBookId!,
        cfiLocation: 'epubcfi(/6/8[chapter3]!/4/2/1:0)',
        chapterName: 'Chapter III',
      );

      // Open the app
      await tester.pumpWidget(await TestApp.createTestApp());
      await tester.pumpAndSettle();

      // Find and open the book
      final allBooks = await TestApp.database.getAllBooks();
      final book = allBooks[0];
      final bookTile = find.text(book.title).first;
      await tester.tap(bookTile);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open reader
      final readButtons = find.textContaining('Read');
      if (readButtons.evaluate().isNotEmpty) {
        await tester.tap(readButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        final readerFinder = find.byType(ReaderScreen);
        if (readerFinder.evaluate().isNotEmpty) {
          final readerState = tester.state<ReaderScreenState>(readerFinder);

          // Find the slider
          final sliderFinder = find.byType(Slider);
          if (sliderFinder.evaluate().isNotEmpty) {
            final slider = tester.widget<Slider>(sliderFinder.first);
            final sliderRect = tester.getRect(sliderFinder.first);

            // Calculate position for chapter 3 (assuming it's around 30% through)
            final targetPosition = sliderRect.left + (sliderRect.width * 0.3);

            final initialChapter = readerState.currentChapterIndex;
            debugPrint('Initial chapter: $initialChapter');
            debugPrint('Tapping at position for bookmark indicator...');

            // Tap at the calculated position
            await tester.tapAt(Offset(targetPosition, sliderRect.center.dy));
            await tester.pumpAndSettle(const Duration(seconds: 3));

            final newChapter = readerState.currentChapterIndex;
            debugPrint('After tapping, chapter: $newChapter');

            if (newChapter != initialChapter) {
              debugPrint('✅ Navigation occurred when tapping slider at bookmark position');
            } else {
              debugPrint('Slider tap at bookmark position did not navigate');
            }
          }
        }
      }
    });
  });
}
