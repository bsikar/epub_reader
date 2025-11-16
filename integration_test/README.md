# EPUB Reader Integration Tests

Comprehensive integration test suite for the EPUB Reader Flutter application.

## Overview

This integration test suite provides end-to-end testing for all major features and user flows in the EPUB Reader application. The tests ensure that the app functions correctly from a user's perspective and maintains data integrity across various scenarios.

## Test Structure

```
integration_test/
├── app_test.dart           # Main test runner
├── helpers/                # Test utilities and helpers
│   ├── test_app.dart       # App initialization and cleanup
│   ├── test_data.dart      # Test data factory
│   ├── test_actions.dart   # Common test actions
│   └── widget_finders.dart # Widget finder helpers
└── test_suites/           # Individual test suites
    ├── import_flow_test.dart       # Book import functionality
    ├── reading_flow_test.dart      # Reading and progress tracking
    ├── bookmark_flow_test.dart     # Bookmark management
    ├── highlight_flow_test.dart    # Highlight management
    ├── library_management_test.dart # Library features
    ├── navigation_flow_test.dart   # Navigation patterns
    ├── error_handling_test.dart    # Error scenarios
    ├── state_persistence_test.dart # Data persistence
    └── end_to_end_flow_test.dart  # Complete user journeys
```

## Test Coverage

### 1. Import Flow Tests
- Import valid EPUB files
- Handle duplicate books
- Verify metadata extraction
- Cover image display
- Import error handling

### 2. Reading Flow Tests
- Open books for reading
- Progress tracking and auto-save
- Chapter navigation
- Reading settings (font size, theme)
- Progress persistence

### 3. Bookmark Management Tests
- Add/delete bookmarks
- Navigate to bookmarks
- Bookmark persistence
- Multiple bookmarks handling

### 4. Highlight Management Tests
- Create highlights with colors
- Add notes to highlights
- Delete highlights
- Navigate to highlighted sections

### 5. Library Management Tests
- View modes (grid/list)
- Search functionality
- Sort and filter options
- Delete books
- Selection mode

### 6. Navigation Tests
- Screen transitions
- Drawer navigation
- Back button handling
- Deep linking
- Rapid navigation stress tests

### 7. Error Handling Tests
- Missing files
- Corrupted EPUBs
- Database errors
- Network failures
- Permission issues

### 8. State Persistence Tests
- Reading progress persistence
- Settings preservation
- Bookmark/highlight persistence
- App state recovery

### 9. End-to-End Tests
- Complete user journeys
- Multi-book workflows
- Feature integration
- Performance with many books

## Running Tests

### Prerequisites
1. Flutter SDK installed
2. Device/emulator available
3. Project dependencies installed

### Run All Tests
```bash
flutter test integration_test/app_test.dart
```

### Run Specific Test Suite
```bash
flutter test integration_test/test_suites/import_flow_test.dart
```

### Run with Coverage
```bash
flutter test integration_test/app_test.dart --coverage
```

### Run on Specific Device
```bash
flutter test integration_test/app_test.dart -d <device_id>
```

### Run on Multiple Devices
```bash
# iOS Simulator
flutter test integration_test/app_test.dart -d iPhone

# Android Emulator
flutter test integration_test/app_test.dart -d emulator-5554

# Web
flutter test integration_test/app_test.dart -d chrome
```

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test integration_test/app_test.dart
```

### Firebase Test Lab
```bash
# Build APK
flutter build apk --debug

# Upload to Firebase Test Lab
gcloud firebase test android run \
  --app=build/app/outputs/flutter-apk/app-debug.apk \
  --test=build/app/outputs/flutter-apk/app-debug-androidTest.apk \
  --device model=Pixel2,version=28
```

## Test Data Management

The test suite uses a factory pattern for creating test data:

- **TestData**: Factory for creating books, bookmarks, highlights
- **TestApp**: Manages app initialization and database operations
- **Sample EPUBs**: Minimal EPUB files for testing

## Best Practices

1. **Isolation**: Each test cleans up after itself
2. **Independence**: Tests can run in any order
3. **Reliability**: Use proper waits and assertions
4. **Maintainability**: Reuse helpers and actions
5. **Performance**: Run tests in parallel when possible

## Debugging Tests

### Enable Verbose Output
```bash
flutter test integration_test/app_test.dart --verbose
```

### Take Screenshots on Failure
```dart
testWidgets('test name', (tester) async {
  try {
    // test code
  } catch (e) {
    await tester.takeScreenshot();
    rethrow;
  }
});
```

### Debug Mode
```bash
flutter test integration_test/app_test.dart --start-paused
```

## Common Issues

### Issue: Tests fail on CI
**Solution**: Increase timeout values and ensure proper async handling

### Issue: Database conflicts
**Solution**: Ensure proper cleanup in setUp/tearDown

### Issue: Widget not found
**Solution**: Add pumpAndSettle() after actions

### Issue: Slow test execution
**Solution**: Run tests in parallel, optimize database operations

## Contributing

When adding new tests:

1. Follow existing patterns
2. Use helper functions
3. Add to appropriate test suite
4. Update this documentation
5. Ensure tests are reliable

## Test Metrics

- **Total Test Cases**: ~150+
- **Coverage Areas**: 9 major features
- **Execution Time**: ~10-15 minutes (full suite)
- **Platform Support**: iOS, Android, Web

## Maintenance

### Weekly
- Run full test suite
- Update failing tests
- Review test coverage

### Monthly
- Optimize slow tests
- Update test data
- Review error scenarios

### Quarterly
- Refactor test helpers
- Update documentation
- Performance benchmarking