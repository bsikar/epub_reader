import 'package:drift/drift.dart';
import 'package:epub_reader/core/database/app_database.dart' as db;
import 'package:epub_reader/core/error/exceptions.dart';
import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/core/utils/typedefs.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetHighlights {
  final db.AppDatabase _database;

  GetHighlights(this._database);

  FutureResult<List<db.Highlight>> call(int bookId) async {
    try {
      final highlights = await (_database.select(_database.highlights)
            ..where((tbl) => tbl.bookId.equals(bookId))
            ..orderBy([
              (t) => OrderingTerm(
                    expression: t.createdAt,
                    mode: OrderingMode.desc,
                  ),
            ]))
          .get();

      return Right(highlights);
      // coverage:ignore-start
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
      // coverage:ignore-end
    }
  }
}
