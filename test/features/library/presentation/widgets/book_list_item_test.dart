import 'dart:io';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/presentation/widgets/book_list_item.dart';
import 'package:epub_reader/features/reader/presentation/screens/reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Book testBook;

  setUp(() {
    testBook = Book(
      id: 1,
      title: 'Test Book',
      author: 'Test Author',
      filePath: '/test/path/book.epub',
      addedDate: DateTime(2025, 1, 1),
      readingProgress: 0.5,
      lastOpened: DateTime(2025, 1, 10),
    );
  });

  Widget createWidgetUnderTest({
    required Book book,
    bool isSelectionMode = false,
    bool isSelected = false,
    VoidCallback? onSelectionChanged,
    VoidCallback? onDelete,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BookListItem(
          book: book,
          isSelectionMode: isSelectionMode,
          isSelected: isSelected,
          onSelectionChanged: onSelectionChanged,
          onDelete: onDelete,
        ),
      ),
    );
  }

  group('BookListItem', () {
    testWidgets('should display book title and author', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(book: testBook));

      // Assert
      expect(find.text('Test Book'), findsOneWidget);
      expect(find.text('Test Author'), findsOneWidget);
    });

    testWidgets('should display reading progress when > 0', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(book: testBook));

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('50% complete'), findsOneWidget);
    });

    testWidgets('should display last read date when available', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest(book: testBook));

      // Assert
      expect(find.textContaining('Last read:'), findsOneWidget);
    });

    group('Selection Mode', () {
      testWidgets('should show checkbox when in selection mode', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(
          book: testBook,
          isSelectionMode: true,
        ));

        // Assert
        expect(find.byType(Checkbox), findsOneWidget);
      });

      testWidgets('should not show checkbox when not in selection mode', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(
          book: testBook,
          isSelectionMode: false,
        ));

        // Assert
        expect(find.byType(Checkbox), findsNothing);
      });

      testWidgets('should check checkbox when book is selected', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(
          book: testBook,
          isSelectionMode: true,
          isSelected: true,
        ));

        // Assert
        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, true);
      });

      testWidgets('should call onSelectionChanged when tapping in selection mode', (tester) async {
        // Arrange
        bool called = false;
        await tester.pumpWidget(createWidgetUnderTest(
          book: testBook,
          isSelectionMode: true,
          onSelectionChanged: () => called = true,
        ));

        // Act
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Assert
        expect(called, true);
      });

      testWidgets('should call onSelectionChanged when tapping checkbox', (tester) async {
        // Arrange
        bool called = false;
        await tester.pumpWidget(createWidgetUnderTest(
          book: testBook,
          isSelectionMode: true,
          onSelectionChanged: () => called = true,
        ));

        // Act
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        // Assert
        expect(called, true);
      });

      testWidgets('should not show slidable in selection mode', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(
          book: testBook,
          isSelectionMode: true,
        ));

        // Assert
        expect(find.byType(Slidable), findsNothing);
      });
    });

    group('Normal Mode', () {
      testWidgets('should show chevron icon when not in selection mode', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(
          book: testBook,
          isSelectionMode: false,
        ));

        // Assert
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });

      testWidgets('should show slidable when not in selection mode', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(
          book: testBook,
          isSelectionMode: false,
        ));

        // Assert
        expect(find.byType(Slidable), findsOneWidget);
      });

      testWidgets('should navigate to ReaderScreen when tapped in normal mode', (tester) async {
        // Arrange
        final mockObserver = NavigatorObserver();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookListItem(
                book: testBook,
                isSelectionMode: false,
              ),
            ),
            navigatorObservers: [mockObserver],
          ),
        );

        // Act
        await tester.tap(find.byType(InkWell));
        await tester.pump(); // Start navigation animation
        await tester.pump(const Duration(seconds: 1)); // Complete animation

        // Assert - Check that a route was pushed
        expect(find.byType(ReaderScreen), findsOneWidget);
      });
    });

    group('Swipe to Delete', () {
      testWidgets('should show delete action when swiping', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidgetUnderTest(
          book: testBook,
          isSelectionMode: false,
          onDelete: () {},
        ));

        // Act
        await tester.drag(find.byType(Slidable), const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Delete'), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);
      });

      testWidgets('should show confirmation dialog when tapping delete', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidgetUnderTest(
          book: testBook,
          isSelectionMode: false,
          onDelete: () {},
        ));

        // Swipe to reveal delete button
        await tester.drag(find.byType(Slidable), const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Delete Book'), findsOneWidget);
        expect(find.textContaining('Are you sure you want to delete "Test Book"'), findsOneWidget);
      });

      testWidgets('should call onDelete when confirming deletion', (tester) async {
        // Arrange
        bool deleteCalled = false;
        await tester.pumpWidget(createWidgetUnderTest(
          book: testBook,
          isSelectionMode: false,
          onDelete: () => deleteCalled = true,
        ));

        // Swipe to reveal delete button
        await tester.drag(find.byType(Slidable), const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Tap delete button
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Act - Confirm deletion
        await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
        await tester.pumpAndSettle();

        // Assert
        expect(deleteCalled, true);
      });

      testWidgets('should not call onDelete when canceling deletion', (tester) async {
        // Arrange
        bool deleteCalled = false;
        await tester.pumpWidget(createWidgetUnderTest(
          book: testBook,
          isSelectionMode: false,
          onDelete: () => deleteCalled = true,
        ));

        // Swipe to reveal delete button
        await tester.drag(find.byType(Slidable), const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Tap delete button
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Act - Cancel deletion
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Assert
        expect(deleteCalled, false);
      });
    });

    group('Cover Display', () {
      testWidgets('should show default icon when no cover path', (tester) async {
        // Arrange
        final bookNoCover = Book(
          id: 1,
          title: 'Test Book',
          author: 'Test Author',
          filePath: '/test/path/book.epub',
          addedDate: DateTime(2025, 1, 1),
        );

        // Act
        await tester.pumpWidget(createWidgetUnderTest(book: bookNoCover));

        // Assert
        expect(find.byIcon(Icons.menu_book), findsOneWidget);
      });

      testWidgets('should display cover image when file exists', (tester) async {
        // Arrange - Create a temporary file to act as cover
        final tempDir = Directory.systemTemp.createTempSync('cover_test_');
        final tempFile = File('${tempDir.path}/cover.jpg');
        tempFile.writeAsBytesSync([0, 0, 0, 0]); // Write dummy bytes

        final bookWithCover = Book(
          id: 1,
          title: 'Test Book',
          author: 'Test Author',
          filePath: '/test/path/book.epub',
          addedDate: DateTime(2025, 1, 1),
          coverPath: tempFile.path,
        );

        try {
          // Act
          await tester.pumpWidget(createWidgetUnderTest(book: bookWithCover));

          // Assert - Should use Image.file instead of Icon
          expect(find.byType(Image), findsOneWidget);
          expect(find.byIcon(Icons.menu_book), findsNothing);
        } finally {
          // Clean up
          tempDir.deleteSync(recursive: true);
        }
      });
    });

    group('Date Formatting', () {
      testWidgets('should display "X days ago" for dates within last week', (tester) async {
        // Arrange
        final now = DateTime.now();
        final threeDaysAgo = now.subtract(const Duration(days: 3));
        final bookWithRecentDate = Book(
          id: 1,
          title: 'Recent Book',
          author: 'Test Author',
          filePath: '/test/path/book.epub',
          addedDate: DateTime(2025, 1, 1),
          lastOpened: threeDaysAgo,
        );

        // Act
        await tester.pumpWidget(createWidgetUnderTest(book: bookWithRecentDate));

        // Assert
        expect(find.textContaining('3 days ago'), findsOneWidget);
      });

      testWidgets('should display "Today" for today\'s date', (tester) async {
        // Arrange
        final now = DateTime.now();
        final bookWithToday = Book(
          id: 1,
          title: 'Test Book A',
          author: 'Test Author',
          filePath: '/test/path/book.epub',
          addedDate: DateTime(2025, 1, 1),
          lastOpened: now,
        );

        // Act
        await tester.pumpWidget(createWidgetUnderTest(book: bookWithToday));

        // Assert
        expect(find.textContaining('Today'), findsOneWidget);
      });

      testWidgets('should display "Yesterday" for yesterday\'s date', (tester) async {
        // Arrange
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final bookWithYesterday = Book(
          id: 1,
          title: 'Test Book B',
          author: 'Test Author',
          filePath: '/test/path/book.epub',
          addedDate: DateTime(2025, 1, 1),
          lastOpened: yesterday,
        );

        // Act
        await tester.pumpWidget(createWidgetUnderTest(book: bookWithYesterday));

        // Assert
        expect(find.textContaining('Yesterday'), findsOneWidget);
      });
    });
  });
}
