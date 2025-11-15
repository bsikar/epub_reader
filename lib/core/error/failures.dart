import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
/// Failures represent errors that have been handled and are safe to show to users
abstract class Failure extends Equatable {
  final String message;
  final StackTrace? stackTrace;

  const Failure(this.message, [this.stackTrace]);

  @override
  List<Object?> get props => [message, stackTrace];
}

/// Failure when storage operations fail (disk full, permissions, etc.)
class StorageFailure extends Failure {
  const StorageFailure(super.message, [super.stackTrace]);
}

/// Failure when EPUB parsing fails (corrupted file, unsupported format, etc.)
class ParsingFailure extends Failure {
  const ParsingFailure(super.message, [super.stackTrace]);
}

/// Failure when database operations fail
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, [super.stackTrace]);
}

/// Failure when input validation fails
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.stackTrace]);
}

/// Failure when file operations fail
class FileFailure extends Failure {
  const FileFailure(super.message, [super.stackTrace]);
}

/// Failure when dictionary operations fail
class DictionaryFailure extends Failure {
  const DictionaryFailure(super.message, [super.stackTrace]);
}

/// Unexpected/unknown failure
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, [super.stackTrace]);
}
