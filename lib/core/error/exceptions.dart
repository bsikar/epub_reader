/// Base class for all exceptions in the application
/// Exceptions are thrown at the data layer and converted to Failures at the repository layer
class AppException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  AppException(this.message, [this.stackTrace]);

  @override
  String toString() => 'AppException: $message';
}

/// Exception when storage operations fail
class StorageException extends AppException {
  StorageException(super.message, [super.stackTrace]);
}

/// Exception when EPUB parsing fails
class ParsingException extends AppException {
  ParsingException(super.message, [super.stackTrace]);
}

/// Exception when database operations fail
class DatabaseException extends AppException {
  DatabaseException(super.message, [super.stackTrace]);
}

/// Exception when validation fails
class ValidationException extends AppException {
  ValidationException(super.message, [super.stackTrace]);
}

/// Exception when file operations fail
class FileException extends AppException {
  FileException(super.message, [super.stackTrace]);
}

/// Exception when dictionary operations fail
class DictionaryException extends AppException {
  DictionaryException(super.message, [super.stackTrace]);
}

/// Exception when cache operations fail
class CacheException extends AppException {
  CacheException(super.message, [super.stackTrace]);
}
