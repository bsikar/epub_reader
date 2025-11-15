import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// Books Table
class Books extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get author => text()();
  TextColumn get filePath => text()();
  TextColumn get coverPath => text().nullable()();
  TextColumn get publisher => text().nullable()();
  TextColumn get language => text().nullable()();
  TextColumn get isbn => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get addedDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastOpened => dateTime().nullable()();
  RealColumn get readingProgress => real().withDefault(const Constant(0.0))();
  IntColumn get currentPage => integer().withDefault(const Constant(0))();
  IntColumn get totalPages => integer().withDefault(const Constant(0))();
  TextColumn get currentCfi => text().nullable()();
}

// Bookmarks Table
class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get cfiLocation => text()();
  TextColumn get chapterName => text()();
  IntColumn get pageNumber => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Highlights Table
class Highlights extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get cfiRange => text()();
  TextColumn get selectedText => text()();
  TextColumn get color => text().withDefault(const Constant('yellow'))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

// Annotations Table
class Annotations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get cfiLocation => text()();
  TextColumn get noteText => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

// Collections Table
class Collections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Book Collections (Many-to-Many)
class BookCollections extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer().references(Books, #id, onDelete: KeyAction.cascade)();
  IntColumn get collectionId => integer().references(Collections, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

// Reading Sessions Table (for statistics)
class ReadingSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer().references(Books, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get pagesRead => integer().withDefault(const Constant(0))();
  IntColumn get durationMinutes => integer().withDefault(const Constant(0))();
}

// Dictionary History Table
class DictionaryHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get word => text()();
  TextColumn get definition => text()();
  IntColumn get bookId => integer().nullable().references(Books, #id, onDelete: KeyAction.setNull)();
  TextColumn get cfiLocation => text().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

// Dictionary Favorites Table
class DictionaryFavorites extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get word => text().unique()();
  TextColumn get definition => text()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

// Settings Table (for user preferences)
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  Books,
  Bookmarks,
  Highlights,
  Annotations,
  Collections,
  BookCollections,
  ReadingSessions,
  DictionaryHistory,
  DictionaryFavorites,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();

          // Create indexes for better query performance
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_books_title ON books(title)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_books_author ON books(author)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_books_last_opened ON books(last_opened)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_bookmarks_book_id ON bookmarks(book_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_highlights_book_id ON highlights(book_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_dictionary_history_word ON dictionary_history(word)',
          );
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Future migrations will go here
        },
      );

  // Books queries
  Future<List<Book>> getAllBooks() => select(books).get();

  Future<Book?> getBookById(int id) =>
      (select(books)..where((b) => b.id.equals(id))).getSingleOrNull();

  Future<List<Book>> getRecentBooks(int limit) => (select(books)
        ..orderBy([(b) => OrderingTerm.desc(b.lastOpened)])
        ..limit(limit))
      .get();

  Future<int> insertBook(BooksCompanion book) => into(books).insert(book);

  Future<bool> updateBook(Book book) => update(books).replace(book);

  Future<int> deleteBook(int id) =>
      (delete(books)..where((b) => b.id.equals(id))).go();

  // Bookmarks queries
  Future<List<Bookmark>> getBookmarksByBookId(int bookId) =>
      (select(bookmarks)..where((b) => b.bookId.equals(bookId))).get();

  Future<int> insertBookmark(BookmarksCompanion bookmark) =>
      into(bookmarks).insert(bookmark);

  Future<int> deleteBookmark(int id) =>
      (delete(bookmarks)..where((b) => b.id.equals(id))).go();

  // Highlights queries
  Future<List<Highlight>> getHighlightsByBookId(int bookId) =>
      (select(highlights)..where((h) => h.bookId.equals(bookId))).get();

  Future<int> insertHighlight(HighlightsCompanion highlight) =>
      into(highlights).insert(highlight);

  Future<bool> updateHighlight(Highlight highlight) =>
      update(highlights).replace(highlight);

  Future<int> deleteHighlight(int id) =>
      (delete(highlights)..where((h) => h.id.equals(id))).go();

  // Settings queries
  Future<String?> getSetting(String key) async {
    final result = await (select(settings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(key: key, value: value),
    );
  }

  // Dictionary History queries
  Future<List<DictionaryHistoryData>> getRecentDictionaryHistory(int limit) =>
      (select(dictionaryHistory)
            ..orderBy([(h) => OrderingTerm.desc(h.timestamp)])
            ..limit(limit))
          .get();

  Future<int> insertDictionaryHistory(
          DictionaryHistoryCompanion history) =>
      into(dictionaryHistory).insert(history);

  // Dictionary Favorites queries
  Future<List<DictionaryFavorite>> getAllDictionaryFavorites() =>
      select(dictionaryFavorites).get();

  Future<int> insertDictionaryFavorite(
          DictionaryFavoritesCompanion favorite) =>
      into(dictionaryFavorites).insert(favorite);

  Future<int> deleteDictionaryFavorite(int id) =>
      (delete(dictionaryFavorites)..where((f) => f.id.equals(id))).go();

  // Collections queries
  Future<List<Collection>> getAllCollections() => select(collections).get();

  Future<int> insertCollection(CollectionsCompanion collection) =>
      into(collections).insert(collection);

  Future<int> deleteCollection(int id) =>
      (delete(collections)..where((c) => c.id.equals(id))).go();
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'epub_reader_db');
}
