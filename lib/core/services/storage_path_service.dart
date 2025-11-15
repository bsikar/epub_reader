import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Service that provides consistent storage paths for the application.
/// Uses ApplicationSupportDirectory which is the recommended location for app data:
/// - Windows: C:\Users\{username}\AppData\Roaming\epub_reader\
/// - macOS: ~/Library/Application Support/epub_reader/
/// - Linux: ~/.local/share/epub_reader/
@singleton
class StoragePathService {
  Directory? _appSupportDir;
  Directory? _booksDir;
  Directory? _coversDir;

  /// Initializes the storage directories
  Future<void> initialize() async {
    _appSupportDir = await getApplicationSupportDirectory();
    _booksDir = Directory(path.join(_appSupportDir!.path, 'books'));
    _coversDir = Directory(path.join(_appSupportDir!.path, 'covers'));

    // Create directories if they don't exist
    await _booksDir!.create(recursive: true);
    await _coversDir!.create(recursive: true);
  }

  /// Returns the directory where EPUB files are stored
  Future<Directory> getBooksDirectory() async {
    if (_booksDir == null) {
      await initialize();
    }
    return _booksDir!;
  }

  /// Returns the directory where cover images are stored
  Future<Directory> getCoversDirectory() async {
    if (_coversDir == null) {
      await initialize();
    }
    return _coversDir!;
  }

  /// Returns the full path for a book file
  Future<String> getBookPath(String fileName) async {
    final dir = await getBooksDirectory();
    return path.join(dir.path, fileName);
  }

  /// Returns the full path for a cover file
  Future<String> getCoverPath(String fileName) async {
    final dir = await getCoversDirectory();
    return path.join(dir.path, fileName);
  }

  /// Returns the application support directory
  Future<Directory> getAppDirectory() async {
    if (_appSupportDir == null) {
      await initialize();
    }
    return _appSupportDir!;
  }
}
