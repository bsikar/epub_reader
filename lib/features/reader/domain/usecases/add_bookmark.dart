import 'package:drift/drift.dart';
import 'package:epub_reader/core/database/app_database.dart' as db;
import 'package:epub_reader/core/error/exceptions.dart';
import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/core/utils/typedefs.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class AddBookmark {
  final db.AppDatabase _database;

  AddBookmark(this._database);

  FutureResult<int> call({
    required int bookId,
    required String cfi,
    String? chapterTitle,
    String? note,
  }) async {
    try {
      final bookmark = db.BookmarksCompanion.insert(
        bookId: bookId,
        cfiLocation: cfi,
        chapterName: chapterTitle ?? '',
        pageNumber: 0,
        note: note != null ? Value(note) : const Value.absent(),
      );

      final id = await _database.into(_database.bookmarks).insert(bookmark);
      return Right(id);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
