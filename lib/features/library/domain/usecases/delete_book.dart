import 'dart:io';
import 'package:epub_reader/core/error/failures.dart';
import 'package:epub_reader/core/utils/typedefs.dart';
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/domain/repositories/library_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeleteBook {
  final LibraryRepository _repository;

  DeleteBook(this._repository);

  FutureResult<void> call(Book book) async {
    try {
      print('DeleteBook use case: Deleting book ID ${book.id}');

      if (book.id == null) {
        print('DeleteBook: Book ID is null!');
        return Left(UnknownFailure('Book ID is null'));
      }

      // Delete book from database
      print('DeleteBook: Calling repository.deleteBook(${book.id})');
      final result = await _repository.deleteBook(book.id!);

      return result.fold(
        (failure) {
          print('DeleteBook: Database delete failed - ${failure.message}');
          return Left(failure);
        },
        (_) async {
          print('DeleteBook: Database delete successful, deleting files');
          // Delete associated files
          await _deleteBookFiles(book);
          print('DeleteBook: Files deleted, operation complete');
          return const Right(null);
        },
      );
    } catch (e) {
      print('DeleteBook: Exception caught - $e');
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<void> _deleteBookFiles(Book book) async {
    try {
      print('DeleteBook: Deleting files for ${book.title}');

      // Delete EPUB file
      final epubFile = File(book.filePath);
      print('DeleteBook: EPUB file path: ${book.filePath}');
      if (await epubFile.exists()) {
        print('DeleteBook: EPUB file exists, deleting...');
        await epubFile.delete();
        print('DeleteBook: EPUB file deleted');
      } else {
        print('DeleteBook: EPUB file does not exist');
      }

      // Delete cover image if exists
      if (book.coverPath != null) {
        final coverFile = File(book.coverPath!);
        print('DeleteBook: Cover file path: ${book.coverPath}');
        if (await coverFile.exists()) {
          print('DeleteBook: Cover file exists, deleting...');
          await coverFile.delete();
          print('DeleteBook: Cover file deleted');
        } else {
          print('DeleteBook: Cover file does not exist');
        }
      } else {
        print('DeleteBook: No cover path to delete');
      }
    } catch (e) {
      // Log but don't fail the operation if file deletion fails
      print('DeleteBook: Error deleting book files: $e');
    }
  }
}
