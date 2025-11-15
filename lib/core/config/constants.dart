class AppConstants {
  // App Info
  static const String appName = 'EPUB Reader';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'epub_reader.db';
  static const int databaseVersion = 1;
  static const String dictionaryDatabaseName = 'dictionary.db';

  // Storage
  static const String booksDirectory = 'books';
  static const String coversDirectory = 'covers';
  static const String cacheDirectory = 'cache';

  // Reading Settings Defaults
  static const double defaultFontSize = 16.0;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 48.0;
  static const double defaultLineHeight = 1.5;
  static const double defaultLetterSpacing = 0.0;
  static const double defaultParagraphSpacing = 1.0;

  // Theme
  static const String defaultTheme = 'system';
  static const String lightTheme = 'light';
  static const String darkTheme = 'dark';
  static const String sepiaTheme = 'sepia';

  // Cache
  static const int coverCacheSize = 100; // Number of covers to cache
  static const int chapterCacheSize = 5; // Number of chapters to cache
  static const int imageCacheSize = 50; // Number of images to cache
  static const int dictionaryCacheSize = 100; // Number of definitions to cache

  // Performance
  static const int libraryPageSize = 50; // Books per page in library
  static const int searchDebounceMs = 300; // Milliseconds to debounce search
  static const Duration autoSaveInterval = Duration(seconds: 10);

  // Dictionary
  static const int dictionarySuggestionLimit = 10;
  static const int dictionaryHistoryLimit = 1000;

  // File
  static const int maxFileSize = 100 * 1024 * 1024; // 100 MB
  static const List<String> supportedExtensions = ['.epub'];

  // Reading Progress
  static const double progressCompletionThreshold = 0.95; // 95% = completed

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // UI
  static const double defaultBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
}
