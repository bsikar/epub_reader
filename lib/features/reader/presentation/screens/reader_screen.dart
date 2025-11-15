import 'dart:io';
import 'dart:async';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/reader/presentation/providers/reader_providers.dart';
import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  EpubController? _epubController;
  bool _isLoading = true;
  String? _errorMessage;
  double _fontSize = 16.0;
  String _selectedTheme = 'light';
  List<EpubChapter>? _chapters;
  Timer? _progressSaveTimer;
  String? _currentCfi;

  @override
  void initState() {
    super.initState();
    _loadEpub();
    _startAutoSave();
  }

  void _startAutoSave() {
    // Auto-save reading progress every 5 seconds
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _saveProgress();
    });
  }

  Future<void> _saveProgress() async {
    if (_epubController == null || widget.book.id == null) return;

    try {
      final cfi = _epubController!.generateEpubCfi();
      if (cfi == null || cfi == _currentCfi) return;

      _currentCfi = cfi;

      final updateProgress = ref.read(updateReadingProgressProvider);
      await updateProgress(
        book: widget.book,
        cfi: cfi,
      );

      debugPrint('Progress saved: $cfi');
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  Future<void> _loadEpub() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final file = File(widget.book.filePath);
      if (!await file.exists()) {
        throw Exception('EPUB file not found at: ${widget.book.filePath}');
      }

      final epubDoc = await EpubDocument.openFile(file);

      if (!mounted) return;

      // Load saved reading position if available
      final savedCfi = widget.book.currentCfi;

      _epubController = EpubController(
        document: Future.value(epubDoc),
        epubCfi: savedCfi,
      );

      _currentCfi = savedCfi;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load EPUB: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _progressSaveTimer?.cancel();
    _saveProgress(); // Save one last time before disposing
    _epubController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: _epubController != null
            ? [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // TODO: Implement search
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search feature coming soon')),
                    );
                  },
                  tooltip: 'Search in book',
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: _addBookmark,
                  tooltip: 'Add bookmark',
                ),
                IconButton(
                  icon: const Icon(Icons.format_size),
                  onPressed: () {
                    _showFontSettings(context);
                  },
                  tooltip: 'Font settings',
                ),
                IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: _showTableOfContents,
                  tooltip: 'Table of contents',
                ),
              ]
            : [],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading EPUB...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Book',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadEpub,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_epubController == null) {
      return const Center(
        child: Text('No EPUB controller available'),
      );
    }

    return EpubView(
      controller: _epubController!,
      onChapterChanged: _onChapterChanged,
      onDocumentLoaded: _onDocumentLoaded,
      onDocumentError: _onDocumentError,
    );
  }

  void _onChapterChanged(dynamic chapterValue) {
    // TODO: Save reading progress to database
    debugPrint('Chapter changed');
  }

  void _onDocumentLoaded(EpubBook document) {
    setState(() {
      _chapters = document.Chapters;
    });
    debugPrint('Document loaded with ${_chapters?.length ?? 0} chapters');
  }

  void _onDocumentError(Exception? error) {
    debugPrint('Document error: $error');
    setState(() {
      _errorMessage = 'Error loading document: ${error.toString()}';
      _isLoading = false;
    });
  }

  Future<void> _addBookmark() async {
    if (_epubController == null || widget.book.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to add bookmark')),
      );
      return;
    }

    try {
      final cfi = _epubController!.generateEpubCfi();
      if (cfi == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get current position')),
        );
        return;
      }

      // Show dialog to add note
      final note = await showDialog<String>(
        context: context,
        builder: (context) => _BookmarkNoteDialog(),
      );

      if (note == null) return; // User cancelled

      final addBookmark = ref.read(addBookmarkProvider);
      final result = await addBookmark(
        bookId: widget.book.id!,
        cfi: cfi,
        note: note.isEmpty ? null : note,
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding bookmark: ${failure.message}')),
          );
        },
        (id) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bookmark added successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding bookmark: $e')),
      );
    }
  }

  void _showTableOfContents() {
    if (_chapters == null || _chapters!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No table of contents available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Table of Contents',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _chapters!.length,
                  itemBuilder: (context, index) {
                    final chapter = _chapters![index];
                    return _buildChapterTile(chapter, 0, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterTile(EpubChapter chapter, int level, int index) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 16.0 + (level * 16.0)),
          title: Text(
            chapter.Title?.trim() ?? 'Chapter ${index + 1}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            if (chapter.Anchor != null) {
              _epubController?.gotoEpubCfi(chapter.Anchor!);
              Navigator.pop(context);
            }
          },
        ),
        if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty)
          ...chapter.SubChapters!.asMap().entries.map(
                (entry) => _buildChapterTile(entry.value, level + 1, entry.key),
              ),
      ],
    );
  }

  void _showFontSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Font Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text('Font size'),
              Slider(
                value: _fontSize,
                min: 12,
                max: 48,
                divisions: 36,
                label: _fontSize.round().toString(),
                onChanged: (value) {
                  setModalState(() {
                    _fontSize = value;
                  });
                  setState(() {
                    _fontSize = value;
                  });
                  // TODO: Apply font size to epub_view controller
                },
              ),
              Text(
                'Current size: ${_fontSize.round()}pt',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              const Text('Reading theme'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Light'),
                    selected: _selectedTheme == 'light',
                    onSelected: (selected) {
                      if (selected) {
                        setModalState(() {
                          _selectedTheme = 'light';
                        });
                        setState(() {
                          _selectedTheme = 'light';
                        });
                        // TODO: Apply theme to epub_view controller
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Dark'),
                    selected: _selectedTheme == 'dark',
                    onSelected: (selected) {
                      if (selected) {
                        setModalState(() {
                          _selectedTheme = 'dark';
                        });
                        setState(() {
                          _selectedTheme = 'dark';
                        });
                        // TODO: Apply theme to epub_view controller
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Sepia'),
                    selected: _selectedTheme == 'sepia',
                    onSelected: (selected) {
                      if (selected) {
                        setModalState(() {
                          _selectedTheme = 'sepia';
                        });
                        setState(() {
                          _selectedTheme = 'sepia';
                        });
                        // TODO: Apply theme to epub_view controller
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookmarkNoteDialog extends StatefulWidget {
  @override
  State<_BookmarkNoteDialog> createState() => _BookmarkNoteDialogState();
}

class _BookmarkNoteDialogState extends State<_BookmarkNoteDialog> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Bookmark'),
      content: TextField(
        controller: _noteController,
        decoration: const InputDecoration(
          labelText: 'Note (optional)',
          hintText: 'Add a note to remember this bookmark...',
        ),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _noteController.text),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
