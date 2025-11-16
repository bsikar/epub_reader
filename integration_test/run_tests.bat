@echo off
REM EPUB Reader Integration Test Runner for Windows

echo EPUB Reader Integration Test Runner
echo ===================================
echo.

if "%1"=="" goto :help

if "%1"=="all" goto :all
if "%1"=="suite" goto :suite
if "%1"=="parallel" goto :parallel
if "%1"=="coverage" goto :coverage
if "%1"=="device" goto :device
if "%1"=="clean" goto :clean
if "%1"=="help" goto :help

echo Unknown command: %1
goto :help

:all
echo Running all integration tests...
flutter test integration_test/app_test.dart
goto :end

:suite
if "%2"=="" (
    echo Error: Please specify a test suite name
    echo.
    echo Available test suites:
    echo   - import_flow
    echo   - reading_flow
    echo   - bookmark_flow
    echo   - highlight_flow
    echo   - library_management
    echo   - navigation_flow
    echo   - error_handling
    echo   - state_persistence
    echo   - end_to_end_flow
    goto :end
)
echo Running %2 test suite...
flutter test integration_test/test_suites/%2_test.dart
goto :end

:parallel
echo Running tests in parallel...
echo This may take several minutes...
start /B flutter test integration_test/test_suites/import_flow_test.dart
start /B flutter test integration_test/test_suites/reading_flow_test.dart
start /B flutter test integration_test/test_suites/bookmark_flow_test.dart
start /B flutter test integration_test/test_suites/highlight_flow_test.dart
start /B flutter test integration_test/test_suites/library_management_test.dart
start /B flutter test integration_test/test_suites/navigation_flow_test.dart
start /B flutter test integration_test/test_suites/error_handling_test.dart
start /B flutter test integration_test/test_suites/state_persistence_test.dart
start /B flutter test integration_test/test_suites/end_to_end_flow_test.dart
echo All test suites started. Check individual console windows for results.
goto :end

:coverage
echo Running tests with coverage...
flutter test --coverage integration_test/app_test.dart
echo.
echo Coverage report saved to coverage/lcov.info
goto :end

:device
if "%2"=="" (
    echo Error: Please specify a device ID
    echo.
    echo Available devices:
    flutter devices
    goto :end
)
echo Running tests on device: %2
flutter test -d %2 integration_test/app_test.dart
goto :end

:clean
echo Cleaning test data...
if exist "integration_test\test_data" rmdir /s /q "integration_test\test_data"
if exist "integration_test\screenshots" rmdir /s /q "integration_test\screenshots"
if exist "coverage" rmdir /s /q "coverage"
echo Test data cleaned successfully
goto :end

:help
echo Usage: run_tests.bat ^<command^> [options]
echo.
echo Commands:
echo   all              Run all integration tests
echo   suite ^<name^>     Run a specific test suite
echo   parallel         Run all test suites in parallel
echo   coverage         Run tests with coverage report
echo   device ^<id^>      Run tests on specific device
echo   clean            Clean test data and artifacts
echo   help             Show this help message
echo.
echo Examples:
echo   run_tests.bat all
echo   run_tests.bat suite bookmark_flow
echo   run_tests.bat parallel
echo   run_tests.bat coverage
echo   run_tests.bat device emulator-5554
echo.
echo For more information, see integration_test\README.md

:end