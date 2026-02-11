import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';

/// Provider for DatabaseHelper singleton
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

/// Provider for CarRepository
final carRepositoryProvider = Provider<CarRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return CarRepository(databaseHelper: databaseHelper);
});
