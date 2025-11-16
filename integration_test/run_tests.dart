#!/usr/bin/env dart

import 'dart:io';

/// Script to run integration tests with various configurations
void main(List<String> args) async {
  print('EPUB Reader Integration Test Runner');
  print('===================================\n');

  if (args.isEmpty) {
    showHelp();
    return;
  }

  final command = args[0];

  switch (command) {
    case 'all':
      await runAllTests();
      break;
    case 'suite':
      if (args.length < 2) {
        print('Error: Please specify a test suite name');
        showAvailableSuites();
        exit(1);
      }
      await runTestSuite(args[1]);
      break;
    case 'parallel':
      await runTestsInParallel();
      break;
    case 'coverage':
      await runWithCoverage();
      break;
    case 'device':
      if (args.length < 2) {
        print('Error: Please specify a device ID');
        await showDevices();
        exit(1);
      }
      await runOnDevice(args[1]);
      break;
    case 'clean':
      await cleanTestData();
      break;
    case 'help':
      showHelp();
      break;
    default:
      print('Unknown command: $command');
      showHelp();
      exit(1);
  }
}

Future<void> runAllTests() async {
  print('Running all integration tests...\n');
  final result = await Process.run(
    'flutter',
    ['test', 'integration_test/app_test.dart'],
    runInShell: true,
  );

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  exit(result.exitCode);
}

Future<void> runTestSuite(String suiteName) async {
  final testFile = 'integration_test/test_suites/${suiteName}_test.dart';
  final file = File(testFile);

  if (!await file.exists()) {
    print('Error: Test suite "$suiteName" not found');
    showAvailableSuites();
    exit(1);
  }

  print('Running $suiteName test suite...\n');
  final result = await Process.run(
    'flutter',
    ['test', testFile],
    runInShell: true,
  );

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  exit(result.exitCode);
}

Future<void> runTestsInParallel() async {
  print('Running tests in parallel...\n');

  final suites = [
    'import_flow',
    'reading_flow',
    'bookmark_flow',
    'highlight_flow',
    'library_management',
    'navigation_flow',
    'error_handling',
    'state_persistence',
    'end_to_end_flow',
  ];

  final processes = <Future<ProcessResult>>[];

  for (final suite in suites) {
    processes.add(
      Process.run(
        'flutter',
        ['test', 'integration_test/test_suites/${suite}_test.dart'],
        runInShell: true,
      ),
    );
  }

  print('Started ${processes.length} test suites in parallel');
  print('Waiting for completion...\n');

  final results = await Future.wait(processes);

  var hasFailures = false;
  for (int i = 0; i < results.length; i++) {
    print('\n${suites[i]} results:');
    print('=' * 40);
    print(results[i].stdout);

    if (results[i].exitCode != 0) {
      hasFailures = true;
      print('FAILED: ${suites[i]}');
      if (results[i].stderr.isNotEmpty) {
        print('Errors: ${results[i].stderr}');
      }
    } else {
      print('PASSED: ${suites[i]}');
    }
  }

  exit(hasFailures ? 1 : 0);
}

Future<void> runWithCoverage() async {
  print('Running tests with coverage...\n');

  final result = await Process.run(
    'flutter',
    ['test', '--coverage', 'integration_test/app_test.dart'],
    runInShell: true,
  );

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  if (result.exitCode == 0) {
    print('\nGenerating coverage report...');
    final coverageResult = await Process.run(
      'genhtml',
      ['coverage/lcov.info', '-o', 'coverage/html'],
      runInShell: true,
    );

    if (coverageResult.exitCode == 0) {
      print('Coverage report generated at: coverage/html/index.html');
    } else {
      print('Note: Install lcov to generate HTML coverage reports');
    }
  }

  exit(result.exitCode);
}

Future<void> runOnDevice(String deviceId) async {
  print('Running tests on device: $deviceId\n');

  final result = await Process.run(
    'flutter',
    ['test', '-d', deviceId, 'integration_test/app_test.dart'],
    runInShell: true,
  );

  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  exit(result.exitCode);
}

Future<void> showDevices() async {
  print('Available devices:\n');

  final result = await Process.run(
    'flutter',
    ['devices'],
    runInShell: true,
  );

  print(result.stdout);
}

Future<void> cleanTestData() async {
  print('Cleaning test data...\n');

  // Clean test directories
  final testDirs = [
    'integration_test/test_data',
    'integration_test/screenshots',
    'coverage',
  ];

  for (final dirPath in testDirs) {
    final dir = Directory(dirPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      print('Deleted: $dirPath');
    }
  }

  print('\nTest data cleaned successfully');
}

void showAvailableSuites() {
  print('\nAvailable test suites:');
  print('  - import_flow');
  print('  - reading_flow');
  print('  - bookmark_flow');
  print('  - highlight_flow');
  print('  - library_management');
  print('  - navigation_flow');
  print('  - error_handling');
  print('  - state_persistence');
  print('  - end_to_end_flow');
}

void showHelp() {
  print('''
Usage: dart run integration_test/run_tests.dart <command> [options]

Commands:
  all              Run all integration tests
  suite <name>     Run a specific test suite
  parallel         Run all test suites in parallel
  coverage         Run tests with coverage report
  device <id>      Run tests on specific device
  clean            Clean test data and artifacts
  help             Show this help message

Examples:
  dart run integration_test/run_tests.dart all
  dart run integration_test/run_tests.dart suite bookmark_flow
  dart run integration_test/run_tests.dart parallel
  dart run integration_test/run_tests.dart coverage
  dart run integration_test/run_tests.dart device iPhone

For more information, see integration_test/README.md
''');
}