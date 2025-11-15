import 'package:epub_reader/core/database/app_database.dart';
import 'package:epub_reader/core/error/exceptions.dart';
import 'package:injectable/injectable.dart';

typedef BookData = Book;

@injectable
class LibraryLocalDataSource {
  final AppDatabase _database;

  LibraryLocalDataSource(this._database);

  Future<List<BookData>> getAllBooks() async {
    try {
      return await _database.getAllBooks();
    } catch (e) {
      throw DatabaseException('Failed to get all books: $e');
    }
  }

  Future<BookData?> getBookById(int id) async {
    try {
      return await _database.getBookById(id);
    } catch (e) {
      throw DatabaseException('Failed to get book by id: $e');
    }
  }

  Future<List<BookData>> getRecentBooks(int limit) async {
    try {
      return await _database.getRecentBooks(limit);
    } catch (e) {
      throw DatabaseException('Failed to get recent books: $e');
    }
  }

  Future<int> insertBook(BooksCompanion book) async {
    try {
      return await _database.insertBook(book);
    } catch (e) {
      throw DatabaseException('Failed to insert book: $e');
    }
  }

  Future<void> updateBook(BookData book) async {
    try {
      await _database.updateBook(book);
    } catch (e) {
      throw DatabaseException('Failed to update book: $e');
    }
  }

  Future<void> deleteBook(int id) async {
    try {
      await _database.deleteBook(id);
    } catch (e) {
      throw DatabaseException('Failed to delete book: $e');
    }
  }

  Future<List<BookData>> searchBooks(String query) async {
    try {
      final allBooks = await _database.getAllBooks();
      final lowerQuery = query.toLowerCase();
      return allBooks.where((book) {
        return book.title.toLowerCase().contains(lowerQuery) ||
            book.author.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      throw DatabaseException('Failed to search books: $e');
    }
  }
}
