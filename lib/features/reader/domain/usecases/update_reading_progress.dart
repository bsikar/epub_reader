import 'package:epub_reader/core/utils/typedefs.dart';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/domain/repositories/library_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class UpdateReadingProgress {
  final LibraryRepository _repository;

  UpdateReadingProgress(this._repository);

  FutureResult<void> call({
    required Book book,
    required String cfi,
    double? progress,
  }) async {
    final updatedBook = book.copyWith(
      currentCfi: cfi,
      lastOpened: DateTime.now(),
      readingProgress: progress ?? book.readingProgress,
    );

    return await _repository.updateBook(updatedBook);
  }
}
