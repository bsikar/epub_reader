import 'package:epub_reader/features/library/domain/entities/book.dart';
import 'package:epub_reader/features/library/domain/usecases/delete_book.dart';
import 'package:epub_reader/features/library/domain/usecases/get_all_books.dart';
import 'package:epub_reader/features/library/domain/usecases/get_recent_books.dart';
import 'package:epub_reader/injection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier(
    getIt<GetAllBooks>(),
    getIt<GetRecentBooks>(),
    getIt<DeleteBook>(),
  );
});

class LibraryState {
  final List<Book> books;
  final bool isLoading;
  final String? error;
  final LibraryViewMode viewMode;
  final bool isSelectionMode;
  final Set<int> selectedBookIds;

  LibraryState({
    this.books = const [],
    this.isLoading = false,
    this.error,
    this.viewMode = LibraryViewMode.grid,
    this.isSelectionMode = false,
    this.selectedBookIds = const {},
  });

  LibraryState copyWith({
    List<Book>? books,
    bool? isLoading,
    String? error,
    LibraryViewMode? viewMode,
    bool? isSelectionMode,
    Set<int>? selectedBookIds,
  }) {
    return LibraryState(
      books: books ?? this.books,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      viewMode: viewMode ?? this.viewMode,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedBookIds: selectedBookIds ?? this.selectedBookIds,
    );
  }
}

enum LibraryViewMode { grid, list }

class LibraryNotifier extends StateNotifier<LibraryState> {
  final GetAllBooks _getAllBooks;
  final GetRecentBooks _getRecentBooks;
  final DeleteBook _deleteBook;

  LibraryNotifier(
    this._getAllBooks,
    this._getRecentBooks,
    this._deleteBook,
  ) : super(LibraryState()) {
    loadBooks();
  }

  Future<void> loadBooks() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getAllBooks();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (books) => state = state.copyWith(
        isLoading: false,
        books: books,
        error: null,
      ),
    );
  }

  Future<void> deleteBook(Book book) async {
    print('Attempting to delete book: ${book.title} (ID: ${book.id})');
    final result = await _deleteBook(book);

    result.fold(
      (failure) {
        print('Delete failed: ${failure.message}');
        state = state.copyWith(error: failure.message);
      },
      (_) {
        print('Delete successful, updating state');
        final updatedBooks = state.books.where((b) => b.id != book.id).toList();
        state = state.copyWith(books: updatedBooks, error: null);
      },
    );
  }

  Future<void> deleteSelectedBooks() async {
    print('Deleting ${state.selectedBookIds.length} books');
    final booksToDelete = state.books
        .where((book) => state.selectedBookIds.contains(book.id))
        .toList();

    print('Books to delete: ${booksToDelete.map((b) => b.title).join(", ")}');

    for (final book in booksToDelete) {
      await deleteBook(book);
    }

    // Exit selection mode after deletion
    state = state.copyWith(
      isSelectionMode: false,
      selectedBookIds: {},
    );
  }

  void toggleSelectionMode() {
    print('Toggling selection mode. Current: ${state.isSelectionMode}');
    state = state.copyWith(
      isSelectionMode: !state.isSelectionMode,
      selectedBookIds: {}, // Clear selection when toggling
    );
    print('Selection mode now: ${state.isSelectionMode}');
  }

  void toggleBookSelection(int bookId) {
    print('Toggling book selection for ID: $bookId');
    final newSelection = Set<int>.from(state.selectedBookIds);
    if (newSelection.contains(bookId)) {
      newSelection.remove(bookId);
      print('Removed book $bookId from selection');
    } else {
      newSelection.add(bookId);
      print('Added book $bookId to selection');
    }
    state = state.copyWith(selectedBookIds: newSelection);
    print('Selected books: ${newSelection.length} (${newSelection.join(", ")})');
  }

  void selectAll() {
    final allIds = state.books.map((b) => b.id!).toSet();
    state = state.copyWith(selectedBookIds: allIds);
  }

  void deselectAll() {
    state = state.copyWith(selectedBookIds: {});
  }

  void toggleViewMode() {
    state = state.copyWith(
      viewMode: state.viewMode == LibraryViewMode.grid
          ? LibraryViewMode.list
          : LibraryViewMode.grid,
    );
  }
}
