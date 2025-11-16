import 'package:epub_reader/core/database/app_database.dart' as db;
import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/features/reader/domain/usecases/delete_bookmark.dart';
import 'package:epub_reader/features/reader/domain/usecases/get_bookmarks.dart';
import 'package:epub_reader/features/reader/presentation/providers/reader_providers.dart';
import 'package:epub_reader/features/reader/presentation/widgets/bookmarks_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetBookmarks extends Mock implements GetBookmarks {}

class MockDeleteBookmark extends Mock implements DeleteBookmark {}

void main() {
  late MockGetBookmarks mockGetBookmarks;
  late MockDeleteBookmark mockDeleteBookmark;

  setUp(() {
    mockGetBookmarks = MockGetBookmarks();
    mockDeleteBookmark = MockDeleteBookmark();
  });

  Widget createWidgetUnderTest({
    required int bookId,
    Function(String)? onBookmarkTap,
  }) {
    return ProviderScope(
      overrides: [
        getBookmarksProvider.overrideWithValue(mockGetBookmarks),
        deleteBookmarkProvider.overrideWithValue(mockDeleteBookmark),
      ],
      child: MaterialApp(
        home: Scaffold(
          endDrawer: BookmarksDrawer(
            bookId: bookId,
            showProgressBar: true,
            onBookmarkTap: onBookmarkTap ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('BookmarksDrawer', () {
    testWidgets('should display header with bookmarks title and icon',
        (tester) async {
      // Arrange
      when(() => mockGetBookmarks(any()))
          .thenAnswer((_) async => const Right([]));

      // Act
      await tester.pumpWidget(createWidgetUnderTest(bookId: 1));
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openEndDrawer();
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Bookmarks'), findsOneWidget);
      expect(find.byIcon(Icons.bookmarks), findsOneWidget);
    });

    testWidgets('should display empty state when no bookmarks exist',
        (tester) async {
      // Arrange
      when(() => mockGetBookmarks(any()))
          .thenAnswer((_) async => const Right([]));

      // Act
      await tester.pumpWidget(createWidgetUnderTest(bookId: 1));
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openEndDrawer();
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No bookmarks yet'), findsOneWidget);
      expect(
          find.text(
              'Tap the bookmark icon while reading\nto save your favorite locations'),
          findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });

    testWidgets('should display loading indicator while fetching bookmarks',
        (tester) async {
      // Arrange
      when(() => mockGetBookmarks(any())).thenAnswer(
          (_) => Future.delayed(
              const Duration(milliseconds: 100), () => const Right([])));

      // Act
      await tester.pumpWidget(createWidgetUnderTest(bookId: 1));
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openEndDrawer();
      await tester.pump();

      // Assert - should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for completion
      await tester.pumpAndSettle();
    });

    testWidgets('should display list of bookmarks', (tester) async {
      // Arrange
      final bookmarks = [
        db.Bookmark(
          id: 1,
          bookId: 1,
          cfiLocation: 'cfi1',
          chapterName: 'Chapter 1',
          pageNumber: 1,
          note: null,
          createdAt: DateTime(2025, 1, 1, 10, 0),
        ),
        db.Bookmark(
          id: 2,
          bookId: 1,
          cfiLocation: 'cfi2',
          chapterName: 'Chapter 2',
          pageNumber: 2,
          note: 'Important section',
          createdAt: DateTime(2025, 1, 2, 15, 30),
        ),
      ];

      when(() => mockGetBookmarks(any()))
          .thenAnswer((_) async => Right(bookmarks));

      // Act
      await tester.pumpWidget(createWidgetUnderTest(bookId: 1));
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openEndDrawer();
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Chapter 1'), findsOneWidget);
      expect(find.text('Chapter 2'), findsOneWidget);
      expect(find.text('Important section'), findsOneWidget);
    });

    testWidgets('should show error message when fetching bookmarks fails',
        (tester) async {
      // Arrange
      when(() => mockGetBookmarks(any())).thenAnswer(
          (_) async => const Left(DatabaseFailure('Failed to load')));

      // Act
      await tester.pumpWidget(createWidgetUnderTest(bookId: 1));
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openEndDrawer();
      await tester.pumpAndSettle();

      // Assert - should show empty state (errors are logged, empty list returned)
      expect(find.text('No bookmarks yet'), findsOneWidget);
    });

    testWidgets('should display bookmark with note', (tester) async {
      // Arrange
      final bookmarks = [
        db.Bookmark(
          id: 1,
          bookId: 1,
          cfiLocation: 'cfi1',
          chapterName: 'Chapter 1',
          pageNumber: 1,
          note: 'This is my note',
          createdAt: DateTime(2025, 1, 1),
        ),
      ];

      when(() => mockGetBookmarks(any()))
          .thenAnswer((_) async => Right(bookmarks));

      // Act
      await tester.pumpWidget(createWidgetUnderTest(bookId: 1));
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openEndDrawer();
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('This is my note'), findsOneWidget);
    });

    testWidgets('should show delete button for each bookmark', (tester) async {
      // Arrange
      final bookmarks = [
        db.Bookmark(
          id: 1,
          bookId: 1,
          cfiLocation: 'cfi1',
          chapterName: 'Chapter 1',
          pageNumber: 1,
          note: null,
          createdAt: DateTime(2025, 1, 1),
        ),
      ];

      when(() => mockGetBookmarks(any()))
          .thenAnswer((_) async => Right(bookmarks));

      // Act
      await tester.pumpWidget(createWidgetUnderTest(bookId: 1));
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openEndDrawer();
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.byTooltip('Delete bookmark'), findsOneWidget);
    });

    testWidgets('should show confirmation dialog when delete is tapped',
        (tester) async {
      // Arrange
      final bookmarks = [
        db.Bookmark(
          id: 1,
          bookId: 1,
          cfiLocation: 'cfi1',
          chapterName: 'Chapter 1',
          pageNumber: 1,
          note: null,
          createdAt: DateTime(2025, 1, 1),
        ),
      ];

      when(() => mockGetBookmarks(any()))
          .thenAnswer((_) async => Right(bookmarks));

      // Act
      await tester.pumpWidget(createWidgetUnderTest(bookId: 1));
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openEndDrawer();
      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Assert - dialog should appear
      expect(find.text('Delete Bookmark'), findsOneWidget);
      expect(
          find.text(
              'Are you sure you want to delete this bookmark from "Chapter 1"?'),
          findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('should not delete bookmark when cancel is tapped',
        (tester) async {
      // Arrange
      final bookmarks = [
        db.Bookmark(
          id: 1,
          bookId: 1,
          cfiLocation: 'cfi1',
          chapterName: 'Chapter 1',
          pageNumber: 1,
          note: null,
          createdAt: DateTime(2025, 1, 1),
        ),
      ];

      when(() => mockGetBookmarks(any()))
          .thenAnswer((_) async => Right(bookmarks));

      // Act
      await tester.pumpWidget(createWidgetUnderTest(bookId: 1));
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openEndDrawer();
      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert - delete should not be called
      verifyNever(() => mockDeleteBookmark(any()));
    });

    testWidgets('should format date as "Today" for today\'s bookmarks',
        (tester) async {
      // Arrange
      final bookmarks = [
        db.Bookmark(
          id: 1,
          bookId: 1,
          cfiLocation: 'cfi1',
          chapterName: 'Chapter 1',
          pageNumber: 1,
          note: null,
          createdAt: DateTime.now(),
        ),
      ];

      when(() => mockGetBookmarks(any()))
          .thenAnswer((_) async => Right(bookmarks));

      // Act
      await tester.pumpWidget(createWidgetUnderTest(bookId: 1));
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openEndDrawer();
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Today at'), findsOneWidget);
    });

    testWidgets('should display page number when chapter name is empty',
        (tester) async {
      // Arrange
      final bookmarks = [
        db.Bookmark(
          id: 1,
          bookId: 1,
          cfiLocation: 'cfi1',
          chapterName: '',
          pageNumber: 42,
          note: null,
          createdAt: DateTime.now(),
        ),
      ];

      when(() => mockGetBookmarks(any()))
          .thenAnswer((_) async => Right(bookmarks));

      // Act
      await tester.pumpWidget(createWidgetUnderTest(bookId: 1));
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openEndDrawer();
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Page 42'), findsOneWidget);
    });
  });
}
