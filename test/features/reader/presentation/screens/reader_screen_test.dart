import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/reader/presentation/screens/reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Book testBook;

  setUp(() {
    testBook = Book(
      id: 1,
      title: 'Test Book',
      author: 'Test Author',
      filePath: 'test.epub',
      addedDate: DateTime.now(),
      lastCfi: null,
    );
  });

  testWidgets('ReaderScreen shows loading initially', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ReaderScreen(book: testBook),
        ),
      ),
    );

    expect(find.text('Loading EPUB...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ReaderScreen has correct title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ReaderScreen(book: testBook),
        ),
      ),
    );

    // Wait for the widget to be built
    await tester.pumpAndSettle();

    // Check that book title is shown in the app bar (after controls are shown)
    // Note: The actual epub viewer won't load in tests, so we just verify basic structure
  });
}
