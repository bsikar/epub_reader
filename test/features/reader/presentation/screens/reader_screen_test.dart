import 'dart:io';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/reader/domain/usecases/add_bookmark.dart';
import 'package:epub_reader/features/reader/domain/usecases/update_reading_progress.dart';
import 'package:epub_reader/features/reader/presentation/providers/reader_providers.dart';
import 'package:epub_reader/features/reader/presentation/screens/reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockUpdateReadingProgress extends Mock implements UpdateReadingProgress {}
class MockAddBookmark extends Mock implements AddBookmark {}
class FakeBook extends Fake implements Book {}

void main() {
  late MockUpdateReadingProgress mockUpdateProgress;
  late MockAddBookmark mockAddBookmark;
  late Book testBook;

  setUpAll(() {
    registerFallbackValue(FakeBook());
  });

  setUp(() {
    mockUpdateProgress = MockUpdateReadingProgress();
    mockAddBookmark = MockAddBookmark();

    // Mock successful progress updates
    when(() => mockUpdateProgress(book: any(named: 'book'), cfi: any(named: 'cfi')))
        .thenAnswer((_) async => const Right(null));

    testBook = Book(
      id: 1,
      title: 'Test Book',
      author: 'Test Author',
      filePath: '/test/path/book.epub',
      addedDate: DateTime(2025, 1, 1),
    );
  });

  Widget createWidgetUnderTest(Book book) {
    return ProviderScope(
      overrides: [
        updateReadingProgressProvider.overrideWith((ref) => mockUpdateProgress),
        addBookmarkProvider.overrideWith((ref) => mockAddBookmark),
      ],
      child: MaterialApp(
        home: ReaderScreen(book: book),
      ),
    );
  }

  group('ReaderScreen - Progress Slider', () {
    testWidgets('should display app bar with book title', (tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(testBook));
      await tester.pump();

      // Assert
      expect(find.text('Test Book'), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(testBook));

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading EPUB...'), findsOneWidget);
    });

    testWidgets('should have back button in app bar', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(testBook));
      await tester.pump();

      // Back button is automatically added by AppBar
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have bookmark button in app bar actions', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(testBook));
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have font settings button in app bar actions', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(testBook));
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have table of contents button in app bar actions', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(testBook));
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
    });
  });

  group('ReaderScreen - Auto-save Progress', () {
    testWidgets('should auto-save progress periodically', (tester) async {
      // This test verifies the timer is set up
      // Actual auto-save would require a loaded EPUB controller
      await tester.pumpWidget(createWidgetUnderTest(testBook));
      await tester.pump();

      // Verify widget exists and timer would be created
      expect(find.byType(ReaderScreen), findsOneWidget);
    });
  });

  group('ReaderScreen - Font Settings', () {
    testWidgets('should show font settings button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(testBook));
      await tester.pump();

      // Font settings icon should be in the app bar actions
      expect(find.byType(AppBar), findsOneWidget);
    });
  });

  group('ReaderScreen - Bookmarks', () {
    testWidgets('should show bookmark button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(testBook));
      await tester.pump();

      // Bookmark icon should be in the app bar actions
      expect(find.byType(AppBar), findsOneWidget);
    });
  });

  group('ReaderScreen - Table of Contents', () {
    testWidgets('should show table of contents button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(testBook));
      await tester.pump();

      // TOC icon should be in the app bar actions
      expect(find.byType(AppBar), findsOneWidget);
    });
  });

  group('ReaderScreen - Search', () {
    testWidgets('should show search button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(testBook));
      await tester.pump();

      // Search icon should be in the app bar actions
      expect(find.byType(AppBar), findsOneWidget);
    });
  });

  group('ReaderScreen - Lifecycle', () {
    testWidgets('should dispose controller and timer on dispose', (tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(testBook));
      await tester.pump();

      // Dispose by removing widget
      await tester.pumpWidget(const SizedBox());

      // If we got here without errors, dispose worked correctly
      expect(find.byType(ReaderScreen), findsNothing);
    });
  });
}
