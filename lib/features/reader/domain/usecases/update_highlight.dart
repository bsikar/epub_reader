import 'package:drift/drift.dart';
import 'package:epub_reader/core/database/app_database.dart' as db;
import 'package:epub_reader/core/error/exceptions.dart';
import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/core/utils/typedefs.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class UpdateHighlight {
  final db.AppDatabase _database;

  UpdateHighlight(this._database);

  FutureResult<void> call({
    required int highlightId,
    String? color,
    String? note,
  }) async {
    try {
      // First, get the existing highlight
      final highlight = await (_database.select(_database.highlights)
            ..where((tbl) => tbl.id.equals(highlightId)))
          .getSingleOrNull();

      if (highlight == null) {
        return const Left(DatabaseFailure('Highlight not found'));
      }

      // Update the highlight
      final updatedHighlight = highlight.copyWith(
        color: color ?? highlight.color,
        note: Value(note),
        updatedAt: Value(DateTime.now()),
      );

      await _database.update(_database.highlights).replace(updatedHighlight);
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
