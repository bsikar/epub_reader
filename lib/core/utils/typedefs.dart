import 'package:fpdart/fpdart.dart';
import 'package:epub_reader/core/error/failures.dart';

/// Type alias for Either type used throughout the application
/// Left = Failure, Right = Success
typedef Result<T> = Either<Failure, T>;

/// Type alias for Future<Either<Failure, T>>
typedef FutureResult<T> = Future<Either<Failure, T>>;
