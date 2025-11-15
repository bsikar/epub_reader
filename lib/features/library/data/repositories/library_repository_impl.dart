import 'package:epub_reader/core/error/exceptions.dart';
import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/core/utils/typedefs.dart';
import 'package:epub_reader/features/library/data/datasources/library_local_datasource.dart';
import 'package:epub_reader/features/library/data/models/book_model.dart';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/domain/repositories/library_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: LibraryRepository)
class LibraryRepositoryImpl implements LibraryRepository {
  final LibraryLocalDataSource _localDataSource;

  LibraryRepositoryImpl(this._localDataSource);

  @override
  FutureResult<List<Book>> getAllBooks() async {
    try {
      final books = await _localDataSource.getAllBooks();
      return Right(books.map((e) => e.toEntity()).toList());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  FutureResult<Book> getBookById(int id) async {
    try {
      final book = await _localDataSource.getBookById(id);
      if (book == null) {
        return Left(DatabaseFailure('Book not found'));
      }
      return Right(book.toEntity());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  FutureResult<List<Book>> getRecentBooks({int limit = 10}) async {
    try {
      final books = await _localDataSource.getRecentBooks(limit);
      return Right(books.map((e) => e.toEntity()).toList());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  FutureResult<int> addBook(Book book) async {
    try {
      final id = await _localDataSource.insertBook(book.toCompanion());
      return Right(id);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  FutureResult<void> updateBook(Book book) async {
    try {
      final bookData = book.toDrift();
      await _localDataSource.updateBook(bookData);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  FutureResult<void> deleteBook(int id) async {
    try {
      await _localDataSource.deleteBook(id);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  FutureResult<List<Book>> searchBooks(String query) async {
    try {
      final books = await _localDataSource.searchBooks(query);
      return Right(books.map((e) => e.toEntity()).toList());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
