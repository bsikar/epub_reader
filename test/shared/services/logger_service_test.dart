import 'package:flutter_test/flutter_test.dart';
import 'package:epub_reader/shared/services/services.dart';

void main() {
  group('LoggerService', () {
    late LoggerService loggerService;

    setUp(() {
      loggerService = LoggerService();
    });

    test('debug logs message in debug mode', () {
      // This test just verifies the method doesn't throw
      expect(
        () => loggerService.debug('Debug message'),
        returnsNormally,
      );
    });

    test('info logs message', () {
      expect(
        () => loggerService.info('Info message'),
        returnsNormally,
      );
    });

    test('warning logs message', () {
      expect(
        () => loggerService.warning('Warning message'),
        returnsNormally,
      );
    });

    test('error logs message with error and stack trace', () {
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;

      expect(
        () => loggerService.error(
          'Error message',
          error: error,
          stackTrace: stackTrace,
        ),
        returnsNormally,
      );
    });

    test('logs with feature tag', () {
      expect(
        () => loggerService.info('Message', feature: 'Library'),
        returnsNormally,
      );
    });

    test('logs with data', () {
      expect(
        () => loggerService.info(
          'Message',
          data: {'key': 'value', 'count': 42},
        ),
        returnsNormally,
      );
    });

    test('logFeatureStart logs start message', () {
      expect(
        () => loggerService.logFeatureStart('Library', 'import book'),
        returnsNormally,
      );
    });

    test('logFeatureEnd logs success', () {
      expect(
        () => loggerService.logFeatureEnd('Library', 'import book', success: true),
        returnsNormally,
      );
    });

    test('logFeatureEnd logs failure', () {
      expect(
        () => loggerService.logFeatureEnd('Library', 'import book', success: false),
        returnsNormally,
      );
    });

    test('logUserAction logs user action', () {
      expect(
        () => loggerService.logUserAction(
          'tapped import button',
          data: {'screen': 'library'},
        ),
        returnsNormally,
      );
    });

    test('logPerformance logs performance metrics', () {
      final duration = const Duration(milliseconds: 150);

      expect(
        () => loggerService.logPerformance(
          'import EPUB',
          duration,
          feature: 'Import',
          data: {'fileSize': 1024},
        ),
        returnsNormally,
      );
    });
  });
}
