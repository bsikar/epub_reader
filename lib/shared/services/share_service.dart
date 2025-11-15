import 'dart:io';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/core/utils/typedefs.dart';
import 'package:fpdart/fpdart.dart';

/// A service for sharing content from the app.
///
/// Provides methods to:
/// - Share text content (highlights, quotes)
/// - Share files (EPUB exports, PDFs)
/// - Copy text to clipboard
///
/// Usage:
/// ```dart
/// final shareService = getIt<ShareService>();
/// await shareService.shareText('Check out this quote from my book!');
/// await shareService.copyToClipboard('Highlighted text');
/// ```
@singleton
class ShareService {
  /// Share plain text content
  Future<Result<void>> shareText(String text, {String? subject}) async {
    try {
      // TODO: Implement actual sharing using share_plus package
      // For now, just copy to clipboard as fallback
      await Clipboard.setData(ClipboardData(text: text));
      return right(null);
    } catch (e, stackTrace) {
      return left(
        StorageFailure(
          'Failed to share text: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  /// Share a file
  Future<Result<void>> shareFile(
    File file, {
    String? subject,
    String? text,
  }) async {
    try {
      if (!await file.exists()) {
        return left(
          const StorageFailure('File does not exist'),
        );
      }

      // TODO: Implement actual file sharing using share_plus package
      // For now, return success
      return right(null);
    } catch (e, stackTrace) {
      return left(
        StorageFailure(
          'Failed to share file: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  /// Share multiple files
  Future<Result<void>> shareFiles(
    List<File> files, {
    String? subject,
    String? text,
  }) async {
    try {
      for (final file in files) {
        if (!await file.exists()) {
          return left(
            StorageFailure(
              'File does not exist: ${file.path}',
            ),
          );
        }
      }

      // TODO: Implement actual file sharing using share_plus package
      // For now, return success
      return right(null);
    } catch (e, stackTrace) {
      return left(
        StorageFailure(
          'Failed to share files: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  /// Copy text to clipboard
  Future<Result<void>> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return right(null);
    } catch (e, stackTrace) {
      return left(
        StorageFailure(
          'Failed to copy to clipboard: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  /// Get text from clipboard
  Future<Result<String>> getFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData == null || clipboardData.text == null) {
        return left(
          const StorageFailure('Clipboard is empty'),
        );
      }
      return right(clipboardData.text!);
    } catch (e, stackTrace) {
      return left(
        StorageFailure(
          'Failed to get clipboard data: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  /// Share a book highlight
  Future<Result<void>> shareHighlight({
    required String text,
    required String bookTitle,
    required String author,
  }) async {
    final formattedText = '''
"$text"

— $author, $bookTitle
''';
    return shareText(formattedText);
  }

  /// Share multiple highlights as formatted text
  Future<Result<void>> shareHighlights({
    required List<String> highlights,
    required String bookTitle,
    required String author,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('Highlights from "$bookTitle" by $author\n');

    for (var i = 0; i < highlights.length; i++) {
      buffer.writeln('${i + 1}. "${highlights[i]}"\n');
    }

    return shareText(buffer.toString());
  }
}
