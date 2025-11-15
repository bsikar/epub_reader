import 'dart:io';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/reader/presentation/screens/reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class BookListItem extends StatelessWidget {
  final Book book;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionChanged;
  final VoidCallback? onDelete;

  const BookListItem({
    super.key,
    required this.book,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final content = Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () {
          if (isSelectionMode) {
            onSelectionChanged?.call();
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ReaderScreen(book: book),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onSelectionChanged?.call(),
                ),
              _buildCover(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.lastOpened != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last read: ${_formatDate(book.lastOpened!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (book.readingProgress > 0) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: book.readingProgress,
                        backgroundColor: Colors.grey[300],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(book.readingProgress * 100).toInt()}% complete',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (!isSelectionMode) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );

    // Don't show slidable in selection mode
    if (isSelectionMode) {
      return content;
    }

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (slidableContext) async {
              final confirmed = await showDialog<bool>(
                context: slidableContext,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Delete Book'),
                  content: Text(
                    'Are you sure you want to delete "${book.title}"? This will also delete the EPUB file and cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                onDelete?.call();
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _buildCover(BuildContext context) {
    Widget coverWidget;

    if (book.coverPath != null && File(book.coverPath!).existsSync()) {
      coverWidget = Image.file(
        File(book.coverPath!),
        fit: BoxFit.cover,
      );
    } else {
      coverWidget = Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.menu_book,
          size: 32,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      );
    }

    return SizedBox(
      width: 60,
      height: 90,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: coverWidget,
      ),
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
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
