import 'package:epub_reader/core/database/app_database.dart' as db;
import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:drift/drift.dart' as drift;

extension BookModelX on Book {
  db.BooksCompanion toCompanion() {
    return db.BooksCompanion(
      id: id != null ? drift.Value(id!) : const drift.Value.absent(),
      title: drift.Value(title),
      author: drift.Value(author),
      filePath: drift.Value(filePath),
      coverPath: drift.Value(coverPath),
      publisher: drift.Value(publisher),
      language: drift.Value(language),
      isbn: drift.Value(isbn),
      description: drift.Value(description),
      addedDate: drift.Value(addedDate),
      lastOpened: drift.Value(lastOpened),
      readingProgress: drift.Value(readingProgress),
      currentPage: drift.Value(currentPage),
      totalPages: drift.Value(totalPages),
      currentCfi: drift.Value(currentCfi),
    );
  }

  db.Book toDrift() {
    return db.Book(
      id: id!,
      title: title,
      author: author,
      filePath: filePath,
      coverPath: coverPath,
      publisher: publisher,
      language: language,
      isbn: isbn,
      description: description,
      addedDate: addedDate,
      lastOpened: lastOpened,
      readingProgress: readingProgress,
      currentPage: currentPage,
      totalPages: totalPages,
      currentCfi: currentCfi,
    );
  }
}

extension BookEntityX on db.Book {
  Book toEntity() {
    return Book(
      id: id,
      title: title,
      author: author,
      filePath: filePath,
      coverPath: coverPath,
      publisher: publisher,
      language: language,
      isbn: isbn,
      description: description,
      addedDate: addedDate,
      lastOpened: lastOpened,
      readingProgress: readingProgress,
      currentPage: currentPage,
      totalPages: totalPages,
      currentCfi: currentCfi,
    );
  }
}
