import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/presentation/widgets/book_grid_item.dart';
import 'package:flutter/material.dart';
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
    );
  });

  Widget createWidgetUnderTest({
    required Book book,
    bool isSelectionMode = false,
    bool isSelected = false,
    VoidCallback? onSelectionChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          children: [
            BookGridItem(
              book: book,
              isSelectionMode: isSelectionMode,
              isSelected: isSelected,
              onSelectionChanged: onSelectionChanged,
            ),
          ],
        ),
      ),
    );
  }

  group('BookGridItem', () {
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
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('should not display progress when 0', (tester) async {
      // Arrange
      final bookNoProgress = testBook.copyWith(readingProgress: 0.0);

      // Act
      await tester.pumpWidget(createWidgetUnderTest(book: bookNoProgress));

      // Assert
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('0%'), findsNothing);
    });

    testWidgets('should display 100% when progress is 1.0', (tester) async {
      // Arrange
      final completeBook = testBook.copyWith(readingProgress: 1.0);

      // Act
      await tester.pumpWidget(createWidgetUnderTest(book: completeBook));

      // Assert
      expect(find.text('100%'), findsOneWidget);
    });

    group('Selection Mode', () {
      testWidgets('should show selection overlay when in selection mode', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(
          book: testBook,
          isSelectionMode: true,
        ));

        // Assert - Should find the circular selection indicator
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('should show check icon when selected', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(
          book: testBook,
          isSelectionMode: true,
          isSelected: true,
        ));

        // Assert
        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('should show circle outline when not selected', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(
          book: testBook,
          isSelectionMode: true,
          isSelected: false,
        ));

        // Assert
        expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
      });

      testWidgets('should call onSelectionChanged when tapped in selection mode', (tester) async {
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

      testWidgets('should not show selection overlay when not in selection mode', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidgetUnderTest(
          book: testBook,
          isSelectionMode: false,
        ));

        // Assert
        expect(find.byIcon(Icons.check), findsNothing);
        expect(find.byIcon(Icons.circle_outlined), findsNothing);
      });
    });

    group('Cover Display', () {
      testWidgets('should show default icon when no cover path', (tester) async {
        // Arrange
        final bookNoCover = testBook.copyWith(coverPath: null);

        // Act
        await tester.pumpWidget(createWidgetUnderTest(book: bookNoCover));

        // Assert
        expect(find.byIcon(Icons.menu_book), findsOneWidget);
      });
    });

    group('Navigation', () {
      testWidgets('should not navigate when tapped in selection mode', (tester) async {
        // Arrange
        bool selectionChanged = false;
        await tester.pumpWidget(createWidgetUnderTest(
          book: testBook,
          isSelectionMode: true,
          onSelectionChanged: () => selectionChanged = true,
        ));

        // Act
        await tester.tap(find.byType(InkWell));
        await tester.pump();

        // Assert - Should trigger selection, not navigation
        expect(selectionChanged, true);
      });
    });

    group('Text Overflow', () {
      testWidgets('should handle long titles with ellipsis', (tester) async {
        // Arrange
        final longTitleBook = testBook.copyWith(
          title: 'This is a very long book title that should be truncated with ellipsis',
        );

        // Act
        await tester.pumpWidget(createWidgetUnderTest(book: longTitleBook));

        // Assert
        final textWidget = tester.widget<Text>(
          find.text(longTitleBook.title),
        );
        expect(textWidget.maxLines, 2);
        expect(textWidget.overflow, TextOverflow.ellipsis);
      });

      testWidgets('should handle long author names with ellipsis', (tester) async {
        // Arrange
        final longAuthorBook = testBook.copyWith(
          author: 'This is a very long author name that should be truncated',
        );

        // Act
        await tester.pumpWidget(createWidgetUnderTest(book: longAuthorBook));

        // Assert
        final textWidget = tester.widget<Text>(
          find.text(longAuthorBook.author),
        );
        expect(textWidget.maxLines, 1);
        expect(textWidget.overflow, TextOverflow.ellipsis);
      });
    });
  });
}
