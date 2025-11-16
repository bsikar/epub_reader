# Screenshot Instructions for Chapter Navigation Testing

## Goal
Take screenshots to compare the difference between chapters when navigating

## Automated Method (Recommended)

### Setup (one time)
```bash
python -m pip install -r requirements.txt
```

### Usage

**Option A: Screenshot running app (Recommended)**
```bash
# Terminal 1: Start Flutter app
flutter run -d windows

# Terminal 2: Run screenshot tool
python take_screenshot.py
```

**Option B: Auto-start app**
```bash
# Starts Flutter in a new window, then allows screenshots
python take_screenshot.py --auto-start
```

Note: Option A is recommended because you can see Flutter's output directly.

### Interactive Commands
- Press `s` + Enter to take a screenshot
- Enter a name when prompted (or press Enter for auto-name)
- Press `q` + Enter to quit

Screenshots are saved to `screenshots/` directory.

### Benefits
- Captures only the Flutter window (not entire screen)
- Can attach to already-running app
- Automatic naming with timestamps
- Organized output directory

## Manual Method

### 1. Launch the App
```bash
flutter run -d windows
```

### 2. Import a Book (if not already imported)
- Click the import button (FAB)
- Select `test_epubs/pg11.epub` (Alice's Adventures in Wonderland)

### 3. Take Screenshot 1: Initial Chapter
1. Open the book by clicking on it
2. Click "Start Reading" or "Continue Reading"
3. Wait for the book to load completely
4. Note the current chapter shown in the progress bar (e.g., "Chapter 1 of 12")
5. **Take Screenshot 1** - Press `Windows + Shift + S` or use Snipping Tool
   - Save as: `screenshot_chapter_1_initial.png`

### 4. Navigate to a Different Chapter
Use one of these methods:

**Method A: Using the Slider**
1. Look at the bottom of the screen for the progress slider
2. Drag the slider to a different chapter (e.g., Chapter 5)
3. Wait for navigation to complete (2-3 seconds)

**Method B: Using Table of Contents**
1. Click the TOC icon (list icon) in the app bar
2. Select a different chapter (e.g., "Chapter V")
3. Wait for navigation to complete

**Method C: Using Bookmark Indicators** (if you have bookmarks)
1. Add bookmarks to different chapters first
2. Click on a bookmark dot on the progress slider
3. Wait for navigation to complete

### 5. Take Screenshot 2: After Navigation
1. Verify the chapter number changed in the progress bar
2. **Take Screenshot 2** - Press `Windows + Shift + S`
   - Save as: `screenshot_chapter_5_navigated.png`

### 6. Compare Screenshots
Look for these differences between screenshots:
- **Chapter number** in the progress bar (e.g., "Chapter 1 of 12" → "Chapter 5 of 12")
- **Chapter title** in the progress bar (e.g., "Down the Rabbit-Hole" → "Advice from a Caterpillar")
- **Book content** - different text/paragraphs displayed
- **Slider position** - the slider thumb should be at a different position
- **Percentage complete** - should show different percentage

## Alternative: Use Windows Game Bar
1. Press `Windows + G` to open Game Bar
2. Click the camera icon to take screenshots
3. Screenshots saved to: `C:\Users\YourName\Videos\Captures\`

## Expected Results

### If Navigation Works ✅
- Chapter number changes (e.g., 1 → 5)
- Chapter title changes
- Text content is completely different
- Slider position moves
- Percentage complete changes

### If Navigation Doesn't Work ❌
- Chapter number stays the same
- No visible change in the UI
- Same text content displayed
- This would indicate the bug is still present

## Troubleshooting

**If the reader doesn't open:**
- Check that the EPUB file path is valid
- Try importing the book again
- Check console for error messages

**If navigation doesn't work:**
- Check the debug console for navigation logs
- Look for messages like "TOC navigation to chapter X"
- Try different navigation methods (slider, TOC, bookmarks)

## Automated Screenshot Locations
If you ran the integration test, screenshots (if generated) are in:
- `build/screenshots/` directory
- Look for files like `chapter_0_initial.png`, `chapter_3_navigated.png`
