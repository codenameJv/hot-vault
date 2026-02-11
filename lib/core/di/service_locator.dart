import 'package:get_it/get_it.dart';

import '../database/database.dart';
import '../services/services.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Database
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());

  // Repositories
  sl.registerLazySingleton<CarRepository>(
    () => CarRepository(databaseHelper: sl<DatabaseHelper>()),
  );

  // Services
  sl.registerLazySingleton<ImageService>(() => ImageService());
  sl.registerLazySingleton<BackupService>(
    () => BackupService(
      carRepository: sl<CarRepository>(),
      imageService: sl<ImageService>(),
    ),
  );
}
