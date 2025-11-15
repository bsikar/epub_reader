import 'package:epub_reader/features/import/domain/usecases/import_epub.dart';
import 'package:epub_reader/injection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final importProvider = StateNotifierProvider<ImportNotifier, ImportState>((ref) {
  return ImportNotifier(getIt<ImportEpub>());
});

class ImportState {
  final bool isImporting;
  final String? error;
  final double progress;

  ImportState({
    this.isImporting = false,
    this.error,
    this.progress = 0.0,
  });

  ImportState copyWith({
    bool? isImporting,
    String? error,
    double? progress,
  }) {
    return ImportState(
      isImporting: isImporting ?? this.isImporting,
      error: error,
      progress: progress ?? this.progress,
    );
  }
}

class ImportNotifier extends StateNotifier<ImportState> {
  final ImportEpub _importEpub;

  ImportNotifier(this._importEpub) : super(ImportState());

  Future<bool> pickAndImportEpub() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        state = state.copyWith(error: 'Could not get file path');
        return false;
      }

      state = state.copyWith(isImporting: true, error: null, progress: 0.0);

      // Import EPUB
      final importResult = await _importEpub(filePath);

      return importResult.fold(
        (failure) {
          state = state.copyWith(
            isImporting: false,
            error: failure.message,
          );
          return false;
        },
        (book) {
          state = state.copyWith(
            isImporting: false,
            progress: 1.0,
          );
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(
        isImporting: false,
        error: 'Failed to import: $e',
      );
      return false;
    }
  }
}
