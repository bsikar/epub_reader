import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_suites/import_flow_test.dart' as import_flow;
import 'test_suites/reading_flow_test.dart' as reading_flow;
import 'test_suites/bookmark_flow_test.dart' as bookmark_flow;
import 'test_suites/highlight_flow_test.dart' as highlight_flow;
import 'test_suites/library_management_test.dart' as library_management;
import 'test_suites/navigation_flow_test.dart' as navigation_flow;
import 'test_suites/chapter_navigation_test.dart' as chapter_navigation;
import 'test_suites/bookmark_indicator_click_test.dart' as bookmark_indicator_click;
import 'test_suites/error_handling_test.dart' as error_handling;
import 'test_suites/state_persistence_test.dart' as state_persistence;
import 'test_suites/end_to_end_flow_test.dart' as end_to_end;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('EPUB Reader Integration Tests', () {
    // Run all test suites
    import_flow.main();
    reading_flow.main();
    bookmark_flow.main();
    highlight_flow.main();
    library_management.main();
    navigation_flow.main();
    chapter_navigation.main();
    bookmark_indicator_click.main();
    error_handling.main();
    state_persistence.main();
    end_to_end.main();
  });
}