import 'dart:io';
import 'package:epub_reader/core/services/storage_path_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StoragePathService', () {
    late StoragePathService service;

    setUp(() {
      service = StoragePathService();
    });

    test('should be a singleton', () {
      final service1 = StoragePathService();
      final service2 = StoragePathService();

      expect(identical(service1, service2), true);
    });

    test('should initialize directories on first access', () async {
      // Act
      final booksDir = await service.getBooksDirectory();

      // Assert
      expect(booksDir, isA<Directory>());
      expect(booksDir.path, contains('books'));
    });

    test('should return books directory path', () async {
      // Act
      final booksDir = await service.getBooksDirectory();

      // Assert
      expect(booksDir.path, endsWith('books'));
    });

    test('should return covers directory path', () async {
      // Act
      final coversDir = await service.getCoversDirectory();

      // Assert
      expect(coversDir.path, endsWith('covers'));
    });

    test('should return full book path', () async {
      // Act
      final bookPath = await service.getBookPath('test.epub');

      // Assert
      expect(bookPath, contains('books'));
      expect(bookPath, endsWith('test.epub'));
    });

    test('should return full cover path', () async {
      // Act
      final coverPath = await service.getCoverPath('cover.jpg');

      // Assert
      expect(coverPath, contains('covers'));
      expect(coverPath, endsWith('cover.jpg'));
    });

    test('should return app directory', () async {
      // Act
      final appDir = await service.getAppDirectory();

      // Assert
      expect(appDir, isA<Directory>());
      expect(appDir.path, isNotEmpty);
    });

    test('should cache directories after initialization', () async {
      // Act
      final booksDir1 = await service.getBooksDirectory();
      final booksDir2 = await service.getBooksDirectory();

      // Assert - Same instance returned
      expect(booksDir1.path, booksDir2.path);
    });

    test('should handle multiple concurrent initializations', () async {
      // Act - Call multiple methods concurrently
      final results = await Future.wait([
        service.getBooksDirectory(),
        service.getCoversDirectory(),
        service.getAppDirectory(),
      ]);

      // Assert
      expect(results.length, 3);
      expect(results[0], isA<Directory>());
      expect(results[1], isA<Directory>());
      expect(results[2], isA<Directory>());
    });

    test('should construct valid file paths', () async {
      // Act
      final bookPath = await service.getBookPath('my book.epub');
      final coverPath = await service.getCoverPath('my cover.jpg');

      // Assert
      expect(path.isAbsolute(bookPath), true);
      expect(path.isAbsolute(coverPath), true);
      expect(path.basename(bookPath), 'my book.epub');
      expect(path.basename(coverPath), 'my cover.jpg');
    });

    group('Directory Creation', () {
      test('should create books directory if it does not exist', () async {
        // Act
        final booksDir = await service.getBooksDirectory();

        // Assert - Directory should exist or be created
        expect(booksDir, isA<Directory>());
      });

      test('should create covers directory if it does not exist', () async {
        // Act
        final coversDir = await service.getCoversDirectory();

        // Assert - Directory should exist or be created
        expect(coversDir, isA<Directory>());
      });
    });
  });
}
