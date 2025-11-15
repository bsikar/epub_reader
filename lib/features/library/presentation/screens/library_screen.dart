import 'package:epub_reader/core/widgets/empty_state.dart';
import 'package:epub_reader/core/widgets/error_view.dart';
import 'package:epub_reader/core/widgets/loading_indicator.dart';
import 'package:epub_reader/features/import/presentation/providers/import_provider.dart';
import 'package:epub_reader/features/library/presentation/providers/library_provider.dart';
import 'package:epub_reader/features/library/presentation/widgets/book_grid_item.dart';
import 'package:epub_reader/features/library/presentation/widgets/book_list_item.dart';
import 'package:epub_reader/features/library/presentation/widgets/library_search_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(importProvider.notifier).pickAndImportEpub();

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book imported successfully!')),
        );
        ref.read(libraryProvider.notifier).loadBooks();
      } else {
        final error = ref.read(importProvider).error;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final state = ref.read(libraryProvider);
    final count = state.selectedBookIds.length;

    print('LibraryScreen: Confirm delete called for $count books');
    print('LibraryScreen: Selected IDs: ${state.selectedBookIds.join(", ")}');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Books'),
        content: Text(
          'Are you sure you want to delete $count ${count == 1 ? 'book' : 'books'}? This will also delete the EPUB files and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('LibraryScreen: Delete cancelled');
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              print('LibraryScreen: Delete confirmed');
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    print('LibraryScreen: Dialog result: $confirmed');

    if (confirmed == true && context.mounted) {
      print('LibraryScreen: Calling deleteSelectedBooks');
      await ref.read(libraryProvider.notifier).deleteSelectedBooks();
      print('LibraryScreen: Delete completed');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count ${count == 1 ? 'book' : 'books'} deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);
    final importState = ref.watch(importProvider);

    if (importState.isImporting) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Importing EPUB...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: state.isSelectionMode
            ? Text('${state.selectedBookIds.length} selected')
            : const Text('My Library'),
        leading: state.isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(libraryProvider.notifier).toggleSelectionMode();
                },
              )
            : null,
        actions: state.isSelectionMode
            ? [
                if (state.selectedBookIds.length < state.books.length)
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    onPressed: () {
                      ref.read(libraryProvider.notifier).selectAll();
                    },
                    tooltip: 'Select all',
                  ),
                if (state.selectedBookIds.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(context, ref),
                    tooltip: 'Delete selected',
                  ),
              ]
            : [
                IconButton(
                  icon: Icon(
                    state.viewMode == LibraryViewMode.grid
                        ? Icons.view_list
                        : Icons.grid_view,
                  ),
                  onPressed: () {
                    ref.read(libraryProvider.notifier).toggleViewMode();
                  },
                  tooltip: 'Toggle view mode',
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: LibrarySearchDelegate(),
                    );
                  },
                  tooltip: 'Search',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'select') {
                      ref.read(libraryProvider.notifier).toggleSelectionMode();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'select',
                      child: Row(
                        children: [
                          Icon(Icons.checklist),
                          SizedBox(width: 8),
                          Text('Select books'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: _buildBody(context, ref, state),
      floatingActionButton: state.isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _handleImport(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Import EPUB'),
            ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, LibraryState state) {
    if (state.isLoading) {
      return const LoadingIndicator(message: 'Loading library...');
    }

    if (state.error != null) {
      return ErrorView(
        message: state.error!,
        onRetry: () => ref.read(libraryProvider.notifier).loadBooks(),
      );
    }

    if (state.books.isEmpty) {
      return EmptyState(
        message: 'No books in your library',
        subtitle: 'Import an EPUB file to get started',
        icon: Icons.menu_book_outlined,
        action: ElevatedButton.icon(
          onPressed: () => _handleImport(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Import EPUB'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(libraryProvider.notifier).loadBooks(),
      child: state.viewMode == LibraryViewMode.grid
          ? _buildGridView(context, ref, state)
          : _buildListView(context, ref, state),
    );
  }

  Widget _buildGridView(BuildContext context, WidgetRef ref, LibraryState state) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: state.books.length,
      itemBuilder: (context, index) {
        final book = state.books[index];
        return BookGridItem(
          book: book,
          isSelectionMode: state.isSelectionMode,
          isSelected: state.selectedBookIds.contains(book.id),
          onSelectionChanged: () {
            ref.read(libraryProvider.notifier).toggleBookSelection(book.id!);
          },
        );
      },
    );
  }

  Widget _buildListView(BuildContext context, WidgetRef ref, LibraryState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.books.length,
      itemBuilder: (context, index) {
        final book = state.books[index];
        return BookListItem(
          book: book,
          isSelectionMode: state.isSelectionMode,
          isSelected: state.selectedBookIds.contains(book.id),
          onSelectionChanged: () {
            ref.read(libraryProvider.notifier).toggleBookSelection(book.id!);
          },
          onDelete: () async {
            print('LibraryScreen: Single book delete for ${book.title}');
            await ref.read(libraryProvider.notifier).deleteBook(book);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${book.title} deleted')),
              );
            }
          },
        );
      },
    );
  }
}
