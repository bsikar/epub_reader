import 'package:epub_reader/core/utils/typedefs.dart';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/domain/repositories/library_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetRecentBooks {
  final LibraryRepository _repository;

  GetRecentBooks(this._repository);

  FutureResult<List<Book>> call({int limit = 10}) {
    return _repository.getRecentBooks(limit: limit);
  }
}
