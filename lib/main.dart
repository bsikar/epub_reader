import 'package:epub_reader/app.dart';
import 'package:epub_reader/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress WebView resume errors on macOS
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception.toString().contains('resume is not implemented')) {
      // Silently ignore resume errors from WebView on macOS
      debugPrint('Suppressed WebView resume error on macOS');
      return;
    }
    FlutterError.presentError(details);
  };

  // Initialize dependency injection
  await configureDependencies();

  runApp(
    const ProviderScope(
      child: EPUBReaderApp(),
    ),
  );
}
