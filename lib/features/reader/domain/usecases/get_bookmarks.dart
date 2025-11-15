import 'package:drift/drift.dart';
import 'package:epub_reader/core/database/app_database.dart' as db;
import 'package:epub_reader/core/error/exceptions.dart';
import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/core/utils/typedefs.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetBookmarks {
  final db.AppDatabase _database;

  GetBookmarks(this._database);

  FutureResult<List<db.Bookmark>> call(int bookId) async {
    try {
      final bookmarks = await (_database.select(_database.bookmarks)
            ..where((tbl) => tbl.bookId.equals(bookId))
            ..orderBy([
              (t) => OrderingTerm(
                    expression: t.createdAt,
                    mode: OrderingMode.desc,
                  ),
            ]))
          .get();

      return Right(bookmarks);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
