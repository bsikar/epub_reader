# Test EPUB Files

This directory contains Project Gutenberg EPUB files for testing the EPUB Reader app.

## Files Included (21 EPUBs)

### Alice's Adventures in Wonderland - Lewis Carroll (pg11)
- `pg11.epub` - Text only
- `pg11-images.epub` - With images (EPUB 2.0)
- `pg11-images-3.epub` - With images (EPUB 3.0)

### Complete Works of William Shakespeare (pg100)
- `pg100-images.epub` - With images (EPUB 2.0)
- `pg100-images-3.epub` - With images (EPUB 3.0)

### Pride and Prejudice - Jane Austen (pg1342)
- `pg1342.epub` - Text only
- `pg1342-images.epub` - With images (EPUB 2.0)
- `pg1342-images-3.epub` - With images (EPUB 3.0)

### Romeo and Juliet - William Shakespeare (pg1513)
- `pg1513.epub` - Text only
- `pg1513-images.epub` - With images (EPUB 2.0)
- `pg1513-images-3.epub` - With images (EPUB 3.0)

### Scarlet Letter - Nathaniel Hawthorne (pg25344)
- `pg25344.epub` - Text only
- `pg25344-images.epub` - With images (EPUB 2.0)
- `pg25344-images-3.epub` - With images (EPUB 3.0)

### Moby Dick - Herman Melville (pg2701)
- `pg2701.epub` - Text only
- `pg2701-images.epub` - With images (EPUB 2.0)
- `pg2701-images-3.epub` - With images (EPUB 3.0)

### Frankenstein - Mary Shelley (pg84)
- `pg84.epub` - Text only
- `pg84-images.epub` - With images (EPUB 2.0)
- `pg84-images-3.epub` - With images (EPUB 3.0)

### The Necklace - Guy de Maupassant (pg8492)
- `pg8492.epub` - Text only
- `pg8492-images.epub` - With images (EPUB 2.0)
- `pg8492-images-3.epub` - With images (EPUB 3.0)

## EPUB Format Variations

Each book comes in up to 3 versions:

1. **Text Only** (`pgXXXX.epub`) - Simple, no images
   - Best compatibility
   - Smallest file size
   - Recommended for testing basic functionality

2. **EPUB 2.0 with Images** (`pgXXXX-images.epub`)
   - EPUB 2.0 standard
   - Contains cover and illustrations
   - Good for testing image handling

3. **EPUB 3.0 with Images** (`pgXXXX-images-3.epub`)
   - EPUB 3.0 standard
   - Enhanced features
   - Tests modern EPUB support

## Testing Recommendations

### For Basic Testing
Start with text-only versions:
- `pg11.epub` (Alice in Wonderland) - Short, simple
- `pg1513.epub` (Romeo and Juliet) - Classic play format
- `pg8492.epub` (The Necklace) - Very short story

### For Image Testing
Try EPUB 2.0 with images:
- `pg1342-images.epub` (Pride and Prejudice)
- `pg84-images.epub` (Frankenstein)

### For Advanced Testing
Test EPUB 3.0 features:
- `pg2701-images-3.epub` (Moby Dick) - Large, complex book
- `pg100-images-3.epub` (Shakespeare) - Very large collection

### For Compatibility Testing
If you encounter rendering issues with one version, try:
1. Text-only version first
2. EPUB 2.0 with images next
3. EPUB 3.0 last

## Expected Behavior

✅ **Should Work Well:**
- Text-only versions (simplest format)
- Standard formatting books
- Table of contents navigation
- Reading progress tracking
- Bookmarks

⚠️ **May Have Issues:**
- Books with complex HTML/CSS
- Heavy image content
- Custom fonts or styling
- See KNOWN_ISSUES.md for details

## Source

All files from [Project Gutenberg](https://www.gutenberg.org/)
- Public domain books
- Multiple format options
- Free to use and distribute

## Usage

1. Launch the EPUB Reader app
2. Click "Import EPUB" button
3. Navigate to this directory
4. Select any .epub file
5. Start reading!

---

**Last Updated:** 2025-11-14
**Total Files:** 21 EPUBs
**Total Books:** 8 titles
