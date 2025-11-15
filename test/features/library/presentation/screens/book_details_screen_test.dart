import 'dart:io';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/domain/usecases/delete_book.dart';
import 'package:epub_reader/features/library/domain/usecases/get_all_books.dart';
import 'package:epub_reader/features/library/domain/usecases/get_recent_books.dart';
import 'package:epub_reader/features/library/presentation/providers/library_provider.dart';
import 'package:epub_reader/features/library/presentation/screens/book_details_screen.dart';
import 'package:epub_reader/features/reader/presentation/screens/reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetAllBooks extends Mock implements GetAllBooks {}
class MockGetRecentBooks extends Mock implements GetRecentBooks {}
class MockDeleteBook extends Mock implements DeleteBook {}
class FakeBook extends Fake implements Book {}

void main() {
  late MockGetAllBooks mockGetAllBooks;
  late MockGetRecentBooks mockGetRecentBooks;
  late MockDeleteBook mockDeleteBook;
  late Book testBook;

  setUpAll(() {
    registerFallbackValue(FakeBook());
  });

  setUp(() {
    mockGetAllBooks = MockGetAllBooks();
    mockGetRecentBooks = MockGetRecentBooks();
    mockDeleteBook = MockDeleteBook();

    // Mock the GetAllBooks call that happens in LibraryNotifier constructor
    when(() => mockGetAllBooks()).thenAnswer((_) async => const Right([]));

    testBook = Book(
      id: 1,
      title: 'Test Book',
      author: 'Test Author',
      filePath: '/test/path/book.epub',
      publisher: 'Test Publisher',
      language: 'English',
      isbn: '123-456-789',
      description: 'This is a test book description.',
      addedDate: DateTime(2025, 1, 1),
      lastOpened: DateTime(2025, 1, 10),
      readingProgress: 0.5,
      currentPage: 50,
      totalPages: 100,
    );
  });

  Widget createWidgetUnderTest(Book book) {
    return ProviderScope(
      overrides: [
        libraryProvider.overrideWith((ref) => LibraryNotifier(
              mockGetAllBooks,
              mockGetRecentBooks,
              mockDeleteBook,
            )),
      ],
      child: MaterialApp(
        home: BookDetailsScreen(book: book),
      ),
    );
  }

  group('BookDetailsScreen', () {
    testWidgets('should display book title and author', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testBook));

      // Assert
      expect(find.text('Test Book'), findsOneWidget);
      expect(find.text('by Test Author'), findsOneWidget);
    });

    testWidgets('should display reading progress percentage', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testBook));

      // Assert
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Reading Progress'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should display current and total pages', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testBook));

      // Assert
      expect(find.text('Current Page'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('Total Pages'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('should display metadata information', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testBook));

      // Assert
      expect(find.text('Publisher'), findsOneWidget);
      expect(find.text('Test Publisher'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('ISBN'), findsOneWidget);
      expect(find.text('123-456-789'), findsOneWidget);
    });

    testWidgets('should display description when available', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testBook));

      // Assert
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('This is a test book description.'), findsOneWidget);
    });

    testWidgets('should not display description when null', (tester) async {
      // Arrange
      final bookNoDescription = Book(
        id: 1,
        title: 'Test Book',
        author: 'Test Author',
        filePath: '/test/path/book.epub',
        addedDate: DateTime(2025, 1, 1),
        description: null,
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest(bookNoDescription));

      // Assert
      expect(find.text('Description'), findsNothing);
    });

    testWidgets('should not display description when empty', (tester) async {
      // Arrange
      final bookNoDescription = Book(
        id: 1,
        title: 'Test Book',
        author: 'Test Author',
        filePath: '/test/path/book.epub',
        addedDate: DateTime(2025, 1, 1),
        description: '',
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest(bookNoDescription));

      // Assert
      expect(find.text('Description'), findsNothing);
    });

    testWidgets('should display default icon when no cover path', (tester) async {
      // Arrange
      final bookNoCover = Book(
        id: 1,
        title: 'Test Book',
        author: 'Test Author',
        filePath: '/test/path/book.epub',
        addedDate: DateTime(2025, 1, 1),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest(bookNoCover));

      // Assert
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
    });

    testWidgets('should display cover image when file exists', (tester) async {
      // Arrange - Create a temporary file
      final tempDir = Directory.systemTemp.createTempSync('cover_test_');
      final tempFile = File('${tempDir.path}/cover.jpg');
      tempFile.writeAsBytesSync([0, 0, 0, 0]);

      final bookWithCover = testBook.copyWith(coverPath: tempFile.path);

      try {
        // Act
        await tester.pumpWidget(createWidgetUnderTest(bookWithCover));

        // Assert
        expect(find.byType(Image), findsOneWidget);
        expect(find.byIcon(Icons.menu_book), findsNothing);
      } finally {
        // Clean up
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets('should show "Continue Reading" FAB when progress > 0', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testBook));

      // Assert
      expect(find.widgetWithText(FloatingActionButton, 'Continue Reading'), findsOneWidget);
      expect(find.byIcon(Icons.book), findsOneWidget);
    });

    testWidgets('should show "Start Reading" FAB when progress = 0', (tester) async {
      // Arrange
      final bookNotStarted = testBook.copyWith(readingProgress: 0.0);

      // Act
      await tester.pumpWidget(createWidgetUnderTest(bookNotStarted));

      // Assert
      expect(find.widgetWithText(FloatingActionButton, 'Start Reading'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should navigate to ReaderScreen when FAB is tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest(testBook));

      // Act
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(); // Start navigation
      await tester.pump(const Duration(seconds: 1)); // Allow route animation

      // Assert
      expect(find.byType(ReaderScreen), findsOneWidget);
    });

    testWidgets('should have delete button in app bar', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testBook));

      // Assert
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('should show delete confirmation dialog when delete button tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest(testBook));

      // Act
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Delete Book'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to delete "Test Book"'), findsOneWidget);
    });

    testWidgets('should cancel delete when Cancel button tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest(testBook));

      // Act - Open dialog
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Act - Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert - Dialog should be closed
      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(() => mockDeleteBook(any()));
    });

    testWidgets('should delete book when Delete button tapped', (tester) async {
      // Arrange
      when(() => mockDeleteBook(any())).thenAnswer((_) async => const Right(null));
      await tester.pumpWidget(createWidgetUnderTest(testBook));

      // Act - Open dialog
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Act - Confirm delete
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockDeleteBook(testBook)).called(1);
      expect(find.byType(BookDetailsScreen), findsNothing); // Should navigate back
    });

    testWidgets('should show edit metadata button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testBook));

      // Assert
      expect(find.widgetWithText(OutlinedButton, 'Edit Metadata'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('should show coming soon message when edit button tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest(testBook));

      // Act - Scroll to make button visible
      await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Edit Metadata'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Edit Metadata'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Edit metadata feature coming soon!'), findsOneWidget);
    });

    testWidgets('should display dates with formatting', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(testBook));

      // Assert
      expect(find.text('Added'), findsOneWidget);
      expect(find.text('Last Opened'), findsOneWidget);
    });

    testWidgets('should display "Not started" when currentPage is 0', (tester) async {
      // Arrange
      final bookNotStarted = testBook.copyWith(
        currentPage: 0,
        readingProgress: 0.0,
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest(bookNotStarted));

      // Assert
      expect(find.text('Not started'), findsOneWidget);
    });

    testWidgets('should display "Unknown" when totalPages is 0', (tester) async {
      // Arrange
      final bookNoPages = testBook.copyWith(totalPages: 0);

      // Act
      await tester.pumpWidget(createWidgetUnderTest(bookNoPages));

      // Assert
      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('should not display optional metadata when not available', (tester) async {
      // Arrange
      final bookMinimal = Book(
        id: 1,
        title: 'Minimal Book',
        author: 'Author',
        filePath: '/path/book.epub',
        addedDate: DateTime(2025, 1, 1),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest(bookMinimal));

      // Assert
      expect(find.text('Publisher'), findsNothing);
      expect(find.text('Language'), findsNothing);
      expect(find.text('ISBN'), findsNothing);
      expect(find.text('Last Opened'), findsNothing);
    });
  });
}
