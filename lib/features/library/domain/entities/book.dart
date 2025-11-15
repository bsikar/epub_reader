import 'package:equatable/equatable.dart';

class Book extends Equatable {
  final int? id;
  final String title;
  final String author;
  final String filePath;
  final String? coverPath;
  final String? publisher;
  final String? language;
  final String? isbn;
  final String? description;
  final DateTime addedDate;
  final DateTime? lastOpened;
  final double readingProgress;
  final int currentPage;
  final int totalPages;
  final String? currentCfi;

  const Book({
    this.id,
    required this.title,
    required this.author,
    required this.filePath,
    this.coverPath,
    this.publisher,
    this.language,
    this.isbn,
    this.description,
    required this.addedDate,
    this.lastOpened,
    this.readingProgress = 0.0,
    this.currentPage = 0,
    this.totalPages = 0,
    this.currentCfi,
  });

  Book copyWith({
    int? id,
    String? title,
    String? author,
    String? filePath,
    String? coverPath,
    String? publisher,
    String? language,
    String? isbn,
    String? description,
    DateTime? addedDate,
    DateTime? lastOpened,
    double? readingProgress,
    int? currentPage,
    int? totalPages,
    String? currentCfi,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      coverPath: coverPath ?? this.coverPath,
      publisher: publisher ?? this.publisher,
      language: language ?? this.language,
      isbn: isbn ?? this.isbn,
      description: description ?? this.description,
      addedDate: addedDate ?? this.addedDate,
      lastOpened: lastOpened ?? this.lastOpened,
      readingProgress: readingProgress ?? this.readingProgress,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      currentCfi: currentCfi ?? this.currentCfi,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        filePath,
        coverPath,
        publisher,
        language,
        isbn,
        description,
        addedDate,
        lastOpened,
        readingProgress,
        currentPage,
        totalPages,
        currentCfi,
      ];
}
