import 'package:epub_reader/core/utils/typedefs.dart';
import 'package:epub_reader/features/library/domain/entities/book.dart';

abstract class LibraryRepository {
  FutureResult<List<Book>> getAllBooks();
  FutureResult<Book> getBookById(int id);
  FutureResult<List<Book>> getRecentBooks({int limit = 10});
  FutureResult<int> addBook(Book book);
  FutureResult<void> updateBook(Book book);
  FutureResult<void> deleteBook(int id);
  FutureResult<List<Book>> searchBooks(String query);
}
