# Comprehensive Guide: Building an Offline Dictionary Database for Flutter

This guide provides detailed technical information for implementing a production-quality offline dictionary in a Flutter application, covering data sources, database design, optimization, and integration.

---

## Table of Contents

1. [Dictionary Data Sources](#1-dictionary-data-sources)
2. [Database Schema Design](#2-database-schema-design)
3. [Data Processing](#3-data-processing)
4. [Database Optimization](#4-database-optimization)
5. [Integration with Flutter](#5-integration-with-flutter)
6. [Implementation Examples](#6-implementation-examples)

---

## 1. Dictionary Data Sources

### 1.1 WordNet 3.1

**Overview**: Princeton WordNet is a comprehensive lexical database of English, grouping words into synonym sets (synsets) and providing definitions, examples, and semantic relationships.

**Download Sources**:
- Official: https://wordnet.princeton.edu/download
- Version 3.1 (latest): https://wordnetcode.princeton.edu/wn3.1.dict.tar.gz
- GitHub repository: https://github.com/moos/wordnet-db

**Data Structure**:
- Size: ~10 MB compressed, ~34 MB uncompressed
- Files: `data.noun`, `data.verb`, `data.adj`, `data.adv`, `index.*`, `index.sense`
- Format: Plain text with structured fields separated by spaces and pipes
- Contains: ~147,000 words, ~117,000 synsets

**Data Format Example**:
```
00001740 03 n 01 entity 0 001 @ 00001930 n 0000 | that which is perceived...
```

**License**:
- WordNet Release 3.0 License (free for research and commercial use)
- Requires citation: Fellbaum, C. (1998, ed.) WordNet: An Electronic Lexical Database. Cambridge, MA: MIT Press.

**Key Features**:
- Synsets with definitions and examples
- Semantic relationships (hypernyms, hyponyms, meronyms, etc.)
- Part of speech tags (noun, verb, adjective, adverb)
- Word frequency rankings
- Cross-references between concepts

---

### 1.2 Wiktionary

**Overview**: Multilingual, crowd-sourced dictionary with extensive coverage including pronunciations, etymologies, translations, and usage examples.

**Download Sources**:
- English Wiktionary dumps: https://dumps.wikimedia.org/enwiktionary/
- Latest dump: https://dumps.wikimedia.org/enwiktionary/latest/enwiktionary-latest-pages-articles.xml.bz2
- Pre-extracted JSON data: https://kaikki.org/dictionary/

**Data Structure**:
- Size: ~5-10 GB compressed XML
- Format: MediaWiki XML with wikitext markup
- Contains: 6+ million entries across all languages

**License**: Creative Commons Attribution-ShareAlike 3.0 Unported License (CC BY-SA 3.0)

**Parsing Tools**:

1. **Wiktextract (Python)** - Recommended
   ```bash
   pip install wiktextract
   ```
   - Extracts structured data from XML dumps
   - Outputs JSONL format
   - Pre-extracted data available at kaikki.org
   - Processing time: 1-24 hours depending on hardware

2. **JWKTL (Java)**
   - Library for parsing Wiktionary dumps
   - Supports multiple languages
   - Requires Java 8+

**Key Features**:
- IPA pronunciation
- Etymology information
- Multiple definitions per word
- Usage examples
- Translations (100+ languages)
- Inflection tables
- Regional variations

---

### 1.3 GCIDE (GNU Collaborative International Dictionary of English)

**Overview**: Based on Webster's Revised Unabridged Dictionary (1913) and enhanced with WordNet data.

**Download Sources**:
- Official GNU FTP: https://ftp.gnu.org/gnu/gcide/
- Latest version (0.54, December 2024):
  - tar.gz: https://ftp.gnu.org/gnu/gcide/gcide-0.54.tar.gz (19 MB)
  - tar.xz: https://ftp.gnu.org/gnu/gcide/gcide-0.54.tar.xz (15 MB)
  - zip: https://ftp.gnu.org/gnu/gcide/gcide-0.54.zip (19 MB)

**Data Structure**:
- Size: ~15-19 MB compressed
- Format: SGML/XML
- Contains: ~131,566 headwords
- File structure: Individual XML files per letter

**License**: GNU General Public License (GPL)

**Key Features**:
- Comprehensive definitions
- Etymology
- Usage examples
- Cross-references
- Pronunciation guides
- Public domain base (1913 Webster's)

---

### 1.4 CMU Pronouncing Dictionary (for IPA/Pronunciation)

**Overview**: Open-source pronunciation dictionary for North American English with 134,000+ entries.

**Download Sources**:
- Original (ARPAbet): http://www.speech.cs.cmu.edu/cgi-bin/cmudict
- IPA conversion: https://github.com/menelik3/cmudict-ipa
- Multi-language IPA: https://github.com/open-dict-data/ipa-dict
- Kaggle dataset: https://www.kaggle.com/datasets/rtatman/cmu-pronouncing-dictionary

**Data Structure**:
```
DICTIONARY  D IH1 K SH AH0 N EH2 R IY0
DICTIONARY(2)  D IH1 K SH AH0 N EH2 R IY0
```

IPA conversion:
```
dictionary  dˈɪkʃənˌɛɹi
```

**License**: Public domain / Open source

**Format**:
- Original: ARPAbet phonetic notation
- Converted: International Phonetic Alphabet (IPA)

---

### 1.5 Data Source Comparison

| Source | Entries | Size | Definitions | Pronunciation | Etymology | License | Best For |
|--------|---------|------|-------------|---------------|-----------|---------|----------|
| WordNet 3.1 | 147K | 34 MB | Yes | No | No | Free | Semantic relationships, synonyms |
| Wiktionary | 6M+ | 5-10 GB | Yes | Yes (IPA) | Yes | CC BY-SA | Comprehensive coverage |
| GCIDE | 132K | 15-19 MB | Yes | Text-based | Yes | GPL | Classic definitions |
| CMU Dict | 134K | <5 MB | No | Yes (IPA) | No | Public | Pronunciation only |

**Recommendation for Production**:
- **Primary**: WordNet 3.1 (definitions + semantic data)
- **Pronunciation**: CMU Dictionary IPA conversion
- **Enhanced**: Combine with Wiktionary subset for etymology and additional examples

---

## 2. Database Schema Design

### 2.1 Recommended Schema Architecture

#### Core Tables

**1. words** - Main word entries
```sql
CREATE TABLE words (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    word TEXT NOT NULL UNIQUE COLLATE NOCASE,
    word_lower TEXT NOT NULL,  -- Normalized lowercase for indexing
    frequency_rank INTEGER DEFAULT 0,  -- Word frequency (higher = more common)
    created_at INTEGER DEFAULT (strftime('%s', 'now'))
);

CREATE INDEX idx_words_lower ON words(word_lower);
CREATE INDEX idx_words_frequency ON words(frequency_rank DESC);
```

**2. definitions** - Word definitions with multiple senses
```sql
CREATE TABLE definitions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    word_id INTEGER NOT NULL,
    definition TEXT NOT NULL,
    part_of_speech TEXT,  -- noun, verb, adjective, adverb, etc.
    sense_number INTEGER DEFAULT 1,  -- For words with multiple meanings
    example TEXT,  -- Usage example
    synset_id TEXT,  -- WordNet synset ID (e.g., 'dog.n.01')
    FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
);

CREATE INDEX idx_definitions_word_id ON definitions(word_id);
CREATE INDEX idx_definitions_pos ON definitions(part_of_speech);
```

**3. pronunciations** - IPA pronunciation data
```sql
CREATE TABLE pronunciations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    word_id INTEGER NOT NULL,
    ipa TEXT NOT NULL,  -- International Phonetic Alphabet
    variant_number INTEGER DEFAULT 1,  -- For words with multiple pronunciations
    region TEXT,  -- 'us', 'uk', 'au', etc.
    FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
);

CREATE INDEX idx_pronunciations_word_id ON pronunciations(word_id);
```

**4. etymologies** - Word origins (optional)
```sql
CREATE TABLE etymologies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    word_id INTEGER NOT NULL,
    etymology TEXT NOT NULL,
    language_origin TEXT,  -- Latin, Greek, Old English, etc.
    FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
);

CREATE INDEX idx_etymologies_word_id ON etymologies(word_id);
```

**5. semantic_relations** - WordNet relationships
```sql
CREATE TABLE semantic_relations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_word_id INTEGER NOT NULL,
    target_word_id INTEGER NOT NULL,
    relation_type TEXT NOT NULL,  -- 'hypernym', 'hyponym', 'synonym', 'antonym', etc.
    synset_id TEXT,  -- Related synset
    FOREIGN KEY (source_word_id) REFERENCES words(id) ON DELETE CASCADE,
    FOREIGN KEY (target_word_id) REFERENCES words(id) ON DELETE CASCADE
);

CREATE INDEX idx_semantic_source ON semantic_relations(source_word_id, relation_type);
CREATE INDEX idx_semantic_target ON semantic_relations(target_word_id);
```

---

### 2.2 Full-Text Search (FTS5) Implementation

FTS5 provides fast full-text search capabilities for dictionary lookups, autocomplete, and fuzzy matching.

#### FTS5 Table for Word Search

```sql
-- Create FTS5 virtual table for word search
CREATE VIRTUAL TABLE words_fts USING fts5(
    word,
    word_lower UNINDEXED,  -- Don't index, just store
    content='words',  -- Reference the words table
    content_rowid='id',  -- Map to words.id
    tokenize='unicode61 remove_diacritics 2'  -- Unicode tokenizer
);

-- Populate FTS5 table
INSERT INTO words_fts(rowid, word, word_lower)
SELECT id, word, word_lower FROM words;
```

#### FTS5 Table for Definition Search

```sql
-- Create FTS5 virtual table for searching definitions
CREATE VIRTUAL TABLE definitions_fts USING fts5(
    definition,
    example,
    word_id UNINDEXED,
    content='definitions',
    content_rowid='id',
    tokenize='porter unicode61'  -- Porter stemming for better matching
);

-- Populate FTS5 table
INSERT INTO definitions_fts(rowid, definition, example, word_id)
SELECT id, definition, example, word_id FROM definitions;
```

#### Triggers to Keep FTS5 in Sync

```sql
-- Insert trigger
CREATE TRIGGER words_ai AFTER INSERT ON words BEGIN
    INSERT INTO words_fts(rowid, word, word_lower)
    VALUES (new.id, new.word, new.word_lower);
END;

-- Update trigger
CREATE TRIGGER words_au AFTER UPDATE ON words BEGIN
    UPDATE words_fts SET word = new.word, word_lower = new.word_lower
    WHERE rowid = new.id;
END;

-- Delete trigger
CREATE TRIGGER words_ad AFTER DELETE ON words BEGIN
    DELETE FROM words_fts WHERE rowid = old.id;
END;

-- Similar triggers for definitions_fts
CREATE TRIGGER definitions_ai AFTER INSERT ON definitions BEGIN
    INSERT INTO definitions_fts(rowid, definition, example, word_id)
    VALUES (new.id, new.definition, new.example, new.word_id);
END;

CREATE TRIGGER definitions_au AFTER UPDATE ON definitions BEGIN
    UPDATE definitions_fts
    SET definition = new.definition, example = new.example, word_id = new.word_id
    WHERE rowid = new.id;
END;

CREATE TRIGGER definitions_ad AFTER DELETE ON definitions BEGIN
    DELETE FROM definitions_fts WHERE rowid = old.id;
END;
```

---

### 2.3 FTS5 Configuration Options

#### Tokenizer Selection

```sql
-- Unicode61 (default) - Multilingual support with diacritic removal
CREATE VIRTUAL TABLE words_fts USING fts5(
    word,
    tokenize='unicode61 remove_diacritics 2'
);

-- ASCII - Faster for English-only dictionaries
CREATE VIRTUAL TABLE words_fts USING fts5(
    word,
    tokenize='ascii'
);

-- Porter - Stemming for better search matches (e.g., "running" matches "run")
CREATE VIRTUAL TABLE words_fts USING fts5(
    word,
    tokenize='porter unicode61'
);

-- Trigram - For substring/fuzzy matching and autocomplete
CREATE VIRTUAL TABLE words_trigram USING fts5(
    word,
    tokenize='trigram',
    detail='none'  -- Reduces index size for LIKE queries
);
```

#### Prefix Indexes for Autocomplete

```sql
-- Enable prefix indexing for fast autocomplete
CREATE VIRTUAL TABLE words_fts USING fts5(
    word,
    prefix='2 3 4',  -- Index 2, 3, and 4-character prefixes
    tokenize='unicode61'
);

-- Query with prefix
SELECT word FROM words_fts WHERE word MATCH '^dict*' LIMIT 10;
```

#### Content Options for Size Reduction

```sql
-- Contentless FTS5 (smallest size, index only)
CREATE VIRTUAL TABLE words_fts USING fts5(
    word,
    content=''
);

-- Must manually insert with explicit rowid
INSERT INTO words_fts(rowid, word) VALUES (1, 'dictionary');

-- External content (recommended for dictionaries)
CREATE VIRTUAL TABLE words_fts USING fts5(
    word,
    content='words',
    content_rowid='id'
);
```

---

### 2.4 Alternative Schema: Denormalized (Simpler, Faster Reads)

For smaller dictionaries or when prioritizing query performance over normalization:

```sql
CREATE TABLE dictionary (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    word TEXT NOT NULL UNIQUE COLLATE NOCASE,
    word_lower TEXT NOT NULL,
    part_of_speech TEXT,
    definition TEXT NOT NULL,
    example TEXT,
    pronunciation_ipa TEXT,
    etymology TEXT,
    frequency_rank INTEGER DEFAULT 0,
    synonyms TEXT,  -- Comma-separated
    antonyms TEXT,  -- Comma-separated
    synset_id TEXT
);

CREATE INDEX idx_dictionary_word_lower ON dictionary(word_lower);
CREATE INDEX idx_dictionary_pos ON dictionary(part_of_speech);

-- FTS5 for full-text search
CREATE VIRTUAL TABLE dictionary_fts USING fts5(
    word,
    definition,
    example,
    content='dictionary',
    content_rowid='id',
    tokenize='porter unicode61'
);
```

**Pros**: Simpler queries, faster single-word lookups, easier to manage
**Cons**: Data duplication for words with multiple definitions, larger database size

---

## 3. Data Processing

### 3.1 Parsing WordNet 3.1 Data Files

#### Understanding WordNet File Format

**Synset Data Files** (`data.noun`, `data.verb`, `data.adj`, `data.adv`):
```
synset_offset lex_filenum ss_type w_cnt word lex_id [word lex_id...] p_cnt [ptr...] [frames...] | gloss
```

Example:
```
00001740 03 n 01 entity 0 001 @ 00001930 n 0000 | that which is perceived or known...
```

**Index Files** (`index.noun`, `index.verb`, etc.):
```
lemma pos synset_cnt p_cnt [ptr_symbol...] sense_cnt tagsense_cnt synset_offset [synset_offset...]
```

#### Python Script to Parse WordNet

```python
import sqlite3
import re
from pathlib import Path

class WordNetParser:
    """Parse WordNet data files and create SQLite database"""

    def __init__(self, wordnet_dir, db_path):
        self.wordnet_dir = Path(wordnet_dir)
        self.db_path = db_path
        self.conn = None
        self.cursor = None

        # Part of speech mapping
        self.pos_map = {
            'n': 'noun',
            'v': 'verb',
            'a': 'adjective',
            's': 'adjective satellite',
            'r': 'adverb'
        }

    def create_schema(self):
        """Create database schema"""
        self.conn = sqlite3.connect(self.db_path)
        self.cursor = self.conn.cursor()

        # Create tables
        self.cursor.executescript('''
            CREATE TABLE IF NOT EXISTS words (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                word TEXT NOT NULL UNIQUE COLLATE NOCASE,
                word_lower TEXT NOT NULL,
                frequency_rank INTEGER DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS definitions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                word_id INTEGER NOT NULL,
                definition TEXT NOT NULL,
                part_of_speech TEXT,
                sense_number INTEGER DEFAULT 1,
                example TEXT,
                synset_id TEXT,
                FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_words_lower ON words(word_lower);
            CREATE INDEX IF NOT EXISTS idx_definitions_word_id ON definitions(word_id);
        ''')
        self.conn.commit()

    def parse_synset_line(self, line):
        """Parse a synset line from data.* file"""
        if line.startswith('  ') or not line.strip():
            return None

        # Split on pipe to separate synset data from gloss
        parts = line.split('|')
        if len(parts) < 2:
            return None

        synset_data = parts[0].strip().split()
        gloss = parts[1].strip()

        # Extract synset offset, part of speech, and word count
        synset_offset = synset_data[0]
        pos = synset_data[2]
        word_count = int(synset_data[3], 16)  # Hex format

        # Extract words
        words = []
        idx = 4
        for _ in range(word_count):
            word = synset_data[idx].replace('_', ' ')
            words.append(word)
            idx += 2  # Skip lex_id

        # Extract definition and examples from gloss
        definition = gloss
        examples = []

        # Examples are typically in quotes after the definition
        if '"' in gloss:
            def_part = gloss.split('"')[0].strip()
            example_matches = re.findall(r'"([^"]*)"', gloss)
            definition = def_part
            examples = example_matches

        return {
            'synset_id': f"{pos}.{synset_offset}",
            'words': words,
            'pos': self.pos_map.get(pos, pos),
            'definition': definition,
            'examples': examples
        }

    def parse_data_file(self, filename):
        """Parse a WordNet data.* file"""
        file_path = self.wordnet_dir / filename

        if not file_path.exists():
            print(f"Warning: {filename} not found")
            return []

        synsets = []
        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                synset = self.parse_synset_line(line)
                if synset:
                    synsets.append(synset)

        return synsets

    def insert_synsets(self, synsets):
        """Insert synsets into database"""
        word_map = {}  # Track word_id for each word

        for synset in synsets:
            synset_id = synset['synset_id']
            pos = synset['pos']
            definition = synset['definition']
            examples = synset['examples']

            for word in synset['words']:
                word_lower = word.lower()

                # Insert or get word ID
                if word_lower not in word_map:
                    self.cursor.execute(
                        'INSERT OR IGNORE INTO words (word, word_lower) VALUES (?, ?)',
                        (word, word_lower)
                    )
                    self.cursor.execute(
                        'SELECT id FROM words WHERE word_lower = ?',
                        (word_lower,)
                    )
                    word_id = self.cursor.fetchone()[0]
                    word_map[word_lower] = word_id
                else:
                    word_id = word_map[word_lower]

                # Insert definition
                example_text = '; '.join(examples) if examples else None
                self.cursor.execute('''
                    INSERT INTO definitions
                    (word_id, definition, part_of_speech, example, synset_id)
                    VALUES (?, ?, ?, ?, ?)
                ''', (word_id, definition, pos, example_text, synset_id))

        self.conn.commit()

    def process_all_files(self):
        """Process all WordNet data files"""
        print("Creating schema...")
        self.create_schema()

        data_files = ['data.noun', 'data.verb', 'data.adj', 'data.adv']

        for filename in data_files:
            print(f"Processing {filename}...")
            synsets = self.parse_data_file(filename)
            print(f"  Found {len(synsets)} synsets")
            self.insert_synsets(synsets)
            print(f"  Inserted into database")

        # Create FTS5 tables
        print("Creating FTS5 indexes...")
        self.cursor.executescript('''
            CREATE VIRTUAL TABLE IF NOT EXISTS words_fts USING fts5(
                word,
                content='words',
                content_rowid='id',
                tokenize='unicode61 remove_diacritics 2'
            );

            INSERT INTO words_fts(rowid, word)
            SELECT id, word FROM words;

            CREATE VIRTUAL TABLE IF NOT EXISTS definitions_fts USING fts5(
                definition,
                example,
                content='definitions',
                content_rowid='id',
                tokenize='porter unicode61'
            );

            INSERT INTO definitions_fts(rowid, definition, example)
            SELECT id, definition, example FROM definitions;
        ''')
        self.conn.commit()

        print("Done!")
        self.conn.close()

# Usage
if __name__ == '__main__':
    parser = WordNetParser(
        wordnet_dir='/path/to/wordnet/dict',
        db_path='dictionary.db'
    )
    parser.process_all_files()
```

---

### 3.2 Parsing Wiktionary XML Dumps

#### Using Wiktextract (Recommended)

**Installation**:
```bash
pip install wiktextract
```

**Processing Wiktionary**:
```python
from wiktextract import parse_wiktionary
import json
import sqlite3

def process_wiktionary_dump(dump_path, db_path, language='en'):
    """Extract Wiktionary data and insert into SQLite"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Process dump and extract data
    print("Processing Wiktionary dump (this may take hours)...")

    with open('wiktionary_extract.jsonl', 'w', encoding='utf-8') as out_f:
        for entry in parse_wiktionary(dump_path, [language]):
            json.dump(entry, out_f)
            out_f.write('\n')

    print("Inserting into database...")

    # Read extracted JSONL and insert into database
    with open('wiktionary_extract.jsonl', 'r', encoding='utf-8') as f:
        for line in f:
            entry = json.loads(line)

            word = entry.get('word', '')
            pos = entry.get('pos', '')

            # Insert word
            cursor.execute(
                'INSERT OR IGNORE INTO words (word, word_lower) VALUES (?, ?)',
                (word, word.lower())
            )
            cursor.execute(
                'SELECT id FROM words WHERE word_lower = ?',
                (word.lower(),)
            )
            word_id = cursor.fetchone()[0]

            # Insert definitions (senses)
            for sense in entry.get('senses', []):
                definition = sense.get('glosses', [''])[0]
                examples = sense.get('examples', [])

                if definition:
                    cursor.execute('''
                        INSERT INTO definitions
                        (word_id, definition, part_of_speech, example)
                        VALUES (?, ?, ?, ?)
                    ''', (word_id, definition, pos,
                          '; '.join([ex.get('text', '') for ex in examples])))

            # Insert pronunciation
            for sound in entry.get('sounds', []):
                ipa = sound.get('ipa')
                if ipa:
                    cursor.execute('''
                        INSERT INTO pronunciations (word_id, ipa)
                        VALUES (?, ?)
                    ''', (word_id, ipa))

            # Insert etymology
            etymology = entry.get('etymology_text')
            if etymology:
                cursor.execute('''
                    INSERT INTO etymologies (word_id, etymology)
                    VALUES (?, ?)
                ''', (word_id, etymology))

    conn.commit()
    conn.close()
    print("Done!")

# Usage
process_wiktionary_dump(
    dump_path='enwiktionary-latest-pages-articles.xml.bz2',
    db_path='dictionary.db',
    language='en'
)
```

**Alternative: Use Pre-extracted Data** (Much Faster):
```python
import json
import sqlite3
import gzip

def import_kaikki_data(jsonl_path, db_path):
    """Import pre-extracted Wiktionary data from kaikki.org"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Download from https://kaikki.org/dictionary/English/kaikki.org-dictionary-English.json

    with gzip.open(jsonl_path, 'rt', encoding='utf-8') as f:
        for line in f:
            entry = json.loads(line)

            # Process entry (similar to above)
            # ...

    conn.commit()
    conn.close()
```

---

### 3.3 Processing CMU Pronunciation Dictionary

```python
import sqlite3

def import_cmu_ipa(cmu_ipa_path, db_path):
    """Import CMU Pronouncing Dictionary with IPA transcriptions"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    with open(cmu_ipa_path, 'r', encoding='utf-8') as f:
        for line in f:
            if line.startswith(';;;') or not line.strip():
                continue

            # Format: word  ipa_transcription
            parts = line.strip().split(maxsplit=1)
            if len(parts) != 2:
                continue

            word, ipa = parts
            word_lower = word.lower()

            # Handle variants like WORD(2)
            variant = 1
            if '(' in word:
                word_clean = word.split('(')[0]
                variant_match = re.search(r'\((\d+)\)', word)
                if variant_match:
                    variant = int(variant_match.group(1))
                word_lower = word_clean.lower()

            # Get or create word ID
            cursor.execute(
                'INSERT OR IGNORE INTO words (word, word_lower) VALUES (?, ?)',
                (word_lower, word_lower)
            )
            cursor.execute(
                'SELECT id FROM words WHERE word_lower = ?',
                (word_lower,)
            )
            result = cursor.fetchone()
            if result:
                word_id = result[0]

                # Insert pronunciation
                cursor.execute('''
                    INSERT INTO pronunciations
                    (word_id, ipa, variant_number, region)
                    VALUES (?, ?, ?, ?)
                ''', (word_id, ipa, variant, 'us'))

    conn.commit()
    conn.close()
    print("CMU IPA data imported successfully")

# Usage
import_cmu_ipa('cmudict-ipa.txt', 'dictionary.db')
```

---

### 3.4 Data Cleaning and Normalization

```python
def clean_and_normalize(db_path):
    """Clean and normalize dictionary data"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("Cleaning data...")

    # 1. Remove profanity (optional)
    profanity_list = ['word1', 'word2']  # Load from file
    profanity_pattern = '|'.join(profanity_list)
    cursor.execute(f'''
        DELETE FROM words
        WHERE word_lower REGEXP ?
    ''', (profanity_pattern,))

    # 2. Remove single-letter words (except 'a' and 'I')
    cursor.execute('''
        DELETE FROM words
        WHERE LENGTH(word) = 1
        AND word_lower NOT IN ('a', 'i')
    ''')

    # 3. Remove words with special characters (keep hyphens and apostrophes)
    cursor.execute('''
        DELETE FROM words
        WHERE word_lower REGEXP '[^a-z\-'' ]'
    ''')

    # 4. Normalize whitespace in definitions
    cursor.execute('''
        UPDATE definitions
        SET definition = TRIM(REPLACE(REPLACE(definition, '\n', ' '), '  ', ' '))
    ''')

    # 5. Add sense numbers for multiple definitions
    cursor.execute('''
        WITH numbered AS (
            SELECT
                id,
                ROW_NUMBER() OVER (
                    PARTITION BY word_id, part_of_speech
                    ORDER BY id
                ) AS sense_num
            FROM definitions
        )
        UPDATE definitions
        SET sense_number = (
            SELECT sense_num FROM numbered WHERE numbered.id = definitions.id
        )
    ''')

    # 6. Calculate word frequency ranks (if you have frequency data)
    # cursor.execute('''...''')

    conn.commit()

    # 7. Vacuum to reclaim space
    print("Vacuuming database...")
    cursor.execute('VACUUM')

    conn.close()
    print("Cleaning complete")
```

---

## 4. Database Optimization

### 4.1 Index Optimization

```sql
-- Primary indexes (already created in schema)
CREATE INDEX IF NOT EXISTS idx_words_lower ON words(word_lower);
CREATE INDEX IF NOT EXISTS idx_words_frequency ON words(frequency_rank DESC);
CREATE INDEX IF NOT EXISTS idx_definitions_word_id ON definitions(word_id);
CREATE INDEX IF NOT EXISTS idx_definitions_pos ON definitions(part_of_speech);

-- Covering indexes for common queries
CREATE INDEX IF NOT EXISTS idx_words_cover ON words(word_lower, id, frequency_rank);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_definitions_word_pos
    ON definitions(word_id, part_of_speech);

-- Analyze tables for query planner
ANALYZE;
```

---

### 4.2 FTS5 Optimization

```sql
-- Rebuild FTS5 index for optimal structure
INSERT INTO words_fts(words_fts) VALUES('rebuild');
INSERT INTO definitions_fts(definitions_fts) VALUES('rebuild');

-- Optimize FTS5 index (merges all b-trees)
INSERT INTO words_fts(words_fts) VALUES('optimize');
INSERT INTO definitions_fts(definitions_fts) VALUES('optimize');

-- Configure automerge (default is 4)
INSERT INTO words_fts(words_fts, rank) VALUES('automerge', 8);

-- Delete FTS5 content if using external content table
-- This saves significant space since content is stored in main table
-- Already configured with content='words' in schema
```

---

### 4.3 Compression Techniques

#### 1. Using ZSTD Compression (sqlite-zstd extension)

```bash
# Install sqlite-zstd
pip install sqlite-zstd
```

```python
import sqlite3
from sqlite_zstd import load_zstd

conn = sqlite3.connect('dictionary.db')
load_zstd(conn)

# Enable compression on definitions table
conn.execute('''
    CREATE TABLE definitions_compressed (
        id INTEGER PRIMARY KEY,
        word_id INTEGER,
        definition BLOB,  -- Compressed
        -- ... other fields
    )
''')

# Compress existing data
conn.execute('''
    INSERT INTO definitions_compressed
    SELECT id, word_id, zstd_compress(definition, 3) as definition
    FROM definitions
''')

# Query (automatic decompression)
result = conn.execute('''
    SELECT zstd_decompress(definition) as definition
    FROM definitions_compressed
    WHERE word_id = ?
''', (word_id,)).fetchone()
```

**Benefits**: 50-95% size reduction with minimal performance impact

#### 2. Page Size Optimization

```sql
-- Set before creating tables (default is 4096)
PRAGMA page_size = 8192;  -- Larger pages = fewer seeks
VACUUM;
```

#### 3. Remove Unused Data

```sql
-- Remove unnecessary columns
ALTER TABLE definitions DROP COLUMN IF EXISTS unused_column;

-- Use detail='none' for FTS5 if phrase queries aren't needed
CREATE VIRTUAL TABLE words_fts USING fts5(
    word,
    detail='none',  -- Smaller index, no phrase/NEAR queries
    tokenize='unicode61'
);
```

---

### 4.4 Query Performance Optimization

#### Use Prepared Statements

```dart
// Drift example
@DriftAccessor(tables: [Words, Definitions])
class DictionaryDao extends DatabaseAccessor<DictionaryDatabase> {
  DictionaryDao(DictionaryDatabase db) : super(db);

  // Prepared statement (compiled once, reused)
  Future<Word?> getWord(String word) {
    return (select(words)..where((w) => w.wordLower.equals(word.toLowerCase())))
        .getSingleOrNull();
  }
}
```

#### Optimize Joins

```sql
-- Use covering index to avoid table lookup
EXPLAIN QUERY PLAN
SELECT w.word, d.definition
FROM words w
JOIN definitions d ON w.id = d.word_id
WHERE w.word_lower = 'dictionary';

-- If not using index, create:
CREATE INDEX idx_words_cover ON words(word_lower, id);
```

#### Limit Result Sets

```sql
-- Always use LIMIT for search results
SELECT word FROM words_fts
WHERE word MATCH 'dict*'
LIMIT 20;
```

---

### 4.5 Database Size Reduction

#### Typical Sizes After Optimization

| Dataset | Unoptimized | With FTS5 | + Indexes | Optimized | Compressed |
|---------|-------------|-----------|-----------|-----------|------------|
| WordNet 3.1 | 150 MB | 200 MB | 220 MB | 80 MB | 30-40 MB |
| Wiktionary (EN) | 2-3 GB | 3-4 GB | 4-5 GB | 1.5 GB | 500 MB - 1 GB |
| Combined | 300 MB | 400 MB | 450 MB | 150 MB | 50-80 MB |

#### Size Reduction Checklist

1. Use external content FTS5 tables (`content='table_name'`)
2. Set `detail='none'` for FTS5 if phrase queries not needed
3. Remove unused indexes
4. VACUUM after deletions
5. Use INTEGER PRIMARY KEY (alias for rowid)
6. Compress TEXT blobs with ZSTD for large fields
7. Normalize data (avoid duplication)
8. Remove low-frequency words if acceptable

```sql
-- Example: Remove words used less than X times (if you have frequency data)
DELETE FROM words WHERE frequency_rank < 100;
VACUUM;
```

---

## 5. Integration with Flutter

### 5.1 Bundling Database with App

#### Small Databases (< 10 MB)

**pubspec.yaml**:
```yaml
flutter:
  assets:
    - assets/dictionary.db
```

**Load on first launch**:
```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String dbName = 'dictionary.db';
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    // Check if database exists
    final exists = await databaseExists(path);

    if (!exists) {
      // Copy from assets
      print("Copying database from assets...");

      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Read from assets
      ByteData data = await rootBundle.load('assets/$dbName');
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes
      );

      // Write to disk
      await File(path).writeAsBytes(bytes, flush: true);
      print("Database copied successfully");
    } else {
      print("Database already exists");
    }

    // Open database
    return await openDatabase(path, readOnly: true);
  }
}
```

---

#### Large Databases (> 50 MB)

**Problem**: `rootBundle.load()` can fail with large files, and APK size limit is 100 MB on Google Play.

**Solution 1: Version-based copying (for databases 50-100 MB)**:

```dart
class DatabaseHelper {
  static const String dbName = 'dictionary.db';
  static const String versionFile = 'db_version.txt';
  static const int currentVersion = 1;

  Future<Database> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);
    final versionPath = join(dbPath, versionFile);

    // Check existing version
    int existingVersion = 0;
    if (await File(versionPath).exists()) {
      final versionStr = await File(versionPath).readAsString();
      existingVersion = int.tryParse(versionStr.trim()) ?? 0;
    }

    // Copy if needed
    if (existingVersion < currentVersion) {
      print("Updating database to version $currentVersion...");

      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Read asset version
      final assetVersion = await rootBundle.loadString('assets/$versionFile');
      final assetVersionNum = int.parse(assetVersion.trim());

      if (assetVersionNum > existingVersion) {
        // Copy database
        ByteData data = await rootBundle.load('assets/$dbName');
        Uint8List bytes = Uint8List.sublistView(data);
        await File(path).writeAsBytes(bytes, flush: true);

        // Update version
        await File(versionPath).writeAsString('$assetVersionNum', flush: true);
        print("Database updated");
      }
    }

    return await openDatabase(path, readOnly: true);
  }
}
```

**assets/db_version.txt**:
```
1
```

Increment this version number when you update the database.

---

**Solution 2: Download on first launch (> 100 MB)**:

```dart
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  static const String dbUrl = 'https://yourserver.com/dictionary.db';
  static const String dbName = 'dictionary.db';
  static const String dbVersionKey = 'db_version';
  static const int currentVersion = 1;

  Future<Database> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    // Check version
    final prefs = await SharedPreferences.getInstance();
    final existingVersion = prefs.getInt(dbVersionKey) ?? 0;

    if (existingVersion < currentVersion || !await File(path).exists()) {
      await _downloadDatabase(path);
      await prefs.setInt(dbVersionKey, currentVersion);
    }

    return await openDatabase(path, readOnly: true);
  }

  Future<void> _downloadDatabase(String path) async {
    print("Downloading dictionary database...");

    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {}

    // Download with progress
    final request = http.Request('GET', Uri.parse(dbUrl));
    final response = await request.send();

    final contentLength = response.contentLength ?? 0;
    var downloadedBytes = 0;

    final file = File(path);
    final sink = file.openWrite();

    await response.stream.map((chunk) {
      downloadedBytes += chunk.length;
      final progress = downloadedBytes / contentLength;
      print("Download progress: ${(progress * 100).toStringAsFixed(1)}%");
      return chunk;
    }).pipe(sink);

    await sink.flush();
    await sink.close();

    print("Download complete");
  }
}
```

---

**Solution 3: Split APK by architecture**:

```bash
# Build separate APKs for different architectures
flutter build apk --split-per-abi

# Results in smaller APKs:
# app-armeabi-v7a-release.apk
# app-arm64-v8a-release.apk
# app-x86_64-release.apk
```

---

**Solution 4: Android App Bundle (AAB) - Recommended**:

```bash
# Build App Bundle (Google Play will optimize for each device)
flutter build appbundle

# No 100 MB limit, and users download only what they need
```

---

### 5.2 Using Drift for Type-Safe Queries

**pubspec.yaml**:
```yaml
dependencies:
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.8.3

dev_dependencies:
  drift_dev: ^2.14.0
  build_runner: ^2.4.0
```

**build.yaml** (enable FTS5):
```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          sql:
            dialect: sqlite
            options:
              modules:
                - json1
                - fts5
```

---

**Define Tables** (`database.dart`):

```dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// Words table
class Words extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get word => text()();
  TextColumn get wordLower => text()();
  IntColumn get frequencyRank => integer().withDefault(const Constant(0))();
}

// Definitions table
class Definitions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wordId => integer().references(Words, #id, onDelete: KeyAction.cascade)();
  TextColumn get definition => text()();
  TextColumn get partOfSpeech => text().nullable()();
  IntColumn get senseNumber => integer().withDefault(const Constant(1))();
  TextColumn get example => text().nullable()();
  TextColumn get synsetId => text().nullable()();
}

// Pronunciations table
class Pronunciations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wordId => integer().references(Words, #id, onDelete: KeyAction.cascade)();
  TextColumn get ipa => text()();
  IntColumn get variantNumber => integer().withDefault(const Constant(1))();
  TextColumn get region => text().nullable()();
}

// Database class
@DriftDatabase(tables: [Words, Definitions, Pronunciations])
class DictionaryDatabase extends _$DictionaryDatabase {
  DictionaryDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Word lookup
  Future<Word?> getWord(String word) {
    return (select(words)
      ..where((w) => w.wordLower.equals(word.toLowerCase()))
    ).getSingleOrNull();
  }

  // Get definitions for a word
  Future<List<Definition>> getDefinitions(int wordId) {
    return (select(definitions)
      ..where((d) => d.wordId.equals(wordId))
      ..orderBy([(d) => OrderingTerm(expression: d.senseNumber)])
    ).get();
  }

  // Full-text search
  Future<List<Word>> searchWords(String query) async {
    // Use FTS5 for search
    final results = await customSelect(
      '''
      SELECT w.* FROM words w
      JOIN words_fts fts ON w.id = fts.rowid
      WHERE words_fts MATCH ?
      LIMIT 20
      ''',
      variables: [Variable.withString(query)],
      readsFrom: {words}
    ).map((row) => Word.fromData(row.data)).get();

    return results;
  }

  // Prefix search for autocomplete
  Future<List<String>> autocomplete(String prefix) async {
    final results = await customSelect(
      '''
      SELECT word FROM words
      WHERE word_lower LIKE ? || '%'
      ORDER BY frequency_rank DESC
      LIMIT 10
      ''',
      variables: [Variable.withString(prefix.toLowerCase())]
    ).get();

    return results.map((row) => row.read<String>('word')).toList();
  }

  // Get complete word entry with definitions and pronunciations
  Future<WordEntry> getCompleteEntry(String word) async {
    final wordEntry = await getWord(word);
    if (wordEntry == null) return WordEntry.empty();

    final defs = await getDefinitions(wordEntry.id);

    final pronuns = await (select(pronunciations)
      ..where((p) => p.wordId.equals(wordEntry.id))
    ).get();

    return WordEntry(
      word: wordEntry,
      definitions: defs,
      pronunciations: pronuns,
    );
  }
}

// Helper class for complete word entry
class WordEntry {
  final Word word;
  final List<Definition> definitions;
  final List<Pronunciation> pronunciations;

  WordEntry({
    required this.word,
    required this.definitions,
    required this.pronunciations,
  });

  factory WordEntry.empty() => WordEntry(
    word: Word(id: 0, word: '', wordLower: '', frequencyRank: 0),
    definitions: [],
    pronunciations: [],
  );
}

// Connection helper
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'dictionary.db'));
    return NativeDatabase(file);
  });
}
```

**Generate code**:
```bash
flutter pub run build_runner build
```

---

**Usage in UI**:

```dart
import 'package:flutter/material.dart';
import 'database.dart';

class DictionaryScreen extends StatefulWidget {
  @override
  _DictionaryScreenState createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final DictionaryDatabase _db = DictionaryDatabase();
  final TextEditingController _searchController = TextEditingController();

  WordEntry? _currentEntry;
  List<String> _suggestions = [];
  bool _loading = false;

  @override
  void dispose() {
    _db.close();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchWord(String word) async {
    if (word.isEmpty) return;

    setState(() => _loading = true);

    try {
      final entry = await _db.getCompleteEntry(word);
      setState(() {
        _currentEntry = entry;
        _suggestions = [];
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateAutocomplete(String prefix) async {
    if (prefix.length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    final suggestions = await _db.autocomplete(prefix);
    setState(() => _suggestions = suggestions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dictionary')),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a word...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _searchWord(_searchController.text),
                ),
              ),
              onChanged: _updateAutocomplete,
              onSubmitted: _searchWord,
            ),
          ),

          // Autocomplete suggestions
          if (_suggestions.isNotEmpty)
            Container(
              height: 200,
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    title: Text(suggestion),
                    onTap: () {
                      _searchController.text = suggestion;
                      _searchWord(suggestion);
                    },
                  );
                },
              ),
            ),

          // Results
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : _currentEntry == null
                    ? Center(child: Text('Search for a word'))
                    : _buildWordEntry(_currentEntry!),
          ),
        ],
      ),
    );
  }

  Widget _buildWordEntry(WordEntry entry) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Word
        Text(
          entry.word.word,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),

        // Pronunciations
        if (entry.pronunciations.isNotEmpty)
          ...entry.pronunciations.map((p) => Text(
            '/${p.ipa}/',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          )),

        SizedBox(height: 16),

        // Definitions
        ...entry.definitions.map((def) => Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Part of speech
              if (def.partOfSpeech != null)
                Text(
                  def.partOfSpeech!,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.blue,
                  ),
                ),

              SizedBox(height: 4),

              // Sense number and definition
              Text(
                '${def.senseNumber}. ${def.definition}',
                style: TextStyle(fontSize: 16),
              ),

              // Example
              if (def.example != null)
                Padding(
                  padding: EdgeInsets.only(left: 16, top: 8),
                  child: Text(
                    '"${def.example}"',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
            ],
          ),
        )),
      ],
    );
  }
}
```

---

### 5.3 Performance Best Practices

#### 1. Use Database Connection Pooling

```dart
// Singleton pattern for database instance
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  DictionaryDatabase? _database;

  Future<DictionaryDatabase> get database async {
    if (_database != null) return _database!;
    _database = DictionaryDatabase();
    return _database!;
  }
}
```

#### 2. Use Isolates for Heavy Queries

```dart
import 'dart:isolate';

Future<List<Word>> searchInIsolate(String query) async {
  final receivePort = ReceivePort();

  await Isolate.spawn(_searchIsolate, receivePort.sendPort);

  final sendPort = await receivePort.first as SendPort;
  final responsePort = ReceivePort();

  sendPort.send([query, responsePort.sendPort]);

  final results = await responsePort.first as List<Word>;
  return results;
}

void _searchIsolate(SendPort sendPort) async {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  await for (final message in receivePort) {
    final query = message[0] as String;
    final replyPort = message[1] as SendPort;

    final db = DictionaryDatabase();
    final results = await db.searchWords(query);

    replyPort.send(results);
  }
}
```

#### 3. Cache Frequently Accessed Words

```dart
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class DictionaryCache {
  final Map<String, WordEntry> _cache = {};
  final int maxSize = 100;

  WordEntry? get(String word) => _cache[word.toLowerCase()];

  void put(String word, WordEntry entry) {
    final key = word.toLowerCase();

    // Evict oldest if cache full
    if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = entry;
  }

  void clear() => _cache.clear();
}
```

#### 4. Lazy Load Definitions

```dart
// Load word first, then definitions on demand
class WordEntryProvider extends ChangeNotifier {
  Word? _word;
  List<Definition>? _definitions;
  bool _definitionsLoaded = false;

  Future<void> loadWord(String word) async {
    _word = await db.getWord(word);
    _definitionsLoaded = false;
    notifyListeners();
  }

  Future<void> loadDefinitions() async {
    if (!_definitionsLoaded && _word != null) {
      _definitions = await db.getDefinitions(_word!.id);
      _definitionsLoaded = true;
      notifyListeners();
    }
  }
}
```

---

## 6. Implementation Examples

### 6.1 Complete SQL Schema

```sql
-- ============================================
-- Complete Dictionary Database Schema
-- ============================================

-- Core tables
CREATE TABLE words (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    word TEXT NOT NULL UNIQUE COLLATE NOCASE,
    word_lower TEXT NOT NULL,
    frequency_rank INTEGER DEFAULT 0,
    created_at INTEGER DEFAULT (strftime('%s', 'now'))
);

CREATE TABLE definitions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    word_id INTEGER NOT NULL,
    definition TEXT NOT NULL,
    part_of_speech TEXT,
    sense_number INTEGER DEFAULT 1,
    example TEXT,
    synset_id TEXT,
    FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
);

CREATE TABLE pronunciations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    word_id INTEGER NOT NULL,
    ipa TEXT NOT NULL,
    variant_number INTEGER DEFAULT 1,
    region TEXT,
    FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
);

CREATE TABLE etymologies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    word_id INTEGER NOT NULL,
    etymology TEXT NOT NULL,
    language_origin TEXT,
    FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
);

CREATE TABLE semantic_relations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_word_id INTEGER NOT NULL,
    target_word_id INTEGER NOT NULL,
    relation_type TEXT NOT NULL,
    synset_id TEXT,
    FOREIGN KEY (source_word_id) REFERENCES words(id) ON DELETE CASCADE,
    FOREIGN KEY (target_word_id) REFERENCES words(id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_words_lower ON words(word_lower);
CREATE INDEX idx_words_frequency ON words(frequency_rank DESC);
CREATE INDEX idx_definitions_word_id ON definitions(word_id);
CREATE INDEX idx_definitions_pos ON definitions(part_of_speech);
CREATE INDEX idx_definitions_word_pos ON definitions(word_id, part_of_speech);
CREATE INDEX idx_pronunciations_word_id ON pronunciations(word_id);
CREATE INDEX idx_etymologies_word_id ON etymologies(word_id);
CREATE INDEX idx_semantic_source ON semantic_relations(source_word_id, relation_type);
CREATE INDEX idx_semantic_target ON semantic_relations(target_word_id);

-- FTS5 tables
CREATE VIRTUAL TABLE words_fts USING fts5(
    word,
    content='words',
    content_rowid='id',
    tokenize='unicode61 remove_diacritics 2',
    prefix='2 3 4'
);

CREATE VIRTUAL TABLE definitions_fts USING fts5(
    definition,
    example,
    content='definitions',
    content_rowid='id',
    tokenize='porter unicode61'
);

-- Triggers to keep FTS5 in sync
CREATE TRIGGER words_ai AFTER INSERT ON words BEGIN
    INSERT INTO words_fts(rowid, word) VALUES (new.id, new.word);
END;

CREATE TRIGGER words_au AFTER UPDATE ON words BEGIN
    UPDATE words_fts SET word = new.word WHERE rowid = new.id;
END;

CREATE TRIGGER words_ad AFTER DELETE ON words BEGIN
    DELETE FROM words_fts WHERE rowid = old.id;
END;

CREATE TRIGGER definitions_ai AFTER INSERT ON definitions BEGIN
    INSERT INTO definitions_fts(rowid, definition, example)
    VALUES (new.id, new.definition, new.example);
END;

CREATE TRIGGER definitions_au AFTER UPDATE ON definitions BEGIN
    UPDATE definitions_fts
    SET definition = new.definition, example = new.example
    WHERE rowid = new.id;
END;

CREATE TRIGGER definitions_ad AFTER DELETE ON definitions BEGIN
    DELETE FROM definitions_fts WHERE rowid = old.id;
END;

-- Trigram table for fuzzy search (optional)
CREATE VIRTUAL TABLE words_trigram USING fts5(
    word,
    content='words',
    content_rowid='id',
    tokenize='trigram',
    detail='none'
);

-- Spellfix table for typo correction (requires spellfix1 extension)
CREATE VIRTUAL TABLE words_spellfix USING spellfix1;

-- Populate spellfix from words
INSERT INTO words_spellfix(word, rank)
SELECT word, frequency_rank FROM words;
```

---

### 6.2 Query Examples

#### Basic Word Lookup

```sql
-- Get word by exact match
SELECT * FROM words WHERE word_lower = 'dictionary';

-- Get word with all definitions
SELECT
    w.word,
    d.part_of_speech,
    d.sense_number,
    d.definition,
    d.example
FROM words w
JOIN definitions d ON w.id = d.word_id
WHERE w.word_lower = 'dictionary'
ORDER BY d.sense_number;

-- Get complete word entry
SELECT
    w.word,
    w.frequency_rank,
    d.part_of_speech,
    d.sense_number,
    d.definition,
    d.example,
    p.ipa,
    e.etymology
FROM words w
LEFT JOIN definitions d ON w.id = d.word_id
LEFT JOIN pronunciations p ON w.id = p.word_id
LEFT JOIN etymologies e ON w.id = e.word_id
WHERE w.word_lower = 'dictionary'
ORDER BY d.sense_number, p.variant_number;
```

---

#### Full-Text Search

```sql
-- Search words containing pattern
SELECT w.word FROM words w
JOIN words_fts fts ON w.id = fts.rowid
WHERE words_fts MATCH 'dict*'
ORDER BY w.frequency_rank DESC
LIMIT 20;

-- Search definitions
SELECT
    w.word,
    d.definition,
    snippet(definitions_fts, 0, '<b>', '</b>', '...', 30) as snippet
FROM definitions d
JOIN definitions_fts fts ON d.id = fts.rowid
JOIN words w ON d.word_id = w.id
WHERE definitions_fts MATCH 'knowledge'
LIMIT 20;

-- Combined word and definition search
SELECT DISTINCT w.word, w.frequency_rank
FROM words w
LEFT JOIN words_fts wfts ON w.id = wfts.rowid
LEFT JOIN definitions d ON w.id = d.word_id
LEFT JOIN definitions_fts dfts ON d.id = dfts.rowid
WHERE words_fts MATCH 'scienc*' OR definitions_fts MATCH 'scienc*'
ORDER BY w.frequency_rank DESC
LIMIT 20;
```

---

#### Autocomplete / Prefix Search

```sql
-- Simple prefix match
SELECT word FROM words
WHERE word_lower LIKE 'dict%'
ORDER BY frequency_rank DESC
LIMIT 10;

-- FTS5 prefix match (faster for large datasets)
SELECT w.word FROM words w
JOIN words_fts fts ON w.id = fts.rowid
WHERE words_fts MATCH '^dict*'
ORDER BY w.frequency_rank DESC
LIMIT 10;

-- Trigram-based autocomplete (handles typos)
SELECT w.word,
       length(w.word) - length('dictonary') as len_diff
FROM words w
JOIN words_trigram tri ON w.id = tri.rowid
WHERE words_trigram MATCH 'dictonary'
ORDER BY len_diff, w.frequency_rank DESC
LIMIT 10;
```

---

#### Fuzzy Matching / Typo Tolerance

```sql
-- Using Spellfix1 extension
SELECT word, distance, score
FROM words_spellfix
WHERE word MATCH 'dictonary'  -- misspelled
AND top = 5
ORDER BY score;

-- Returns suggestions: dictionary, dictionaries, etc.

-- Trigram-based fuzzy search
SELECT DISTINCT w.word
FROM words w
JOIN words_trigram tri ON w.id = tri.rowid
WHERE words_trigram MATCH 'dictinary'  -- misspelled
LIMIT 10;
```

---

#### Semantic Relations

```sql
-- Get synonyms (words in same synset)
SELECT DISTINCT w2.word as synonym
FROM words w1
JOIN definitions d1 ON w1.id = d1.word_id
JOIN definitions d2 ON d1.synset_id = d2.synset_id AND d2.word_id != w1.id
JOIN words w2 ON d2.word_id = w2.id
WHERE w1.word_lower = 'dog' AND d1.part_of_speech = 'noun';

-- Get hypernyms (parent concepts)
SELECT DISTINCT w2.word as hypernym
FROM words w1
JOIN semantic_relations sr ON w1.id = sr.source_word_id
JOIN words w2 ON sr.target_word_id = w2.id
WHERE w1.word_lower = 'dog' AND sr.relation_type = 'hypernym';

-- Get hyponyms (child concepts)
SELECT DISTINCT w2.word as hyponym
FROM words w1
JOIN semantic_relations sr ON w1.id = sr.source_word_id
JOIN words w2 ON sr.target_word_id = w2.id
WHERE w1.word_lower = 'animal' AND sr.relation_type = 'hyponym'
ORDER BY w2.frequency_rank DESC
LIMIT 20;
```

---

### 6.3 Data Import Script (Python)

Complete script combining WordNet + CMU Dictionary:

```python
#!/usr/bin/env python3
"""
Complete Dictionary Database Builder
Combines WordNet 3.1 + CMU Pronouncing Dictionary (IPA)
"""

import sqlite3
import re
from pathlib import Path
from typing import List, Dict, Optional

class DictionaryBuilder:
    """Build comprehensive dictionary database from multiple sources"""

    def __init__(self, db_path: str):
        self.db_path = db_path
        self.conn = None
        self.cursor = None
        self.word_cache = {}  # word_lower -> word_id mapping

    def create_schema(self):
        """Create complete database schema"""
        print("Creating database schema...")

        self.conn = sqlite3.connect(self.db_path)
        self.cursor = self.conn.cursor()

        # Read schema from file or inline
        schema_sql = open('schema.sql', 'r').read()
        self.cursor.executescript(schema_sql)

        self.conn.commit()
        print("Schema created")

    def import_wordnet(self, wordnet_dir: str):
        """Import WordNet 3.1 data"""
        print("\nImporting WordNet data...")

        wordnet_path = Path(wordnet_dir)
        pos_map = {
            'n': 'noun',
            'v': 'verb',
            'a': 'adjective',
            's': 'adjective satellite',
            'r': 'adverb'
        }

        data_files = ['data.noun', 'data.verb', 'data.adj', 'data.adv']
        total_synsets = 0

        for data_file in data_files:
            file_path = wordnet_path / data_file
            if not file_path.exists():
                print(f"  Warning: {data_file} not found")
                continue

            print(f"  Processing {data_file}...")
            synset_count = 0

            with open(file_path, 'r', encoding='utf-8') as f:
                for line in f:
                    # Skip comments and empty lines
                    if line.startswith('  ') or not line.strip():
                        continue

                    synset = self._parse_synset_line(line)
                    if synset:
                        self._insert_synset(synset, pos_map)
                        synset_count += 1

            print(f"    Imported {synset_count} synsets")
            total_synsets += synset_count

        self.conn.commit()
        print(f"Total synsets imported: {total_synsets}")

    def _parse_synset_line(self, line: str) -> Optional[Dict]:
        """Parse a WordNet synset line"""
        try:
            # Split on pipe to separate data from gloss
            parts = line.split('|')
            if len(parts) < 2:
                return None

            synset_data = parts[0].strip().split()
            gloss = parts[1].strip()

            # Extract basic info
            synset_offset = synset_data[0]
            pos = synset_data[2]
            word_count = int(synset_data[3], 16)

            # Extract words
            words = []
            idx = 4
            for _ in range(word_count):
                word = synset_data[idx].replace('_', ' ')
                words.append(word)
                idx += 2

            # Parse gloss for definition and examples
            definition = gloss
            examples = []

            if '"' in gloss:
                def_part = gloss.split('"')[0].strip()
                example_matches = re.findall(r'"([^"]*)"', gloss)
                definition = def_part
                examples = example_matches

            return {
                'synset_id': f"{pos}.{synset_offset}",
                'pos': pos,
                'words': words,
                'definition': definition,
                'examples': examples
            }
        except Exception as e:
            print(f"    Error parsing line: {e}")
            return None

    def _insert_synset(self, synset: Dict, pos_map: Dict):
        """Insert a synset into database"""
        synset_id = synset['synset_id']
        pos = pos_map.get(synset['pos'], synset['pos'])
        definition = synset['definition']
        examples = synset['examples']

        for word_text in synset['words']:
            # Get or create word
            word_id = self._get_or_create_word(word_text)

            # Check if this exact definition already exists
            self.cursor.execute('''
                SELECT id FROM definitions
                WHERE word_id = ? AND synset_id = ?
            ''', (word_id, synset_id))

            if not self.cursor.fetchone():
                # Determine sense number
                self.cursor.execute('''
                    SELECT COALESCE(MAX(sense_number), 0) + 1
                    FROM definitions
                    WHERE word_id = ? AND part_of_speech = ?
                ''', (word_id, pos))
                sense_number = self.cursor.fetchone()[0]

                # Insert definition
                example_text = '; '.join(examples) if examples else None
                self.cursor.execute('''
                    INSERT INTO definitions
                    (word_id, definition, part_of_speech, sense_number, example, synset_id)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (word_id, definition, pos, sense_number, example_text, synset_id))

    def _get_or_create_word(self, word: str) -> int:
        """Get existing word ID or create new word"""
        word_lower = word.lower()

        # Check cache
        if word_lower in self.word_cache:
            return self.word_cache[word_lower]

        # Check database
        self.cursor.execute(
            'SELECT id FROM words WHERE word_lower = ?',
            (word_lower,)
        )
        result = self.cursor.fetchone()

        if result:
            word_id = result[0]
        else:
            # Insert new word
            self.cursor.execute(
                'INSERT INTO words (word, word_lower) VALUES (?, ?)',
                (word, word_lower)
            )
            word_id = self.cursor.lastrowid

        # Cache it
        self.word_cache[word_lower] = word_id
        return word_id

    def import_cmu_ipa(self, cmu_ipa_path: str):
        """Import CMU Pronouncing Dictionary (IPA format)"""
        print("\nImporting CMU pronunciation data...")

        ipa_file = Path(cmu_ipa_path)
        if not ipa_file.exists():
            print("  CMU IPA file not found, skipping")
            return

        count = 0
        with open(ipa_file, 'r', encoding='utf-8') as f:
            for line in f:
                # Skip comments
                if line.startswith(';;;') or not line.strip():
                    continue

                # Parse: word  ipa_transcription
                parts = line.strip().split(maxsplit=1)
                if len(parts) != 2:
                    continue

                word_text, ipa = parts
                variant = 1

                # Handle variants like WORD(2)
                if '(' in word_text:
                    word_clean = word_text.split('(')[0]
                    variant_match = re.search(r'\((\d+)\)', word_text)
                    if variant_match:
                        variant = int(variant_match.group(1))
                    word_text = word_clean

                word_lower = word_text.lower()

                # Get word ID if exists
                if word_lower not in self.word_cache:
                    self.cursor.execute(
                        'SELECT id FROM words WHERE word_lower = ?',
                        (word_lower,)
                    )
                    result = self.cursor.fetchone()
                    if not result:
                        continue  # Skip if word not in dictionary
                    self.word_cache[word_lower] = result[0]

                word_id = self.word_cache[word_lower]

                # Insert pronunciation
                self.cursor.execute('''
                    INSERT OR IGNORE INTO pronunciations
                    (word_id, ipa, variant_number, region)
                    VALUES (?, ?, ?, ?)
                ''', (word_id, ipa, variant, 'us'))

                count += 1

        self.conn.commit()
        print(f"  Imported {count} pronunciations")

    def clean_data(self):
        """Clean and normalize data"""
        print("\nCleaning data...")

        # Remove single-letter words (except a, i)
        self.cursor.execute('''
            DELETE FROM words
            WHERE LENGTH(word) = 1
            AND word_lower NOT IN ('a', 'i')
        ''')
        deleted = self.cursor.rowcount
        print(f"  Removed {deleted} single-letter words")

        # Normalize whitespace in definitions
        self.cursor.execute('''
            UPDATE definitions
            SET definition = TRIM(REPLACE(REPLACE(definition, '  ', ' '), '\n', ' '))
            WHERE definition LIKE '%  %' OR definition LIKE '%\n%'
        ''')

        self.conn.commit()
        print("  Data cleaned")

    def optimize(self):
        """Optimize database"""
        print("\nOptimizing database...")

        # Populate FTS5 tables
        print("  Populating FTS5 indexes...")
        self.cursor.executescript('''
            DELETE FROM words_fts;
            INSERT INTO words_fts(rowid, word)
            SELECT id, word FROM words;

            DELETE FROM definitions_fts;
            INSERT INTO definitions_fts(rowid, definition, example)
            SELECT id, definition, example FROM definitions;
        ''')

        # Optimize FTS5
        print("  Optimizing FTS5...")
        self.cursor.executescript('''
            INSERT INTO words_fts(words_fts) VALUES('optimize');
            INSERT INTO definitions_fts(definitions_fts) VALUES('optimize');
        ''')

        # Analyze for query planner
        print("  Analyzing tables...")
        self.cursor.execute('ANALYZE')

        # Vacuum
        print("  Vacuuming...")
        self.cursor.execute('VACUUM')

        self.conn.commit()
        print("  Optimization complete")

    def print_stats(self):
        """Print database statistics"""
        print("\nDatabase Statistics:")

        self.cursor.execute('SELECT COUNT(*) FROM words')
        word_count = self.cursor.fetchone()[0]
        print(f"  Total words: {word_count:,}")

        self.cursor.execute('SELECT COUNT(*) FROM definitions')
        def_count = self.cursor.fetchone()[0]
        print(f"  Total definitions: {def_count:,}")

        self.cursor.execute('SELECT COUNT(*) FROM pronunciations')
        pron_count = self.cursor.fetchone()[0]
        print(f"  Total pronunciations: {pron_count:,}")

        # File size
        import os
        size_mb = os.path.getsize(self.db_path) / (1024 * 1024)
        print(f"  Database size: {size_mb:.2f} MB")

    def close(self):
        """Close database connection"""
        if self.conn:
            self.conn.close()

# Main execution
if __name__ == '__main__':
    import sys

    if len(sys.argv) < 3:
        print("Usage: python build_dictionary.py <wordnet_dir> <cmu_ipa_file>")
        print("Example: python build_dictionary.py ./WordNet-3.0/dict ./cmudict-ipa.txt")
        sys.exit(1)

    wordnet_dir = sys.argv[1]
    cmu_ipa_file = sys.argv[2]

    builder = DictionaryBuilder('dictionary.db')

    try:
        builder.create_schema()
        builder.import_wordnet(wordnet_dir)
        builder.import_cmu_ipa(cmu_ipa_file)
        builder.clean_data()
        builder.optimize()
        builder.print_stats()
    finally:
        builder.close()

    print("\nDictionary database created successfully!")
```

**Save schema to `schema.sql`** (paste the complete schema from section 6.1)

**Run the script**:
```bash
python build_dictionary.py /path/to/WordNet-3.0/dict /path/to/cmudict-ipa.txt
```

---

### 6.4 Flutter Autocomplete Widget

```dart
import 'package:flutter/material.dart';
import 'database.dart';

class DictionaryAutocomplete extends StatefulWidget {
  final Function(String) onWordSelected;

  const DictionaryAutocomplete({
    Key? key,
    required this.onWordSelected,
  }) : super(key: key);

  @override
  _DictionaryAutocompleteState createState() => _DictionaryAutocompleteState();
}

class _DictionaryAutocompleteState extends State<DictionaryAutocomplete> {
  final DictionaryDatabase _db = DictionaryDatabase();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<String> _suggestions = [];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _updateSuggestions(String query) async {
    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _loading = true);

    try {
      final suggestions = await _db.autocomplete(query);
      setState(() {
        _suggestions = suggestions;
        _loading = false;
      });
    } catch (e) {
      print('Error fetching suggestions: $e');
      setState(() => _loading = false);
    }
  }

  void _selectSuggestion(String word) {
    _controller.text = word;
    setState(() => _suggestions = []);
    widget.onWordSelected(word);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search dictionary...',
            prefixIcon: Icon(Icons.search),
            suffixIcon: _loading
                ? Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _suggestions = []);
                        },
                      )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: _updateSuggestions,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              widget.onWordSelected(value);
              _focusNode.unfocus();
            }
          },
        ),

        if (_suggestions.isNotEmpty)
          Card(
            margin: EdgeInsets.only(top: 4),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    dense: true,
                    title: Text(suggestion),
                    onTap: () => _selectSuggestion(suggestion),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
```

---

## Summary and Recommendations

### Recommended Stack for Production

1. **Data Sources**:
   - Primary: WordNet 3.1 (definitions + semantic relationships)
   - Pronunciation: CMU Pronouncing Dictionary (IPA conversion)
   - Optional: Wiktionary subset for etymology

2. **Database**:
   - SQLite with FTS5 for full-text search
   - External content tables to minimize size
   - Spellfix1 extension for typo correction
   - Trigram tokenizer for fuzzy autocomplete

3. **Flutter Integration**:
   - Drift ORM for type-safe queries
   - Bundle database in assets for < 100 MB
   - Use Android App Bundle (AAB) for larger databases
   - Download on first launch for very large databases (> 100 MB)

4. **Optimizations**:
   - Use covering indexes
   - Compress with ZSTD if needed
   - Cache frequently accessed words
   - Use isolates for heavy queries
   - Lazy load definitions

### Expected Database Sizes

- **Minimal** (WordNet only, no FTS): ~40 MB
- **Standard** (WordNet + CMU + FTS5): ~80-100 MB
- **Compressed**: ~30-50 MB
- **Full** (Wiktionary subset + all features): ~150-200 MB

### Development Workflow

1. Download data sources
2. Run Python import script
3. Test queries and optimize
4. Bundle with Flutter app
5. Implement UI with autocomplete
6. Add caching and performance optimizations

---

## Additional Resources

- WordNet Documentation: https://wordnet.princeton.edu/
- SQLite FTS5: https://www.sqlite.org/fts5.html
- Drift ORM: https://drift.simonbinder.eu/
- Wiktextract: https://github.com/tatuylonen/wiktextract
- CMU IPA: https://github.com/menelik3/cmudict-ipa

---

**Last Updated**: 2025-01-14
**Version**: 1.0
