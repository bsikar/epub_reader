import 'package:epub_reader/features/reader/domain/usecases/add_bookmark.dart';
import 'package:epub_reader/features/reader/domain/usecases/delete_bookmark.dart';
import 'package:epub_reader/features/reader/domain/usecases/get_bookmarks.dart';
import 'package:epub_reader/features/reader/domain/usecases/update_reading_progress.dart';
import 'package:epub_reader/injection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final updateReadingProgressProvider = Provider<UpdateReadingProgress>((ref) {
  return getIt<UpdateReadingProgress>();
});

final addBookmarkProvider = Provider<AddBookmark>((ref) {
  return getIt<AddBookmark>();
});

final getBookmarksProvider = Provider<GetBookmarks>((ref) {
  return getIt<GetBookmarks>();
});

final deleteBookmarkProvider = Provider<DeleteBookmark>((ref) {
  return getIt<DeleteBookmark>();
});
