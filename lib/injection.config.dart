// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import 'core/database/app_database.dart' as _i111;
import 'core/services/storage_path_service.dart' as _i476;
import 'features/import/domain/usecases/import_epub.dart' as _i369;
import 'features/library/data/datasources/library_local_datasource.dart'
    as _i856;
import 'features/library/data/repositories/library_repository_impl.dart'
    as _i1002;
import 'features/library/domain/repositories/library_repository.dart' as _i921;
import 'features/library/domain/usecases/delete_book.dart' as _i120;
import 'features/library/domain/usecases/get_all_books.dart' as _i387;
import 'features/library/domain/usecases/get_recent_books.dart' as _i578;
import 'features/reader/domain/usecases/add_bookmark.dart' as _i915;
import 'features/reader/domain/usecases/delete_bookmark.dart' as _i916;
import 'features/reader/domain/usecases/get_bookmarks.dart' as _i574;
import 'features/reader/domain/usecases/update_reading_progress.dart' as _i530;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i476.StoragePathService>(() => _i476.StoragePathService());
    gh.factory<_i856.LibraryLocalDataSource>(
      () => _i856.LibraryLocalDataSource(gh<_i111.AppDatabase>()),
    );
    gh.factory<_i915.AddBookmark>(
      () => _i915.AddBookmark(gh<_i111.AppDatabase>()),
    );
    gh.factory<_i916.DeleteBookmark>(
      () => _i916.DeleteBookmark(gh<_i111.AppDatabase>()),
    );
    gh.factory<_i574.GetBookmarks>(
      () => _i574.GetBookmarks(gh<_i111.AppDatabase>()),
    );
    gh.factory<_i921.LibraryRepository>(
      () => _i1002.LibraryRepositoryImpl(gh<_i856.LibraryLocalDataSource>()),
    );
    gh.factory<_i369.ImportEpub>(
      () => _i369.ImportEpub(
        gh<_i921.LibraryRepository>(),
        gh<_i476.StoragePathService>(),
      ),
    );
    gh.factory<_i120.DeleteBook>(
      () => _i120.DeleteBook(gh<_i921.LibraryRepository>()),
    );
    gh.factory<_i387.GetAllBooks>(
      () => _i387.GetAllBooks(gh<_i921.LibraryRepository>()),
    );
    gh.factory<_i578.GetRecentBooks>(
      () => _i578.GetRecentBooks(gh<_i921.LibraryRepository>()),
    );
    gh.factory<_i530.UpdateReadingProgress>(
      () => _i530.UpdateReadingProgress(gh<_i921.LibraryRepository>()),
    );
    return this;
  }
}
