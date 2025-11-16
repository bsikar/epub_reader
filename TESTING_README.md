# Chapter Navigation Testing Tool

## Quick Start

```bash
.\test_chapter_navigation.bat
```

## What It Does

This interactive tool:
- ✅ Launches the Flutter app on Windows
- ✅ Hides all logs (saves to `app_logs.txt`)
- ✅ Provides a CLI for taking screenshots
- ✅ Lets you name screenshots interactively
- ✅ Saves all screenshots to `screenshots/` folder

## Usage

### 1. Launch the Tool
```bash
.\test_chapter_navigation.bat
```

The app will launch and you'll see an interactive prompt:
```
========================================
Chapter Navigation Testing Tool
========================================

App launched! Process ID: 12345

========================================
Available Commands:
========================================
  s          - Take a screenshot
  l          - Show last 10 log lines
  logs       - Open full log file
  list       - List all screenshots taken
  q / quit   - Quit app and exit
  h / help   - Show this help
========================================

>
```

### 2. Take Screenshots

**Command:** `s` or `screenshot`

1. Type `s` and press Enter
2. Enter a name for the screenshot (or press Enter for auto-name)
3. Screenshot is saved to `screenshots/` folder

**Example:**
```
> s

Taking screenshot...
Enter screenshot name (or press Enter for auto-name): chapter_1_initial
✓ Screenshot saved: screenshots/chapter_1_initial.png

>
```

### 3. Test Chapter Navigation

1. In the app window, open a book
2. Take screenshot 1: `s` → name it `chapter_1_initial`
3. Navigate to a different chapter (using slider, TOC, or bookmark dot)
4. Take screenshot 2: `s` → name it `chapter_5_navigated`
5. Type `list` to see all screenshots
6. Type `q` to quit

### 4. View Logs

**Show recent logs:**
```
> l
```

**Open full log file:**
```
> logs
```

### 5. List Screenshots

```
> list

Screenshots taken:
-------------------
  chapter_1_initial.png (245.67 KB)
  chapter_5_navigated.png (248.12 KB)
-------------------
```

### 6. Exit

```
> q
```

## Testing Workflow

### Test 1: Slider Navigation
```
1. Open book in app
2. CLI: s → "before_slider"
3. In app: Drag slider to chapter 5
4. CLI: s → "after_slider"
5. CLI: list (verify both screenshots)
6. Compare screenshots in screenshots/ folder
```

### Test 2: TOC Navigation
```
1. CLI: s → "before_toc"
2. In app: Click list icon → Select different chapter
3. CLI: s → "after_toc"
```

### Test 3: Bookmark Indicator Click
```
1. In app: Add bookmarks to different chapters
2. CLI: s → "before_bookmark_click"
3. In app: Click a bookmark dot on the slider
4. CLI: s → "after_bookmark_click"
```

## Files Generated

- `screenshots/` - All screenshots saved here
- `app_logs.txt` - Flutter app stdout
- `app_logs.txt.err` - Flutter app stderr (errors)

## Troubleshooting

**"Execution of scripts is disabled"**
```bash
powershell -ExecutionPolicy Bypass -File test_navigation.ps1
```

**App doesn't launch**
- Check `app_logs.txt` for errors
- Make sure Flutter is in your PATH
- Try running `flutter doctor`

**Screenshot is black/wrong window**
- Make sure the app window is visible (not minimized)
- Click on the app window before taking screenshot
- The tool captures the entire screen, then crops

**Can't see logs**
```
> logs
```
This opens the full log file in Notepad.

## Expected Results

### If Navigation Works ✅
- Screenshots show different chapters
- Chapter number changes in progress bar
- Different text content visible
- Slider position differs

### If Navigation Broken ❌
- Screenshots look identical
- Same chapter number
- Same text content
- No visual difference

## Tips

- Take screenshots AFTER navigation completes (wait 2-3 seconds)
- Use descriptive names like `chapter_1`, `chapter_5`, etc.
- Compare screenshots side-by-side in Windows Photo Viewer
- Check the chapter indicator in the progress bar for changes
