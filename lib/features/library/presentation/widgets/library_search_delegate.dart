import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/presentation/providers/library_provider.dart';
import 'package:epub_reader/features/library/presentation/screens/book_details_screen.dart';
import 'package:epub_reader/features/library/presentation/widgets/book_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibrarySearchDelegate extends SearchDelegate<Book?> {
  final WidgetRef ref;

  LibrarySearchDelegate(this.ref);

  @override
  String get searchFieldLabel => 'Search books...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
          tooltip: 'Clear',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
      tooltip: 'Back',
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return _buildEmptyState('Enter a search term to find books');
    }

    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildEmptyState('Search your library by title or author');
    }

    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(libraryProvider);

        // Filter books locally by title or author
        final filteredBooks = state.books.where((book) {
          final queryLower = query.toLowerCase();
          return book.title.toLowerCase().contains(queryLower) ||
                 book.author.toLowerCase().contains(queryLower);
        }).toList();

        if (filteredBooks.isEmpty) {
          return _buildEmptyState('No books found for "$query"');
        }

        return ListView.builder(
          itemCount: filteredBooks.length,
          itemBuilder: (context, index) {
            final book = filteredBooks[index];
            return BookListItem(
              book: book,
              isSelectionMode: false,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
