import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
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
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  ConsumerState<ReaderScreen> createState() => ReaderScreenState();
}

@visibleForTesting
class ReaderScreenState extends ConsumerState<ReaderScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey _screenshotKey = GlobalKey();
  EpubController? _epubController;
  bool _isLoading = true;
  bool _epubFullyLoaded = false;
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
    WidgetsBinding.instance.addObserver(this);
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
      if (_epubController != null && mounted && !_isLoading && _epubFullyLoaded) {
        _epubController!.getCurrentLocation().then((location) {
          if (location != null && location.startCfi != null && location.startCfi!.isNotEmpty) {
            _savePosition(location.startCfi!);
          }
        }).catchError((e) {
          // Suppress common harmless errors during EPUB loading
          final errorStr = e.toString();
          if (!errorStr.contains('locations not loaded') && 
              !errorStr.contains('rendition.location') &&
              !errorStr.contains('not a subtype of type') &&
              !errorStr.contains('Map<String, dynamic>')) {
            debugPrint('Error getting location: $e');
          }
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

      // Configure WebView settings directly to disable keyboard shortcuts
      await _configureWebViewSettings();

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

  Future<void> _configureWebViewSettings() async {
    try {
      // Wait a bit more to ensure WebView is fully initialized
      await Future.delayed(const Duration(milliseconds: 500));

      final webViewController = _epubController?.webViewController;
      if (webViewController != null) {
        // Try to set settings to disable browser accelerator keys
        // This may not work on all versions, but worth trying
        await webViewController.setSettings(
          settings: InAppWebViewSettings(
            isInspectable: false,
            disableContextMenu: true,
            supportZoom: false,
          ),
        );

        // Register JavaScript handler for screenshot requests from WebView
        webViewController.addJavaScriptHandler(
          handlerName: 'takeScreenshot',
          callback: (args) {
            debugPrint('WebView requested screenshot via handler');
            _takeScreenshot();
            return null;
          },
        );

        debugPrint('WebView settings configured successfully');
      }
    } catch (e) {
      debugPrint('Error configuring WebView settings: $e');
      // Continue anyway - we'll rely on JavaScript blocking
    }
  }

  Future<void> _loadSavedPosition() async {
    if (widget.book.lastCfi != null && widget.book.lastCfi!.isNotEmpty) {
      // Wait longer to ensure the EPUB is fully loaded
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted && _epubController != null) {
        try {
          _epubController!.display(cfi: widget.book.lastCfi!);
          debugPrint('Loaded saved position: ${widget.book.lastCfi}');
        } catch (e) {
          debugPrint('Error loading saved position: $e');
        }
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
    WidgetsBinding.instance.removeObserver(this);
    _progressTracker?.cancel();
    _appBarController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Override to prevent WebView resume errors on macOS
    // The flutter_epub_reader package tries to call resume which isn't implemented on macOS
    super.didChangeAppLifecycleState(state);
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
      debugPrint('Screenshot requested');
      
      // Try to create composite screenshot with WebView content and Flutter UI
      Uint8List? compositeBytes = await _createCompositeScreenshot();
      
      if (compositeBytes != null) {
        await _saveScreenshotBytes(compositeBytes);
        debugPrint('Screenshot taken (composite with WebView content)');
        return;
      }
      
      // Fallback to RepaintBoundary method
      final RenderRepaintBoundary? boundary = _screenshotKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('Screenshot failed: boundary is null');
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        debugPrint('Screenshot failed: byteData is null');
        return;
      }

      await _saveScreenshotBytes(byteData.buffer.asUint8List());
      debugPrint('Screenshot taken from RepaintBoundary (fallback)');
    } catch (e) {
      debugPrint('Screenshot error: $e');
      // Silently fail - don't disrupt user experience
    }
  }

  Future<Uint8List?> _createCompositeScreenshot() async {
    try {
      // Get WebView screenshot
      final webViewBytes = await _epubController?.webViewController?.takeScreenshot();
      if (webViewBytes == null) return null;
      
      // Get Flutter UI screenshot  
      final RenderRepaintBoundary? boundary = _screenshotKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      final ui.Image uiImage = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? uiByteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      if (uiByteData == null) return null;
      
      // Convert to image package format
      final webViewImage = img.decodeImage(webViewBytes);
      final uiImageData = img.decodeImage(uiByteData.buffer.asUint8List());
      
      if (webViewImage == null || uiImageData == null) return null;
      
      // Create composite by overlaying WebView content onto UI
      // The UI image should have a transparent area where the WebView is
      final composite = img.Image.from(uiImageData);
      
      // Calculate WebView area position (roughly center area minus header/footer)
      final headerHeight = (composite.height * 0.15).round(); // Approximate header
      final footerHeight = (composite.height * 0.1).round();  // Approximate footer
      final contentHeight = composite.height - headerHeight - footerHeight;
      
      // Resize WebView image to fit content area
      final resizedWebView = img.copyResize(
        webViewImage, 
        width: composite.width,
        height: contentHeight,
      );
      
      // Composite the images
      img.drawImage(composite, resizedWebView, dstX: 0, dstY: headerHeight);
      
      return Uint8List.fromList(img.encodePng(composite));
    } catch (e) {
      debugPrint('Composite screenshot error: $e');
      return null;
    }
  }

  Future<void> _saveScreenshotBytes(Uint8List bytes) async {
    String projectPath;
    if (Platform.isWindows) {
      final userHome = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
      if (userHome != null) {
        projectPath = '$userHome\\IdeaProjects\\epub_reader\\screenshots';
      } else {
        projectPath = '${Directory.systemTemp.path}\\epub_screenshots';
      }
    } else if (Platform.isMacOS) {
      final userHome = Platform.environment['HOME'];
      if (userHome != null) {
        projectPath = '$userHome/Documents/git/epub_reader/screenshots';
      } else {
        final appDocuments = await getApplicationDocumentsDirectory();
        projectPath = '${appDocuments.path}/epub_screenshots';
      }
    } else {
      // Linux and other platforms
      final appDocuments = await getApplicationDocumentsDirectory();
      projectPath = '${appDocuments.path}/epub_screenshots';
    }

    final Directory screenshotsDir = Directory(projectPath);

    if (!await screenshotsDir.exists()) {
      await screenshotsDir.create(recursive: true);
      debugPrint('Created screenshot directory: $projectPath');
    }

    final String screenName = ref.read(currentScreenProvider);
    final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final String filename = '${timestamp}_screenshot_$screenName.png';
    final String filePath = '${screenshotsDir.path}${Platform.pathSeparator}$filename';

    final File file = File(filePath);
    await file.writeAsBytes(bytes);
    debugPrint('Screenshot saved: $filePath');
  }

  void _hideScrollbars() {
    _injectWebViewCustomizations();
  }

  void _injectWebViewCustomizations() {
    // Disable scrolling in the WebView and block F5/F12
    // This uses a more aggressive approach that survives page reloads
    _epubController?.webViewController?.evaluateJavascript(source: '''
      (function() {
        console.log('[EPUB] Injecting customizations...');

        // Always re-apply styles
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

        // Define event handlers as named functions (easier to debug)
        function blockScroll(e) {
          e.preventDefault();
          e.stopImmediatePropagation();
        }

        function blockKeys(e) {
          var isF5 = e.keyCode === 116;
          var isF12 = e.keyCode === 123;
          var isDevTools =
            (e.ctrlKey && e.shiftKey && (e.keyCode === 73 || e.keyCode === 74)) || // Ctrl+Shift+I/J
            (e.ctrlKey && e.keyCode === 85); // Ctrl+U

          if (isF5 || isF12) {
            console.log('[EPUB] Blocked screenshot key:', e.keyCode, e.key);
            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();

            // Notify Flutter to take screenshot
            window.flutter_inappwebview.callHandler('takeScreenshot', { key: e.keyCode });

            return false;
          }

          if (isDevTools) {
            console.log('[EPUB] Blocked dev tools key:', e.keyCode, e.key);
            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();
            return false;
          }
        }

        function blockContextMenu(e) {
          e.preventDefault();
          e.stopImmediatePropagation();
          return false;
        }

        // Remove existing listeners first (if they exist)
        if (window._epubEventHandlers) {
          console.log('[EPUB] Removing old event handlers');
          window.removeEventListener('wheel', window._epubEventHandlers.scroll, true);
          document.removeEventListener('wheel', window._epubEventHandlers.scroll, true);
          window.removeEventListener('touchmove', window._epubEventHandlers.scroll, true);
          document.removeEventListener('touchmove', window._epubEventHandlers.scroll, true);
          window.removeEventListener('keydown', window._epubEventHandlers.keys, true);
          document.removeEventListener('keydown', window._epubEventHandlers.keys, true);
          window.removeEventListener('contextmenu', window._epubEventHandlers.context, true);
          document.removeEventListener('contextmenu', window._epubEventHandlers.context, true);
        }

        // Store handlers for potential removal later
        window._epubEventHandlers = {
          scroll: blockScroll,
          keys: blockKeys,
          context: blockContextMenu
        };

        // Attach event listeners with capture=true for highest priority
        window.addEventListener('wheel', blockScroll, { passive: false, capture: true });
        document.addEventListener('wheel', blockScroll, { passive: false, capture: true });
        window.addEventListener('touchmove', blockScroll, { passive: false, capture: true });
        document.addEventListener('touchmove', blockScroll, { passive: false, capture: true });

        // CRITICAL: Block keyboard events
        window.addEventListener('keydown', blockKeys, { passive: false, capture: true });
        document.addEventListener('keydown', blockKeys, { passive: false, capture: true });

        // Block context menu
        window.addEventListener('contextmenu', blockContextMenu, { passive: false, capture: true });
        document.addEventListener('contextmenu', blockContextMenu, { passive: false, capture: true });

        // Mark as applied
        window._epubCustomizationsApplied = true;
        console.log('[EPUB] Customizations applied successfully');

        // Re-inject on any iframe load (epub.js uses iframes)
        setTimeout(function() {
          var iframes = document.querySelectorAll('iframe');
          iframes.forEach(function(iframe) {
            try {
              if (iframe.contentDocument) {
                var iframeDoc = iframe.contentDocument;
                iframeDoc.addEventListener('keydown', blockKeys, { passive: false, capture: true });
                console.log('[EPUB] Applied to iframe');
              }
            } catch(e) {
              console.log('[EPUB] Cannot access iframe (cross-origin):', e);
            }
          });
        }, 500);
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
                    onEpubLoaded: () async {
                      debugPrint('EPUB loaded successfully');
                      _hideScrollbars();
                      // Wait a bit more before allowing location tracking
                      await Future.delayed(const Duration(milliseconds: 1000));
                      setState(() {
                        _epubFullyLoaded = true;
                      });
                      debugPrint('EPUB fully initialized');
                    },
                    onRelocated: (location) {
                      // Re-inject customizations after any page navigation/reload
                      _injectWebViewCustomizations();
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
      // Re-inject customizations multiple times to ensure they stick
      // The WebView might reload during font size/position changes
      await Future.delayed(const Duration(milliseconds: 200));
      _injectWebViewCustomizations();
      await Future.delayed(const Duration(milliseconds: 300));
      _injectWebViewCustomizations();
      await Future.delayed(const Duration(milliseconds: 500));
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
