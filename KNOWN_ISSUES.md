# Known Issues & Limitations

## EPUB Rendering Compatibility

### Issue: HTML Parser Null Check Error with Certain EPUB Files

**Status:** Known limitation of epub_view package v3.2.0

**Error Message:**
```
Null check operator used on a null value
at _EpubViewState._chapterBuilder.<anonymous closure> (package:epub_view/src/ui/epub_view.dart:361:51)
at TagExtension.build (package:flutter_html/src/extension/helpers/tag_extension.dart:49:19)
```

**Description:**
The epub_view package (v3.2.0) uses flutter_html for HTML rendering, which has compatibility issues with certain EPUB files that contain complex or non-standard HTML formatting. When the HTML parser encounters specific tag combinations or malformed markup, it throws a null check error that cannot be gracefully caught at the widget level.

**Root Cause:**
- The flutter_html package used by epub_view has strict parsing requirements
- Some EPUB files contain HTML that doesn't perfectly conform to expected structures
- The TagExtension builder assumes certain properties are non-null when they can actually be null in edge cases

**Impact:**
- Affects EPUB files with complex HTML formatting
- Document loads successfully (you'll see "Document loaded with N chapters")
- Error occurs during rendering phase, making the book unreadable in the app
- Progress saving and other features still work in the background

**Affected EPUB Characteristics:**
- EPUBs with complex nested HTML structures
- Files with custom CSS or JavaScript embeds
- EPUBs exported from certain authoring tools
- Files with embedded SVG images or complex formatting

**Workarounds:**

### Option 1: Try Different EPUB Files (Recommended)
- Test with standard EPUB 2.0 or EPUB 3.0 files
- EPUBs from major publishers (O'Reilly, Penguin, etc.) tend to work well
- Simple text-based EPUBs without heavy formatting work best

### Option 2: Convert Problematic EPUBs
Use Calibre to convert/clean the EPUB:
1. Open EPUB in Calibre
2. Convert to EPUB format again (Edit → Convert books)
3. In conversion options, select "Remove spacing between paragraphs"
4. Check "Insert blank line between paragraphs"
5. Convert and try the new file

### Option 3: Use Alternative EPUB Package (Future Enhancement)
Consider replacing epub_view with one of these alternatives:
- **vocsy_epub_viewer** - Native plugin with better compatibility
- **cosmos_epub** - Modern EPUB reader with better UI
- **epub_plus** - Updated fork with bug fixes

### Option 4: Custom HTML Error Handling (Not Yet Implemented)
Potential future fix:
- Fork epub_view package
- Add null-safety checks in TagExtension
- Submit PR to upstream package
- Or maintain custom fork

**Testing Recommendations:**
1. Test with multiple EPUB sources:
   - Project Gutenberg (simple formatting)
   - Standard Ebooks (clean EPUB 3.0)
   - O'Reilly books (technical content)
   - Personal library EPUBs

2. Validate EPUBs before importing:
   - Use EPUBCheck validator
   - Check for HTML compliance
   - Ensure proper EPUB structure

**Technical Details:**
- Package: epub_view ^3.1.0 (resolved to 3.2.0)
- Dependency: flutter_html ^3.0.0
- Last updated: 2 years ago
- Known upstream issue: flutter_html has strict null-safety requirements

**Future Plans:**
1. Research alternative EPUB packages
2. Consider forking epub_view with fixes
3. Implement fallback reader for incompatible files
4. Add EPUB validation before import
5. Provide better user feedback for incompatible files

**Current Status:**
- App builds successfully
- Works perfectly with compatible EPUB files
- All features (progress, bookmarks, TOC) functional for compatible files
- Incompatible files will show error in debug mode

**Recommendation for Users:**
If you encounter this error:
1. The file loaded but couldn't be rendered
2. Try a different EPUB file to test the app
3. Use Calibre to convert/clean problematic EPUBs
4. The app works great with standard EPUB files!

---

**Last Updated:** 2025-11-14
**Tracked In:** GitHub issue (if applicable)
**Priority:** Medium (workarounds available)
