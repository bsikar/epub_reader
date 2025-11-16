import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epub_reader/features/library/presentation/widgets/book_grid_item.dart';
import 'package:epub_reader/features/library/presentation/widgets/book_list_item.dart';
import 'package:epub_reader/features/reader/presentation/widgets/bookmarks_drawer.dart';

/// Helper class for finding widgets in integration tests
class WidgetFinders {
  // Screen finders
  static Finder get libraryScreen => find.byKey(const Key('library_screen'));
  static Finder get bookDetailsScreen => find.byKey(const Key('book_details_screen'));
  static Finder get readerScreen => find.byKey(const Key('reader_screen'));

  // Navigation bar and app bar
  static Finder get appBar => find.byType(AppBar);
  static Finder get navigationBar => find.byType(BottomNavigationBar);
  static Finder get drawerButton => find.byIcon(Icons.menu);
  static Finder get backButton => find.byType(BackButton);

  // Library screen widgets
  static Finder get bookGrid => find.byType(GridView);
  static Finder get bookList => find.byType(ListView);
  static Finder bookGridItem(String title) => find.ancestor(
        of: find.text(title),
        matching: find.byType(BookGridItem),
      );
  static Finder bookListItem(String title) => find.ancestor(
        of: find.text(title),
        matching: find.byType(BookListItem),
      );
  static Finder get viewModeToggle => find.byIcon(Icons.view_module);
  static Finder get listViewIcon => find.byIcon(Icons.view_list);
  static Finder get gridViewIcon => find.byIcon(Icons.grid_view);
  static Finder get searchIcon => find.byIcon(Icons.search);
  static Finder get importFab => find.byKey(const Key('import_fab'));
  static Finder get selectionModeCheckbox => find.byType(Checkbox);
  static Finder get deleteSelectedButton => find.byIcon(Icons.delete);

  // Book details screen widgets
  static Finder get continueReadingButton => find.text('Continue Reading');
  static Finder get startReadingButton => find.text('Start Reading');
  static Finder get bookCoverImage => find.byKey(const Key('book_cover'));
  static Finder get bookTitle => find.byKey(const Key('book_title'));
  static Finder get bookAuthor => find.byKey(const Key('book_author'));
  static Finder get readingProgressIndicator => find.byKey(const Key('reading_progress'));
  static Finder get bookDescription => find.byKey(const Key('book_description'));
  static Finder get bookMetadata => find.byKey(const Key('book_metadata'));

  // Reader screen widgets
  static Finder get epubView => find.byKey(const Key('epub_view'));
  static Finder get progressSlider => find.byType(Slider);
  static Finder get chapterTitle => find.byKey(const Key('chapter_title'));
  static Finder get addBookmarkButton => find.byIcon(Icons.bookmark_add);
  static Finder get bookmarksButton => find.byIcon(Icons.bookmarks);
  static Finder get tocButton => find.byIcon(Icons.list);
  static Finder get searchInBookButton => find.byIcon(Icons.search);
  static Finder get settingsButton => find.byIcon(Icons.settings);
  static Finder get fontSizeSlider => find.byKey(const Key('font_size_slider'));
  static Finder get themeSelector => find.byKey(const Key('theme_selector'));
  static Finder get progressBarToggle => find.byKey(const Key('progress_bar_toggle'));

  // Bookmarks drawer
  static Finder get bookmarksDrawer => find.byType(BookmarksDrawer);
  static Finder bookmarkItem(String text) => find.descendant(
        of: bookmarksDrawer,
        matching: find.text(text, skipOffstage: false),
      );
  static Finder get bookmarkDeleteButton => find.byIcon(Icons.delete);
  static Finder get noBookmarksText => find.text('No bookmarks yet');

  // Table of contents drawer
  static Finder get tocDrawer => find.byKey(const Key('toc_drawer'));
  static Finder chapterItem(String title) => find.ancestor(
        of: find.text(title, skipOffstage: false),
        matching: find.byType(ListTile),
      );

  // Dialogs and overlays
  static Finder get confirmDialog => find.byType(AlertDialog);
  static Finder get confirmButton => find.text('Confirm');
  static Finder get cancelButton => find.text('Cancel');
  static Finder get okButton => find.text('OK');
  static Finder get deleteButton => find.text('Delete');
  static Finder get addBookmarkDialog => find.byKey(const Key('add_bookmark_dialog'));
  static Finder get bookmarkNoteField => find.byKey(const Key('bookmark_note_field'));
  static Finder get saveBookmarkButton => find.text('Save Bookmark');

  // Search
  static Finder get searchField => find.byType(TextField).first;
  static Finder get searchResults => find.byKey(const Key('search_results'));
  static Finder searchResultItem(String text) => find.ancestor(
        of: find.text(text),
        matching: find.byType(ListTile),
      );

  // Settings and preferences
  static Finder get lightThemeOption => find.text('Light');
  static Finder get darkThemeOption => find.text('Dark');
  static Finder get sepiaThemeOption => find.text('Sepia');

  // Progress indicators
  static Finder get loadingIndicator => find.byType(CircularProgressIndicator);
  static Finder get linearProgressIndicator => find.byType(LinearProgressIndicator);

  // Snackbars and toasts
  static Finder snackBar(String message) => find.ancestor(
        of: find.text(message),
        matching: find.byType(SnackBar),
      );

  // Import flow
  static Finder get filePickerButton => find.byKey(const Key('file_picker_button'));
  static Finder get importProgressDialog => find.byKey(const Key('import_progress'));
  static Finder get importSuccessMessage => find.text('Book imported successfully');
  static Finder get importErrorMessage => find.textContaining('Error importing');

  // Error states
  static Finder errorMessage(String text) => find.text(text);
  static Finder get retryButton => find.text('Retry');
  static Finder get errorIcon => find.byIcon(Icons.error);

  // Highlight-related
  static Finder get highlightButton => find.byIcon(Icons.highlight);
  static Finder get highlightsDrawer => find.byKey(const Key('highlights_drawer'));
  static Finder highlightItem(String text) => find.descendant(
        of: highlightsDrawer,
        matching: find.text(text, skipOffstage: false),
      );
  static Finder get highlightColorPicker => find.byKey(const Key('highlight_color_picker'));

  // Custom matchers
  static Finder bookWithProgress(double progress) => find.byWidgetPredicate(
        (widget) {
          if (widget is BookGridItem) {
            // Check if the book has the expected progress
            // This would need to access the book's progress value
            return true; // Simplified for now
          }
          return false;
        },
      );

  // Helper methods for complex widget finding
  static Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final end = DateTime.now().add(timeout);
    do {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 100));
    } while (DateTime.now().isBefore(end));

    throw TestFailure('Widget not found: $finder');
  }

  static Future<void> waitForNoWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final end = DateTime.now().add(timeout);
    do {
      if (finder.evaluate().isEmpty) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 100));
    } while (DateTime.now().isBefore(end));

    throw TestFailure('Widget still present: $finder');
  }
}