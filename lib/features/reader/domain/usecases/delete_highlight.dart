import 'package:epub_reader/core/database/app_database.dart' as db;
import 'package:epub_reader/core/error/exceptions.dart';
import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/core/utils/typedefs.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeleteHighlight {
  final db.AppDatabase _database;

  DeleteHighlight(this._database);

  FutureResult<void> call(int highlightId) async {
    try {
      await (_database.delete(_database.highlights)
            ..where((tbl) => tbl.id.equals(highlightId)))
          .go();

      return const Right(null);
      // coverage:ignore-start
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
      // coverage:ignore-end
    }
  }
}
