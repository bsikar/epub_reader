import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'helpers/test_app.dart';
import 'helpers/test_data.dart';
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Debug: Test database and UI sync', (tester) async {
    // Clean start
    await TestApp.cleanup();
    await TestApp.createTestApp(); // Initialize dependencies

    // Clear the database first
    print('Clearing database...');
    await TestApp.clearDatabase();

    // Add books to database
    print('Adding books to database...');
    for (int i = 0; i < 3; i++) {
      final book = TestData.createBook(
        title: TestData.bookTitles[i],
        author: TestData.authors[i],
      );

      print('Adding book: ${book.title} by ${book.author}');
      await TestApp.addTestBook(
        title: book.title,
        author: book.author,
      );
    }

    // Verify books are in database
    print('Verifying database contents...');
    final allBooks = await TestApp.database.getAllBooks();
    print('Books in database: ${allBooks.length}');
    for (final book in allBooks) {
      print('  - ${book.title} by ${book.author}');
    }

    print('Books added. Creating widget...');

    // Create the app widget
    await tester.pumpWidget(await TestApp.createTestApp());
    await tester.pumpAndSettle();

    print('Widget created. Looking for books...');

    // Check what's actually on screen
    final textWidgets = find.byType(Text).evaluate();
    print('Found ${textWidgets.length} Text widgets:');
    for (final widget in textWidgets) {
      final text = (widget.widget as Text).data;
      if (text != null && text.isNotEmpty) {
        print('  - "$text"');
      }
    }

    // Try to find specific books
    for (int i = 0; i < 3; i++) {
      final title = TestData.bookTitles[i];
      final titleFinder = find.text(title);
      print('Looking for "$title": ${titleFinder.evaluate().length} found');
    }

    // Try scrolling to find the third book
    print('Trying to scroll to find Pride and Prejudice...');
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      await tester.drag(scrollable.first, const Offset(0, -200));
      await tester.pumpAndSettle();

      final prideFinder = find.text('Pride and Prejudice');
      print('After scrolling: Pride and Prejudice found: ${prideFinder.evaluate().length}');
    } else {
      print('No scrollable widget found');
    }
  });
}