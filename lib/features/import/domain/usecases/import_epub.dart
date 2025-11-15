import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/core/services/storage_path_service.dart';
import 'package:epub_reader/core/utils/typedefs.dart';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/domain/repositories/library_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

@injectable
class ImportEpub {
  final LibraryRepository _repository;
  final StoragePathService _storagePathService;

  ImportEpub(this._repository, this._storagePathService);

  FutureResult<Book> call(String filePath) async {
    try {
      // Read EPUB file
      final epubFile = File(filePath);
      if (!await epubFile.exists()) {
        return Left(FileFailure('EPUB file not found'));
      }

      // Copy EPUB to app directory
      final fileName = path.basename(filePath);
      final newPath = await _storagePathService.getBookPath(fileName);
      await epubFile.copy(newPath);

      // Extract metadata
      final metadata = await _extractMetadata(newPath);

      // Extract cover
      String? coverPath;
      try {
        coverPath = await _extractCover(newPath, metadata['coverImage']);
      } catch (e) {
        // Cover extraction failed, continue without it
      }

      // Create book entity
      final book = Book(
        title: metadata['title'] ?? 'Unknown Title',
        author: metadata['author'] ?? 'Unknown Author',
        filePath: newPath,
        coverPath: coverPath,
        publisher: metadata['publisher'],
        language: metadata['language'],
        description: metadata['description'],
        addedDate: DateTime.now(),
      );

      // Add to database
      final result = await _repository.addBook(book);

      return result.map((id) => book.copyWith(id: id));
    } catch (e) {
      return Left(ParsingFailure('Failed to import EPUB: $e'));
    }
  }

  Future<Map<String, String?>> _extractMetadata(String epubPath) async {
    try {
      final bytes = await File(epubPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find content.opf
      ArchiveFile? opfFile;
      for (final file in archive.files) {
        if (file.name.endsWith('.opf') || file.name.contains('content.opf')) {
          opfFile = file;
          break;
        }
      }

      if (opfFile == null) {
        return {
          'title': null,
          'author': null,
          'publisher': null,
          'language': null,
          'description': null,
          'coverImage': null,
        };
      }

      final opfContent = String.fromCharCodes(opfFile.content as List<int>);
      final document = XmlDocument.parse(opfContent);

      String? title;
      String? author;
      String? publisher;
      String? language;
      String? description;
      String? coverImage;

      // Parse metadata
      final metadata = document.findAllElements('metadata').firstOrNull;
      if (metadata != null) {
        title = metadata.findElements('dc:title').firstOrNull?.innerText;
        author = metadata.findElements('dc:creator').firstOrNull?.innerText;
        publisher = metadata.findElements('dc:publisher').firstOrNull?.innerText;
        language = metadata.findElements('dc:language').firstOrNull?.innerText;
        description = metadata.findElements('dc:description').firstOrNull?.innerText;

        // Try to find cover image
        final metaElements = metadata.findAllElements('meta');
        for (final meta in metaElements) {
          if (meta.getAttribute('name') == 'cover') {
            coverImage = meta.getAttribute('content');
            break;
          }
        }
      }

      return {
        'title': title,
        'author': author,
        'publisher': publisher,
        'language': language,
        'description': description,
        'coverImage': coverImage,
      };
    } catch (e) {
      return {
        'title': null,
        'author': null,
        'publisher': null,
        'language': null,
        'description': null,
        'coverImage': null,
      };
    }
  }

  Future<String?> _extractCover(String epubPath, String? coverId) async {
    try {
      final bytes = await File(epubPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find cover image
      ArchiveFile? coverFile;
      if (coverId != null) {
        for (final file in archive.files) {
          if (file.name.contains(coverId) &&
              (file.name.endsWith('.jpg') ||
               file.name.endsWith('.jpeg') ||
               file.name.endsWith('.png'))) {
            coverFile = file;
            break;
          }
        }
      }

      // If not found by ID, look for common cover names
      if (coverFile == null) {
        for (final file in archive.files) {
          final lowerName = file.name.toLowerCase();
          if ((lowerName.contains('cover') || lowerName.contains('thumbnail')) &&
              (lowerName.endsWith('.jpg') ||
               lowerName.endsWith('.jpeg') ||
               lowerName.endsWith('.png'))) {
            coverFile = file;
            break;
          }
        }
      }

      if (coverFile == null) {
        return null;
      }

      // Save cover image
      final ext = path.extension(coverFile.name);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final coverPath = await _storagePathService.getCoverPath(fileName);

      final coverImageFile = File(coverPath);
      await coverImageFile.writeAsBytes(coverFile.content as List<int>);

      return coverPath;
    } catch (e) {
      return null;
    }
  }
}
