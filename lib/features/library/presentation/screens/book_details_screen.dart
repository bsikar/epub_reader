import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epub_reader/app.dart';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/presentation/providers/library_provider.dart';
import 'package:epub_reader/features/reader/presentation/screens/reader_screen.dart';
import 'package:intl/intl.dart';

class BookDetailsScreen extends ConsumerWidget {
  final Book book;

  const BookDetailsScreen({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Update the current screen provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenProvider.notifier).state = 'book-details';
    });

    final theme = Theme.of(context);
    final libraryNotifier = ref.read(libraryProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Book',
            onPressed: () => _showDeleteConfirmation(context, ref, libraryNotifier),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image Section
            _buildCoverSection(theme),

            // Book Information
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    book.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Author
                  Text(
                    'by ${book.author}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reading Progress Card
                  _buildReadingProgressCard(theme),
                  const SizedBox(height: 24),

                  // Metadata Section
                  _buildMetadataSection(theme),
                  const SizedBox(height: 24),

                  // Description
                  if (book.description != null && book.description!.isNotEmpty) ...[
                    _buildSectionTitle(theme, 'Description'),
                    const SizedBox(height: 8),
                    Text(
                      book.description!,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  _buildActionButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildContinueReadingFAB(context),
    );
  }

  Widget _buildCoverSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
      ),
      child: book.coverPath != null && File(book.coverPath!).existsSync()
          ? Image.file(
              File(book.coverPath!),
              fit: BoxFit.contain,
            )
          : Icon(
              Icons.menu_book,
              size: 120,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
    );
  }

  Widget _buildReadingProgressCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reading Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(book.readingProgress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: book.readingProgress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Current Page',
                    book.currentPage > 0 ? book.currentPage.toString() : 'Not started',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Total Pages',
                    book.totalPages > 0 ? book.totalPages.toString() : 'Unknown',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(theme, 'Information'),
        const SizedBox(height: 12),

        if (book.publisher != null && book.publisher!.isNotEmpty)
          _buildMetadataRow(theme, 'Publisher', book.publisher!),

        if (book.language != null && book.language!.isNotEmpty)
          _buildMetadataRow(theme, 'Language', book.language!),

        if (book.isbn != null && book.isbn!.isNotEmpty)
          _buildMetadataRow(theme, 'ISBN', book.isbn!),

        _buildMetadataRow(
          theme,
          'Added',
          _formatDate(book.addedDate),
        ),

        if (book.lastOpened != null)
          _buildMetadataRow(
            theme,
            'Last Opened',
            _formatDate(book.lastOpened!),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMetadataRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showEditDialog(context),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Metadata'),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueReadingFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _openReader(context),
      icon: Icon(book.readingProgress > 0 ? Icons.book : Icons.play_arrow),
      label: Text(book.readingProgress > 0 ? 'Continue Reading' : 'Start Reading'),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  void _openReader(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReaderScreen(book: book),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    // TODO: Implement edit metadata dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit metadata feature coming soon!')),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    LibraryNotifier libraryNotifier,
  ) async {
    // Update screen name for delete confirmation dialog
    ref.read(currentScreenProvider.notifier).state = 'book-details-delete-confirmation';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
          'Are you sure you want to delete "${book.title}"? This will remove the book and all associated data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // Reset screen name back to book details
    if (context.mounted) {
      ref.read(currentScreenProvider.notifier).state = 'book-details';
    }

    if (confirmed == true && context.mounted) {
      await libraryNotifier.deleteBook(book);
      if (context.mounted) {
        Navigator.of(context).pop(); // Return to library
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${book.title}" has been deleted')),
        );
      }
    }
  }
}
