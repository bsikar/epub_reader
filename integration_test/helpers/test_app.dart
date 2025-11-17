import 'package:epub_reader/app.dart';
import 'package:epub_reader/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:epub_reader/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:typed_data';
import 'package:epub_reader/features/import/domain/usecases/import_epub.dart';
import 'dart:io';

class TestApp {
  static late GetIt getIt;
  static late String testDirectoryPath;
  static late AppDatabase database;
  static ProviderContainer? providerContainer;

  /// Initialize the test application with all dependencies
  static Future<Widget> createTestApp() async {
    // Clean up any existing test instance
    await cleanup();

    // Initialize GetIt
    getIt = GetIt.instance;

    // Create test directory
    final appDir = await getApplicationDocumentsDirectory();
    testDirectoryPath = '${appDir.path}/epub_reader_test';

    // Initialize dependencies
    await configureDependencies();

    // Get the database instance for direct manipulation if needed
    database = getIt<AppDatabase>();

    // Create a ProviderContainer for accessing providers in tests
    providerContainer = ProviderContainer();

    // Return the app wrapped with ProviderScope
    return ProviderScope(
      child: const EPUBReaderApp(),
    );
  }

  /// Clean up test data and reset state
  static Future<void> cleanup() async {
    try {
      // Dispose provider container if it exists
      providerContainer?.dispose();
      providerContainer = null;

      // Reset GetIt if it was initialized
      if (GetIt.I.isRegistered<AppDatabase>()) {
        final db = GetIt.I<AppDatabase>();
        await db.close();
      }
      await GetIt.I.reset();
    } catch (_) {
      // Ignore errors if GetIt wasn't initialized
    }

    // Test directory cleanup is handled elsewhere
    // since we can't directly check/delete directories without dart:io
  }

  /// Refresh the library provider to load new books
  /// Note: Since we can't directly access the provider from tests,
  /// this method now just waits for the library to auto-refresh
  static Future<void> refreshLibrary() async {
    // Give the library time to detect database changes and refresh
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Clear database but keep app running
  static Future<void> clearDatabase() async {
    // Delete all books (cascades to bookmarks, highlights, etc.)
    await database.customStatement('DELETE FROM books');
    await database.customStatement('DELETE FROM collections');
    await database.customStatement('DELETE FROM reading_sessions');
  }

  /// Add a test book directly to the database
  static Future<int> addTestBook({
    required String title,
    required String author,
    String? filePath,
    String? coverPath,
    String? currentCfi,
    double readingProgress = 0.0,
  }) async {
    final companion = BooksCompanion.insert(
      title: title,
      author: author,
      filePath: filePath ?? '$testDirectoryPath/books/${title.toLowerCase().replaceAll(' ', '_')}.epub',
      coverPath: coverPath == null ? const drift.Value.absent() : drift.Value(coverPath),
      addedDate: drift.Value(DateTime.now()),
    );

    return await database.into(database.books).insert(companion);
  }

  /// Add a test bookmark directly to the database
  static Future<int> addTestBookmark({
    required int bookId,
    required String cfiLocation,
    String? chapterName,
    String? note,
  }) async {
    final companion = BookmarksCompanion.insert(
      bookId: bookId,
      cfiLocation: cfiLocation,
      chapterName: chapterName ?? '',
      pageNumber: 0,  // Add required pageNumber parameter
      note: note == null ? const drift.Value.absent() : drift.Value(note),
      createdAt: drift.Value(DateTime.now()),
    );

    return await database.into(database.bookmarks).insert(companion);
  }

  /// Add a test highlight directly to the database
  static Future<int> addTestHighlight({
    required int bookId,
    required String cfiRange,
    required String selectedText,
    String color = '#FFFF00',
    String? note,
  }) async {
    final companion = HighlightsCompanion.insert(
      bookId: bookId,
      cfiRange: cfiRange,
      selectedText: selectedText,
      color: drift.Value(color),
      note: note == null ? const drift.Value.absent() : drift.Value(note),
      createdAt: drift.Value(DateTime.now()),
    );

    return await database.into(database.highlights).insert(companion);
  }

  /// Get the path where EPUB files would be stored
  static String getEpubPath(String fileName) {
    return '$testDirectoryPath/books/$fileName';
  }

  /// Get minimal EPUB file bytes (simplified for testing)
  static Uint8List getMinimalEpubBytes() {
    // This would normally be a proper EPUB file
    // For integration tests, you might want to include a real test EPUB
    return Uint8List.fromList([
      // ZIP file header and minimal EPUB structure
      // This is a placeholder - in production tests, use a real EPUB file
      0x50, 0x4B, 0x03, 0x04, // ZIP header
      // ... rest of EPUB file bytes
    ]);
  }

  /// Wait for all async operations to complete
  static Future<void> waitForAsync() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Import an actual EPUB file using the ImportEpub use case
  /// Returns the imported book or null if import failed
  static Future<int?> importEpubFile(String epubFileName) async {
    try {
      // Get the import use case from GetIt
      final importEpub = getIt<ImportEpub>();

      // Get path to test EPUB file
      final currentDir = Directory.current.path;
      final epubPath = '$currentDir/test_epubs/$epubFileName';

      // Check if file exists
      final file = File(epubPath);
      if (!await file.exists()) {
        print('EPUB file not found: $epubPath');
        return null;
      }

      print('Importing EPUB: $epubPath');

      // Call the import use case
      final result = await importEpub(epubPath);

      return result.fold(
        (failure) {
          print('Import failed: ${failure.message}');
          return null;
        },
        (book) {
          print('Import successful: ${book.title} by ${book.author}');
          return book.id;
        },
      );
    } catch (e) {
      print('Error importing EPUB: $e');
      return null;
    }
  }
}