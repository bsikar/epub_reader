import 'dart:io';
import 'dart:async';
import 'package:epub_reader/app.dart';
import 'package:epub_reader/core/database/app_database.dart' as db;
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/reader/presentation/providers/reader_providers.dart';
import 'package:epub_reader/features/reader/presentation/widgets/bookmarks_drawer.dart';
import 'package:epub_view/epub_view.dart';
import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  ConsumerState<ReaderScreen> createState() => ReaderScreenState();
}

@visibleForTesting
class ReaderScreenState extends ConsumerState<ReaderScreen> {
  EpubController? _epubController;
  bool _isLoading = true;
  String? _errorMessage;
  double _fontSize = 16.0;
  String _selectedTheme = 'light';
  List<EpubChapter>? _chapters;
  List<EpubChapter>? _filteredChapters; // Chapters without footer
  Timer? _progressSaveTimer;
  Timer? _chapterUpdateTimer; // Frequent timer for real-time chapter updates
  String? _currentCfi;
  int _currentChapterIndex = 0;
  bool _showProgressBar = true;
  List<db.Bookmark> _bookmarks = [];
  bool _isUserDraggingSlider = false;
  int? _targetChapterIndex;
  Timer? _navigationTimer;
  String _currentOverlay = '';

  // Test helpers
  @visibleForTesting
  void setChaptersForTesting(List<EpubChapter>? chapters) {
    _chapters = chapters;
    _filteredChapters = chapters?.where((chapter) => !_isFooterChapter(chapter)).toList();
  }

  @visibleForTesting
  void setBookmarksForTesting(List<db.Bookmark> bookmarks) {
    _bookmarks = bookmarks;
  }

  @visibleForTesting
  int get currentChapterIndex => _currentChapterIndex;

  @visibleForTesting
  int? get filteredChaptersLength => _filteredChapters?.length;

  @override
  void initState() {
    super.initState();
    _loadEpub();
    _startAutoSave();
  }

  // coverage:ignore-start
  void _startAutoSave() {
    // Auto-save reading progress every 5 seconds
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _saveProgress();
    });

    // Update chapter indicator in real-time (every 300ms)
    _chapterUpdateTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      _updateChapterIndicator();
    });
  }

  void _updateChapterIndicator() {
    if (_epubController == null || _filteredChapters == null) return;

    try {
      final cfi = _epubController!.generateEpubCfi();
      if (cfi != null && cfi != _currentCfi) {
        // Don't update _currentCfi here (that's for saving), just update the UI
        if (!cfi.contains('[pg-footer-heading]') && !cfi.contains('[pg-header]')) {
          _updateChapterFromCfi(cfi);
        }
      }
    } catch (e) {
      // Silently ignore errors during frequent updates
    }
  }

  Future<void> _saveProgress() async {
    if (_epubController == null || widget.book.id == null) return;

    try {
      final cfi = _epubController!.generateEpubCfi();
      if (cfi == null || cfi == _currentCfi) return;

      // Don't save footer CFIs - they cause issues with chapter tracking
      // Check for footer-heading anchor, not just pg-footer (which appears in all CFIs)
      if (cfi.contains('[pg-footer-heading]') || cfi.contains('[pg-header]')) {
        debugPrint('Skipping save of footer CFI: $cfi');
        return;
      }

      _currentCfi = cfi;

      // Update chapter index based on CFI since onChapterChanged is unreliable
      _updateChapterFromCfi(cfi);

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

  void _updateChapterFromCfi(String cfi) {
    if (_filteredChapters == null || _filteredChapters!.isEmpty) return;

    try {
      // Extract chapter anchors from CFI (e.g., [pgepubid00003] from epubcfi(/6/30[pg-footer]!/4/2[pgepubid00003]/10))
      final anchorRegex = RegExp(r'\[([^\]]+)\]');
      final matches = anchorRegex.allMatches(cfi);

      for (final match in matches) {
        final anchor = match.group(1);
        if (anchor == null || anchor == 'pg-footer' || anchor == 'pg-header' || anchor == 'pg-footer-heading') continue;

        // Find matching chapter
        final chapterIndex = _filteredChapters!.indexWhere((ch) => ch.Anchor == anchor);
        if (chapterIndex != -1 && chapterIndex != _currentChapterIndex) {
          debugPrint('Chapter updated from CFI: $_currentChapterIndex -> $chapterIndex (anchor: $anchor)');
          setState(() {
            _currentChapterIndex = chapterIndex;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error extracting chapter from CFI: $e');
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
      debugPrint('Loading EPUB with saved CFI: $savedCfi');

      // Don't load footer CFIs - they cause the chapter indicator to not update
      // Check for footer-heading anchor, not just pg-footer (which appears in all CFIs)
      final cfiToLoad = (savedCfi != null && (savedCfi.contains('[pg-footer-heading]') || savedCfi.contains('[pg-header]'))) ? null : savedCfi;
      if (savedCfi != null && cfiToLoad == null) {
        debugPrint('Ignoring footer CFI on load: $savedCfi');
      }

      _epubController = EpubController(
        document: Future.value(epubDoc),
        epubCfi: cfiToLoad,
      );

      _currentCfi = cfiToLoad;

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
  // coverage:ignore-end

  // coverage:ignore-start
  @override
  void dispose() {
    _progressSaveTimer?.cancel();
    _chapterUpdateTimer?.cancel();
    _navigationTimer?.cancel();
    _saveProgress(); // Save one last time before disposing
    _epubController?.dispose();
    super.dispose();
  }
  // coverage:ignore-end

  @override
  Widget build(BuildContext context) {
    // Update the current screen provider based on progress bar visibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenName = _showProgressBar ? 'reader-progress' : 'reader';
      ref.read(currentScreenProvider.notifier).state = screenName;
    });

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
                  icon: const Icon(Icons.bookmark_add),
                  onPressed: _addBookmark,
                  tooltip: 'Add bookmark',
                ),
                Builder(
                  builder: (BuildContext scaffoldContext) {
                    return IconButton(
                      icon: const Icon(Icons.bookmarks),
                      onPressed: () {
                        // Update screen name for bookmarks drawer
                        ref.read(currentScreenProvider.notifier).state = 'reader-bookmarks-drawer';
                        Scaffold.of(scaffoldContext).openEndDrawer();
                      },
                      tooltip: 'View bookmarks',
                    );
                  },
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
                IconButton(
                  icon: Icon(
                    _showProgressBar
                        ? Icons.linear_scale
                        : Icons.linear_scale_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _showProgressBar = !_showProgressBar;
                    });
                  },
                  tooltip: _showProgressBar
                      ? 'Hide progress bar'
                      : 'Show progress bar',
                ),
              ]
            : [],
      ),
      endDrawer: widget.book.id != null
          ? BookmarksDrawer(
              bookId: widget.book.id!,
              showProgressBar: _showProgressBar,
              onBookmarkTap: (cfi) {
                // Clear any navigation flags when navigating via bookmark
                _navigationTimer?.cancel();
                setState(() {
                  _isUserDraggingSlider = false;
                  // Don't set targetChapterIndex for bookmarks as they may not be chapter starts
                });

                _epubController?.gotoEpubCfi(cfi);
                debugPrint('Bookmark navigation to CFI: $cfi');
              },
            )
          : null,
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

    // coverage:ignore-start
    return Stack(
      children: [
        EpubView(
          controller: _epubController!,
          onChapterChanged: _onChapterChanged,
          onDocumentLoaded: _onDocumentLoaded,
          onDocumentError: _onDocumentError,
        ),
        if (_showProgressBar && _filteredChapters != null && _filteredChapters!.isNotEmpty)
          _buildProgressBar(),
      ],
    );
  }

  Widget _buildProgressBar() {
    final totalChapters = _filteredChapters?.length ?? 0;
    if (totalChapters == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.98),
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Chapter ${_currentChapterIndex + 1} of $totalChapters',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (_filteredChapters != null &&
                              _currentChapterIndex < _filteredChapters!.length)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                _filteredChapters![_currentChapterIndex].Title?.trim() ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _showProgressBar ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        size: 24,
                      ),
                      onPressed: () {
                        setState(() {
                          _showProgressBar = !_showProgressBar;
                        });
                      },
                      tooltip: _showProgressBar ? 'Hide progress bar' : 'Show progress bar',
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Bookmark indicators
                    if (_bookmarks.isNotEmpty) ...buildBookmarkIndicators(totalChapters, colorScheme),
                    // Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: colorScheme.primary,
                        inactiveTrackColor: colorScheme.surfaceContainerHighest,
                        thumbColor: colorScheme.primary,
                        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                        valueIndicatorColor: colorScheme.primaryContainer,
                        valueIndicatorTextStyle: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                        showValueIndicator: ShowValueIndicator.onlyForDiscrete,
                      ),
                      child: Slider(
                        value: _currentChapterIndex.toDouble(),
                        min: 0,
                        max: (totalChapters - 1).toDouble(),
                        divisions: totalChapters > 1 ? totalChapters - 1 : null,
                        label: 'Chapter ${_currentChapterIndex + 1}',
                        onChangeStart: (value) {
                          // Cancel any pending navigation timer
                          _navigationTimer?.cancel();

                          // Mark that user is actively dragging
                          setState(() {
                            _isUserDraggingSlider = true;
                            _targetChapterIndex = null;
                          });
                          debugPrint('Slider drag started - callbacks blocked');
                        },
                        onChanged: (value) {
                          // Update slider position immediately for smooth dragging
                          final newIndex = value.round();
                          if (newIndex != _currentChapterIndex &&
                              newIndex < totalChapters) {
                            debugPrint('Slider position: $_currentChapterIndex -> $newIndex');
                            setState(() {
                              _currentChapterIndex = newIndex;
                            });
                          }
                        },
                        onChangeEnd: (value) {
                          // Navigate to chapter only when user finishes dragging
                          final newIndex = value.round();
                          debugPrint('Slider drag ended at chapter $newIndex - navigating...');

                          if (newIndex < totalChapters) {
                            setState(() {
                              _targetChapterIndex = newIndex;
                              _currentChapterIndex = newIndex;
                            });

                            _navigateToChapter(newIndex);

                            // Improved timeout with proper cleanup
                            _navigationTimer?.cancel();
                            _navigationTimer = Timer(const Duration(milliseconds: 1500), () {
                              if (mounted) {
                                debugPrint('Navigation complete - clearing flags');
                                setState(() {
                                  _isUserDraggingSlider = false;
                                  _targetChapterIndex = null;
                                });
                              }
                            });
                          } else {
                            setState(() {
                              _isUserDraggingSlider = false;
                              _targetChapterIndex = null;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(_currentChapterIndex / (totalChapters - 1).clamp(1, double.infinity) * 100).toStringAsFixed(0)}% complete',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Ch. ${_currentChapterIndex + 1}/$totalChapters',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // coverage:ignore-end

  // coverage:ignore-start
  void _navigateToChapter(int chapterIndex) {
    if (_filteredChapters == null ||
        chapterIndex < 0 ||
        chapterIndex >= _filteredChapters!.length) {
      debugPrint('Navigation aborted: invalid chapter index $chapterIndex');
      return;
    }

    final chapter = _filteredChapters![chapterIndex];
    debugPrint('Navigating to chapter $chapterIndex: "${chapter.Title}" (Anchor: ${chapter.Anchor})');
    if (chapter.Anchor != null) {
      // Try using the anchor ID directly as a fragment identifier
      final anchor = '#${chapter.Anchor}';
      _epubController?.gotoEpubCfi(anchor);
      debugPrint('Called gotoEpubCfi with anchor: $anchor');
    } else {
      debugPrint('WARNING: Chapter $chapterIndex has no Anchor!');
    }
  }

  void _onChapterChanged(dynamic chapterValue) {
    // Block updates while user is dragging the slider
    if (_isUserDraggingSlider) {
      debugPrint('Callback blocked - user is dragging slider');
      return;
    }

    // Try to extract chapter information from the callback value
    if (_chapters != null && _filteredChapters != null && chapterValue != null) {
      try {
        // Attempt to access chapter property dynamically
        final chapter = chapterValue.chapter;
        if (chapter != null) {
          // Ignore footer chapters completely
          if (_isFooterChapter(chapter)) {
            debugPrint('Ignoring footer chapter change: ${chapter.Title}');
            return;
          }

          debugPrint('Chapter anchor from callback: ${chapter.Anchor}');
          debugPrint('Chapter title from callback: ${chapter.Title}');

          // Find the chapter in our filtered list
          int chapterIndex = -1;

          // Try to match by anchor first
          if (chapter.Anchor != null && chapter.Anchor!.isNotEmpty) {
            chapterIndex = _filteredChapters!.indexWhere(
              (ch) => ch.Anchor == chapter.Anchor,
            );
          }

          // If anchor matching failed, try to match by title as fallback
          if (chapterIndex == -1 && chapter.Title != null && chapter.Title!.isNotEmpty) {
            debugPrint('Anchor matching failed, trying title matching for: ${chapter.Title}');
            chapterIndex = _filteredChapters!.indexWhere(
              (ch) => ch.Title?.trim() == chapter.Title?.trim(),
            );
          }

          if (chapterIndex == -1) {
            debugPrint('Chapter not found in filtered list: ${chapter.Title} (Anchor: ${chapter.Anchor})');
            return;
          }

          // If we're navigating to a specific chapter (from slider)
          if (_targetChapterIndex != null) {
            // Clear the navigation state once we reach the target
            if (chapterIndex == _targetChapterIndex) {
              debugPrint('Reached target chapter $chapterIndex');
              _navigationTimer?.cancel();
              setState(() {
                _targetChapterIndex = null;
              });
            }
            // Don't update the chapter index as it's already set by the slider
            return;
          }

          // Normal chapter change from scrolling
          if (chapterIndex != _currentChapterIndex) {
            debugPrint('Chapter changed from scrolling: $_currentChapterIndex -> $chapterIndex');
            debugPrint('  New chapter: ${_filteredChapters![chapterIndex].Title}');
            setState(() {
              _currentChapterIndex = chapterIndex;
            });
          }
        } else {
          debugPrint('Chapter is null in callback value');
        }
      } catch (e) {
        // Fallback: Just log the chapter change
        debugPrint('Chapter changed (unable to determine index): $e');
      }
    } else {
      debugPrint('onChapterChanged: chapters or chapterValue is null');
    }
  }

  bool _isFooterChapter(EpubChapter? chapter) {
    if (chapter == null) return false;

    // Check for common footer patterns
    final anchor = chapter.Anchor?.toLowerCase() ?? '';
    final title = chapter.Title?.toLowerCase() ?? '';

    return anchor.contains('footer') ||
           anchor.contains('pg-footer') ||
           title.contains('project gutenberg') ||
           title.contains('full project gutenberg license') ||
           title.contains('end of the project gutenberg') ||
           title.contains('end of project gutenberg');
  }

  void _onDocumentLoaded(EpubBook document) {
    setState(() {
      _chapters = document.Chapters;

      // Filter out footer chapters for navigation
      _filteredChapters = _chapters?.where((chapter) => !_isFooterChapter(chapter)).toList();
    });

    debugPrint('Document loaded with ${_chapters?.length ?? 0} total chapters');
    debugPrint('Filtered to ${_filteredChapters?.length ?? 0} content chapters (excluded footers)');

    // Debug: Log filtered chapters
    if (_filteredChapters != null) {
      for (int i = 0; i < _filteredChapters!.length; i++) {
        debugPrint('Chapter $i: "${_filteredChapters![i].Title}" -> Anchor: ${_filteredChapters![i].Anchor}');
      }
    }

    // Log excluded chapters
    if (_chapters != null && _filteredChapters != null) {
      final excluded = _chapters!.where((ch) => _isFooterChapter(ch)).toList();
      if (excluded.isNotEmpty) {
        debugPrint('Excluded footer chapters:');
        for (final ch in excluded) {
          debugPrint('  - "${ch.Title}" (Anchor: ${ch.Anchor})');
        }
      }
    }

    // Update chapter index from loaded CFI (for persistence)
    if (_currentCfi != null) {
      _updateChapterFromCfi(_currentCfi!);
    }

    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    if (widget.book.id == null) return;

    final getBookmarks = ref.read(getBookmarksProvider);
    final result = await getBookmarks(widget.book.id!);

    result.fold(
      (failure) {
        debugPrint('Error loading bookmarks: ${failure.message}');
      },
      (bookmarks) {
        if (mounted) {
          setState(() {
            _bookmarks = bookmarks;
          });
          debugPrint('Loaded ${bookmarks.length} bookmarks');
        }
      },
    );
  }

  @visibleForTesting
  Set<int> getBookmarkChapterIndices() {
    if (_filteredChapters == null || _bookmarks.isEmpty) {
      return {};
    }

    final bookmarkIndices = <int>{};
    for (final bookmark in _bookmarks) {
      // Try to find matching chapter by name
      final chapterIndex = _filteredChapters!.indexWhere(
        (chapter) {
          final chapterTitle = chapter.Title?.trim() ?? '';
          final bookmarkChapter = bookmark.chapterName.trim();
          return chapterTitle.isNotEmpty &&
              bookmarkChapter.isNotEmpty &&
              chapterTitle == bookmarkChapter;
        },
      );

      if (chapterIndex != -1) {
        bookmarkIndices.add(chapterIndex);
      }
    }

    return bookmarkIndices;
  }

  @visibleForTesting
  List<Widget> buildBookmarkIndicators(int totalChapters, ColorScheme colorScheme) {
    final bookmarkIndices = getBookmarkChapterIndices();
    if (bookmarkIndices.isEmpty || totalChapters <= 1) {
      return [];
    }

    return bookmarkIndices.map((chapterIndex) {
      // Calculate position as percentage (0.0 to 1.0)
      final position = chapterIndex / (totalChapters - 1);

      return LayoutBuilder(
        builder: (context, constraints) {
          // Account for slider thumb radius (10px on each side)
          const thumbRadius = 10.0;
          const indicatorSize = 8.0;
          const tapTargetSize = 24.0; // Minimum touch target size
          final availableWidth = constraints.maxWidth - (thumbRadius * 2);
          final leftPosition = (availableWidth * position) + thumbRadius - (tapTargetSize / 2);

          return Positioned(
            left: leftPosition,
            child: GestureDetector(
              onTap: () {
                debugPrint('Bookmark indicator tapped for chapter $chapterIndex');

                // Clear navigation flags
                _navigationTimer?.cancel();
                setState(() {
                  _isUserDraggingSlider = false;
                  _targetChapterIndex = chapterIndex;
                  _currentChapterIndex = chapterIndex;
                });

                // Navigate to the chapter
                _navigateToChapter(chapterIndex);

                // Set timeout to clear navigation flags
                _navigationTimer = Timer(const Duration(milliseconds: 1500), () {
                  if (mounted) {
                    setState(() {
                      _targetChapterIndex = null;
                    });
                  }
                });
              },
              child: Container(
                width: tapTargetSize,
                height: tapTargetSize,
                alignment: Alignment.center,
                child: Container(
                  width: indicatorSize,
                  height: indicatorSize,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.surface,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.2),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }
  // coverage:ignore-end

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
      // Update screen name for add bookmark dialog
      ref.read(currentScreenProvider.notifier).state = 'reader-add-bookmark';

      final note = await showDialog<String>(
        context: context,
        builder: (context) => const BookmarkNoteDialog(),
      );

      // Reset screen name when dialog is closed
      if (mounted) {
        final screenName = _showProgressBar ? 'reader-progress' : 'reader';
        ref.read(currentScreenProvider.notifier).state = screenName;
      }

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
          // Reload bookmarks to update indicators
          _loadBookmarks();
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
    if (_filteredChapters == null || _filteredChapters!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No table of contents available')),
      );
      return;
    }

    // Update screen name for table of contents
    ref.read(currentScreenProvider.notifier).state = 'reader-table-of-contents';

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
                  itemCount: _filteredChapters!.length,
                  itemBuilder: (context, index) {
                    final chapter = _filteredChapters![index];
                    return _buildChapterTile(chapter, 0, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // Reset screen name when bottom sheet is closed
      if (mounted) {
        final screenName = _showProgressBar ? 'reader-progress' : 'reader';
        ref.read(currentScreenProvider.notifier).state = screenName;
      }
    });
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
            if (chapter.Anchor != null && _filteredChapters != null) {
              // Find the chapter index in filtered chapters
              final chapterIndex = _filteredChapters!.indexWhere(
                (ch) => ch.Anchor == chapter.Anchor,
              );

              if (chapterIndex != -1) {
                // Clear any navigation flags and update state
                _navigationTimer?.cancel();
                setState(() {
                  _isUserDraggingSlider = false;
                  _targetChapterIndex = chapterIndex;
                  _currentChapterIndex = chapterIndex;
                });

                // Navigate to the chapter
                _epubController?.gotoEpubCfi(chapter.Anchor!);
                debugPrint('TOC navigation to chapter $chapterIndex: ${chapter.Title}');

                // Set timeout to clear navigation flags
                _navigationTimer = Timer(const Duration(milliseconds: 1500), () {
                  if (mounted) {
                    setState(() {
                      _targetChapterIndex = null;
                    });
                  }
                });
              }

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
    // Update screen name for font settings
    ref.read(currentScreenProvider.notifier).state = 'reader-font-settings';

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
    ).then((_) {
      // Reset screen name when bottom sheet is closed
      if (mounted) {
        final screenName = _showProgressBar ? 'reader-progress' : 'reader';
        ref.read(currentScreenProvider.notifier).state = screenName;
      }
    });
  }
}

class BookmarkNoteDialog extends StatefulWidget {
  const BookmarkNoteDialog({super.key});

  @override
  State<BookmarkNoteDialog> createState() => _BookmarkNoteDialogState();
}

class _BookmarkNoteDialogState extends State<BookmarkNoteDialog> {
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
