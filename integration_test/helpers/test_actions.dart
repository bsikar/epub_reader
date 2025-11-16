import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'widget_finders.dart';

/// Helper class for common test actions
class TestActions {
  /// Navigate to a book's details screen
  static Future<void> openBookDetails(
    WidgetTester tester,
    String bookTitle,
  ) async {
    // Find and tap the book
    final bookFinder = find.text(bookTitle).first;
    await tester.tap(bookFinder);
    await tester.pumpAndSettle();

    // Verify we're on the book details screen
    expect(WidgetFinders.bookDetailsScreen, findsOneWidget);
  }

  /// Open the reader screen from book details
  static Future<void> openReader(WidgetTester tester) async {
    // Look for either "Continue Reading" or "Start Reading" button
    Finder readButton;
    if (WidgetFinders.continueReadingButton.evaluate().isNotEmpty) {
      readButton = WidgetFinders.continueReadingButton;
    } else {
      readButton = WidgetFinders.startReadingButton;
    }

    await tester.tap(readButton);
    await tester.pumpAndSettle();

    // Wait for reader to load
    await WidgetFinders.waitForWidget(
      tester,
      WidgetFinders.readerScreen,
      timeout: const Duration(seconds: 5),
    );
  }

  /// Add a bookmark at the current position
  static Future<void> addBookmark(
    WidgetTester tester, {
    String? note,
  }) async {
    // Tap add bookmark button
    await tester.tap(WidgetFinders.addBookmarkButton);
    await tester.pumpAndSettle();

    // If note is provided, enter it
    if (note != null) {
      final noteField = WidgetFinders.bookmarkNoteField;
      if (noteField.evaluate().isNotEmpty) {
        await tester.enterText(noteField, note);
        await tester.pumpAndSettle();
      }
    }

    // Save the bookmark
    await tester.tap(WidgetFinders.saveBookmarkButton);
    await tester.pumpAndSettle();
  }

  /// Open the bookmarks drawer
  static Future<void> openBookmarksDrawer(WidgetTester tester) async {
    await tester.tap(WidgetFinders.bookmarksButton);
    await tester.pumpAndSettle();

    // Verify drawer is open
    expect(WidgetFinders.bookmarksDrawer, findsOneWidget);
  }

  /// Navigate to a specific bookmark
  static Future<void> navigateToBookmark(
    WidgetTester tester,
    String bookmarkText,
  ) async {
    // Open bookmarks drawer if not already open
    if (WidgetFinders.bookmarksDrawer.evaluate().isEmpty) {
      await openBookmarksDrawer(tester);
    }

    // Find and tap the bookmark
    final bookmark = WidgetFinders.bookmarkItem(bookmarkText);
    await tester.tap(bookmark);
    await tester.pumpAndSettle();
  }

  /// Delete a bookmark
  static Future<void> deleteBookmark(
    WidgetTester tester,
    String bookmarkText,
  ) async {
    // Open bookmarks drawer if not already open
    if (WidgetFinders.bookmarksDrawer.evaluate().isEmpty) {
      await openBookmarksDrawer(tester);
    }

    // Find the bookmark and its delete button
    final bookmark = find.ancestor(
      of: find.text(bookmarkText),
      matching: find.byType(ListTile),
    );

    final deleteButton = find.descendant(
      of: bookmark,
      matching: WidgetFinders.bookmarkDeleteButton,
    );

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Confirm deletion if dialog appears
    if (WidgetFinders.confirmDialog.evaluate().isNotEmpty) {
      await tester.tap(WidgetFinders.deleteButton);
      await tester.pumpAndSettle();
    }
  }

  /// Open table of contents
  static Future<void> openTableOfContents(WidgetTester tester) async {
    await tester.tap(WidgetFinders.tocButton);
    await tester.pumpAndSettle();

    // Verify TOC is open
    expect(WidgetFinders.tocDrawer, findsOneWidget);
  }

  /// Navigate to a specific chapter
  static Future<void> navigateToChapter(
    WidgetTester tester,
    String chapterTitle,
  ) async {
    // Open TOC if not already open
    if (WidgetFinders.tocDrawer.evaluate().isEmpty) {
      await openTableOfContents(tester);
    }

    // Find and tap the chapter
    final chapter = WidgetFinders.chapterItem(chapterTitle);
    await tester.tap(chapter);
    await tester.pumpAndSettle();
  }

  /// Adjust font size in reader
  static Future<void> adjustFontSize(
    WidgetTester tester,
    double size,
  ) async {
    // Open settings if not already open
    await tester.tap(WidgetFinders.settingsButton);
    await tester.pumpAndSettle();

    // Find and adjust font size slider
    final slider = WidgetFinders.fontSizeSlider;
    if (slider.evaluate().isNotEmpty) {
      // Simulate dragging the slider
      final sliderWidget = tester.widget<Slider>(slider);
      final newValue = size.clamp(sliderWidget.min ?? 12, sliderWidget.max ?? 24);

      // Tap at the position for the desired value
      final rect = tester.getRect(slider);
      final dx = rect.left +
          (rect.width * ((newValue - (sliderWidget.min ?? 12)) /
              ((sliderWidget.max ?? 24) - (sliderWidget.min ?? 12))));

      await tester.tapAt(Offset(dx, rect.center.dy));
      await tester.pumpAndSettle();
    }
  }

  /// Change reader theme
  static Future<void> changeTheme(
    WidgetTester tester,
    String theme,
  ) async {
    // Open settings if not already open
    await tester.tap(WidgetFinders.settingsButton);
    await tester.pumpAndSettle();

    // Select theme
    Finder themeFinder;
    switch (theme.toLowerCase()) {
      case 'dark':
        themeFinder = WidgetFinders.darkThemeOption;
        break;
      case 'sepia':
        themeFinder = WidgetFinders.sepiaThemeOption;
        break;
      default:
        themeFinder = WidgetFinders.lightThemeOption;
    }

    await tester.tap(themeFinder);
    await tester.pumpAndSettle();
  }

  /// Search for books in library
  static Future<void> searchBooks(
    WidgetTester tester,
    String query,
  ) async {
    // Tap search icon
    await tester.tap(WidgetFinders.searchIcon);
    await tester.pumpAndSettle();

    // Enter search query
    await tester.enterText(WidgetFinders.searchField, query);
    await tester.pumpAndSettle();

    // Submit search
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

  /// Delete selected books from library
  static Future<void> deleteSelectedBooks(
    WidgetTester tester,
    List<String> bookTitles,
  ) async {
    // Enable selection mode (implementation depends on UI)
    // This might involve long-pressing a book or tapping a selection mode button

    // Select each book
    for (final title in bookTitles) {
      final book = find.text(title).first;
      await tester.tap(book);
      await tester.pump();
    }

    // Tap delete button
    await tester.tap(WidgetFinders.deleteSelectedButton);
    await tester.pumpAndSettle();

    // Confirm deletion
    if (WidgetFinders.confirmDialog.evaluate().isNotEmpty) {
      await tester.tap(WidgetFinders.deleteButton);
      await tester.pumpAndSettle();
    }
  }

  /// Import a book (mock file picker)
  static Future<void> importBook(
    WidgetTester tester, {
    required String fileName,
    bool expectSuccess = true,
  }) async {
    // Tap import FAB
    await tester.tap(WidgetFinders.importFab);
    await tester.pumpAndSettle();

    // The actual file picking would be mocked in tests
    // Wait for import to complete
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Check for success or error message
    if (expectSuccess) {
      expect(WidgetFinders.importSuccessMessage, findsOneWidget);
    } else {
      expect(find.textContaining('Error'), findsOneWidget);
    }
  }

  /// Navigate back
  static Future<void> navigateBack(WidgetTester tester) async {
    await tester.tap(WidgetFinders.backButton);
    await tester.pumpAndSettle();
  }

  /// Trigger pull-to-refresh in library
  static Future<void> refreshLibrary(WidgetTester tester) async {
    // Find scrollable widgets (usually ListView or GridView)
    final scrollableFinder = find.byType(Scrollable);

    if (scrollableFinder.evaluate().isNotEmpty) {
      // Perform pull-to-refresh gesture
      await tester.drag(scrollableFinder.first, const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    } else {
      // No scrollable widget found (empty library), just wait for potential update
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    }
  }

  /// Verify reading progress
  static Future<void> verifyReadingProgress(
    WidgetTester tester,
    double expectedProgress,
  ) async {
    final progressIndicator = WidgetFinders.readingProgressIndicator;
    if (progressIndicator.evaluate().isNotEmpty) {
      // Get the actual progress value from the widget
      // This would depend on how progress is displayed in your UI
      // For example, if it's a LinearProgressIndicator:
      final indicator = tester.widget<LinearProgressIndicator>(progressIndicator);
      expect(indicator.value, closeTo(expectedProgress, 0.01));
    }
  }

  /// Move progress slider
  static Future<void> moveProgressSlider(
    WidgetTester tester,
    double position,
  ) async {
    final slider = WidgetFinders.progressSlider;
    expect(slider, findsOneWidget);

    // Get slider widget
    final sliderWidget = tester.widget<Slider>(slider);
    final newValue = position.clamp(0.0, 1.0);

    // Calculate tap position
    final rect = tester.getRect(slider);
    final dx = rect.left + (rect.width * newValue);

    // Tap at the calculated position
    await tester.tapAt(Offset(dx, rect.center.dy));
    await tester.pumpAndSettle();
  }

  /// Toggle view mode in library
  static Future<void> toggleViewMode(WidgetTester tester) async {
    await tester.tap(WidgetFinders.viewModeToggle);
    await tester.pumpAndSettle();
  }

  /// Verify book exists in library
  static void verifyBookInLibrary(String title) {
    expect(find.text(title), findsOneWidget);
  }

  /// Verify book does not exist in library
  static void verifyBookNotInLibrary(String title) {
    expect(find.text(title), findsNothing);
  }

  /// Wait for loading to complete
  static Future<void> waitForLoading(WidgetTester tester) async {
    await WidgetFinders.waitForNoWidget(
      tester,
      WidgetFinders.loadingIndicator,
      timeout: const Duration(seconds: 10),
    );
  }

  /// Scroll to find widget
  static Future<void> scrollToFind(
    WidgetTester tester,
    Finder finder, {
    Finder? scrollable,
  }) async {
    final scrollableFinder = scrollable ?? find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: scrollableFinder,
      maxScrolls: 20,
    );
  }

  /// Verify snackbar message
  static void verifySnackbar(String message) {
    expect(WidgetFinders.snackBar(message), findsOneWidget);
  }

  /// Dismiss snackbar
  static Future<void> dismissSnackbar(WidgetTester tester) async {
    // Swipe to dismiss or wait for timeout
    await tester.pump(const Duration(seconds: 4));
  }
}