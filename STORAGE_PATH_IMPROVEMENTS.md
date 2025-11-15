# Storage Path Improvements

## Summary
Refactored file storage from user's Documents folder to proper application data directory for better organization and efficiency.

## Changes Made

### Before (Inefficient)
- **EPUB files:** `C:\Users\{username}\Documents\books\`
- **Cover images:** `C:\Users\{username}\Documents\covers\`

**Problems:**
- Cluttered user's Documents folder with app-specific data
- Not following Windows best practices
- Files weren't grouped under app-specific directory
- User data gets mixed with app data

### After (Efficient)
- **EPUB files:** `C:\Users\{username}\AppData\Roaming\epub_reader\books\`
- **Cover images:** `C:\Users\{username}\AppData\Roaming\epub_reader\covers\`

**Benefits:**
- ✅ Follows Windows application data best practices
- ✅ All app data grouped under `epub_reader` folder
- ✅ Doesn't clutter user's Documents folder
- ✅ Proper separation of app data and user documents
- ✅ Better for backup/sync tools (AppData is typically excluded)
- ✅ Centralized path management for future changes

## Implementation Details

### New Service: `StoragePathService`
**Location:** `lib/core/services/storage_path_service.dart`

A singleton service that provides centralized storage path management:

```dart
@singleton
class StoragePathService {
  Future<Directory> getBooksDirectory() async { ... }
  Future<Directory> getCoversDirectory() async { ... }
  Future<String> getBookPath(String fileName) async { ... }
  Future<String> getCoverPath(String fileName) async { ... }
  Future<Directory> getAppDirectory() async { ... }
}
```

**Features:**
- Automatic directory initialization
- Lazy loading with caching
- Consistent path resolution
- Easy to extend for future storage needs (cache, thumbnails, etc.)

### Updated Files

#### `lib/features/import/domain/usecases/import_epub.dart`
**Changes:**
1. Added `StoragePathService` dependency injection
2. Replaced `getApplicationDocumentsDirectory()` with `_storagePathService`
3. Simplified book path logic: `await _storagePathService.getBookPath(fileName)`
4. Simplified cover path logic: `await _storagePathService.getCoverPath(fileName)`

**Before:**
```dart
final appDir = await getApplicationDocumentsDirectory();
final booksDir = Directory(path.join(appDir.path, 'books'));
if (!await booksDir.exists()) {
  await booksDir.create(recursive: true);
}
final newPath = path.join(booksDir.path, fileName);
```

**After:**
```dart
final newPath = await _storagePathService.getBookPath(fileName);
```

## Platform-Specific Paths

The new implementation uses `getApplicationSupportDirectory()` which resolves to:

- **Windows:** `C:\Users\{username}\AppData\Roaming\epub_reader\`
- **macOS:** `~/Library/Application Support/epub_reader/`
- **Linux:** `~/.local/share/epub_reader/`

All platforms now follow their respective OS conventions for application data storage.

## Migration Notes

**Important:** Existing users with books in the old location will need to:
1. Re-import their EPUB files, OR
2. Manually move files from `Documents/books/` and `Documents/covers/` to the new location

The app will automatically create the new directory structure on first import.

## Future Extensibility

The `StoragePathService` makes it easy to add new storage locations:

```dart
// Easy to add new directories:
Future<Directory> getCacheDirectory() async {
  if (_cacheDir == null) {
    _cacheDir = Directory(path.join(_appSupportDir!.path, 'cache'));
    await _cacheDir!.create(recursive: true);
  }
  return _cacheDir!;
}

Future<Directory> getThumbnailsDirectory() async { ... }
Future<Directory> getExportsDirectory() async { ... }
```

## Testing Checklist

- [x] App builds successfully
- [x] Dependency injection works with new service
- [ ] Import new EPUB and verify it goes to AppData location
- [ ] Verify covers are extracted to AppData location
- [ ] Verify delete functionality still works with new paths
- [ ] Test on different Windows user accounts

## Related Files
- `lib/core/services/storage_path_service.dart` - New centralized path service
- `lib/features/import/domain/usecases/import_epub.dart` - Updated to use new service
- `lib/injection.dart` - Auto-generated DI configuration (includes new service)
