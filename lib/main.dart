import 'package:epub_reader/app.dart';
import 'package:epub_reader/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await configureDependencies();

  runApp(
    const ProviderScope(
      child: EPUBReaderApp(),
    ),
  );
}
