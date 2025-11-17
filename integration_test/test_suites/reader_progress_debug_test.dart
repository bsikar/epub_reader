import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:epub_view/epub_view.dart';
import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Reader Progress Bar Debug Tests', () {
    late Widget app;
    late int bookId;

    setUpAll(() async {
      // Create the app once for all tests
      app = await TestApp.createTestApp();
    });

    setUp() async {
      // Clear database and import book before each test
      await TestApp.clearDatabase();
      bookId = (await TestApp.importEpubFile('pg11.epub'))!;
      expect(bookId, isNotNull, reason: 'Book import should succeed');
      // Wait for library to refresh
      await TestApp.refreshLibrary();
    }

    tearDownAll() async {
      await TestApp.cleanup();
    }

    Future<void> waitForWidget(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 60)}) async {
      final end = DateTime.now().add(timeout);
      while (DateTime.now().isBefore(end)) {
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        if (finder.evaluate().isNotEmpty) {
          print('Widget found: $finder');
          return;
        }
        // Also check for error messages
        final errorFinder = find.textContaining('Error');
        if (errorFinder.evaluate().isNotEmpty) {
          print('ERROR found in UI!');
          for (final element in errorFinder.evaluate()) {
            final widget = element.widget;
            if (widget is Text) {
              print('Error text: ${widget.data}');
            }
          }
        }
      }
      // Print what's actually visible
      print('FAILED to find widget. Current widgets:');
      final allWidgets = find.byType(Widget);
      int count = 0;
      for (final element in allWidgets.evaluate().take(20)) {
        print('  ${element.widget.runtimeType}');
        count++;
      }
      print('  ... (showing first $count widgets)');

      throw TestFailure('Widget not found after ${timeout.inSeconds}s: $finder');
    }

    testWidgets('Debug Issue 1: Scrolling does not update progress bar', (tester) async {
      print('===== TEST 1: Scrolling does not update progress bar =====');

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Find and tap Alice book
      final aliceFinder = find.textContaining('Alice');
      await waitForWidget(tester, aliceFinder, timeout: const Duration(seconds: 10));
      await tester.tap(aliceFinder.first);
      await tester.pumpAndSettle();
      print('Opened book details');

      // Find the FloatingActionButton (the "Start Reading" button)
      final fabFinder = find.byType(FloatingActionButton);
      await waitForWidget(tester, fabFinder, timeout: const Duration(seconds: 10));

      print('DEBUG: About to tap FAB button...');
      await tester.tap(fabFinder);
      print('DEBUG: Tapped, now pumping frames...');

      // Pump frames slowly to see what happens
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        final widgetCount = find.byType(Widget).evaluate().length;
        print('DEBUG: Frame $i - widget count: $widgetCount');

        // Check for common widgets
        final scaffoldCount = find.byType(Scaffold).evaluate().length;
        final materialAppCount = find.byType(MaterialApp).evaluate().length;
        final errorCount = find.textContaining('Error').evaluate().length;
        print('  Scaffolds: $scaffoldCount, MaterialApps: $materialAppCount, Errors: $errorCount');

        if (errorCount > 0) {
          print('  ERROR FOUND IN UI!');
          for (final element in find.textContaining('Error').evaluate()) {
            final widget = element.widget;
            if (widget is Text) {
              print('    Error text: ${widget.data}');
            }
          }
        }
      }

      await tester.pumpAndSettle();
      print('Tapped reading button and settled');

      // Check what we have now
      final totalWidgets = find.byType(Widget).evaluate().length;
      print('DEBUG: After settle - total widgets: $totalWidgets');

      if (totalWidgets > 0) {
        print('DEBUG: Widget types present:');
        final widgetTypes = <String>{};
        for (final element in find.byType(Widget).evaluate().take(50)) {
          widgetTypes.add(element.widget.runtimeType.toString());
        }
        for (final type in widgetTypes.take(20)) {
          print('  - $type');
        }
      }

      // Wait for loading to complete (CircularProgressIndicator to disappear)
      print('Waiting for EPUB to load (checking for progress indicator to disappear)...');
      final loadingFinder = find.byType(CircularProgressIndicator);
      if (loadingFinder.evaluate().isNotEmpty) {
        print('Found loading indicator, waiting for it to disappear...');
        final endWait = DateTime.now().add(const Duration(seconds: 60));
        while (DateTime.now().isBefore(endWait)) {
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
          if (loadingFinder.evaluate().isEmpty) {
            print('Loading completed!');
            break;
          }
        }
      } else {
        print('No loading indicator found');
      }

      // Now look for EpubView
      print('Looking for EpubView...');
      final epubViewFinder = find.byType(EpubView);
      await waitForWidget(tester, epubViewFinder, timeout: const Duration(seconds: 10));
      print('EpubView loaded!');

      // Wait for progress bar chapter text
      await tester.pumpAndSettle(const Duration(seconds: 2));
      final chapterFinder = find.textContaining('Chapter');

      String getChapter() {
        if (chapterFinder.evaluate().isNotEmpty) {
          return tester.widget<Text>(chapterFinder.first).data ?? 'Unknown';
        }
        return 'No chapter found';
      }

      print('Initial chapter: ${getChapter()}');

      // Scroll down 3 times
      for (int i = 0; i < 3; i++) {
        print('Scrolling ${i + 1}/3...');
        await tester.drag(epubViewFinder, const Offset(0, -500));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        print('After scroll ${i + 1}: ${getChapter()}');
      }

      // Extensive scrolling
      print('Extensive scrolling (5 more)...');
      for (int i = 0; i < 5; i++) {
        await tester.drag(epubViewFinder, const Offset(0, -600));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      await tester.pumpAndSettle(const Duration(seconds: 2));
      print('Final chapter: ${getChapter()}');
      print('ISSUE 1 COMPLETE');
      print('=====\n');
    });

    testWidgets('Debug Issue 2a: Tapping progress bar does not change chapters', (tester) async {
      print('===== TEST 2a: Tapping progress bar =====');

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      final aliceFinder = find.textContaining('Alice');
      await waitForWidget(tester, aliceFinder, timeout: const Duration(seconds: 10));
      await tester.tap(aliceFinder.first);
      await tester.pumpAndSettle();

      final fabFinder = find.byType(FloatingActionButton);
      await waitForWidget(tester, fabFinder, timeout: const Duration(seconds: 10));
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Wait for loading
      print('Waiting for loading to complete...');
      await tester.pumpAndSettle(const Duration(seconds: 15));

      // Wait for slider and chapter indicator
      final sliderFinder = find.byType(Slider);
      await waitForWidget(tester, sliderFinder, timeout: const Duration(seconds: 10));

      await tester.pumpAndSettle(const Duration(seconds: 2));
      final chapterFinder = find.textContaining('Chapter');

      String getChapter() {
        if (chapterFinder.evaluate().isNotEmpty) {
          return tester.widget<Text>(chapterFinder.first).data ?? 'Unknown';
        }
        return 'No chapter found';
      }

      final sliderWidget = tester.widget<Slider>(sliderFinder);
      final initialValue = sliderWidget.value;
      final maxValue = sliderWidget.max;
      final initialChapter = getChapter();
      print('Initial slider: $initialValue / $maxValue');
      print('Initial chapter: $initialChapter');

      // Tap at 75% position (chapter 11 out of 15)
      final sliderRect = tester.getRect(sliderFinder);
      final tapX = sliderRect.left + (sliderRect.width * 0.75);
      final tapY = sliderRect.center.dy;

      print('Tapping slider at 75% (${tapX.toInt()}, ${tapY.toInt()})');
      await tester.tapAt(Offset(tapX, tapY));

      // Wait a bit longer and pump multiple times to allow navigation to complete
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 300));
        print('Pump $i: Chapter indicator shows: ${getChapter()}');
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final newSliderWidget = tester.widget<Slider>(sliderFinder);
      final newValue = newSliderWidget.value;
      final newChapter = getChapter();

      print('New slider: $newValue / $maxValue');
      print('New chapter: $newChapter');
      print('RESULT: Slider ${initialValue.toStringAsFixed(1)} -> ${newValue.toStringAsFixed(1)}, Chapter: $initialChapter -> $newChapter');

      if (newChapter == initialChapter) {
        print('WARNING: Chapter did NOT change after slider tap!');
      } else {
        print('SUCCESS: Chapter changed from $initialChapter to $newChapter');
      }

      print('ISSUE 2a COMPLETE');
      print('=====\n');
    });

    testWidgets('Debug Issue 2b: Dragging slider does not change chapters', (tester) async {
      print('===== TEST 2b: Dragging slider =====');

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      final aliceFinder = find.textContaining('Alice');
      await waitForWidget(tester, aliceFinder, timeout: const Duration(seconds: 10));
      await tester.tap(aliceFinder.first);
      await tester.pumpAndSettle();

      final fabFinder = find.byType(FloatingActionButton);
      await waitForWidget(tester, fabFinder, timeout: const Duration(seconds: 10));
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Wait for loading
      await tester.pumpAndSettle(const Duration(seconds: 15));

      final sliderFinder = find.byType(Slider);
      await waitForWidget(tester, sliderFinder, timeout: const Duration(seconds: 10));

      await tester.pumpAndSettle(const Duration(seconds: 2));
      final chapterFinder = find.textContaining('Chapter');

      String getChapter() {
        if (chapterFinder.evaluate().isNotEmpty) {
          return tester.widget<Text>(chapterFinder.first).data ?? 'Unknown';
        }
        return 'No chapter found';
      }

      final sliderWidget = tester.widget<Slider>(sliderFinder);
      final initialValue = sliderWidget.value;
      final maxValue = sliderWidget.max;
      final initialChapter = getChapter();
      print('Initial slider: $initialValue / $maxValue');
      print('Initial chapter: $initialChapter');

      print('Dragging slider 150px right...');
      await tester.drag(sliderFinder, const Offset(150, 0));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final newSliderWidget = tester.widget<Slider>(sliderFinder);
      final newValue = newSliderWidget.value;
      final newChapter = getChapter();

      print('New slider: $newValue / $maxValue');
      print('New chapter: $newChapter');
      print('RESULT: Slider ${initialValue} -> $newValue, Chapter: $initialChapter -> $newChapter');

      if (newChapter == initialChapter) {
        print('WARNING: Chapter did NOT change after slider drag!');
      } else {
        print('SUCCESS: Chapter changed from $initialChapter to $newChapter');
      }

      print('ISSUE 2b COMPLETE');
      print('=====\n');
    });

    testWidgets('Debug Issue 3: Reading progress does not persist', (tester) async {
      print('===== TEST 3: Reading progress persistence =====');

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      final aliceFinder = find.textContaining('Alice');
      await waitForWidget(tester, aliceFinder, timeout: const Duration(seconds: 10));
      await tester.tap(aliceFinder.first);
      await tester.pumpAndSettle();

      final fabFinder = find.byType(FloatingActionButton);
      await waitForWidget(tester, fabFinder, timeout: const Duration(seconds: 10));
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      await tester.pumpAndSettle(const Duration(seconds: 15));

      final epubViewFinder = find.byType(EpubView);
      await waitForWidget(tester, epubViewFinder, timeout: const Duration(seconds: 10));

      await tester.pumpAndSettle(const Duration(seconds: 2));
      final chapterFinder = find.textContaining('Chapter');

      String getChapter() {
        if (chapterFinder.evaluate().isNotEmpty) {
          return tester.widget<Text>(chapterFinder.first).data ?? 'Unknown';
        }
        return 'No chapter';
      }

      final initialChapter = getChapter();
      print('Initial chapter: $initialChapter');

      // Scroll significantly
      print('Scrolling 10 times...');
      for (int i = 0; i < 10; i++) {
        await tester.drag(epubViewFinder, const Offset(0, -600));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }

      final newChapter = getChapter();
      print('After scrolling: $newChapter');

      // Wait for auto-save
      print('Waiting 6s for auto-save...');
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // Go back
      print('Going back to library...');
      final backButton = find.byType(BackButton);
      await tester.tap(backButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Reopen
      print('Reopening book...');
      await tester.tap(aliceFinder.first);
      await tester.pumpAndSettle();

      final fabFinder2 = find.byType(FloatingActionButton);
      await waitForWidget(tester, fabFinder2, timeout: const Duration(seconds: 10));
      await tester.tap(fabFinder2);
      await tester.pumpAndSettle();

      await tester.pumpAndSettle(const Duration(seconds: 15));
      await waitForWidget(tester, epubViewFinder, timeout: const Duration(seconds: 10));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final reopenedChapter = getChapter();
      print('Reopened chapter: $reopenedChapter');

      print('RESULT:');
      print('  Initial: $initialChapter');
      print('  After scroll: $newChapter');
      print('  Reopened: $reopenedChapter');
      print('  Expected: $newChapter');
      print('ISSUE 3 COMPLETE');
      print('=====\n');
    });

    testWidgets('Debug: Progress bar chapter indicator updates', (tester) async {
      print('===== TEST 4: Chapter indicator updates =====');

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      final aliceFinder = find.textContaining('Alice');
      await waitForWidget(tester, aliceFinder, timeout: const Duration(seconds: 10));
      await tester.tap(aliceFinder.first);
      await tester.pumpAndSettle();

      final fabFinder = find.byType(FloatingActionButton);
      await waitForWidget(tester, fabFinder, timeout: const Duration(seconds: 10));
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      await tester.pumpAndSettle(const Duration(seconds: 15));

      final epubViewFinder = find.byType(EpubView);
      await waitForWidget(tester, epubViewFinder, timeout: const Duration(seconds: 10));

      await tester.pumpAndSettle(const Duration(seconds: 2));
      final chapterFinder = find.textContaining('Chapter');

      String getChapter() {
        if (chapterFinder.evaluate().isNotEmpty) {
          return tester.widget<Text>(chapterFinder.first).data ?? 'Unknown';
        }
        return 'No chapter';
      }

      final initialChapter = getChapter();
      print('Initial: $initialChapter');

      print('Scrolling 15 times to change chapters...');
      for (int i = 0; i < 15; i++) {
        await tester.drag(epubViewFinder, const Offset(0, -600));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        if (i % 5 == 4) {
          print('After ${i + 1} scrolls: ${getChapter()}');
        }
      }

      await tester.pumpAndSettle(const Duration(seconds: 2));
      final finalChapter = getChapter();
      print('Final: $finalChapter');

      print('RESULT:');
      print('  Initial: $initialChapter');
      print('  Final: $finalChapter');
      print('ISSUE 4 COMPLETE');
      print('=====\n');
    });
  });
}
