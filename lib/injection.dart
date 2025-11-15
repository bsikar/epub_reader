import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:epub_reader/core/database/app_database.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  // Initialize database
  final database = AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);

  // Configure other dependencies with injectable
  getIt.init();
}
