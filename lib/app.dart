import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:epub_reader/core/config/theme.dart';
import 'package:epub_reader/features/library/presentation/screens/library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Provider to track the current screen name
final currentScreenProvider = StateProvider<String>((ref) => 'library');

class EPUBReaderApp extends ConsumerStatefulWidget {
  const EPUBReaderApp({super.key});

  @override
  ConsumerState<EPUBReaderApp> createState() => _EPUBReaderAppState();
}

class _EPUBReaderAppState extends ConsumerState<EPUBReaderApp> {
  final GlobalKey _screenshotKey = GlobalKey();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  String _getCurrentScreenName() {
    // Simply read from the provider
    return ref.read(currentScreenProvider);
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

      final String screenName = _getCurrentScreenName();
      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String filename = '${timestamp}_screenshot_$screenName.png';
      final String filePath = '${screenshotsDir.path}${Platform.pathSeparator}$filename';

      final File file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());
    } catch (e, stackTrace) {
      // Silently fail - don't disrupt user experience
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f12): _takeScreenshot,
        const SingleActivator(
          LogicalKeyboardKey.keyS,
          control: true,
          shift: true,
        ): _takeScreenshot,
      },
      child: Focus(
        autofocus: true,
        child: RepaintBoundary(
          key: _screenshotKey,
          child: MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'EPUB Reader',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: ThemeMode.system,
            onGenerateRoute: (settings) {
              // This will never be called since we're using home, but kept for future routing
              return null;
            },
            home: Builder(
              builder: (context) => const LibraryScreen(),
            ),
          ),
        ),
      ),
    );
  }
}
