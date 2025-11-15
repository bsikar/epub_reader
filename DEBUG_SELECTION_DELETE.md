# Debug Guide: Selection & Delete Issues

## Issue Report
User reports two issues:
1. **Selection mode doesn't work well** - Clicking books may not select them properly
2. **Delete is not actually deleting** - Books remain after delete confirmation

## Debug Logging Added

I've added comprehensive logging throughout the selection and delete flow. When you run the app in debug mode, you'll see detailed console output showing exactly what's happening.

### How to Run with Debug Logs

```bash
flutter run -d windows
```

Then check the console output as you perform these actions:

## Test Steps

### Test 1: Selection Mode Activation
1. Open the app with books in library
2. Tap the **three dots menu** (⋮) in top right
3. Select "Select books"

**Expected Console Output:**
```
Toggling selection mode. Current: false
Selection mode now: true
```

**What to check:**
- Do checkboxes appear on books?
- Does the app bar title change to "0 selected"?
- Does the close (X) button appear?

### Test 2: Selecting Books
1. While in selection mode, tap on a book

**Expected Console Output:**
```
Toggling book selection for ID: <book_id>
Added book <book_id> to selection
Selected books: 1 (<book_id>)
```

**What to check:**
- Does the checkbox fill in?
- Does the app bar title update to "1 selected"?
- Does the delete button appear in app bar?

### Test 3: Select Multiple Books
1. Tap on more books to select them

**Expected Console Output (for each tap):**
```
Toggling book selection for ID: <book_id>
Added book <book_id> to selection
Selected books: <count> (<ids>)
```

### Test 4: Deselect a Book
1. Tap on an already-selected book

**Expected Console Output:**
```
Toggling book selection for ID: <book_id>
Removed book <book_id> from selection
Selected books: <count> (<remaining_ids>)
```

### Test 5: Select All
1. Tap the "Select all" button (if available)

**Expected Console Output:**
```
(Should show all book IDs in selected set)
```

### Test 6: Delete Confirmation
1. With books selected, tap the delete button (trash icon)

**Expected Console Output:**
```
LibraryScreen: Confirm delete called for <count> books
LibraryScreen: Selected IDs: <id1>, <id2>, ...
```

**What to check:**
- Does the confirmation dialog appear?
- Does it show the correct count?

### Test 7: Confirm Delete
1. In the dialog, click "Delete" button

**Expected Console Output:**
```
LibraryScreen: Delete confirmed
LibraryScreen: Dialog result: true
LibraryScreen: Calling deleteSelectedBooks
Deleting <count> books
Books to delete: <book titles>
Attempting to delete book: <title> (ID: <id>)
DeleteBook use case: Deleting book ID <id>
DeleteBook: Calling repository.deleteBook(<id>)
DeleteBook: Database delete successful, deleting files
DeleteBook: Deleting files for <title>
DeleteBook: EPUB file path: <path>
DeleteBook: EPUB file exists, deleting...
DeleteBook: EPUB file deleted
DeleteBook: Cover file path: <path>
DeleteBook: Cover file exists, deleting...
DeleteBook: Cover file deleted
Delete successful, updating state
LibraryScreen: Delete completed
```

**What to check:**
- Are the console logs appearing?
- Are books disappearing from the UI?
- Do files actually get deleted from disk?

## Potential Issues to Look For

### Issue 1: Selection Not Working
**Symptom:** Clicking books doesn't select them, no checkbox changes

**Possible causes:**
- `onSelectionChanged` callback not being called
- `toggleBookSelection` not executing
- State not updating

**Look for in logs:**
- Missing "Toggling book selection for ID:" messages
- Check if book IDs are null

### Issue 2: Delete Not Working - Database
**Symptom:** Logs show "Database delete failed"

**Possible causes:**
- Book ID is null
- Database connection issue
- Foreign key constraints preventing deletion

**Look for in logs:**
```
DeleteBook: Book ID is null!
// OR
DeleteBook: Database delete failed - <error message>
```

### Issue 3: Delete Not Working - Files
**Symptom:** Database deletes but books reappear after refresh

**Possible causes:**
- File deletion failing
- Files being re-imported
- State not updating properly

**Look for in logs:**
```
DeleteBook: EPUB file does not exist
// OR
DeleteBook: Error deleting book files: <error>
```

### Issue 4: Delete Not Working - State Update
**Symptom:** Logs show success but UI doesn't update

**Possible causes:**
- State not being copied correctly
- Riverpod state not triggering rebuild

**Look for in logs:**
```
Delete successful, updating state
// But no visible change in UI
```

## Quick Fixes

### If Selection Isn't Responding:
Check in the code that `book.id` is not null. Look at the console for:
```
Toggling book selection for ID: null
```

### If Delete Completes But Books Return:
The books might be getting reloaded from the database. Check if `loadBooks()` is being called after delete.

### If Confirmation Dialog Doesn't Appear:
Check if `selectedBookIds` is actually populated. Look for:
```
LibraryScreen: Confirm delete called for 0 books
```

## Next Steps After Testing

1. **Run the app**: `flutter run -d windows`
2. **Perform the test steps above**
3. **Copy all console output**
4. **Identify which step fails** based on missing/error logs
5. **Report findings** with the specific log output

This will help pinpoint exactly where the issue is occurring in the selection/delete flow.

---

**Debug Logging Locations:**
- `lib/features/library/presentation/providers/library_provider.dart` - Selection & delete state logic
- `lib/features/library/domain/usecases/delete_book.dart` - Delete operation & file cleanup
- `lib/features/library/presentation/screens/library_screen.dart` - UI interactions & confirmation dialog

**Files to Check After Delete:**
- Database: Check if book records are removed
- EPUB files: `<app_documents>/books/` directory
- Cover files: `<app_documents>/covers/` directory
