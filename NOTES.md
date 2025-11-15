# Development Notes

## Known Issues

### flutter_tts Windows Build Issue
**Status**: Temporarily Resolved
**Date**: 2025-11-14

**Issue**: The `flutter_tts` package has a CMake configuration issue on Windows that prevents builds from completing:
```
CMake Error at flutter/ephemeral/.plugin_symlinks/flutter_tts/windows/CMakeLists.txt:18:
  Parse error.  Expected "(", got identifier with text "install".
```

**Resolution**: Temporarily removed `flutter_tts` from pubspec.yaml. The package has been commented out.

**Future Action**: When implementing dictionary pronunciation features (Phase 5), we have several options:
1. Check if `flutter_tts` has been updated with Windows support
2. Use an alternative TTS package that supports Windows
3. Implement Windows-specific TTS using platform channels
4. Skip TTS on Windows platform and only implement on mobile

**Impact**: No immediate impact. TTS is a planned feature for Phase 5 (dictionary pronunciation). All other features can be implemented without it.

## Build Instructions

### Clean Build (after dependency changes)
```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows
```

### If you encounter build errors:
1. Delete `build/` folder manually
2. Run `flutter clean`
3. Run `flutter pub get`
4. Try building again

## Progress Tracking

### Completed (Foundation Phase)
- ✅ All planning documentation
- ✅ Clean architecture folder structure
- ✅ Core infrastructure (errors, config, widgets)
- ✅ Database schema (10 tables with Drift)
- ✅ Build system configured
- ✅ Windows build working (without TTS)

### Next Up (Implementation Phase)
- [ ] Dependency injection setup (get_it + injectable)
- [ ] App initialization (app.dart, main.dart)
- [ ] Library feature (import, grid/list view)
- [ ] EPUB reader (basic rendering)
- [ ] Reading progress tracking

## Development Tips

### Working with Drift Database
- After modifying tables in `app_database.dart`, run: `dart run build_runner build --delete-conflicting-outputs`
- Always check `app_database.g.dart` for generated code
- Use type-safe queries provided by Drift
- Indexes are automatically created on first app launch

### Riverpod Best Practices
- Use code generation with `@riverpod` annotation
- Keep providers close to their features
- Use `ref.watch()` for reactive dependencies
- Use `ref.read()` for one-time reads in callbacks

### Testing Strategy
- Write tests in the order: data → domain → presentation
- Mock repositories at the domain layer
- Test use cases thoroughly (they contain business logic)
- Widget tests for complex UI components

## Architecture Reminders

### Dependency Flow
```
main.dart
  → injection.dart (configures DI)
  → app.dart (MaterialApp + Riverpod)
  → features/
      → presentation (UI + Providers)
      → domain (Use Cases + Repository Interfaces)
      → data (Repository Impl + Data Sources)
```

### Error Handling Pattern
```dart
// Data Layer
try {
  final result = await dataSource.getData();
  return Right(result);
} catch (e) {
  return Left(DataFailure(e.toString()));
}

// Presentation Layer
result.fold(
  (failure) => showError(failure.message),
  (data) => displayData(data),
);
```

## Performance Checklist

Before each release:
- [ ] Run app with `--profile` flag
- [ ] Check memory usage with DevTools
- [ ] Verify database queries are using indexes
- [ ] Test with large EPUB files (> 10MB)
- [ ] Check cold start time (< 2 seconds target)
- [ ] Verify 60fps rendering during reading

## Code Quality Checklist

Before committing:
- [ ] Run `flutter analyze` (no errors/warnings)
- [ ] Run `flutter test` (all tests pass)
- [ ] Format code: `dart format lib/`
- [ ] Update relevant documentation
- [ ] Add/update tests for new features

---

**Last Updated**: 2025-11-14
