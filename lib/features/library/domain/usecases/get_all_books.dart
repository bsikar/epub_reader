import 'package:epub_reader/core/utils/typedefs.dart';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/domain/repositories/library_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetAllBooks {
  final LibraryRepository _repository;

  GetAllBooks(this._repository);

  FutureResult<List<Book>> call() {
    return _repository.getAllBooks();
  }
}
