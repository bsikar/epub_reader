import 'package:drift/drift.dart';
import 'package:epub_reader/core/database/app_database.dart' as db;
import 'package:epub_reader/core/error/exceptions.dart';
import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/core/utils/typedefs.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class AddHighlight {
  final db.AppDatabase _database;

  AddHighlight(this._database);

  FutureResult<int> call({
    required int bookId,
    required String cfiRange,
    required String selectedText,
    String? color,
    String? note,
  }) async {
    try {
      final highlight = db.HighlightsCompanion.insert(
        bookId: bookId,
        cfiRange: cfiRange,
        selectedText: selectedText,
        color: color != null ? Value(color) : const Value.absent(),
        note: note != null ? Value(note) : const Value.absent(),
      );

      final id = await _database.into(_database.highlights).insert(highlight);
      return Right(id);
      // coverage:ignore-start
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
      // coverage:ignore-end
    }
  }
}
