import 'package:epub_reader/core/utils/typedefs.dart';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/domain/repositories/library_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class UpdateBook {
  final LibraryRepository _repository;

  UpdateBook(this._repository);

  FutureResult<void> call(Book book) async {
    return await _repository.updateBook(book);
  }
}
