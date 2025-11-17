import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:epub_reader/app.dart';
import 'package:epub_reader/core/config/theme.dart';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/reader/presentation/providers/reader_providers.dart';
import 'package:epub_reader/features/reader/presentation/widgets/bookmarks_drawer.dart';
import 'package:flutter_epub_reader/flutter_epub_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  ConsumerState<ReaderScreen> createState() => ReaderScreenState();
}

@visibleForTesting
class ReaderScreenState extends ConsumerState<ReaderScreen> with SingleTickerProviderStateMixin {
  final GlobalKey _screenshotKey = GlobalKey();
  EpubController? _epubController;
  bool _isLoading = true;
  String? _errorMessage;
  double _fontSize = 18.0;
  String _selectedTheme = 'sepia';
  String? _currentChapter;
  double _currentProgress = 0.0;
  bool _showAppBar = true;
  late AnimationController _appBarController;
  late Animation<Offset> _appBarSlideAnimation;
  Timer? _progressTracker;

  @override
  void initState() {
    super.initState();
    _appBarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _appBarSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _appBarController,
      curve: Curves.easeInOut,
    ));
    _initializeReader();
    _startProgressTracking();
  }

  void _startProgressTracking() {
    _progressTracker = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_epubController != null && mounted) {
        _epubController!.getCurrentLocation().then((location) {
          if (location != null && location.startCfi != null && location.startCfi!.isNotEmpty) {
            _savePosition(location.startCfi!);
          }
        }).catchError((e) {
          debugPrint('Error getting location: $e');
        });
      }
    });
  }

  Future<void> _initializeReader() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      _epubController = EpubController();

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        await _loadSavedPosition();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load EPUB: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _loadSavedPosition() async {
    if (widget.book.lastCfi != null && widget.book.lastCfi!.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted && _epubController != null) {
        _epubController!.display(cfi: widget.book.lastCfi!);
        debugPrint('Loaded saved position: ${widget.book.lastCfi}');
      }
    }
  }

  Future<void> _savePosition(String cfi) async {
    if (widget.book.id != null && cfi.isNotEmpty) {
      final updateBook = ref.read(updateBookProvider);
      final updatedBook = widget.book.copyWith(
        lastCfi: cfi,
        lastOpened: DateTime.now(),
      );

      await updateBook(updatedBook);
      debugPrint('Saved position: $cfi');
    }
  }

  @override
  void dispose() {
    _progressTracker?.cancel();
    _appBarController.dispose();
    super.dispose();
  }

  void _toggleAppBar() {
    setState(() {
      _showAppBar = !_showAppBar;
    });
    if (_showAppBar) {
      _appBarController.reverse();
    } else {
      _appBarController.forward();
    }
  }

  void _applyTheme(Color background, Color foreground) async {
    _epubController?.updateTheme(
      theme: EpubTheme.custom(
        backgroundColor: background,
        foregroundColor: foreground,
      ),
    );
    // Re-inject customizations after theme change
    await Future.delayed(const Duration(milliseconds: 100));
    _injectWebViewCustomizations();
  }

  Future<void> _takeScreenshot() async {
    try {
      final RenderRepaintBoundary? boundary = _screenshotKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) return;

      String projectPath;
      if (Platform.isWindows) {
        final userHome = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
        if (userHome != null) {
          projectPath = '$userHome\\IdeaProjects\\epub_reader\\screenshots';
        } else {
          projectPath = '${Directory.systemTemp.path}\\epub_screenshots';
        }
      } else {
        projectPath = '${Directory.systemTemp.path}/epub_screenshots';
      }

      final Directory screenshotsDir = Directory(projectPath);

      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }

      final String screenName = ref.read(currentScreenProvider);
      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String filename = '${timestamp}_screenshot_$screenName.png';
      final String filePath = '${screenshotsDir.path}${Platform.pathSeparator}$filename';

      final File file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());
    } catch (e) {
      // Silently fail - don't disrupt user experience
    }
  }

  void _hideScrollbars() {
    _injectWebViewCustomizations();
  }

  void _injectWebViewCustomizations() {
    // Disable scrolling in the WebView, but allow F12 to bubble up for screenshots
    _epubController?.webViewController?.evaluateJavascript(source: '''
      (function() {
        // Remove any existing customizations first
        var existingStyle = document.getElementById('epub-custom-style');
        if (existingStyle) existingStyle.remove();

        var style = document.createElement('style');
        style.id = 'epub-custom-style';
        style.innerHTML = \`
          * {
            scrollbar-width: none !important;
            -ms-overflow-style: none !important;
            overflow: hidden !important;
          }
          *::-webkit-scrollbar {
            display: none !important;
            width: 0 !important;
            height: 0 !important;
          }
          html, body {
            overflow: hidden !important;
            position: fixed !important;
            width: 100% !important;
            height: 100% !important;
          }
        \`;
        document.head.appendChild(style);

        // Remove existing event listeners by cloning
        if (!window._epubCustomizationsApplied) {
          window._epubCustomizationsApplied = true;

          // Disable scroll events
          window.addEventListener('wheel', function(e) {
            e.preventDefault();
            e.stopImmediatePropagation();
          }, { passive: false, capture: true });

          window.addEventListener('touchmove', function(e) {
            e.preventDefault();
            e.stopImmediatePropagation();
          }, { passive: false, capture: true });

          // Block F5 (refresh), F12 (dev tools), and other developer shortcuts
          window.addEventListener('keydown', function(e) {
            if (e.key === 'F5' || e.keyCode === 116 ||
                e.key === 'F12' || e.keyCode === 123 ||
                (e.ctrlKey && e.shiftKey && (e.key === 'I' || e.key === 'i')) ||
                (e.ctrlKey && e.shiftKey && (e.key === 'J' || e.key === 'j')) ||
                (e.ctrlKey && (e.key === 'U' || e.key === 'u'))) {
              e.preventDefault();
              e.stopPropagation();
              return false;
            }
          }, true); // Use capture phase to intercept early

          // Prevent context menu which can open dev tools
          window.addEventListener('contextmenu', function(e) {
            e.preventDefault();
            e.stopImmediatePropagation();
            return false;
          }, { passive: false, capture: true });
        }
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = AppTheme.readingThemes[_selectedTheme]!;

    // Update the current screen provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenProvider.notifier).state = 'reader-${widget.book.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}';
    });

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _epubController?.next(),
        const SingleActivator(LogicalKeyboardKey.space): () => _epubController?.next(),
        const SingleActivator(LogicalKeyboardKey.pageDown): () => _epubController?.next(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _epubController?.prev(),
        const SingleActivator(LogicalKeyboardKey.pageUp): () => _epubController?.prev(),
        const SingleActivator(LogicalKeyboardKey.home): () => _epubController?.moveToFistPage(),
        const SingleActivator(LogicalKeyboardKey.end): () => _epubController?.moveToLastPage(),
        const SingleActivator(LogicalKeyboardKey.escape): _toggleAppBar,
        const SingleActivator(LogicalKeyboardKey.f5): _takeScreenshot,
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          // Always intercept F5 and F12 to prevent WebView from handling them
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.f5) {
              _takeScreenshot();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.f12) {
              _takeScreenshot();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: RepaintBoundary(
          key: _screenshotKey,
          child: Scaffold(
        backgroundColor: themeColors.background,
        appBar: _showAppBar
            ? AppBar(
                title: Text(
                  widget.book.title,
                  style: TextStyle(
                    color: themeColors.onBackground,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: themeColors.background,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: themeColors.onBackground),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.bookmark_border, color: themeColors.onBackground),
                    onPressed: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                    tooltip: 'Bookmarks',
                  ),
                  IconButton(
                    icon: Icon(Icons.format_size, color: themeColors.onBackground),
                    onPressed: () => _showFontSizeDialog(context),
                    tooltip: 'Font size',
                  ),
                  IconButton(
                    icon: Icon(Icons.palette_outlined, color: themeColors.onBackground),
                    onPressed: () => _showThemePicker(context),
                    tooltip: 'Theme',
                  ),
                  const SizedBox(width: 8),
                ],
              )
            : null,
        endDrawer: widget.book.id != null
            ? Drawer(
                child: BookmarksDrawer(
                  bookId: widget.book.id!,
                  onBookmarkTap: (cfi) {
                    _epubController?.display(cfi: cfi);
                    Navigator.of(context).pop();
                  },
                ),
              )
            : null,
        body: SafeArea(
          child: _isLoading
              ? _buildLoadingView(themeColors)
              : _errorMessage != null
                  ? _buildErrorView(themeColors)
                  : _buildReaderView(themeColors),
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView(ReadingThemeColors themeColors) {
    return Container(
      color: themeColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: themeColors.accent),
            const SizedBox(height: 24),
            Text(
              'Loading EPUB...',
              style: TextStyle(
                color: themeColors.onBackground.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(ReadingThemeColors themeColors) {
    return Container(
      color: themeColors.background,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: themeColors.onBackground.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Book',
              style: TextStyle(
                color: themeColors.onBackground,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unknown error',
              style: TextStyle(
                color: themeColors.onBackground.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeReader,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReaderView(ReadingThemeColors themeColors) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -500) {
                      _epubController?.next();
                    } else if (details.primaryVelocity! > 500) {
                      _epubController?.prev();
                    }
                  }
                },
                child: Container(
                  color: themeColors.background,
                  child: EpubViewer(
                    epubController: _epubController!,
                    epubSource: EpubSource.fromFile(File(widget.book.filePath)),
                    displaySettings: EpubDisplaySettings(
                      flow: EpubFlow.paginated,
                      snap: true,
                      fontSize: _fontSize.round(),
                      theme: EpubTheme.custom(
                        backgroundColor: themeColors.background,
                        foregroundColor: themeColors.onBackground,
                      ),
                    ),
                    onEpubLoaded: () {
                      _hideScrollbars();
                    },
                  ),
                ),
              ),
            ),
            _buildFixedProgressBar(themeColors),
          ],
        ),
      ],
    );
  }

  Widget _buildFixedProgressBar(ReadingThemeColors themeColors) {
    return Container(
      decoration: BoxDecoration(
        color: themeColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: themeColors.onBackground,
                  size: 20,
                ),
                onPressed: () {
                  _epubController?.prev();
                },
                tooltip: 'Previous page (←)',
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book,
                          size: 16,
                          color: themeColors.onBackground.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.book.title,
                          style: TextStyle(
                            color: themeColors.onBackground.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: themeColors.onBackground,
                  size: 20,
                ),
                onPressed: () {
                  _epubController?.next();
                },
                tooltip: 'Next page (→)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context) async {
    final themeColors = AppTheme.readingThemes[_selectedTheme]!;
    final initialFontSize = _fontSize;

    // Get and save current position before opening dialog
    final location = await _epubController?.getCurrentLocation();
    final savedCfi = location?.startCfi;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: themeColors.background,
          title: Text(
            'Font Size',
            style: TextStyle(color: themeColors.onBackground),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Aa',
                    style: TextStyle(
                      fontSize: _fontSize,
                      color: themeColors.onBackground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'A',
                    style: TextStyle(
                      fontSize: 14,
                      color: themeColors.onBackground.withValues(alpha: 0.6),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 12,
                      max: 32,
                      divisions: 20,
                      activeColor: themeColors.accent,
                      label: _fontSize.round().toString(),
                      onChanged: (value) {
                        setDialogState(() {
                          _fontSize = value;
                        });
                        setState(() {
                          _fontSize = value;
                        });
                      },
                    ),
                  ),
                  Text(
                    'A',
                    style: TextStyle(
                      fontSize: 24,
                      color: themeColors.onBackground.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Done',
                style: TextStyle(color: themeColors.accent),
              ),
            ),
          ],
        ),
      ),
    );

    // Apply font size change and restore position after dialog closes
    if (initialFontSize != _fontSize && savedCfi != null && savedCfi.isNotEmpty) {
      await _epubController?.setFontSize(_fontSize);
      await Future.delayed(const Duration(milliseconds: 300));
      await _epubController?.display(cfi: savedCfi);
      // Re-inject customizations after font size change
      await Future.delayed(const Duration(milliseconds: 100));
      _injectWebViewCustomizations();
    }
  }

  void _showThemePicker(BuildContext context) {
    final themeColors = AppTheme.readingThemes[_selectedTheme]!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Reading Theme',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: AppTheme.readingThemes.entries.map((entry) {
                return _buildThemeOption(
                  entry.value.name,
                  entry.key,
                  entry.value.background,
                  entry.value.onBackground,
                  entry.value.accent,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String label, String theme, Color bg, Color fg, Color accent) {
    final isSelected = _selectedTheme == theme;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTheme = theme;
        });
        _applyTheme(bg, fg);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? accent : Colors.grey.shade300,
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    'Aa',
                    style: TextStyle(
                      fontSize: 32,
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
