import 'package:epub_reader/features/reader/domain/usecases/add_bookmark.dart';
import 'package:epub_reader/features/reader/domain/usecases/add_highlight.dart';
import 'package:epub_reader/features/reader/domain/usecases/delete_bookmark.dart';
import 'package:epub_reader/features/reader/domain/usecases/delete_highlight.dart';
import 'package:epub_reader/features/reader/domain/usecases/get_bookmarks.dart';
import 'package:epub_reader/features/reader/domain/usecases/get_highlights.dart';
import 'package:epub_reader/features/reader/domain/usecases/update_highlight.dart';
import 'package:epub_reader/features/library/domain/usecases/update_book.dart';
import 'package:epub_reader/injection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final addBookmarkProvider = Provider<AddBookmark>((ref) {
  return getIt<AddBookmark>();
});

final getBookmarksProvider = Provider<GetBookmarks>((ref) {
  return getIt<GetBookmarks>();
});

final deleteBookmarkProvider = Provider<DeleteBookmark>((ref) {
  return getIt<DeleteBookmark>();
});

final addHighlightProvider = Provider<AddHighlight>((ref) {
  return getIt<AddHighlight>();
});

final getHighlightsProvider = Provider<GetHighlights>((ref) {
  return getIt<GetHighlights>();
});

final updateHighlightProvider = Provider<UpdateHighlight>((ref) {
  return getIt<UpdateHighlight>();
});

final deleteHighlightProvider = Provider<DeleteHighlight>((ref) {
  return getIt<DeleteHighlight>();
});

final updateBookProvider = Provider<UpdateBook>((ref) {
  return getIt<UpdateBook>();
});
