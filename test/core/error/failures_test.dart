import 'package:epub_reader/core/error/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failures', () {
    const testMessage = 'Test error message';
    final testStackTrace = StackTrace.current;

    group('StorageFailure', () {
      test('should create StorageFailure with message', () {
        const failure = StorageFailure(testMessage);

        expect(failure.message, testMessage);
        expect(failure.stackTrace, null);
      });

      test('should create StorageFailure with message and stack trace', () {
        final failure = StorageFailure(testMessage, testStackTrace);

        expect(failure.message, testMessage);
        expect(failure.stackTrace, testStackTrace);
      });

      test('should support equality', () {
        const failure1 = StorageFailure('Same message');
        const failure2 = StorageFailure('Same message');

        expect(failure1, equals(failure2));
      });
    });

    group('ParsingFailure', () {
      test('should create ParsingFailure with message', () {
        const failure = ParsingFailure(testMessage);

        expect(failure.message, testMessage);
        expect(failure.stackTrace, null);
      });

      test('should be a Failure', () {
        const failure = ParsingFailure(testMessage);

        expect(failure, isA<Failure>());
      });
    });

    group('DatabaseFailure', () {
      test('should create DatabaseFailure with message', () {
        const failure = DatabaseFailure(testMessage);

        expect(failure.message, testMessage);
        expect(failure.stackTrace, null);
      });

      test('should support stack trace', () {
        final failure = DatabaseFailure(testMessage, testStackTrace);

        expect(failure.message, testMessage);
        expect(failure.stackTrace, testStackTrace);
      });
    });

    group('ValidationFailure', () {
      test('should create ValidationFailure with message', () {
        const failure = ValidationFailure(testMessage);

        expect(failure.message, testMessage);
      });

      test('should be a Failure', () {
        const failure = ValidationFailure(testMessage);

        expect(failure, isA<Failure>());
      });
    });

    group('FileFailure', () {
      test('should create FileFailure with message', () {
        const failure = FileFailure(testMessage);

        expect(failure.message, testMessage);
      });

      test('should support stack trace', () {
        final failure = FileFailure(testMessage, testStackTrace);

        expect(failure.stackTrace, testStackTrace);
      });
    });

    group('DictionaryFailure', () {
      test('should create DictionaryFailure with message', () {
        const failure = DictionaryFailure(testMessage);

        expect(failure.message, testMessage);
      });
    });

    group('UnknownFailure', () {
      test('should create UnknownFailure with message', () {
        const failure = UnknownFailure(testMessage);

        expect(failure.message, testMessage);
      });

      test('should support stack trace', () {
        final failure = UnknownFailure(testMessage, testStackTrace);

        expect(failure.message, testMessage);
        expect(failure.stackTrace, testStackTrace);
      });
    });

    group('Failure Equality', () {
      test('should be equal when messages are the same', () {
        const failure1 = StorageFailure('Same message');
        const failure2 = StorageFailure('Same message');

        expect(failure1, equals(failure2));
      });

      test('should not be equal when messages differ', () {
        const failure1 = StorageFailure('Message 1');
        const failure2 = StorageFailure('Message 2');

        expect(failure1, isNot(equals(failure2)));
      });

      test('should not be equal when types differ', () {
        const failure1 = StorageFailure(testMessage);
        const failure2 = ParsingFailure(testMessage);

        expect(failure1, isNot(equals(failure2)));
      });

      test('should have consistent hashCode', () {
        const failure1 = DatabaseFailure('Test');
        const failure2 = DatabaseFailure('Test');

        expect(failure1.hashCode, equals(failure2.hashCode));
      });
    });

    group('Props', () {
      test('should include message in props', () {
        const failure = StorageFailure('Test message');

        expect(failure.props, contains('Test message'));
      });

      test('should include stack trace in props when present', () {
        final failure = StorageFailure('Test', testStackTrace);

        expect(failure.props, contains(testStackTrace));
      });

      test('should include null stack trace in props when absent', () {
        const failure = StorageFailure('Test');

        expect(failure.props, contains(null));
      });
    });
  });
}
